"""
hermes-iii-worker — A proper iii engine worker that uses the real Hermes AIAgent.

Replaces the ad-hoc hermes-worker.py which called Manifest directly via httpx
with a hardcoded system prompt. This worker imports and uses Hermes's own
AIAgent class — the same one the CLI and gateway use — so every iii-invoked
conversation gets the full Hermes pipeline: system prompt assembly, tools,
memory, skills, context compression, and model routing through Manifest.
"""
