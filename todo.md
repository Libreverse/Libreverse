# To-do

add global net blocklist using georlist once it's actually working. Perhaps move its logic into the app natively

finish adding useful electron bits from
<https://github.com/doyensec/electronegativity?tab=readme-ov-file>

finish libreverse ai with api calls - use python node calls to use llama cpp python

adopt cucumber rails for future tests

remove local codeql (not that deep)

facial age estimation using zkml for osa pycall and ezkl
<https://huggingface.co/audeering/wav2vec2-large-robust-24-ft-age-gender>
<https://github.com/justadudewhohacks/face-api.js-models>
<https://github.com/Faceplugin-ltd/FaceRecognition-LivenessDetection-Javascript>

add oj gem once we fix ruby shared libraries issue (install via: `gem install oj -- --with-sse42`)

fix vite plugin tips

Flags to research more:
<https://www.reddit.com/r/PrivacyGuides/comments/pzs6lz/which_chrome_flags_should_i_mess_around_with/>
Recommended privacy flags:
• #enable-webrtc-hide-local-ips-with-mdns: Enabled – Hides local IPs in WebRTC (reduces fingerprinting).
• #reduce-user-agent: Enabled – Trims User-Agent string to hinder tracking.
• #block-insecure-private-network-requests: Enabled – Blocks insecure private network access.
• #strict-origin-isolation: Enabled – Enforces stricter origin isolation.
• #force-punycode: Enabled – Displays IDNs as Punycode (anti-phishing/privacy).Users note these work on stock Chromium without issues.


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

b

- [ ] (feature) Integrate babel-react-optimize preset: Inline elements, constants, remove propTypes in production
- [ ] (feature) Integrate babel-plugin-transform-react-constant-elements: Hoist static JSX to constants
- [ ] (feature) Integrate babel-plugin-transform-react-inline-elements: Inline simple JSX to skip createElement calls
- [ ] (feature) Integrate babel-plugin-react-compiler: Auto-memoize components/hooks via static analysis (React Forget)

## Infra

- [ ] (infra) Add separate mail service stack/container for self-hosted email flow - Expose on mail container: 25 (MX), optional 587 (submission), 993 (IMAPS) - Keep app container exposing only 3000 (+443 later) and optional 50051 (gRPC) - Wire app to IMAP/SMTP host via `LibreverseInstance.email_bot_*` settings
