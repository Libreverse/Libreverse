import { BrowserWindow, screen, WebContentsView } from "electron";
import path from "node:path";
import { fileURLToPath } from "node:url";
import net from "node:net";
import isDev from "electron-is-dev";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const retryableChromiumErrorCodes = new Set([
    -3, -100, -102, -105, -106, -108, -109, -111,
]);
const retryableElectronErrorCodes = new Set(["ERR_ABORTED"]);
const retryableNodeErrorCodes = new Set([
    "ECONNREFUSED",
    "ECONNRESET",
    "EHOSTUNREACH",
    "ENETUNREACH",
    "ETIMEDOUT",
]);

const normalizeErrorCode = (code) => {
    if (typeof code === "string" && /^-?\d+$/.test(code)) {
        return Number.parseInt(code, 10);
    }
    return code;
};

const isRetryableLoadError = (error) => {
    const rawCode = error?.code ?? error?.errno;
    const code = normalizeErrorCode(rawCode);
    return (
        retryableChromiumErrorCodes.has(code) ||
        retryableElectronErrorCodes.has(code) ||
        retryableNodeErrorCodes.has(code) ||
        error?.message === "tcp_timeout"
    );
};

const getTcpProbeForUrl = (rawUrl) => {
    try {
        const u = new URL(rawUrl);
        const isLocalhost =
            u.hostname === "localhost" ||
            u.hostname === "127.0.0.1" ||
            u.hostname === "::1";
        const isHttp = u.protocol === "http:" || u.protocol === "https:";
        if (!isLocalhost || !isHttp) return;

        const port = u.port
            ? Number.parseInt(u.port, 10)
            : (u.protocol === "https:"
              ? 443
              : 80);

        return { host: u.hostname, port };
    } catch {
        return;
    }
};

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

        socket.once("error", (error) => {
            clearTimeout(timeout);
            socket.destroy();
            reject(error);
        });
    });
};

const buildWaitingPageUrl = (targetUrl) => {
    const html = `<html><body style="background:#0e0e0e;color:#fff;font-family:sans-serif;display:flex;align-items:center;justify-content:center;height:100vh;margin:0;"><div style="text-align:center;max-width:640px;padding:24px;"><h1>Libreverse</h1><p>Waiting for <code>${targetUrl}</code></p><p>Start Rails with: <code>bin/dev</code></p><p>Retrying automatically…</p></div></body></html>`;
    return `data:text/html;charset=utf-8,${encodeURIComponent(html)}`;
};

const buildFatalPageUrl = (targetUrl, error) => {
    const rawCode = error?.code ?? error?.errno;
    const code = rawCode == undefined ? "" : String(rawCode);
    const message = error?.message ? String(error.message) : "Unknown error";
    const html = `<html><body style="background:#0e0e0e;color:#fff;font-family:sans-serif;display:flex;align-items:center;justify-content:center;height:100vh;margin:0;"><div style="text-align:center;max-width:640px;padding:24px;"><h1>Libreverse</h1><p>Failed to load <code>${targetUrl}</code></p><p><code>${code}</code> ${message}</p></div></body></html>`;
    return `data:text/html;charset=utf-8,${encodeURIComponent(html)}`;
};

const loadUrlWithPeriodicRetry = async (
    win,
    targetUrl,
    { retryIntervalMs = 2000, tcpTimeoutMs = 750 } = {},
) => {
    const tcpProbe = getTcpProbeForUrl(targetUrl);
    const waitingPageUrl = buildWaitingPageUrl(targetUrl);

    while (!win.isDestroyed()) {
        try {
            if (tcpProbe) {
                await waitForTcp(tcpProbe.host, tcpProbe.port, tcpTimeoutMs);
            }

            await win.loadURL(targetUrl);
            return true;
        } catch (error) {
            const shouldRetry = tcpProbe && isRetryableLoadError(error);
            if (!shouldRetry) throw error;

            try {
                if (
                    !win.isDestroyed() &&
                    win.webContents.getURL() !== waitingPageUrl
                ) {
                    await win.loadURL(waitingPageUrl);
                }
            } catch {
                // ignore
            }

            await sleep(retryIntervalMs);
        }
    }

    return false;
};

export default ({
    isDev: isDevelopment = isDev,
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
        },
        show: false,
        title: "Libreverse",
    });

    mainWindow.webContents.once("did-finish-load", () => {
        mainWindow.webContents.setZoomLevel(2); // Equivalent to two Cmd+/Ctrl+ + presses
    });

    // Create titlebar view only
    const titlebarView = new WebContentsView({
        webPreferences: {
            contextIsolation: true,
            nodeIntegration: false,
            enableRemoteModule: false,
            transparent: true,
            backgroundColor: "transparent",
        },
    });

    // Add titlebar view to main window
    mainWindow.contentView.addChildView(titlebarView);

    // Position titlebar at top
    const resizeTitlebar = () => {
        const { width } = mainWindow.getBounds();

        titlebarView.setBounds({
            x: 0,
            y: 0,
            width: width,
            height: 32,
        });
    };

    // Handle window resize
    mainWindow.on("resize", resizeTitlebar);

    if (isDevelopment) {
        mainWindow.webContents.on(
            "did-fail-load",
            (event, errorCode, errorDescription, validatedURL) => {
                console.log(
                    "MAIN: Failed to load:",
                    errorCode,
                    errorDescription,
                    validatedURL,
                );
            },
        );
    }

    loadUrlWithPeriodicRetry(mainWindow, url).catch((error) => {
        console.error("Failed to load main URL:", error);
        if (mainWindow.isDestroyed()) return;
        mainWindow.loadURL(buildFatalPageUrl(url, error));
    });

    // Load titlebar content
    console.log("Loading titlebar content...");
    const titlebarHTML = `
        <!doctype html>
        <html>
        <head>
            <style>
                body {
                    margin: 0;
                    padding: 0;
                    height: 32px;
                    background: transparent;
                    display: flex;
                    align-items: center;
                    padding-left: 10px;
                    box-sizing: border-box;
                    -webkit-app-region: drag;
                }
                .traffic-lights {
                    -webkit-app-region: no-drag;
                    display: flex;
                    gap: 8px;
                }
                .traffic-light {
                    width: 12px;
                    height: 12px;
                    border-radius: 50%;
                    cursor: default;
                }
                .close { background-color: #ff5f57; }
                .minimize { background-color: #ffbd2e; }
                .maximize { background-color: #28ca42; }
            </style>
        </head>
        <body>
            <div class="traffic-lights">
                <div class="traffic-light close" id="close"></div>
                <div class="traffic-light minimize" id="minimize"></div>
                <div class="traffic-light maximize" id="maximize"></div>
            </div>
        </body>
        </html>
    `;
    titlebarView.webContents.loadURL(
        `data:text/html;charset=utf-8,${encodeURIComponent(titlebarHTML)}`,
    );

    // Add titlebar event listeners for debugging
    titlebarView.webContents.on("did-finish-load", () => {
        console.log("EVENT: Titlebar finished loading");
        console.log("Titlebar URL:", titlebarView.webContents.getURL());

        // Add click handlers - use main process directly
        titlebarView.webContents.executeJavaScript(`
            console.log('Setting up click handlers...');
            
            try {
                document.getElementById('close').addEventListener('click', () => {
                    console.log('Close button clicked');
                    // Send message to main process via titlebar view
                    document.title = 'CLOSE_WINDOW';
                });
                
                document.getElementById('minimize').addEventListener('click', () => {
                    console.log('Minimize button clicked');
                    // Send message to main process via titlebar view
                    document.title = 'MINIMIZE_WINDOW';
                });
                
                document.getElementById('maximize').addEventListener('click', () => {
                    console.log('Maximize button clicked');
                    // Send message to main process via titlebar view
                    document.title = 'MAXIMIZE_WINDOW';
                });
                
                console.log('Click handlers set up successfully');
            } catch (error) {
                console.error('Error setting up click handlers:', error);
            }
        `);

        // Listen for title changes to detect clicks
        titlebarView.webContents.on("page-title-updated", (event, title) => {
            console.log("Titlebar title changed:", title);
            switch (title) {
                case "CLOSE_WINDOW": {
                    mainWindow.close();

                    break;
                }
                case "MINIMIZE_WINDOW": {
                    mainWindow.minimize();

                    break;
                }
                case "MAXIMIZE_WINDOW": {
                    if (mainWindow.isMaximized()) {
                        mainWindow.unmaximize();
                    } else {
                        mainWindow.maximize();
                    }

                    break;
                }
                // No default
            }
        });

        // Add console error listener
        titlebarView.webContents.on(
            "console-message",
            (_event, level, message) => {
                console.log("Titlebar console:", level, message);
            },
        );
    });

    titlebarView.webContents.on(
        "did-fail-load",
        (event, errorCode, errorDescription) => {
            console.log(
                "EVENT: Titlebar failed to load:",
                errorCode,
                errorDescription,
            );
        },
    );

    // Wait for window to be ready before showing
    mainWindow.once("ready-to-show", () => {
        resizeTitlebar();

        // Show window
        mainWindow.show();
        mainWindow.focus();

        // DevTools can be opened manually when needed
        // if (isDevelopment) {
        //     mainWindow.webContents.openDevTools({ mode: 'detach' });
        // }

        return { mainWindow, titlebarView };
    });

    return mainWindow;
};
