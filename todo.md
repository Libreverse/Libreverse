# Todo List

**Actionable Task List — ordered by priority**
_(check ✓ as you complete each item)_

---

## Critical — current sprint (pre-alpha)

1. □ **Publish Privacy Policy & Cookie Policy** under `/privacy` and `/cookies`.

    - Include: identity, DPO contact, categories, lawful basis, retention, rights, transfers, complaints.

2. □ **Implement user-facing "Delete my account"** (hard-delete or irreversible pseudonymise), plus **data export** (JSON/ZIP of all user-related rows + ActiveStorage files).

3. □ **Add automated retention tasks**:

    - Purge expired `password_reset`, `login_change`, and `remember` keys.
    - Rotate/expire sessions (e.g., 14 days) and logs (use `logrotate`).
    - Ensure `has_one_attached :html_file` calls `dependent: :purge_later` or uses `after_destroy`.

4. □ **Ensure Active Storage encryption** or move to an encrypted cloud bucket.

    - Mark attachments as private/authenticated.

5. □ **Move IP addresses & user agents** to a separate log channel with limited retention (<90 days) or anonymise IP (truncate last octet).

6. □ **Review Sentry config**:

    - Enable `before_send` to redact PII, pass only error fingerprints.
    - Sign DPA with Sentry (or self-host in EEA).

7. □ **Build data-subject request workflow** (admin console + email confirmation).
    - Track fulfillment timestamps.

---

## HIGH — next sprint (post-alpha, still before public beta)

1. □ **Add Terms of Service & Imprint** (if EU).

2. □ **Add Opt-in checkbox for "Remember me" cookie**; set short expiry (<30 days).

3. □ **Document technical & organisational measures (TOMs)** – encryption, access controls, backups.

4. □ **Conduct DPIA** if large-scale profiling or special category data arises (unlikely now).

5. □ **Implement sub-processor register and SCCs** if non-EEA transfers are introduced.

6. □ **Add tests ensuring `filter_parameters` stays updated** when new PII fields are added.

7. □ **Add `Security.txt` or `.well-known/privacy.txt` endpoints**.

8. □ **Figure out how to get rodauth to encrypt data**.

    - _The clue is in the name._

9. □ **Isolate Experience viewer** on a dedicated route with its own CSP header (remove global `'unsafe-inline'`) and serve content from `/experiences/:id/frame` instead of `data:` URI.

10. □ **Readd support for rack deflater**.

    - _The clue is in the name._

11. □ **Conditional compression tweaks**.

    - CPU monitor fallback quality; skip compression on small `Set-Cookie` responses.

12. □ **Local Active Storage tightening**.

    - Serve downloads with `private, max-age=0`; ensure storage path owned by non-root UID.

13. □ **Dependency hygiene in CI**.

    - Add `bundle audit`, `brakeman -Aq`, `npm audit --omit=dev`, Dependabot.

14. □ **SolidCable interim limits** (`MAX_CONNECTIONS=100`); WAL autocheckpoint 1000.

15. □ **CSP violation endpoint** (`POST /csp-report`) — log to Sentry.

16. □ **README updates**.

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
