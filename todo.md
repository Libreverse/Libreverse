# To-do
db find indexes command on static tools
do a massive middleware cleanup operation where we get everything in sense
move rails cache store to the memorystore and cut out the isolator middleware
use SRI for vite rails assets and shakapacker assets
replace all situations where we do inline html with the phlex engine which is much faster
also walk back a bunch of the inlining tech that we've done that doesn't affect render flashes like the sitemap inlining
- [ ] (feature) Build authoritative realtime multiplayer service in parallel to Rails (interest management + generalized state governance; no server-side raycasting)
- [ ] we also need to move the ugc into a separate webcontentsview in electron for more security
- [ ] add trufflehog to not put creds in github repo
- [ ] add pagination instead of limits with geared pagination
- [ ] add global net blocklist using georlist - move its logic into the app natively
- [ ] finish libreverse ai with api calls - use python node calls to use llama cpp python
- [ ] adopt cucumber rails for future tests
- [ ] facial age estimation using zkml for osa pycall and ezkl <https://huggingface.co/audeering/wav2vec2-large-robust-24-ft-age-gender> <https://github.com/justadudewhohacks/face-api.js-models> <https://github.com/Faceplugin-ltd/FaceRecognition-LivenessDetection-Javascript>
- [ ] (feature) Use <https://github.com/slimtoolkit/slim> to optimise the docker image as well as root.io base images
- [ ] (feature) Clear up attribution for images
- [ ] (feature) Finish blog & social features (blog posts as ActivityPub/atproto ideally posts; ship prebuilt blocklist & document censorship considerations)
- [ ] (feature) OSA compliance audit and changes
- [ ] (feature) Deploy without master_key pre-set (remove `credentials.yml.enc` handling adjustments)
- [ ] (feature) Make local codeql work fully
- [ ] (feature) Deploy with SSL without reverse proxy
- [ ] (feature) Add premade "bad content" federation blocklist
- [ ] (feature) Add full decentralisation mode (blockchain-backed index for Decentraland, The Sandbox, etc.)
- [ ] (feature) Add Telegram search bot
- [ ] (feature) Add x.com search bot
- [ ] (infra) Make the email service actually fully wired up while maintaining the container blob system we've been using for the longest time
- [ ] (infra) Migrate Active Storage to use Garage storage with aws-s3-sdk gem (pointing to local fixed port on docker container)
