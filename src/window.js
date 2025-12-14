import { BrowserWindow, screen } from "electron";
import path, { dirname } from "node:path";
import { fileURLToPath } from "node:url";
import net from "node:net";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export default ({
    isDev: isDevelopment = false,
    url = "https://localhost:3000",
} = {}) => {
    const primary = screen.getPrimaryDisplay();
    const { width, height } = primary.size;

    const mainWindow = new BrowserWindow({
        width,
        height,
        backgroundColor: "#0e0e0e",
        frame: false,
        webPreferences: {
            preload: path.join(__dirname, "preload.js"),
            contextIsolation: true,
            nodeIntegration: false,
            enableRemoteModule: false,
        },
        show: false,
        title: "Libreverse",
    });

    const loadUrlWithRetry = async (targetUrl, { maxAttempts = 30 } = {}) => {
        let attempt = 0;

        const waitForTcp = async (host, port, timeoutMs = 750) => {
            return await new Promise((resolve, reject) => {
                const socket = net.createConnection({ host, port });

                const timeout = setTimeout(() => {
                    socket.destroy();
                    reject(new Error("tcp_timeout"));
                }, timeoutMs);

                socket.once("connect", () => {
                    clearTimeout(timeout);
                    socket.end();
                    resolve(true);
                });

                socket.once("error", (err) => {
                    clearTimeout(timeout);
                    socket.destroy();
                    reject(err);
                });
            });
        };

        // Chromium net error codes are negative numbers.
        // -100: ERR_CONNECTION_CLOSED
        // -102: ERR_CONNECTION_REFUSED
        // -105: ERR_NAME_NOT_RESOLVED
        // -106: ERR_INTERNET_DISCONNECTED
        // -108: ERR_ADDRESS_INVALID
        // -109: ERR_ADDRESS_UNREACHABLE
        // -111: ERR_TUNNEL_CONNECTION_FAILED
        const retryableErrorCodes = new Set([
            // -3: ERR_ABORTED (often transient during dev server rebuilds)
            -3,
            -100,
            -102,
            -105,
            -106,
            -108,
            -109,
            -111,
        ]);

        // Some Electron/Chromium errors expose the symbolic code string.
        const retryableElectronErrorCodes = new Set(["ERR_ABORTED"]);

        const retryableNodeErrorCodes = new Set([
            "ECONNREFUSED",
            "ECONNRESET",
            "EHOSTUNREACH",
            "ENETUNREACH",
            "ETIMEDOUT",
        ]);

        while (attempt < maxAttempts && !mainWindow.isDestroyed()) {
            try {
                // When using the local dev proxy, Chromium can log noisy TLS/handshake
                // errors if we attempt to load the URL before the proxy is listening.
                // Avoid that by waiting until the port is reachable.
                try {
                    const u = new URL(targetUrl);
                    const isLocalhost =
                        u.hostname === "localhost" ||
                        u.hostname === "127.0.0.1" ||
                        u.hostname === "::1";
                    const isHttp = u.protocol === "http:" || u.protocol === "https:";

                    if (isLocalhost && isHttp) {
                        const port = u.port
                            ? Number.parseInt(u.port, 10)
                            : u.protocol === "https:"
                              ? 443
                              : 80;
                        await waitForTcp(u.hostname, port);
                    }
                } catch {
                    // Ignore URL parsing errors and attempt to load anyway.
                }

                await mainWindow.loadURL(targetUrl);
                return;
            } catch (err) {
                attempt += 1;

                const errorCode = err?.code;
                const retryable =
                    retryableErrorCodes.has(errorCode) ||
                    retryableElectronErrorCodes.has(errorCode) ||
                    retryableNodeErrorCodes.has(errorCode) ||
                    err?.message === "tcp_timeout";

                if (!retryable || attempt >= maxAttempts) {
                    throw err;
                }

                const delayMs = Math.min(10_000, 250 * 2 ** (attempt - 1));
                await new Promise((resolve) => setTimeout(resolve, delayMs));
            }
        }
    };

    if (
        typeof MAIN_WINDOW_VITE_DEV_SERVER_URL !== "undefined" &&
        MAIN_WINDOW_VITE_DEV_SERVER_URL
    ) {
        let devServerUrl = MAIN_WINDOW_VITE_DEV_SERVER_URL;
        try {
            const u = new URL(devServerUrl);
            if (
                u.protocol === "http:" &&
                (u.hostname === "localhost" ||
                    u.hostname === "127.0.0.1" ||
                    u.hostname === "::1")
            ) {
                u.protocol = "https:";
                devServerUrl = u.toString();
            }
        } catch {
            // ignore
        }

        devServerUrl = devServerUrl.replace(/\/$/, "");
        void loadUrlWithRetry(
            `${devServerUrl}?target=${encodeURIComponent(url)}`,
        ).catch((err) => {
            console.error("Failed to load dev server URL", err);
        });
    } else if (
        typeof MAIN_WINDOW_VITE_NAME !== "undefined" &&
        MAIN_WINDOW_VITE_NAME
    ) {
        mainWindow.loadFile(
            path.join(
                __dirname,
                `../renderer/${MAIN_WINDOW_VITE_NAME}/index.html`,
            ),
            { query: { target: url } },
        );
    } else {
        void loadUrlWithRetry(url).catch((err) => {
            console.error("Failed to load app URL", err);
        });
    }

    mainWindow.once("ready-to-show", () => {
        mainWindow.show();
        mainWindow.focus();
    });

    return mainWindow;
};
