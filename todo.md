# To-do

add a cache preloading job
finish blog and add commontator
add thredded for forum feature
use <https://github.com/slimtoolkit/slim> to optimise the docker image
add <https://github.com/trailblazer/trailblazer> and adopt it for future logic
replace locotmotive scroll with lenis
action cable cable shared worker
minify_html shouldn't remove comments

- [ ] (bugfix) Sidebar moves down when sidebar expanded
- [ ] clear up attribution for images
      --- september ---
- [ ] (feature) Finish blog & social features (blog posts as ActivityPub/atproto ideally posts; ship prebuilt blocklist & document censorship considerations)
- [ ] (feature) osa compliance audit and changes
- [ ] (feature) Deploy without master_key pre-set (remove `credentials.yml.enc` handling adjustments)
- [ ] (feature) make local codeql work fully
- [ ] (feature) Deploy with SSL without reverse proxy (evaluate direct nginx inside container viability vs current cloud setup)
- [ ] (feature) Add container runtime using podman in docker
- [ ] (feature) Release beta
- [ ] (feature) Add premade "bad content" federation blocklist
- [ ] (feature) Add full decentralisation mode (blockchain-backed index for Decentraland, The Sandbox, etc.)
- [ ] (feature) Release v3 gamma
- [ ] (feature) Add Telegram search bot
- [ ] (feature) Add x.com search bot
- [ ] (feature) add litestream back for optional cache backups
      move glitchtip back to local

---

- [ ] (infra) Add separate mail service stack/container for self-hosted email flow - Expose on mail container: 25 (MX), optional 587 (submission), 993 (IMAPS) - Keep app container exposing only 3000 (+443 later) and optional 50051 (gRPC) - Wire app to IMAP/SMTP host via `LibreverseInstance.email_bot_*` settings
