# To-do

we also need to move the ugc into a separate webcontentsview in electron for more security

add trufflehog to not put creds in github repo

add pagination instead of limits with geared pagination

add global net blocklist using georlist - move its logic into the app natively

finish libreverse ai with api calls - use python node calls to use llama cpp python

adopt cucumber rails for future tests

remove local codeql (not that deep)

facial age estimation using zkml for osa pycall and ezkl
<https://huggingface.co/audeering/wav2vec2-large-robust-24-ft-age-gender>
<https://github.com/justadudewhohacks/face-api.js-models>
<https://github.com/Faceplugin-ltd/FaceRecognition-LivenessDetection-Javascript>

- [ ] (feature) Use <https://github.com/slimtoolkit/slim> to optimise the docker image as well as root.io base images
- [ ] (bugfix) Sidebar moves down when sidebar expanded
- [ ] (feature) Clear up attribution for images

## September

- [ ] (feature) Finish blog & social features (blog posts as ActivityPub/atproto ideally posts; ship prebuilt blocklist & document censorship considerations)
- [ ] (feature) OSA compliance audit and changes
- [ ] (feature) Deploy without master_key pre-set (remove `credentials.yml.enc` handling adjustments)
- [ ] (feature) Make local codeql work fully
- [ ] (feature) Deploy with SSL without reverse proxy (evaluate direct nginx inside container viability vs current cloud setup)
- [ ] (feature) Add 2d bridge indexer
- [ ] (feature) Add premade "bad content" federation blocklist
- [ ] (feature) Add full decentralisation mode (blockchain-backed index for Decentraland, The Sandbox, etc.)
- [ ] (feature) Add Telegram search bot
- [ ] (feature) Add x.com search bot

## JavaScript Optimizations

- [ ] (feature) Integrate babel-react-optimize preset: Inline elements, constants, remove propTypes in production
- [ ] (feature) Integrate babel-plugin-transform-react-constant-elements: Hoist static JSX to constants
- [ ] (feature) Integrate babel-plugin-transform-react-inline-elements: Inline simple JSX to skip createElement calls
- [ ] (feature) Integrate babel-plugin-react-compiler: Auto-memoize components/hooks via static analysis (React Forget)

## Infra

- [ ] (infra) Add separate mail service stack/container for self-hosted email flow - Expose on mail container: 25 (MX), optional 587 (submission), 993 (IMAPS) - Keep app container exposing only 3000 (+443 later) and optional 50051 (gRPC) - Wire app to IMAP/SMTP host via `LibreverseInstance.email_bot_*` settings
- [ ] (infra) Migrate Active Storage to use Garage storage with aws-s3-sdk gem (pointing to local fixed port on docker container)
