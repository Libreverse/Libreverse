# Libreverse

Libreverse is a privacy‑centric application for curating and sharing interactive "experiences" (self‑contained HTML documents). Powered by Hotwire, it delivers a seamless, single‑page‑application (SPA) experience entirely within the Ruby on Rails ecosystem while keeping all of your data on your own machine.

> **Alpha release** – this version is under active development. Expect breaking changes, incomplete features, and occasional rough edges. Planned work is tracked in our [road‑map](todo.md).

---

## ✨ Key Features

- **Local‑first data management** – SQLite (via the enhanced adapter) provides generated columns, JSON queries, and full‑text search without a separate database server.
- **Real‑time UI** – Turbo, Stimulus, and StimulusReflex enable instantaneous updates with minimal client‑side JavaScript.
- **Secure account system** – [Rodauth](https://rodauth.dev/) with Argon2 hashing, email‑based login, remember‑me cookies, and optional guest mode.
- **Media attachments** – Active Storage with rigorous validations, encrypted blobs via _lockbox_, and one‑click ZIP export of your entire account.
- **API functionality** – Experimental XML‑RPC endpoint and JSON search API.
- **Zero‑Redis architecture** – Solid Cable and Solid Queue keep ActionCable and background jobs inside SQLite.
- **Security‑centric design** – CSP, Rack::Attack rate limiting, Brotli compression, and an evolving [security roadmap](todo.md).

---

## 🛠 Technology Stack

| Layer           | Technology                                   |
| --------------- | -------------------------------------------- |
| Language        | Ruby 3.4 (YJIT enabled)                      |
| Framework       | Rails 7.2 (Edge) + Hotwire                   |
| Database        | SQLite 3 (enhanced adapter)                  |
| Build / Assets  | Vite 5 + Bun                                 |
| Web Server      | Puma (threaded, Solid Queue plugin)          |
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

- Ruby ≥ 3.4.1 (see .ruby-version)
- Bun ≥ 1.2 (front‑end package manager)
- SQLite ≥ 3.41 (compiled with FTS5 and JSON1)
- ImageMagick (for Active Storage variants)

Installation helpers:

## macOS / Ubuntu installation examples

```bash
# macOS
brew install ruby bun sqlite imagemagick

# Ubuntu
sudo apt install ruby-full bun curl sqlite3 libsqlite3-dev imagemagick
```

---

## 🐳 Running with Docker

```bash
docker build -t libreverse:alpha .
# Persist database and uploads
docker run -p 3000:3000 -v libreverse_data:/data libreverse:alpha
```

The image exposes port **3000** and stores the production SQLite database and uploaded files under `/data`.

---

## 🧪 Testing & Quality Assurance

```bash
bin/rails test                # Executes Minitest suite (unit + system)
bin/rubocop -A                # Lints and auto‑corrects Ruby code
bun run eslint .              # Lints JS/Coffee/Stimulus files
bun run stylelint "**/*.scss" # Lints SCSS stylesheets
```

Security audits (Brakeman, bundle‑audit, npm audit) run automatically in CI.

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

### Acknowledgements

- The Hotwire and StimulusReflex communities for their pioneering tools and inspiration.
- [Fullstaq Ruby](https://fullstaqruby.org/) for optimized, memory‑efficient Ruby images.
- Emoji assets provided by [Twemoji](https://twemoji.twitter.com/) under the CC‑BY 4.0 license.

---

**Thank you for exploring Libreverse!**
