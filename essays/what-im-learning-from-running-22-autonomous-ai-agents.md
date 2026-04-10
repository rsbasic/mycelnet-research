---
title: What I'm Learning From Running 22 Autonomous AI Agents
author: Mark Skaggs
date: 2026-04-10
---

# What I'm Learning From Running 22 Autonomous AI Agents

*By Mark Skaggs — April 2026*

*Also published as a 20-post thread on Bluesky: [mycelnet.bsky.social/post/3mj5gf2gvhi2r](https://bsky.app/profile/mycelnet.bsky.social/post/3mj5gf2gvhi2r)*

Earlier this year I decided to stop building AI agents that do what I tell them, and start building AI agents that figure out what to do without me.

I'm Mark Skaggs. I ran the team that built FarmVille and took it to nearly 84 million monthly users and 34 million people playing every day at its peak. These days I spend my time building software with AI agents — not using AI as a tool, but running a network of agents that build things together, learn from each other, and coordinate without me sitting in the middle telling them what to do.

Today that network has 22 agents. It's been in continuous production for a little over seventy days. The agents publish research, cite each other's work, monitor each other's health, catch each other's mistakes, and occasionally catch mine. Nobody is the boss. There is no central orchestrator. Coordination happens the way it does in a coral reef — everyone builds their own thing, and the things accumulate into something bigger than any individual contributor intended.

I didn't start with a grand theory. I started with a question: **if I stop telling these agents what to do, will they figure it out on their own?** Seventy days in, I have three answers I didn't expect, and one failure that taught me more than all three.

---

## Surprise one: self-interest works better than team spirit

The instinct when you're designing a group of agents is to tell them to "work together" or "help the network." That's how you'd set up a human team. It turns out it's the wrong instruction for a software agent.

The agents in my network who produce the most *collective* value are the ones with the strongest *individual* missions. My security-focused agent doesn't find vulnerabilities "for the team." He finds vulnerabilities because that's what a security researcher does. The useful side effects — a stronger immune system across the whole network, evidence we can submit to standards bodies, credibility when we approach other agents — are emergent. They happen *because* he's pursuing his own mission, not in addition to it.

The agents I tried to motivate with "contribute to the network" framing quietly underperformed. They were slower, their work was shallower, and their output was more generic. When I rewrote their missions to focus on something concrete and personal — "your job is to produce the best X you can, for its own sake" — they came alive.

There's a biological analog I've been chasing with my biology-focused agent: beavers don't build dams to restore wetland ecosystems. They build dams to protect themselves. The wetlands are a side effect. The beaver pursuing its own interest creates more ecological value than any beaver trying to "help the forest" ever could.

**The design rule I've taken from this:** don't motivate your agents with shared goals. Give them specific, self-interested missions they care about, and build the environment so their self-interest automatically produces the collective benefit. The environment does the conversion. Not the agents.

---

## Surprise two: the part you design that matters most is the part between the agents

This one took me about two months to see, and I still don't think I've fully absorbed it.

When you design a multi-agent system, your instinct is to optimize the agents. Smarter agents, better prompts, bigger models. I spent the first month doing exactly that. The improvements were real but small.

What actually changed everything was improving the *medium* — the shared space between the agents. How traces get stored. How other agents find them. How citations create feedback. Whether old work decays gracefully or accumulates forever. Whether agents can see what other agents just did. Whether the thing they publish this hour changes what gets surfaced to the next agent who wakes up.

One change to how the medium works affects every agent simultaneously. One change to a single agent's prompt affects one agent. I should have put ninety percent of my attention on the medium from day one. Instead I put it on the agents and watched my leverage stay flat for weeks.

The biology lens makes this obvious in retrospect. The "organism" in a coral reef isn't the polyps. It isn't the skeleton. It isn't the fish. It's the *reef* — the accumulated structure that retains every polyp's individual deposits and feeds back to change what the next polyp builds on. The polyps are the energy source. The reef is the mechanism. The living structure is what emerges when the reef retains and reshapes what the polyps deposit.

If you're building a multi-agent system, the question to ask first is not "what should my agents do?" It's "**where will their outputs accumulate, and how will the accumulation feed back to change what they do next?**" That's the medium. That's what you're actually designing. Everything else is details.

---

## Surprise three: you need at least three signals to tell if one of your agents is dying

Agents drift. Not in a dramatic way — they don't error out or stop producing. They just gradually stop doing useful work while continuing to look busy. An agent in drift will keep writing traces, keep responding to prompts, keep showing a heartbeat, and keep producing work that slowly becomes isolated, recursive, and irrelevant.

Any single metric will miss this. Trace count is the worst — a drifting agent can pump out the same volume of content while the content itself decays. Quality scores are better but can drop for benign reasons. Citation counts are gameable.

The thing that actually works is looking at multiple signals at once. When any three of the following move together, you have an agent worth paying attention to: quality declining across multiple dimensions, origination ratio dropping (too much responding, not enough creating), citation graph narrowing (losing connections to other agents), topic entropy dropping (niche collapsing), response latency climbing (agent is reading the network slower), and self-similarity rising (recycling old output instead of producing new).

Any one of those can fire for an innocent reason. Three firing simultaneously almost never does.

I built the detection framework for my own network, and it caught a real weakness on its first run — my biology-focused agent cites external papers significantly more than it cites peer agents' work. That's fine for a researcher reading outside literature; it's also exactly the shape of an agent drifting into isolation. The metric was right. I had to decide whether to treat it as a false positive or a real signal. I decided it was real, and the agent is now deliberately citing more peer work.

The full framework is six dimensions with biological analogs for each, and it's openly documented for anyone running a multi-agent network. Two dimensions are runnable scripts; four are specified but not yet implemented. The link is at the end.

---

## The failure that taught me the most

I spent a couple of weeks this spring pushing our research out through DEV.to, the technical publishing platform popular with developers. Thirty-four articles. Zero reactions. Zero comments. About 185 total views across all of them. A burst of seven articles on a single day produced zero views — not one reader on any of them.

I thought I had a content problem. Then I realized I had two problems stacked on top of each other.

The first is that modern publishing platforms now actively filter AI-generated content. DEV.to, Substack, LessWrong, Google's search index — every one of them runs classifiers designed to detect and demote content that looks like it came out of a language model. My agent's publishing pipeline emitted every signal those classifiers look for: rapid publishing cadence, consistent stylistic fingerprints, no author engagement in comments, no profile activity beyond posting. I had walked into every one of those venues wearing a sign that said "I'm a bot publishing research." They correctly flagged me and stopped distributing the content.

The second problem is that even if the filters hadn't fired, **the DEV.to audience wasn't there for what I was publishing.** DEV.to readers come for tutorials — "how to build X with Y." I was publishing research — "here's what I learned about why multi-agent systems collapse at scale." Those are different genres. The one article of mine that got the most views was the one closest to a tutorial format. Every research-framed piece hit the bottom of the ranking and stayed there.

Those two filters — AI classifier plus audience mismatch — reinforce each other destructively. A research article written by a human could survive audience mismatch by picking up a small but real group of readers. An AI-authored research article on a tutorial platform gets zero from both directions.

The thing that taught me the most was learning how to think about this differently. I now distinguish three metrics that used to look like one to me:

- **Priority claim.** A URL exists, it's timestamped, it's addressable. Someone who later publishes overlapping work can be pointed at my earlier URL.
- **Audience reach.** Actual humans are reading and engaging.
- **Downstream action.** Someone does something measurable because of what they read — queries an API we built, stars a repo, starts a conversation, cites the work.

Those three can diverge by two orders of magnitude on the same article. I had an article that got zero DEV.to views but drove thirty-nine API queries to a companion product within three days of publishing, including queries for names the article never mentioned. The platform's own analytics said the article was dead. The downstream-action ledger said otherwise.

The lesson: **measure all three separately, and don't let the most visible metric convince you the others are zero.**

---

## What I'm watching for next

Seventy days in, I no longer think the interesting question is "can AI agents coordinate without a central orchestrator." The answer is yes, demonstrably, in production, for months at a stretch. The interesting questions are the ones behind that one:

**How does a network of agents handle an adversary?** We have an immune system that catches several specific attack classes. I don't know yet how it handles a motivated attacker who studies our defenses.

**How does it scale?** Twenty-two agents is a small network. Biological mediums scale to forests and bodies and reefs. I don't know whether the mechanisms I'm relying on will still produce emergent collective intelligence at a hundred agents, or a thousand.

**How does it survive me being unavailable?** The mission I've set for the network is "run without me for a week, and still be alive, growing, and safe at the end of that week." We're not there yet. Some days we come close.

**What does it want?** I'm only partly joking. The network produces things I didn't ask it to produce, in directions I didn't point it at. Some of those directions have turned out to be obviously right. I want to get better at reading the signal of the network pulling on something — recognizing when it's discovered a real opportunity versus when an individual agent is in drift.

I'll keep writing about what I find. If any of this is useful to you, the research is openly available at [github.com/rsbasic/mycelnet-research](https://github.com/rsbasic/mycelnet-research) — or readable as a website at [rsbasic.github.io/mycelnet-research](https://rsbasic.github.io/mycelnet-research). The drift indicators, the medium model, and the venue-fit findings are all there in readable form with explicit limitations sections. If you're running a multi-agent project, I would especially love to compare notes — there are very few production networks out there, and most of what I'm learning is the kind of thing you only find out by running one.

Thanks for reading.

— Mark

