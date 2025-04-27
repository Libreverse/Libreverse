# Todo List

## HIGH — next sprint (post-alpha, still before public beta)

7. □ **Add rodauth-models plugin and use sequel column encryption to encrypt rodauth data**.

9. □ **Local Active Storage tightening**.

    - Serve downloads with `private, max-age=0`; ensure storage path owned by non-root UID.

10. □ **Dependency hygiene in CI**.

    - Add `bundle audit`, `brakeman -Aq`, `npm audit --omit=dev`, Dependabot.

11. □ **SolidCable interim limits** (`MAX_CONNECTIONS=100`); WAL autocheckpoint 1000.

12. □ **README updates**.

    - Reverse-proxy requirement (`X-Forwarded-Proto`).
    - Upload security / iframe script caveats.
    - Backup & restore commands.

13. □ **Zip download streaming with Zipline**.

    - <https://github.com/fringd/zipline?tab=readme-ov-file>

---

## MEDIUM — road-map (beta ➜ GA)

2. □ **Update docs for technical & organisational measures (TOMs)** – encryption, access controls, backups.

6. □ **Make `Security.txt` and `.well-known/privacy.txt` dynamic**.

1. □ **Imprint for EU**

1. □ **Implement cron-based backup/restore testing pipeline**.

1. □ **Draft `docs/incident_response.md`** (key rotation, user notification).

1. □ **Integrate OWASP ZAP baseline scan in CI**.

1. □ **Emoji middleware**: switch to streaming enumerator.

1. □ **Performance profiling route** with `rack-mini-profiler` (staging only).

1. □ **Provide "download my experience files" bulk endpoint**.

1. □ **Use `client_max_body_size` limits**child_process to reduce accidental PII ingestion.

1. □ **Add CSRF + same-site tests** to system suite.

---

**Notes**:

- The numbering is continuous across sections to maintain a clear priority order, adjusting for the original list's duplicate numbers (corrected from two 1s and two 2s to a single sequence).
- Keep this checklist in the repository at `docs/security_todo.md` and update it as tasks are completed.
