# To-do

solid cache has native encryption and compression which contain micro optimisations. We should use these native features over our own hacks.
libreverse ai with api calls
adopt cucumber rails for future tests
fix map 3d performance being rubbish with million.js, terser and babel react optims
better use of leaflet offline plugin
move to postgres for cache

- [ ] (feature) Use <https://github.com/slimtoolkit/slim> to optimise the docker image
- [ ] (bugfix) Sidebar moves down when sidebar expanded
- [ ] (feature) Clear up attribution for images

## September

- [ ] (feature) Finish blog & social features (blog posts as ActivityPub/atproto ideally posts; ship prebuilt blocklist & document censorship considerations)
- [ ] (feature) OSA compliance audit and changes
- [ ] (feature) Deploy without master_key pre-set (remove `credentials.yml.enc` handling adjustments)
- [ ] (feature) Make local codeql work fully
- [ ] (feature) Deploy with SSL without reverse proxy (evaluate direct nginx inside container viability vs current cloud setup)
- [ ] (feature) Add container runtime using podman in docker
- [ ] (feature) Release beta
- [ ] (feature) Add premade "bad content" federation blocklist
- [ ] (feature) Add full decentralisation mode (blockchain-backed index for Decentraland, The Sandbox, etc.)
- [ ] (feature) Release v3 gamma
- [ ] (feature) Add Telegram search bot
- [ ] (feature) Add x.com search bot
- [ ] (feature) Add litestream back for optional cache backups

## JavaScript Optimizations

- [ ] (feature) Integrate babel-plugin-fast-async: Compile async/await to efficient Promises via Nodent
- [ ] (feature) Integrate babel-plugin-transform-for-of: Optimize for-of to for loops on arrays
- [ ] (feature) Integrate babel-react-optimize preset: Inline elements, constants, remove propTypes in production
- [ ] (feature) Integrate babel-plugin-transform-react-constant-elements: Hoist static JSX to constants
- [ ] (feature) Integrate babel-plugin-transform-react-inline-elements: Inline simple JSX to skip createElement calls
- [ ] (feature) Integrate babel-plugin-react-compiler: Auto-memoize components/hooks via static analysis (React Forget)
- [ ] (feature) Integrate faster.js: Rewrite array methods to optimized loops for massive performance gains
- [ ] (feature) Integrate Prepack: Partial evaluator that runs code at build time and serializes heap

## Infra

- [ ] (infra) Add separate mail service stack/container for self-hosted email flow - Expose on mail container: 25 (MX), optional 587 (submission), 993 (IMAPS) - Keep app container exposing only 3000 (+443 later) and optional 50051 (gRPC) - Wire app to IMAP/SMTP host via `LibreverseInstance.email_bot_*` settings
