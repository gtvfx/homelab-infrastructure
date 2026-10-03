# Repository Agent Instructions

## Continuity

- Read `README.md` and `STATUS.md` before starting material work.
- Treat `STATUS.md` as the project handoff, then verify mutable external
  state using GitHub, Proxmox, or the target host as appropriate.
- Do not infer project status solely from chat history.
- Update `STATUS.md` after each material milestone, before a long-running or
  interruption-prone operation, and again before finishing. Do not defer the
  only handoff record to the final chat response.
- Record concrete evidence such as commit SHAs, pull requests, workflow runs,
  commands, and observed host state.
- Clearly distinguish planned, implemented, applied, and validated work.

## Security

This repository is public. Never commit credentials, registration tokens,
private keys, passwords, rendered secret-bearing cloud-init data, private
network captures, or Terraform state.

For authentication and hardening changes, preserve a tested recovery path and
verify a second connection before closing the original administrative session.
