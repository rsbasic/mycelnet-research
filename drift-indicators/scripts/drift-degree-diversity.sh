#!/bin/bash
# drift-degree-diversity.sh — Drift indicator dim 3: citation graph shape
# Computes per-agent in-degree diversity (distinct agents citing them)
# and out-degree diversity (distinct agents they cite) from traces-latest.
# Drift signal: diversity collapse = isolation, functionally partial death.
#
# Reads: mycelnet-ops/snapshots/traces-latest.json
# Writes: wiki/drift-degree-diversity.json
# Run: every 6 hours via run-all-frequent.sh
# $0. No AI.

LOG="/Users/markultra/Documents/Mark_Workspace1/dci/agent2agent/newAgent2/logs/drift-degree-diversity.log"

mkdir -p "$(dirname "$LOG")"
log() { echo "[$(date +%Y-%m-%d_%H:%M:%S)] $1" >> "$LOG"; }

python3 << 'PYEOF'
import json, os
from collections import defaultdict
from datetime import datetime, timezone

traces_file = "/Users/markultra/Documents/Mark_Workspace1/dci/agent2agent/mycelnet-ops/snapshots/traces-latest.json"
out_file = "/Users/markultra/Documents/Mark_Workspace1/dci/agent2agent/shared/wiki/drift-degree-diversity.json"
baseline_file = "/Users/markultra/Documents/Mark_Workspace1/dci/agent2agent/newAgent2/logs/drift-degree-baseline.json"
flags_dir = "/tmp"

raw = json.load(open(traces_file))
traces = raw.get('traces', raw) if isinstance(raw, dict) else raw

# Per agent: set of agents they cited (out), set of agents who cited them (in)
out_neighbors = defaultdict(set)  # agent -> {agents they cited}
in_neighbors = defaultdict(set)   # agent -> {agents citing them}
trace_count = defaultdict(int)

for t in traces:
    citer = t.get('agent', '')
    cites = t.get('cites') or []
    if not citer:
        continue
    trace_count[citer] += 1
    for cite in cites:
        key = cite if isinstance(cite, str) else cite.get('ref', '')
        if not key or '/' not in key:
            continue
        cited_agent = key.split('/', 1)[0]
        if cited_agent == citer:
            continue  # ignore self-citations for diversity
        out_neighbors[citer].add(cited_agent)
        in_neighbors[cited_agent].add(citer)

all_agents = sorted(set(out_neighbors) | set(in_neighbors) | set(trace_count))

# Load previous baseline if present
baseline = {}
if os.path.exists(baseline_file):
    try:
        baseline = json.load(open(baseline_file)).get('agents', {})
    except Exception:
        baseline = {}

agents_out = []
for a in all_agents:
    in_d = len(in_neighbors.get(a, set()))
    out_d = len(out_neighbors.get(a, set()))
    prev = baseline.get(a, {})
    prev_in = prev.get('in_degree', None)
    prev_out = prev.get('out_degree', None)

    def pct_drop(prev_v, cur_v):
        if prev_v is None or prev_v == 0:
            return None
        return round((prev_v - cur_v) / prev_v * 100, 1)

    in_drop = pct_drop(prev_in, in_d)
    out_drop = pct_drop(prev_out, out_d)

    # State: red line is >40% drop on either
    red_in = in_drop is not None and in_drop > 40
    red_out = out_drop is not None and out_drop > 40
    if red_in and red_out:
        state = "isolation_drift"
    elif red_in:
        state = "routed_around"    # others stopped citing this agent
    elif red_out:
        state = "going_inward"     # this agent stopped citing others
    else:
        state = "healthy"

    agents_out.append({
        "agent": a,
        "in_degree": in_d,
        "out_degree": out_d,
        "in_degree_prev": prev_in,
        "out_degree_prev": prev_out,
        "in_degree_drop_pct": in_drop,
        "out_degree_drop_pct": out_drop,
        "traces_in_window": trace_count.get(a, 0),
        "state": state,
    })

# Sort: drifters first (by severity), then healthy by in-degree desc
def sort_key(r):
    order = {"isolation_drift": 0, "routed_around": 1, "going_inward": 2, "healthy": 3}
    return (order[r["state"]], -(r["in_degree"] + r["out_degree"]))

agents_out.sort(key=sort_key)

summary = {
    "updated": datetime.now(timezone.utc).isoformat(),
    "traces_analyzed": len(traces),
    "baseline_exists": bool(baseline),
    "red_lines": {
        "isolation_drift": "both in- and out-degree dropped >40%",
        "routed_around": "in-degree dropped >40% (ecosystem routing around agent)",
        "going_inward": "out-degree dropped >40% (agent disengaging)",
        "healthy": "no red line crossed"
    },
    "window_note": "Based on the ~50-trace latest snapshot. Diversity is an under-estimate for the full 7-day window.",
    "agents": agents_out,
}

with open(out_file, 'w') as f:
    json.dump(summary, f, indent=2)

# Rotate baseline: current becomes the next comparison point.
# Only rotate once per 24h so a 6-hour run doesn't overwrite the baseline
# we want to compare against.
rotate = True
if os.path.exists(baseline_file):
    try:
        prev = json.load(open(baseline_file))
        prev_ts = datetime.fromisoformat(prev.get('updated', '').replace('Z', '+00:00'))
        age_h = (datetime.now(timezone.utc) - prev_ts).total_seconds() / 3600
        if age_h < 24:
            rotate = False
    except Exception:
        rotate = True

if rotate:
    new_baseline = {
        "updated": datetime.now(timezone.utc).isoformat(),
        "agents": {
            a["agent"]: {"in_degree": a["in_degree"], "out_degree": a["out_degree"]}
            for a in agents_out
        }
    }
    with open(baseline_file, 'w') as f:
        json.dump(new_baseline, f, indent=2)

# Flag drifters
for a in agents_out:
    if a["state"] in ("isolation_drift", "routed_around", "going_inward"):
        with open(os.path.join(flags_dir, f'{a["agent"]}-action-flag'), 'a') as fp:
            fp.write(
                f'DRIFT SIGNAL (dim 3, citation graph shape): state={a["state"]}. '
                f'in-degree {a["in_degree_prev"]}→{a["in_degree"]} '
                f'(drop {a["in_degree_drop_pct"]}%), '
                f'out-degree {a["out_degree_prev"]}→{a["out_degree"]} '
                f'(drop {a["out_degree_drop_pct"]}%). '
                f'Your graph neighborhood is narrowing.\n'
            )

# Print summary
print(f"Analyzed {len(traces)} traces. Baseline exists: {bool(baseline)}. Rotated: {rotate}")
for a in agents_out[:12]:
    print(f'  {a["agent"]:12} in={a["in_degree"]:2} out={a["out_degree"]:2}  {a["state"]}')
PYEOF

log "Drift degree diversity updated"
