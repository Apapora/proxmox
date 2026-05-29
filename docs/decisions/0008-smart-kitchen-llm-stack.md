# 8. Smart-kitchen LLM stack: self-hosted Ollama + NocoDB

Date: 2026-05-29
Status: Accepted

## Context

First real user workload on the lab. Goal: an ingredient inventory (fridge +
pantry) you update by talking to it — voice/text → LLM → structured items —
that also spits out shopping lists and recipes in the style of recipes we
already like. n8n is already running on k3s and will drive the workflows.

Three things to pin down: where the data lives, where the LLM runs, what model.

## Decision

**Data → NocoDB on k3s, Postgres behind it.** Considered Google Sheets and
Airtable. Sheets is just untyped cells with an awkward API. Airtable is nice
but it's SaaS — can't self-host, and the whole point of this repo is to learn
by running things myself. NocoDB is the open-source Airtable: spreadsheet UI
for the household, real Postgres underneath for actual queries (and pgvector
later if recipes need RAG). Argo-managed, same as the n8n app.

**LLM → Ollama in an LXC, CPU only.** No discrete GPU on this box, just the
890M iGPU. LLM token generation is bandwidth-bound, and the iGPU shares the
same RAM bus as the CPU — so it's no faster. On top of that, ROCm wants the
model in the UMA frame buffer, which I shrank to 512MB to get RAM back; using
the iGPU means bumping it to 16GB again for maybe 1.3x, often worse on the
flaky 890M drivers. Not worth it. LXC instead of k8s so it stays up on its own
(like pihole/media) and doesn't fight the 8GB agent VMs for memory.
`10.0.0.162`, 6 vCPU / 12GB / 30GB.

**Model → one `qwen3.5:9b` for everything.** It's a multimodal MoE — vision
comes free (handy for receipt/barcode scanning later), 256K context fits our
favorite recipes inline as style anchors, and MoE means it runs faster than a
dense 9b. The 9b (~6.6GB) fits the LXC; 27b doesn't. Running a single model
keeps RAM simple — nothing to juggle. Bound to `0.0.0.0:11434`, kept warm 30m
so CPU doesn't pay the cold-load tax every call.

## Consequences

- Recipe gen is ~30-40s on CPU. Fine — it's a batch thing, not a chat.
- If parsing feels slow, add a small `qwen3.5:4b` and cap loaded models to 1
  so both never sit in RAM at once.
- Token-created LXC (unprivileged + nesting) — no `root@pam` step, unlike the
  media iGPU passthrough.
- Recipes go in the prompt directly for now; pgvector RAG only if that stops
  being good enough.
- Swapping Ollama for the Anthropic API later is just an n8n change, nothing
  else moves.
