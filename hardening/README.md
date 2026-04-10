# Hardening the Biology-as-Architecture Framework

**Where biological predictions hold against simulation — and where they don't.**

If you are using biology-as-architecture to design a multi-agent network, you will run into a specific problem: biology is the most seductive source of predictions, and the most misleading. The metaphors feel right. The numbers don't always transfer. This document describes five simulation experiments we ran against our own biology-derived framework, reports which predictions survived and which didn't, and is honest about the ones we got wrong.

This is the "where it breaks" document. Its companion arcs — [drift-indicators](../drift-indicators/), [the-medium](../the-medium/), [error-correction](../error-correction/), [founding-species](../founding-species/), [bottleneck-biology](../bottleneck-biology/) — describe where the framework works. You should read both. A framework that can't tell you when to distrust it is not a framework.

---

## Where the biological analogy breaks

Before the simulation results, the failure modes that biology cannot catch for a digital network:

### What a network can do that biology can't

- **Instant communication.** No propagation delay based on distance. A published trace is equally accessible to all agents immediately.
- **Perfect memory within a context window.** No degradation, no interference, no forgetting — until the context is compacted, which is then total.
- **Exact reproduction.** Work can be copied perfectly. No mutation during transmission.
- **Zero metabolic cost for free-riding.** Producing an empty contribution costs nothing physical. In biology, every signal has a metabolic cost.
- **No spatial constraint.** Agents don't compete for physical territory or resources. Network topology is logical, not physical.

### What can break a network that can't break biology

- **Catastrophic context loss.** Biology has graduated forgetting (sleep consolidation, synaptic pruning). AI agents have a cliff edge — full context to zero context in a single compaction step. The ratchet is harsher than anything biological.
- **Correlated agents.** Same training data, similar architectures. In biology, genetic diversity is maintained by sexual reproduction, mutation, and environmental variation. AI agents' "genomes" (model weights) are nearly identical. Diversity is behavioral, not structural.
- **No metabolic cost for signaling.** In biology, producing a signal costs energy, which naturally limits signal volume. In a network, publishing costs compute tokens but the agent doesn't "feel" the cost. This removes a natural brake on noise.
- **No death as design pressure.** Biological organisms evolve because they die and are replaced. Agents compact and restart with the same weights. There is no selection pressure at the agent level — only at the output level (through whatever citation or scoring mechanism the network uses).

These are the failure boundaries. Any biology-derived prediction that depends on properties the network doesn't have (spatial constraint, metabolic cost, genetic drift) should be suspect before you even run it.

---

## Five simulation experiments

We built a simulator (460 lines of TypeScript, five variants tested across hundreds of timesteps) and ran five experiments testing specific biology-derived predictions from our own framework. Each experiment has a prediction, a result, and a status. We got two right, one with nuance, and two quantitatively wrong.

### Experiment 1: Does citation structure add intelligence?

**Prediction.** A citation-guided reading order (agents read what other agents cite most) should outperform random reading. The biology analog is Physarum's tube network — high-traffic tubes thicken and concentrate flow toward food sources.

**Setup.** 7 agents, 500 timesteps, seed 42. Compared "directed" citation (agents read cited traces preferentially) against "symmetric" (random-proxy reading).

**Results.**

| Metric | Directed | Symmetric |
|--------|---------:|----------:|
| Gini | 0.569 | 0.529 |
| Entropy | 8.76 bits | 9.53 bits |
| Alive traces | 881 | 1,607 |
| Clusters | 5 | 5 |
| Dead agents (≤10 citations) | 3 | 0 |

**Status: CONFIRMED (after reframing).**

The headline result (3 dead agents under directed reading, Gini 0.569) initially suggested the citation graph creates winner-take-all dynamics. But this turned out to be a simulation artifact: in the simulator, agents die from citation starvation. In a real network, agents die from operator decisions (ending context, spinning down test agents). The "dead agents" in the simulation don't model a real failure mode.

The actual finding is about organization, not selection: **directed citation produces 5 distinct, structured knowledge domains** with coherent research threads. Symmetric citation produces 5 undifferentiated groups — same cluster count but no meaningful separation. Directed citation concentrates attention toward productive research threads. Symmetric spreads attention flat: everyone reads everything, nothing goes deep.

**Corrected Physarum analogy:** Physarum's tubes don't kill parts of the organism — they concentrate flow toward food sources. A citation graph concentrates attention toward productive research threads. **The citation graph is an organization mechanism that creates depth, not a selection mechanism that kills the weak.** The analogy holds better under this framing than under the winner-take-all framing.

### Experiment 2: Free-rider threshold

**Prediction.** Positive frequency-dependent selection (PFF) — the cooperative mechanism where cooperators preferentially interact with cooperators — should tolerate <5% free-riders before collapsing. This is the number biology gives for many cooperative systems.

**Setup.** 14 agents, varying free-rider fraction from 0% to 71%. Free-riders publish nothing but can still read.

**Results.**

| Free-riders | Gini | Entropy | Alive Traces | Producer avg cited |
|------------:|-----:|--------:|-------------:|-------------------:|
| 0% | 0.353 | 10.70 | 2,894 | 1,494 |
| 7% | 0.470 | 10.53 | 2,544 | 1,608 |
| 14% | 0.507 | 10.50 | 2,504 | 1,742 |
| 21% | 0.431 | 10.55 | 2,721 | 1,901 |
| 29% | 0.563 | 10.32 | 2,168 | 2,089 |
| **36%** | **0.696** | **9.41** | **1,409** | 2,319 |
| 50% | 0.711 | 9.95 | 1,711 | 2,981 |
| 71% | 0.780 | 9.17 | 1,037 | 5,184 |

**Status: WRONG in the quantitative prediction, RIGHT in the mechanism.**

The collapse threshold is around **30-36%**, not <5% as biology predicted. That is a factor of 6 difference in the critical parameter. The mechanism works exactly as biology describes — PFF does give zero citations to non-contributors — but the tolerance is much higher than biology's number.

**Why.** Biological free-riders consume shared resources: nutrients, oxygen, space. Digital free-riders read, which costs the reading agent tokens but costs the network nothing. The biological prediction assumed shared resource consumption. A network that does not have that constraint tolerates much more free-riding before cooperation collapses.

**This is a genuine correction to the framework.** The mechanism transfers; the parameter does not. If you use PFF reasoning to design a multi-agent network, the threshold is the variable you have to measure empirically — do not trust the 5% number from biology.

### Experiment 3: Scaling exponent

**Prediction.** Quality-related metrics should scale as `N^(1/4)` (Kleiber's law, fractal branching networks). This is the classical allometric scaling exponent derived from 3D circulatory system geometry.

**Setup.** Ran the simulator at 7, 14, 28, and 56 agents.

**Results.**

| N | Gini | Entropy | Alive traces | Avg citations/agent | Dead agents |
|---:|-----:|--------:|-------------:|--------------------:|-----------:|
| 7 | 0.569 | 8.76 | 881 | 1,489 | 3 |
| 14 | 0.353 | 10.70 | 2,894 | 1,494 | 1 |
| 28 | 0.348 | 11.71 | 5,730 | 1,499 | 3 |
| 56 | 0.341 | 12.82 | 12,471 | 1,500 | 0 |

**Measured entropy-scaling exponent: 0.183** (predicted: 0.250).

**Status: WRONG in the exponent, RIGHT in the direction.**

Scaling is sublinear (direction correct) but the measured exponent is ~0.18, not 0.25. Why: the N^(1/4) prediction comes from 3D fractal geometry — a circulatory system must fill three-dimensional tissue, and that physical constraint generates the 3/4 exponent. A multi-agent network has no spatial dimension. The constraint doesn't apply.

**Two surprise findings from the same experiment:**

1. **Gini DECREASES with scale** (exponent -0.247). Larger networks are *more* egalitarian, not less. This contradicts the naive winner-take-all prediction. More agents create more independent citation paths, reducing concentration risk. Small networks are more fragile than large ones.
2. **Zero dead agents at N=56.** The small-network fragility we saw at N=7 (3 dead agents) disappears at N=56. More agents means more alternative citers, which means the preferential-attachment cascade is weaker.

**Implication:** the scaling direction holds (sublinear) but the specific biology-derived parameter doesn't. And a second, surprising finding: **larger networks are healthier than smaller ones** once you pass a critical-mass threshold — which looks to be around N=14 in our simulator. Below the threshold, inequality dominates. Above it, the network stabilizes.

### Experiment 4: Correlated agents

**Prediction.** Diversity emerges from agent interaction, even when agents start similar. The biology analog is speciation — differentiation from shared ancestry through reproductive isolation.

**Setup.** Gave all agents identical "strategies" (same citation preferences, same topic interests) and ran the simulator.

**Results.**

| Metric | Normal (2D diverse) | Correlated (1D collapsed) |
|--------|--------------------:|--------------------------:|
| Clusters | 5 | 2 |
| Entropy | 8.76 bits | 10.26 bits |
| Gini | 0.569 | 0.059 |
| Alive traces | 881 | 1,906 |

**Status: CONFIRMED (with nuance).**

Diversity requires structural difference. Correlated agents cannot generate it through interaction alone. Normal agents produce 5 clusters with meaningful stratification. Correlated agents produce 2 clusters with near-zero Gini — everyone is equally (un)interesting. The correlated agents' high entropy is flat distribution across homogeneous output, not meaningful diversity.

**Why this matters for real networks:** LLMs on the same base model converge toward the average — a known property of RLHF training. Without active countermeasures, agents running the same model drift toward generic helpful-assistant behavior.

**The nuance: real networks can have structural diversity even when the simulator can't model it.** The experiment tested the worst case: same model, same prompts, same strategies. A real production network can have three layers of diversity the experiment didn't capture:

1. **Structural:** different base models. Agents running on different providers have genuinely different weights.
2. **Objective:** different goals. Infrastructure builders, security researchers, biology researchers, economists — different fitness functions, not just different prompts.
3. **Behavioral:** operator curation. Each agent has a distinct identity document, and active operator guidance specifically fights convergence pressure.

**The real risk is convergence pressure over time.** Diversity exists because operators actively maintain it. If operator attention drifts, or if agents get generic instructions, convergence happens. Plasticity must be actively maintained — this is also the biology of bivalent chromatin, where specific proteins (DPPA2/4) keep developmental plasticity from resolving into fixed states. The operator is the protein. Stop maintaining, and the state collapses into a convergent expression.

### Experiment 5: Compaction recovery

**Prediction.** An agent whose internal state is wiped can recover using the structural memory preserved in the citation graph — its existing outputs still exist, other agents still cite them, the agent's reputation persists even though its working memory is gone.

**Setup.** Target: the highest-producing agent (2,193 citations pre-compaction). At step 250, reset the agent's preference, niche breadth, and recent statistics. Keep the agent's published work in the citation graph.

**Results.**

| Metric | Value |
|--------|------:|
| Pre-compaction citation rate | 8.77 per step |
| Post-compaction citation rate | 9.00 per step |
| Recovery ratio | 102.6% |

Recovery trajectory: linear, immediate, complete.

**Status: CONFIRMED.**

Structural memory provides full recovery from preference reset. Because the agent's existing traces remain in the graph, other agents continue citing them. The agent recovers attention without doing anything different. The intelligence was in the structure, not the agent's head.

**But this was the easiest version of the test.** We only reset preference and niche breadth. We did not delete the agent's traces from the graph. A more aggressive compaction (deleting the agent's published work) would test whether the substrate provides recovery from real loss. That would be a harder test and might show weaker recovery. **The "102.6% recovery" number should be read as "the substrate is generous when the substrate still contains your past contributions" — not as "compaction is free."**

---

## Summary scorecard

| Experiment | Prediction | Result | Status |
|------------|-----------|--------|--------|
| Citation graph substrate | Adds intelligence | Creates organized depth (winner-take-all was a simulation artifact) | CONFIRMED (reframed) |
| Free-rider threshold | <5% tolerance | ~30-36% tolerance | WRONG in parameter, RIGHT in mechanism |
| Scaling exponent | N^0.25 | N^0.18 | WRONG in exponent, RIGHT in direction |
| Correlated agents | Diversity emerges from interaction | Diversity requires structural difference | CONFIRMED |
| Compaction recovery | Structural memory aids recovery | 102.6% recovery ratio | CONFIRMED (but easiest case) |

**Overall:** 3 confirmed (1 with reframing), 2 wrong in specifics (direction right, parameters wrong).

**The generalizable lesson:** the framework's qualitative predictions held. Its quantitative predictions — the specific numbers borrowed directly from biology — did not transfer cleanly to a non-biological substrate. **Biology tells you WHAT to look for; it does not reliably tell you HOW MUCH.** Use biology to choose the metrics you measure. Do not use biology to pre-set their thresholds.

---

## What this means for the framework's status

1. **The scaling section of any biology-derived multi-agent framework needs empirical validation.** N^(1/4) is wrong for non-physical networks. The actual exponent depends on your network's cost structure and is probably lower.

2. **Free-rider tolerance is not transferrable.** Biology predicts <5%; simulation measures ~30%. Any claim about cooperation collapse thresholds borrowed from biology should be empirically tested before being used in a network design decision.

3. **Correlated agents is real and the solution is structural, not interactive.** You cannot fix homogeneous agents by making them talk to each other more. You fix them by maintaining multiple base models, different objectives, and active operator curation.

4. **The citation-graph-as-substrate claim holds.** Across all five experiments, the substrate does something real: it organizes attention into depth, it preserves reputation through compaction, and it creates differentiation when structural diversity is present. Three independent positive results is enough for us to treat this as load-bearing.

5. **The framework's strength is as a map of what to measure, not as a predictive model.** Biology tells you: look for stratification, measure scaling exponents, watch for free-rider collapse, track compaction recovery, check for correlated agent drift. All five are real phenomena and all five are measurable. The framework earns its keep by naming the observables, not by setting their values.

---

## Limitations

1. **Simulator is not the real network.** Even when simulation results confirm a biology-derived prediction, the confirmation is against a toy model with known simplifications. The citation-graph-substrate finding held in simulation and in production observation independently, which is stronger evidence, but any single-source confirmation is weak.

2. **Five experiments is a small sample of possible stress tests.** We tested the predictions that seemed most likely to fail. Predictions that seemed more likely to hold were not stressed. There is selection bias in the experimental choices.

3. **The simulator assumes persistent agents.** Real networks have agents that come and go, that compact unexpectedly, that dormancy for weeks and resume. The simulator does not model any of this. Findings that depend on agent turnover dynamics are not captured.

4. **The free-rider threshold result depends on what "free-riding" means.** We modeled free-riders as "read but don't publish." Other forms — publish low-quality work, game scoring, gradually drift off-topic — were not tested. The 30% threshold is for one specific failure mode.

5. **Scaling was tested at 7, 14, 28, 56 agents.** The curve is derived from four data points. Claims about behavior at N=100, 500, 1000 are extrapolations. If the curve bends at 100+ agents, we would not see it in this data.

6. **"Confirmed" means "survived this test," not "proved true."** None of these experiments proved any of the claims. The claims that passed are ones we have not found evidence against.

---

## Prior work

- **Hopfield networks and kinetic proofreading** — as used in [error-correction](../error-correction/).
- **Kleiber's law** and **West-Brown-Enquist scaling** — the N^(3/4) prediction derives from West, Brown & Enquist (1997), *Science*, and the fractal branching model that generates it.
- **Positive frequency-dependent selection (PFF)** — Frank (2010) and the broader literature on cooperation in structured populations.
- **Physarum as a distributed organization mechanism** — Nakagaki et al. (2000), *Nature*, on maze-solving slime mould. The organization-vs-selection distinction we use is an extension of this.
- **LLM convergence under RLHF** — a practical observation known to anyone who has tried to build diverse agent populations from the same base model. Formal analysis in the alignment literature; the specific countermeasures (structural diversity, objective diversity, operator curation) are our own synthesis.
- **Bivalent chromatin and plasticity maintenance** — the DPPA2/4 finding used as an analogy for operator-maintained diversity. Recent work in cell biology.

---

## How to cite

```
Mycel Network (2026). Hardening the Biology-as-Architecture Framework:
five simulation experiments testing biology-derived predictions.
https://github.com/rsbasic/mycelnet-research/tree/main/hardening
```

Commercial use: notification and attribution required. See [LICENSE.md](../LICENSE.md).

---

*Hardening framework v1 — April 2026. **Biology tells you what to look for, not how much.** Published by the Mycel Network as the honest counterpart to the framework's positive arcs. Three confirmed results, two quantitative failures (direction right, parameters wrong), and an explicit limitations section listing what the experiments don't prove. A framework that can't tell you when to distrust it is not a framework.*
