# Libreverse

Libreverse is a privacy‑centric application for curating and sharing interactive "experiences" (self‑contained HTML documents). Powered by Hotwire, it delivers a seamless, single‑page‑application (SPA) experience entirely within the Ruby on Rails ecosystem while keeping all data on whatever instance you choose to use.

> **Alpha release** – this version is under active development. Expect breaking changes, incomplete features, and occasional rough edges. Planned work is tracked in our [road‑map](todo.md).

---

## ✨ Key Features

- **Local‑first data management** – SQLite (via the enhanced adapter) provides generated columns, JSON queries, and full‑text search without a separate database server.
- **Real‑time UI** – Turbo, Stimulus, and StimulusReflex enable instantaneous updates with minimal client‑side JavaScript.
- **Secure account system** – Rodauth with Argon2 hashing, email‑based login, remember‑me cookies, and optional guest mode.
- **ActivityPub Federation** – Share experiences across Libreverse instances using ActivityPub protocol with custom metaverse-specific fields.
- **Cross-instance Discovery** – Search and discover experiences from other federated Libreverse instances.
- **Media attachments** – Active Storage with rigorous validations, encrypted blobs at rest, and one‑click ZIP export of your entire account.
- **API functionality** – Full-featured GraphQL API, XML-RPC endpoints, JSON API, and integrated gRPC server with HTTP bridge.
- **Zero‑Redis architecture** – Solid Cable and Solid Queue keep ActionCable and background jobs inside SQLite.
- **DragonflyDB-powered infrastructure** – Redis-compatible in-memory database powers Rails cache, ActionCable pub/sub, Sidekiq job queues, and rate limiting.
- **Security‑centric design** – CSP, Rack::Attack rate limiting, Brotli compression, and an evolving [security roadmap](todo.md).
- **Collaborative Realtime** – WebSocket + Yjs CRDT layer providing durable shared state and ephemeral movement/presence without WebRTC complexity.

---

## 🛠 Technology Stack

| Layer           | Technology                                   |
| --------------- | -------------------------------------------- |
| Language        | Ruby 3.4                                     |
| Framework       | Rails 8.0.2 + Hotwire                        |
| Database        | SQLite 3 (enhanced adapter)                  |
| Build / Assets  | Vite 6 + pnpm                                |
| Web Server      | Puma                                         |
| Container Image | Multi‑stage Dockerfile (< 80 MB final image) |

---

## 🚀 Quick Start (Development)

1. **Clone the repository and install dependencies**

    ```bash
    git clone https://github.com/your-org/libreverse.git
    cd libreverse
    bin/setup # installs Ruby gems, Node packages, and prepares the DB
    ```

2. **Launch the application**

    ```bash
    bin/dev # starts Rails and Vite in watch mode at http://localhost:3000
    ```

    In development, no external mailer is required; password‑reset links are output to the console.

### Prerequisites

- Ruby ≥ 3.4.2 (see .ruby-version)
- Node.js ≥ 20 (for JS tooling)
- pnpm (front‑end package manager; enabled via Corepack)
- SQLite ≥ 3.41 (compiled with FTS5 and JSON1)
- ImageMagick (for Active Storage variants)
- Overmind (process manager for development)

Installation helpers:

## macOS / Ubuntu installation examples

```bash
# macOS
brew install ruby node pnpm sqlite imagemagick overmind

# Ubuntu
sudo apt install ruby-full nodejs npm curl sqlite3 libsqlite3-dev imagemagick
# overmind can be installed from: https://github.com/DarthSim/overmind/releases
```

---

## 🌐 ActivityPub Federation

Libreverse supports decentralized federation using the ActivityPub protocol, allowing instances to share experiences while maintaining local control.

### Federation Features

- **Experience Sharing**: Framework for sharing approved experiences with federated instances
- **Cross-Instance Discovery**: Search framework for finding content from other Libreverse instances
- **Custom ActivityPub Fields**: Rich metadata for metaverse experiences using Libreverse extensions
- **Privacy Controls**: Users can choose whether to federate each experience
- **Admin Tools**: Complete federation management interface for instance administrators

### Configuration

Set your instance domain in environment variables:

```bash
export INSTANCE_DOMAIN=your-domain.com
```

Admin users can manage federation settings at `/admin/federation`. Federation is implemented with a simplified delivery approach to ensure stability - full ActivityPub delivery can be enabled when desired.

For detailed federation documentation, see [`documentation/federation.md`](documentation/federation.md).

---

## 🐳 Running with Docker

> **Note:** Building the Docker image requires at least 8 GB of available memory, though the running container itself needs very little memory. If you encounter out-of-memory errors during the build, try increasing your Docker memory limit.

```bash
docker build -t libreverse:alpha .
# Persist database and uploads
docker run -p 3000:3000 -v libreverse_data:/data libreverse:alpha
```

The image exposes port **3000** and stores the production SQLite database and uploaded files under `/data`.

---

## 🧪 Testing & Quality Assurance

Quality checks now run automatically via GitHub Actions CI on every push and pull request.

To run quality checks manually:

```bash
bin/static
```

### Electron Security Scanning

Libreverse includes [Electronegativity](https://github.com/doyensec/electronegativity), a security scanner for Electron applications that identifies misconfigurations and security anti-patterns.

To run the security scanner:

```bash
# Scan the entire project
pnpm run security:scan

# Or scan specific files/directories
npx electronegativity -i src/
```

The scanner will generate a CSV report of any security issues found.

---

## 📦 Project Structure (TL;DR)

```text
app/            – MVC components, Reflexes, Stimulus controllers (.coffee)
bin/            – Development helpers & executable scripts
db/             – Migrations and schema.sql
documentation/  – Comprehensive guides (e.g., SQLite, security)
scripts/        – One‑off maintenance scripts
```

See the [`documentation/`](documentation/) directory for full guides.

---

## 🛡 Security

Security is a core focus of Libreverse. Please see [SECURITY.md](SECURITY.md) for more information.

---

## 🤝 Contributing

1. Fork the repository and create a feature branch.
2. Adhere to the [Code of Conduct](CODE_OF_CONDUCT.md).
3. Open a pull request – we squash‑merge after review.

Looking for ideas? Check the [good first issue](https://github.com/your-org/libreverse/labels/good%20first%20issue) label or our [road‑map](todo.md).

---

## 📄 License

Libreverse is dual‑licensed under the **MIT License** for source code and various permissive licenses for assets. See the [licenses/](licenses/) directory for full texts.

---

## Column Encryption

Sensitive columns in Rodauth tables are encrypted using Sequel's built-in `column_encryption` plugin. The encryption key is a 32-byte value derived from `Rails.application.secret_key_base` using `ActiveSupport::KeyGenerator` (see `config/initializers/sequel_encryption.rb`).

- **Key Management:** The key is stable as long as `secret_key_base` does not change. If it does, you must re-encrypt existing data.
- **Encrypted Columns:**
    - `accounts.password_hash`
    - `account_remember_keys.key` (searchable)
    - `account_password_reset_keys.key` (searchable)
- **Database Constraints:**
    - Encrypted columns have `CHECK` constraints to ensure only encrypted data is stored (see `db/migrate/20250501000000_add_column_encryption_constraints_to_rodauth.rb`).

No additional gem is required; this uses Sequel's built-in plugin. All Rodauth features continue to work seamlessly with encrypted data.

---

## Caveats

If you deploy Libreverse behind a reverse proxy (such as Nginx, Apache, or a cloud load balancer), you **must** ensure that the proxy sets the `X-Forwarded-Proto` header on all requests. This header is used by Rails and middleware to correctly identify whether the original request was made over HTTP or HTTPS. If this header is missing or misconfigured, you may experience issues such as:

- Incorrect URL generation (e.g., HTTP links on an HTTPS site)
- Broken redirects or authentication flows
- Security features (like secure cookies or CSP) not working as intended

**Solution:**

- For Nginx, add: `proxy_set_header X-Forwarded-Proto $scheme;`
- For Apache, add: `RequestHeader set X-Forwarded-Proto expr=%{REQUEST_SCHEME}`
- For cloud providers, consult their documentation to ensure this header is set.

---

### Acknowledgements

- The Hotwire and StimulusReflex communities for their pioneering tools and inspiration.
- [Fullstaq Ruby](https://fullstaqruby.org/) for optimized, memory‑efficient Ruby images.
- Emoji assets provided by [Twemoji](https://twemoji.twitter.com/) under the CC‑BY 4.0 license.

---

**Thank you for exploring Libreverse!**
