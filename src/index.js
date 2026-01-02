require('v8-compile-cache');
import { app, BrowserWindow, BrowserView, session, Menu, ipcMain } from "electron";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { dirname } from "node:path";
import fixPath from "fix-path";
import openAboutWindow from "about-window";
import squirrelStartup from "electron-squirrel-startup";
import flags from "./flags.js";
import createWindow from "./window.js";
import isDev from "electron-is-dev";
import { FiltersEngine, Request } from "@ghostery/adblocker";
import fs from "node:fs/promises";
import fetch from "node-fetch";
import contextMenu from "electron-context-menu";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

fixPath();

// Set the app name early (before app.whenReady) for macOS dock, menus, etc.
app.setName("Libreverse");

// Handle creating/removing shortcuts on Windows when installing/uninstalling.
if (squirrelStartup) {
    app.quit();
}

// apply CLI switches from a small config to keep this file concise
for (const f of flags) {
    if (Array.isArray(f)) app.commandLine.appendSwitch(f[0], f[1]);
    else app.commandLine.appendSwitch(f);
}

const baseUrl = process.env.APP_URL || "https://localhost:3000";
// strangely it doesn't keep the window open without this.
let mainWindow = null;

let ugcView = null;

const baseOrigin = (() => {
    try {
        return new URL(baseUrl).origin;
    } catch {
        return null;
    }
})();

// Keep a small strip of the main window visible so the app chrome/traffic-lights
// remain usable even while the sandboxed UGC BrowserView is open.
// (We intentionally keep this single-window UX.)
const UGC_VIEW_TOP_INSET_PX = Number.parseInt(
    process.env.UGC_VIEW_TOP_INSET_PX || "44",
    10,
);

const isAllowedUgcUrl = (rawUrl) => {
    if (!rawUrl || typeof rawUrl !== "string") return false;

    let u;
    try {
        // Accept relative URLs by resolving against the app base origin.
        if (baseOrigin && rawUrl.startsWith("/")) {
            u = new URL(rawUrl, baseOrigin);
        } else {
            u = new URL(rawUrl);
        }
    } catch {
        return false;
    }

    if (!baseOrigin || u.origin !== baseOrigin) return false;

    // Only allow our dedicated sandbox endpoint.
    // This prevents a compromised renderer from opening arbitrary app pages.
    if (!u.pathname.includes("/electron_sandbox")) return false;
    if (!u.pathname.startsWith("/experiences/")) return false;

    return true;
};

const closeUgcView = () => {
    if (!ugcView) return;

    try {
        if (mainWindow && !mainWindow.isDestroyed()) {
            // Only remove if it's the current view.
            if (mainWindow.getBrowserView?.() === ugcView) {
                mainWindow.setBrowserView(null);
            }
        }
    } catch {
        // ignore
    }

    try {
        ugcView.webContents?.destroy();
    } catch {
        // ignore
    }

    ugcView = null;
};

const openUgcView = async ({ url }) => {
    if (!isAllowedUgcUrl(url)) {
        throw new Error("ugc:view:open blocked by allowlist");
    }

    const win = ensureMainWindow();
    closeUgcView();

    ugcView = new BrowserView({
        webPreferences: {
            // Strong isolation: no Node, no preload, Chromium sandbox.
            sandbox: true,
            contextIsolation: true,
            nodeIntegration: false,
            enableRemoteModule: false,
            webSecurity: true,
            allowRunningInsecureContent: false,
            safeDialogs: true,
            navigateOnDragDrop: false,
            // Keep default partition so auth continues to work. We rely on the iframe sandbox
            // (no allow-same-origin) to prevent cookie access from UGC.
        },
    });

    win.setBrowserView(ugcView);
    ugcView.setAutoResize({ width: true, height: true });

    // Full-bleed overlay.
    const resize = () => {
        if (!ugcView || !win || win.isDestroyed()) return;
        const { width, height } = win.getContentBounds();
        const inset = Number.isFinite(UGC_VIEW_TOP_INSET_PX)
            ? Math.max(0, UGC_VIEW_TOP_INSET_PX)
            : 0;
        ugcView.setBounds({
            x: 0,
            y: inset,
            width,
            height: Math.max(0, height - inset),
        });
    };
    resize();

    // Keep bounds updated.
    win.on("resize", resize);
    win.on("closed", closeUgcView);

    // Lock down navigation.
    ugcView.webContents.setWindowOpenHandler(() => ({ action: "deny" }));
    ugcView.webContents.on("will-navigate", (event, nextUrl) => {
        if (!isAllowedUgcUrl(nextUrl)) event.preventDefault();
    });
    ugcView.webContents.on("will-redirect", (event, nextUrl) => {
        if (!isAllowedUgcUrl(nextUrl)) event.preventDefault();
    });

    // Press Escape to close the sandbox view.
    ugcView.webContents.on("before-input-event", (event, input) => {
        if (input.type === "keyDown" && input.key === "Escape") {
            event.preventDefault();
            closeUgcView();
        }
    });

    await ugcView.webContents.loadURL(url);
    return true;
};

const getFocusedOrMainWindow = () => {
    const win = BrowserWindow.getFocusedWindow();
    return win && !win.isDestroyed() ? win : mainWindow;
};

const attachContextMenu = (targetWindow) => {
    if (!targetWindow) return;
    contextMenu({
        window: targetWindow,
        prepend: (defaultActions, parameters, browserWindow) => [],
        append: (defaultActions, parameters, browserWindow) => [],
        showLearnSpelling: false,
        showLookUpSelection: false,
        showSearchWithGoogle: false,
        showSelectAll: false,
        showCopyImage: true,
        showCopyImageAddress: false,
        showSaveImage: true,
        showSaveImageAs: false,
        showCopyVideoAddress: false,
        showSaveVideo: false,
        showSaveVideoAs: false,
        showCopyLink: true,
        showSaveLinkAs: false,
        showInspectElement: false,
        showServices: false,
        labels: {},
        shouldShowMenu: (event, parameters) => true,
        menu: undefined,
        onShow: (event) => {},
        onClose: (event) => {},
    });
};

const buildMainWindow = () => {
    const window = createWindow({
        isDev,
    });

    attachContextMenu(window);

    window.on("closed", () => {
        if (mainWindow === window) {
            mainWindow = null;
        }
    });

    return window;
};

const ensureMainWindow = () => {
    if (!mainWindow || mainWindow.isDestroyed()) {
        mainWindow = buildMainWindow();
    }
    return mainWindow;
};

const focusWindow = (window) => {
    if (!window) return;
    if (window.isMinimized()) {
        window.restore();
    }
    if (!window.isVisible()) {
        window.show();
    }
    window.focus();
};

// ensure single instance and focus existing window on second-instance
const gotLock = app.requestSingleInstanceLock();
if (!gotLock) {
    app.quit();
}
app.on("second-instance", () => {
    if (!app.isReady()) {
        app.whenReady().then(() => {
            const win = ensureMainWindow();
            focusWindow(win);
        });
        return;
    }

    const win = ensureMainWindow();
    focusWindow(win);
});

// This method will be called when Electron has finished initialization.
app.whenReady().then(async () => {
    const iconPath = path.join(
        __dirname,
        isDev
            ? "../../app/images/macos-icon.png"
            : "../app/images/macos-icon.png",
    );

    // Set macOS dock icon
    if (process.platform === "darwin") {
        app.dock.setIcon(iconPath);
    }

    mainWindow = ensureMainWindow();

    // ---------------------------------------------------------------------
    // IPC: window controls + cookie management
    // ---------------------------------------------------------------------

    ipcMain.handle("minimize-window", () => {
        const win = getFocusedOrMainWindow();
        if (win && !win.isDestroyed()) win.minimize();
        return true;
    });

    ipcMain.handle("maximize-window", () => {
        const win = getFocusedOrMainWindow();
        if (!win || win.isDestroyed()) return false;
        if (win.isMaximized()) win.unmaximize();
        else win.maximize();
        return true;
    });

    ipcMain.handle("close-window", () => {
        const win = getFocusedOrMainWindow();
        if (win && !win.isDestroyed()) win.close();
        return true;
    });

    // ---------------------------------------------------------------------
    // IPC: UGC sandbox view (BrowserView)
    // ---------------------------------------------------------------------

    ipcMain.handle("ugc:view:open", async (_event, payload = {}) => {
        return await openUgcView({ url: payload?.url });
    });

    ipcMain.handle("ugc:view:close", () => {
        closeUgcView();
        return true;
    });

    ipcMain.handle("cookies:set", async (event, payload = {}) => {
        const { url, name, value, options = {} } = payload;

        if (!url || !name) {
            throw new Error("cookies:set requires url and name");
        }

        const u = new URL(url);
        const cookieUrl = u.origin;

        const details = {
            url: cookieUrl,
            name: String(name),
            value: value == null ? "" : String(value),
            path: options.path || "/",
            httpOnly: !!options.httpOnly,
            secure:
                typeof options.secure === "boolean"
                    ? options.secure
                    : u.protocol === "https:",
        };

        // Electron expects expirationDate in seconds since UNIX epoch.
        if (typeof options.expirationDate === "number") {
            details.expirationDate = options.expirationDate;
        }

        if (options.sameSite) {
            details.sameSite = options.sameSite;
        }

        await event.sender.session.cookies.set(details);
        return true;
    });

    ipcMain.handle("cookies:remove", async (event, payload = {}) => {
        const { url, name } = payload;
        if (!url || !name) {
            throw new Error("cookies:remove requires url and name");
        }
        const u = new URL(url);
        await event.sender.session.cookies.remove(u.origin, String(name));
        return true;
    });

    // Load and enable adblocker
    loadEngine().then(() => {
        blockWithEngine();
    });

    // Create application menu
    const template = [
        {
            label: "Libreverse",
            submenu: [
                {
                    label: "About Libreverse",
                    click: () => {
                        openAboutWindow({
                            icon_path: iconPath,
                            package_json_dir: path.join(__dirname, "../"),
                            use_version_info: true,
                            show_close_button: "Close",
                        });
                    },
                },
                { type: "separator" },
                { role: "quit" },
            ],
        },
        {
            label: "Edit",
            submenu: [
                { role: "undo" },
                { role: "redo" },
                { type: "separator" },
                { role: "cut" },
                { role: "copy" },
                { role: "paste" },
                { role: "selectall" },
            ],
        },
        {
            label: "View",
            submenu: [
                { role: "reload" },
                { role: "forcereload" },
                { role: "toggledevtools" },
                { type: "separator" },
                { role: "resetzoom" },
                { role: "zoomin" },
                { role: "zoomout" },
                { type: "separator" },
                { role: "togglefullscreen" },
            ],
        },
        {
            label: "Window",
            submenu: [{ role: "minimize" }, { role: "close" }],
        },
    ];

    const menu = Menu.buildFromTemplate(template);
    Menu.setApplicationMenu(menu);

    const LISTS = [
        "https://ublockorigin.github.io/uAssetsCDN/filters/filters.min.txt",
        "https://ublockorigin.github.io/uAssetsCDN/filters/badware.txt",
        "https://ublockorigin.github.io/uAssetsCDN/filters/privacy.min.txt",
        "https://ublockorigin.github.io/uAssetsCDN/filters/quick-fixes.txt",
        "https://ublockorigin.github.io/uAssetsCDN/filters/unbreak.txt",
        "https://ublockorigin.github.io/uAssetsCDN/thirdparties/easylist.txt",
        "https://filters.adtidy.org/extension/ublock/filters/2.txt",
        "https://filters.adtidy.org/extension/ublock/filters/11.txt",
        "https://ublockorigin.github.io/uAssetsCDN/thirdparties/easyprivacy.txt",
        "https://filters.adtidy.org/extension/ublock/filters/14.txt",
        "https://secure.fanboy.co.nz/fanboy-cookiemonster.txt",
        "https://ublockorigin.github.io/uAssetsCDN/thirdparties/easylist-cookies.txt",
        "https://filters.adtidy.org/extension/ublock/filters/3.txt",
        "https://ublockorigin.github.io/uAssetsCDN/thirdparties/easylist-social.txt",
        "https://filters.adtidy.org/extension/ublock/filters/15.txt",
        "https://ublockorigin.github.io/uAssetsCDN/thirdparties/easylist-annoyances.txt",
        "https://filters.adtidy.org/extension/ublock/filters/17.txt",
        "https://filters.adtidy.org/extension/ublock/filters/18.txt",
        "https://filters.adtidy.org/extension/ublock/filters/19.txt",
        "https://filters.adtidy.org/extension/ublock/filters/20.txt",
        "https://ublockorigin.github.io/uAssetsCDN/filters/annoyances.txt",
        "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/ClearURLs%20for%20uBo/clear_urls_uboified.txt",
        "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/LegitimateURLShortener.txt",
        "https://raw.githubusercontent.com/DandelionSprout/adfilt/refs/heads/master/BrowseWebsitesWithoutLoggingIn.txt",
        "https://raw.githubusercontent.com/DandelionSprout/adfilt/refs/heads/master/Dandelion%20Sprout's%20Website%20Stretcher.txt",
        "https://raw.githubusercontent.com/DandelionSprout/adfilt/refs/heads/master/EmptyPaddingRemover.txt",
        "https://raw.githubusercontent.com/DandelionSprout/adfilt/refs/heads/master/WebsiteStretcher4K.txt",
        "https://raw.githubusercontent.com/DandelionSprout/adfilt/refs/heads/master/WebsiteStretcherVertical.txt",
        "https://raw.githubusercontent.com/iam-py-test/my_filters_001/main/duckduckgo_extra_clean.txt",
        "https://raw.githubusercontent.com/iam-py-test/my_filters_001/refs/heads/main/special_lists/anti-malware-ubo-extension.txt",
        "https://raw.githubusercontent.com/yokoffing/filterlists/main/click2load.txt",
        "https://raw.githubusercontent.com/yokoffing/filterlists/main/privacy_essentials.txt",
        "https://filters.adtidy.org/extension/ublock/filters/3.txt",
    ];

    let engine;

    // Load or create engine
    async function loadEngine() {
        const CACHE_DIR = path.join(app.getPath("userData"), "adblock-cache");
        const ENGINE_PATH = path.join(CACHE_DIR, "engine.bin");

        // Ensure cache dir
        try {
            await fs.mkdir(CACHE_DIR, { recursive: true });
        } catch {
            // ignore if exists
        }

        if (await fs.stat(ENGINE_PATH).catch(() => false)) {
            try {
                const serialized = await fs.readFile(ENGINE_PATH);
                engine = FiltersEngine.deserialize(serialized);
                return;
            } catch {
                console.warn("Failed to load cached engine, rebuilding...");
            }
        }

        const rawLists = await Promise.all(
            LISTS.map((url) => fetch(url).then((r) => r.text())),
        );

        engine = FiltersEngine.parse(rawLists.join("\n"), {
            enableOptimizations: true,
            loadCosmeticFilters: true,
            loadNetworkFilters: true,
        });

        // Save for next launch
        await fs.writeFile(ENGINE_PATH, engine.serialize());
        console.log("Adblock engine built and cached");
    }

    function blockWithEngine(sess = session.defaultSession) {
        sess.webRequest.onBeforeRequest(
            { urls: ["<all_urls>"] },
            (details, callback) => {
                if (!engine) {
                    callback({});
                    return;
                }

                const request = Request.fromRawDetails({
                    type: details.resourceType || "other",
                    url: details.url,
                    sourceUrl: details.url,
                });

                const { match, redirect } = engine.match(request);

                if (match) {
                    callback({ cancel: true });
                } else if (redirect) {
                    callback({ redirectURL: redirect.dataUrl });
                } else {
                    callback({});
                }
            },
        );
    }
});

// Handle macOS dock icon click when no windows are open
app.on("activate", () => {
    const win = ensureMainWindow();
    focusWindow(win);
});

// Quit when all windows are closed.
app.on("window-all-closed", () => {
    if (process.platform !== "darwin") {
        app.quit();
    }
});

// In this file you can include the rest of your app's specific main process
// code. You can also put them in separate files and import them here.
