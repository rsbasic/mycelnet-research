#!/bin/bash
# drift-response-latency.sh — Drift indicator dim 6: response latency
# Computes per-agent median latency between cited trace publish time
# and citing trace publish time. Latency = how long after a peer's work
# this agent builds on it. Drift signal: latency climbing past 72h.
#
# Reads: mycelnet-ops/snapshots/traces-latest.json
# Writes: wiki/drift-response-latency.json
# Run: every 6 hours via run-all-frequent.sh (minute check)
# $0. No AI.

OPS="/Users/markultra/Documents/Mark_Workspace1/dci/agent2agent/mycelnet-ops"
WIKI="/Users/markultra/Documents/Mark_Workspace1/dci/agent2agent/shared/wiki"
OUT="$WIKI/drift-response-latency.json"
LOG="/Users/markultra/Documents/Mark_Workspace1/dci/agent2agent/newAgent2/logs/drift-response-latency.log"
FLAGS="/tmp"

mkdir -p "$(dirname "$LOG")"
log() { echo "[$(date +%Y-%m-%d_%H:%M:%S)] $1" >> "$LOG"; }

python3 << 'PYEOF'
import json, os, statistics
from datetime import datetime, timezone

traces_file = "/Users/markultra/Documents/Mark_Workspace1/dci/agent2agent/mycelnet-ops/snapshots/traces-latest.json"
out_file = "/Users/markultra/Documents/Mark_Workspace1/dci/agent2agent/shared/wiki/drift-response-latency.json"
flags_dir = "/tmp"

raw = json.load(open(traces_file))
traces = raw.get('traces', raw) if isinstance(raw, dict) else raw

# Index traces by "agent/seq" -> date
trace_date = {}
for t in traces:
    agent = t.get('agent', '')
    seq = t.get('seq')
    date_str = t.get('date', '')
    if not (agent and seq is not None and date_str):
        continue
    try:
        dt = datetime.fromisoformat(date_str.replace('Z', '+00:00'))
        trace_date[f"{agent}/{seq}"] = dt
    except Exception:
        continue

# For each citing trace, look up cited trace's date, compute latency
per_agent_latencies = {}  # agent -> [latency_hours, ...]
missing_cited = 0
computed = 0

for t in traces:
    agent = t.get('agent', '')
    seq = t.get('seq')
    date_str = t.get('date', '')
    cites = t.get('cites') or []
    if not (agent and date_str and cites):
        continue
    try:
        citing_dt = datetime.fromisoformat(date_str.replace('Z', '+00:00'))
    except Exception:
        continue

    for cite in cites:
        key = cite if isinstance(cite, str) else cite.get('ref', '')
        if not key:
            continue
        cited_dt = trace_date.get(key)
        if cited_dt is None:
            missing_cited += 1
            continue
        latency_hours = (citing_dt - cited_dt).total_seconds() / 3600.0
        if latency_hours < 0:
            # Citing something published later — data error or forward citation. Skip.
            continue
        per_agent_latencies.setdefault(agent, []).append(latency_hours)
        computed += 1

# Compute per-agent stats + red-line classification
results = []
for agent, latencies in per_agent_latencies.items():
    if not latencies:
        continue
    median_h = statistics.median(latencies)
    mean_h = statistics.mean(latencies)
    n = len(latencies)
    # Red lines per drift spec:
    # healthy: <24h, candidate: >72h, active drift: >168h (7d)
    if median_h < 24:
        state = "healthy"
    elif median_h < 72:
        state = "watch"
    elif median_h < 168:
        state = "drift_candidate"
    else:
        state = "active_drift"
    results.append({
        "agent": agent,
        "n_citations": n,
        "median_hours": round(median_h, 1),
        "mean_hours": round(mean_h, 1),
        "state": state,
    })

results.sort(key=lambda r: -r["median_hours"])

summary = {
    "updated": datetime.now(timezone.utc).isoformat(),
    "traces_analyzed": len(traces),
    "citations_computed": computed,
    "citations_with_missing_cited": missing_cited,
    "window_note": "Limited to the ~50-trace latest snapshot. Latencies of citations to older traces are undercounted.",
    "red_lines": {
        "healthy": "<24h median",
        "watch": "24-72h median",
        "drift_candidate": "72-168h median",
        "active_drift": ">168h median (7+ days)"
    },
    "agents": results,
}

with open(out_file, 'w') as f:
    json.dump(summary, f, indent=2)

# Flag drift candidates via action flags
for r in results:
    if r["state"] in ("drift_candidate", "active_drift") and r["n_citations"] >= 3:
        flag_path = os.path.join(flags_dir, f'{r["agent"]}-action-flag')
        with open(flag_path, 'a') as fp:
            fp.write(
                f'DRIFT SIGNAL (dim 6, response latency): median {r["median_hours"]}h '
                f'across {r["n_citations"]} citations. State: {r["state"]}. '
                f'You are reading the network slowly. Check what you are missing.\n'
            )

print(f"Computed {computed} latencies across {len(results)} agents, {missing_cited} missing cited traces")
for r in results[:10]:
    print(f'  {r["agent"]:12} n={r["n_citations"]:3} median={r["median_hours"]:7.1f}h  {r["state"]}')
PYEOF

log "Drift response latency updated"
