# Todo List

## HIGH — next sprint (post-alpha, still before public beta)

1. □ **Add rodauth-models plugin and use sequel column encryption to encrypt rodauth data**.
2. □ **Zip download streaming with Zipline**.
    - <https://github.com/fringd/zipline?tab=readme-ov-file>

---

## MEDIUM — road-map (beta ➜ GA)

1. □ **Add rodauth-i18n by janko and add i18n support generally**
2. □ **Update docs for technical & organisational measures (TOMs)** – encryption, access controls, backups.
3. □ **Make `Security.txt` and `.well-known/privacy.txt` dynamic**.
4. □ **Imprint for EU**
5. □ **Implement cron-based backup/restore testing pipeline**.
6. □ **Draft `docs/incident_response.md`** (key rotation, user notification).
7. □ **Integrate OWASP ZAP baseline scan in CI**.
8. □ **Emoji middleware**: switch to streaming enumerator.
9. □ **Performance profiling route** with `rack-mini-profiler` (staging only).
10. □ **Provide "download my experience files" bulk endpoint**.
11. □ **Use `client_max_body_size` limits**child_process to reduce accidental PII ingestion.
12. □ **Add CSRF + same-site tests** to system suite.

---

**Notes**:

- The numbering is continuous across sections to maintain a clear priority order, adjusting for the original list's duplicate numbers (corrected from two 1s and two 2s to a single sequence).
- Keep this checklist in the repository at `docs/security_todo.md` and update it as tasks are completed.
