# Todo List

## HIGH — next sprint (post-alpha, still before public beta)

1. □ **Add rodauth-models plugin and use sequel column encryption to encrypt rodauth data**.

2. □ **SolidCable interim limits** (`MAX_CONNECTIONS=100`); WAL autocheckpoint 1000.

3. □ **README updates**.

    - Reverse-proxy requirement (`X-Forwarded-Proto`).
    - Upload security / iframe script caveats.
    - Backup & restore commands.

4. □ **Zip download streaming with Zipline**.

    - <https://github.com/fringd/zipline?tab=readme-ov-file>

---

## MEDIUM — road-map (beta ➜ GA)

1. □ **Update docs for technical & organisational measures (TOMs)** – encryption, access controls, backups.
2. □ **Make `Security.txt` and `.well-known/privacy.txt` dynamic**.
3. □ **Imprint for EU**
4. □ **Implement cron-based backup/restore testing pipeline**.
5. □ **Draft `docs/incident_response.md`** (key rotation, user notification).
6. □ **Integrate OWASP ZAP baseline scan in CI**.
7. □ **Emoji middleware**: switch to streaming enumerator.
8. □ **Performance profiling route** with `rack-mini-profiler` (staging only).
9. □ **Provide "download my experience files" bulk endpoint**.
10. □ **Use `client_max_body_size` limits**child_process to reduce accidental PII ingestion.
11. □ **Add CSRF + same-site tests** to system suite.

---

**Notes**:

- The numbering is continuous across sections to maintain a clear priority order, adjusting for the original list's duplicate numbers (corrected from two 1s and two 2s to a single sequence).
- Keep this checklist in the repository at `docs/security_todo.md` and update it as tasks are completed.
