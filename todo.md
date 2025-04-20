# Todo List

## HIGH — next sprint (post-alpha, still before public beta)

1. □ **Add Terms of Service & Imprint** (if EU).

2. □ **Document technical & organisational measures (TOMs)** – encryption, access controls, backups.

3. □ **Conduct DPIA** if large-scale profiling or special category data arises (unlikely now).

4. □ **Implement sub-processor register and SCCs** if non-EEA transfers are introduced.

5. □ **Add tests ensuring `filter_parameters` stays updated** when new PII fields are added.

6. □ **Add `Security.txt` or `.well-known/privacy.txt` endpoints**.

7. □ **Figure out how to get rodauth to encrypt data**.

    - _The clue is in the name._

8. □ **Isolate Experience viewer** on a dedicated route with its own CSP header (remove global `'unsafe-inline'`) and serve content from `/experiences/:id/frame` instead of `data:` URI.

9. □ **Readd support for rack deflater**.

    - _The clue is in the name._

10. □ **Conditional compression tweaks**.

    - CPU monitor fallback quality; skip compression on small `Set-Cookie` responses.

11. □ **Local Active Storage tightening**.

    - Serve downloads with `private, max-age=0`; ensure storage path owned by non-root UID.

12. □ **Dependency hygiene in CI**.

    - Add `bundle audit`, `brakeman -Aq`, `npm audit --omit=dev`, Dependabot.

13. □ **SolidCable interim limits** (`MAX_CONNECTIONS=100`); WAL autocheckpoint 1000.

14. □ **CSP violation endpoint** (`POST /csp-report`) — log to Sentry.

15. □ **README updates**.

    - Reverse-proxy requirement (`X-Forwarded-Proto`).
    - Upload security / iframe script caveats.
    - Backup & restore commands.

---

## MEDIUM — road-map (beta ➜ GA)

1. □ **Implement cron-based backup/restore testing pipeline**.

2. □ **Draft `docs/incident_response.md`** (key rotation, user notification).

3. □ **Integrate OWASP ZAP baseline scan in CI**.

4. □ **Emoji middleware**: switch to streaming enumerator.

5. □ **Performance profiling route** with `rack-mini-profiler` (staging only).

6. □ **Provide "download my experience files" bulk endpoint**.

7. □ **Use `client_max_body_size` limits**child_process to reduce accidental PII ingestion.

8. □ **Add CSRF + same-site tests** to system suite.

---

**Notes**:

- The numbering is continuous across sections to maintain a clear priority order, adjusting for the original list's duplicate numbers (corrected from two 1s and two 2s to a single sequence).
- Keep this checklist in the repository at `docs/security_todo.md` and update it as tasks are completed.
