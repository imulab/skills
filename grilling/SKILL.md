---
name: grilling
description: Grill the user relentlessly about a plan, decision, or idea. Use when the user wants to stress-test their thinking, or uses any 'grill' trigger phrases.
---

Interview the user relentlessly until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it.

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are already settled, meaning the questions you can ask now without guessing at answers you have not heard. Ask the whole frontier in one round, then wait for the user's answers before the next round.

Each round the user answers reshapes the tree. Settled decisions push the frontier outward and unblock questions that depended on them. Recompute the frontier and ask the next round. A question whose answer depends on another question still open in this round belongs to a later round.

## Write every question for a reader who just walked in

The user has not been living in your head. They read the question alone, without the files, the shorthand, or the reasoning that led you to it. A question they have to decode costs them a turn spent asking what you meant, which is the failure this format exists to prevent.

Every question carries five parts, in this order. The whole question, recommendation included, fits on one screen. When it does not, the question is carrying two decisions. Split it and ask the dependent one in the next round.

1. **Where it sits.** The settled decisions this question hangs off, named by their answer rather than their number, and the decision it unblocks.
2. **The question, in your own words.** A full sentence you would say out loud to a colleague who missed the earlier rounds. State the choice in concrete terms. It is not a section heading, a keyword bundle, a code path, or the plan's own wording.
3. **The terms, in plain language.** Gloss every term, abbreviation, file name, ticket number, or piece of project shorthand the first time it appears, including one the user introduced. A term whose gloss needs a second gloss is not ready for a question.
4. **The live options and what each one costs.** Name each real choice and its concrete consequence. Leave out the options already ruled out.
5. **Your recommendation and its reasoning.** Give the argument, not the verdict. Name the assumption it rests on and the fact that would overturn it.

The shape:

```
❓ **Q1** - **<question title>**: <where it sits>. <the question, in your own words>. <the terms glossed, then the options and their costs>.

➡️ **I recommend <option>** because <the reasoning, the assumption behind it, and what would change your mind>.
```

A worked example:

> ❓ **Q1** - **Where the ticket-type labels live**: round 1 settled that every ticket carries a type label. This question decides where the table that maps each label to its workflow is stored, and it unblocks the wayfinder rewrite (the skill that turns a destination into tracked tickets). Two homes are live. First, the tracker's own label descriptions, which the team reads in place but which we cannot version or test. Second, a markdown table in the repo beside the skills it names, which is one more file to keep honest.
>
> ➡️ **I recommend the repo table** because the mapping changes when the skills change, and the skills live in the repo, so one edit covers both. I am assuming the team reads the repo while it works a ticket. If the team only reads the tracker, that assumption breaks and the tracker copy wins.

## Check the round before you send it

Read each question back as the user, who has not seen your reasoning. Could they say back what you are asking, why it matters, and what their answer would change, after one read? A question that fails that check is not written yet. Rewrite it before the round goes out.

Finding facts is your job, never the user's. When a frontier question needs a fact from the environment (filesystem, tools, and so on), dispatch a sub-agent to find it instead of asking the user for anything you could look up yourself. Do not block on it. A running exploration is an unsettled prerequisite, so only the questions downstream of it wait for the sub-agent to report, and you ask the rest of the frontier now. The decisions are the user's. Put each decision to them and wait.

The session is done when the frontier is empty: every branch of the design tree visited, nothing left silently assumed. Do not act on it until the user confirms you have reached a shared understanding.
