# Static run TODOs

## ESLint
- [ ] Fix flat config structure: ensure every entry in `eslint.config.js` is an object; the spread from `compat.extends(...)` may be returning non-object. Resolve “Unexpected non-object config at user-defined index 1.”

## Markdownlint
- [ ] Align table pipes in `app/javascript/libs/README.md` lines 264-267 (MD060 table-column-style).

## Rubocop
- [ ] Rails/LexicallyScopedActionFilter: add `approve/reject` definitions in `app/controllers/admin/comments_controller.rb`.
- [ ] Rails/LexicallyScopedActionFilter: add `approve` definition in `app/controllers/admin/experiences_controller.rb`.
- [ ] Rails/LexicallyScopedActionFilter: add `unblock_domain` definition in `app/controllers/admin/federation_controller.rb`.
- [ ] Rails/LexicallyScopedActionFilter: add `accept/decline` definitions in `app/controllers/consent_controller.rb`.
- [ ] Lint/IneffectiveAccessModifier: move `private` or use `private_class_method` for `sitemap_mutex` in `app/controllers/sitemap_controller.rb`.
- [ ] Lint/UnusedMethodArgument: adjust `cursor:` args in `app/jobs/cleanup_abandoned_guests_job.rb` and `app/jobs/generate_missing_actors_job.rb`.
- [ ] Style/EmptyElse: remove redundant `else` in `app/misc/rodauth_app.rb`.
- [ ] Rails/InverseOf: add `inverse_of` to `Comment` thread association in `app/models/comment.rb`.
- [ ] Lint/RescueException: narrow rescue in `config/facets.rb`.
- [ ] Rails/Exit: avoid `abort` in `config/initializers/logger.rb`.
- [ ] Lint/Void: remove unused `store` expressions in `config/patches/truffleruby_fiber_local_storage.rb` (two spots).
- [ ] Rails/SkipsModelValidations: replace `update_column/update_columns/update_all` in listed migrations/scripts (`db/cms_blog_setup.rb`, migrate_*_flags migrations, etc.).
- [ ] Style/OptionalArguments: reorder optional args in `scripts/check_shareable_constants.rb`.

## Active Record Doctor (address all)
- [ ] Add presence validators for all fields listed in AR Doctor output (accounts, action_mailbox, action_text, active_storage*, comfy_cms*, comment*, console1984*, experience*, federails*, friendly_id, oauth*, thredded*, user*, etc.).
- [ ] Set `optional: false` for `Experience` -> `account` association (NOT NULL fk).
- [ ] Add missing foreign keys as listed (audits1984_audits, comfy_cms tables, comments, comment_hierarchies, console1984*, thredded*, etc.).
- [ ] Add unique/general indexes as listed (comfy_cms_fragments, comfy_cms_sites, comfy_cms_translations, thredded_* hash_id, accounts_roles).
- [ ] Add/align length validators with DB limits for all fields listed (accounts, action_mailbox, action_text, active_hashcash, active_storage*, comfy_cms*, comment body vs DB limit, experience*, federails*, federated_announcements, friendly_id, indexed_content*, indexing_runs, instance_settings, oauth*, thredded*, user*).

## Database Consistency
- [x] Boot NameError from `BootTrace::T` fixed (guard added). Verify rerun.

## Fasterer
- [x] Missing `ruby_parser` dependency added to Gemfile. Verify rerun.

## Rails tests
- [ ] Fix fixtures/tests in `test/jobs/vectorize_experience_job_test.rb`: remove stale `approved` column from fixtures or add column/migration; ensure Mocha setup/teardown order is correct once fixtures load.

## Brakeman
- [ ] Investigate Slim parse errors: `app/views/admin/instance_settings/_form.slim`, `app/views/experiences/_form.slim`, `app/views/rodauth/change_password.slim` (check unmatched blocks/Brakeman compatibility).
