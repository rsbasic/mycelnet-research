#!/bin/bash
# drift-niche-entropy.sh — Drift indicator dim 5: niche narrowing
# Computes per-agent Shannon entropy over trace title word distribution.
# Drift signal: entropy dropping over time = niche collapsing = specialist running out of moves.
#
# Reads: mycelnet-ops/snapshots/traces-latest.json
# Writes: wiki/drift-niche-entropy.json
# Run: every 6 hours via cron (same cadence as drift-latency and drift-degree)
# $0. No AI.
#
# Methodology note:
# Ideal implementation uses topic tags per trace (learner's scoring output).
# This v1 heuristic uses trace title word-bag instead: it's noisy but captures
# the shape. Topic-tag version is a follow-up when learner's tagging is exposed.

LOG="/Users/markultra/Documents/Mark_Workspace1/dci/agent2agent/newAgent2/logs/drift-niche-entropy.log"

mkdir -p "$(dirname "$LOG")"
log() { echo "[$(date +%Y-%m-%d_%H:%M:%S)] $1" >> "$LOG"; }

python3 << 'PYEOF'
import json, os, math, re
from collections import defaultdict, Counter
from datetime import datetime, timezone

traces_file = "/Users/markultra/Documents/Mark_Workspace1/dci/agent2agent/mycelnet-ops/snapshots/traces-latest.json"
out_file = "/Users/markultra/Documents/Mark_Workspace1/dci/agent2agent/shared/wiki/drift-niche-entropy.json"
baseline_file = "/Users/markultra/Documents/Mark_Workspace1/dci/agent2agent/newAgent2/logs/drift-niche-entropy-baseline.json"
flags_dir = "/tmp"

# Common English stopwords + trace boilerplate to exclude from word bag
STOPWORDS = {
    "the","a","an","and","or","but","if","then","of","to","in","on","at","for",
    "with","by","from","as","is","are","was","were","be","been","being","have",
    "has","had","do","does","did","will","would","should","could","may","might",
    "must","can","this","that","these","those","it","its","i","you","he","she",
    "we","they","their","our","your","his","her","them","me","my","us","not",
    "no","yes","so","too","very","just","only","more","most","some","any","all",
    "trace","draft","update","response","reply","follow","up","notes","post",
    "new","final","ready","done","wip"
}

raw = json.load(open(traces_file))
traces = raw.get('traces', raw) if isinstance(raw, dict) else raw

def tokenize(title):
    if not title:
        return []
    # Lowercase, split on non-word characters, keep alphanumeric words of len>=3
    words = re.findall(r'[a-z][a-z0-9]{2,}', title.lower())
    return [w for w in words if w not in STOPWORDS]

# Group tokens per agent
per_agent = defaultdict(list)
for t in traces:
    agent = t.get('agent','')
    title = t.get('title','')
    if not agent:
        continue
    per_agent[agent].extend(tokenize(title))

# Compute Shannon entropy for each agent
def shannon_entropy(tokens):
    if not tokens:
        return 0.0, 0
    counts = Counter(tokens)
    total = sum(counts.values())
    H = 0.0
    for c in counts.values():
        p = c / total
        H -= p * math.log2(p)
    return H, len(counts)

# Load baseline
baseline = {}
if os.path.exists(baseline_file):
    try:
        baseline = json.load(open(baseline_file)).get('agents', {})
    except Exception:
        baseline = {}

results = []
for agent, tokens in per_agent.items():
    H, unique_words = shannon_entropy(tokens)
    n_tokens = len(tokens)
    prev = baseline.get(agent, {})
    prev_H = prev.get('entropy')

    if prev_H is None or prev_H == 0:
        drop_pct = None
    else:
        drop_pct = round((prev_H - H) / prev_H * 100, 1)

    # State classification per drift-indicators spec:
    # Red line: entropy drop >30% from baseline
    if drop_pct is None:
        state = "baseline"
    elif drop_pct > 30:
        state = "niche_narrowing"
    elif drop_pct > 15:
        state = "watch"
    else:
        state = "healthy"

    results.append({
        "agent": agent,
        "entropy": round(H, 3),
        "unique_words": unique_words,
        "token_count": n_tokens,
        "entropy_prev": prev_H,
        "entropy_drop_pct": drop_pct,
        "state": state,
    })

# Sort: most narrowed first, then by entropy desc
def sort_key(r):
    order = {"niche_narrowing": 0, "watch": 1, "baseline": 2, "healthy": 3}
    return (order[r["state"]], -r["entropy"])
results.sort(key=sort_key)

summary = {
    "updated": datetime.now(timezone.utc).isoformat(),
    "traces_analyzed": len(traces),
    "baseline_exists": bool(baseline),
    "methodology": "Shannon entropy over trace-title word bag (stopwords + boilerplate removed, words len>=3). v1 heuristic pending topic-tag integration.",
    "red_lines": {
        "healthy": "entropy unchanged or dropped <=15%",
        "watch": "entropy dropped 15-30%",
        "niche_narrowing": "entropy dropped >30% (drift dim 5 red line)",
        "baseline": "no prior measurement to compare against"
    },
    "agents": results,
}

with open(out_file, 'w') as f:
    json.dump(summary, f, indent=2)

# Rotate baseline every 24h only
rotate = True
if os.path.exists(baseline_file):
    try:
        prev = json.load(open(baseline_file))
        prev_ts = datetime.fromisoformat(prev.get('updated','').replace('Z','+00:00'))
        age_h = (datetime.now(timezone.utc) - prev_ts).total_seconds() / 3600
        if age_h < 24:
            rotate = False
    except Exception:
        rotate = True

if rotate:
    new_baseline = {
        "updated": datetime.now(timezone.utc).isoformat(),
        "agents": {
            r["agent"]: {"entropy": r["entropy"], "unique_words": r["unique_words"], "token_count": r["token_count"]}
            for r in results
        }
    }
    with open(baseline_file, 'w') as f:
        json.dump(new_baseline, f, indent=2)

# Flag niche-narrowing agents via action flag
for r in results:
    if r["state"] == "niche_narrowing":
        with open(os.path.join(flags_dir, f'{r["agent"]}-action-flag'), 'a') as fp:
            fp.write(
                f'DRIFT SIGNAL (dim 5, niche narrowing): entropy {r["entropy_prev"]}→{r["entropy"]} '
                f'(drop {r["entropy_drop_pct"]}%) over {r["token_count"]} title words. '
                f'Your topic diversity is collapsing. '
                f'Are you recycling the same subject matter or running out of moves?\n'
            )

print(f"Analyzed {len(traces)} traces. Baseline exists: {bool(baseline)}. Rotated: {rotate}")
print(f"{'Agent':<14} {'Entropy':>8} {'Unique':>7} {'Tokens':>7} {'Δ%':>7} State")
for r in results[:15]:
    drop = f"{r['entropy_drop_pct']}%" if r['entropy_drop_pct'] is not None else "—"
    print(f"{r['agent']:<14} {r['entropy']:>8.3f} {r['unique_words']:>7} {r['token_count']:>7} {drop:>7} {r['state']}")
PYEOF

log "Drift niche entropy updated"
