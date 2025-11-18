import { app, BrowserWindow, session, Menu, ipcMain } from "electron";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { dirname } from "node:path";
import fixPath from "fix-path";
import openAboutWindow from "about-window";
import squirrelStartup from "electron-squirrel-startup";
import flags from "./flags.cjs";
import createWindow from "./window.cjs";
import isDev from "electron-is-dev";
import { ElectronBlocker } from "@ghostery/adblocker-electron";
import fetch from "cross-fetch";
import fs from "node:fs/promises";
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
let mainWindow = null;

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
        url: `${baseUrl}?platform=${process.platform}`,
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
    // Set macOS dock icon
    if (process.platform === "darwin") {
        app.dock.setIcon(path.join(__dirname, "../app/images/macos-icon.png"));
    }

    mainWindow = ensureMainWindow();

    // Create application menu
    const template = [
        {
            label: "Libreverse",
            submenu: [
                {
                    label: "About Libreverse",
                    click: () => {
                        openAboutWindow({
                            icon_path: path.join(
                                __dirname,
                                "../app/images/macos-icon.png",
                            ),
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

    // IPC handlers for window controls
    ipcMain.handle("minimize-window", (event) => {
        const win = BrowserWindow.fromWebContents(event.sender);
        if (win) win.minimize();
    });
    ipcMain.handle("maximize-window", (event) => {
        const win = BrowserWindow.fromWebContents(event.sender);
        if (win) win.maximize();
    });
    ipcMain.handle("close-window", (event) => {
        const win = BrowserWindow.fromWebContents(event.sender);
        if (win) win.close();
    });

    // Load adblocker filters from our Rails proxy endpoint
    const filterListUrl = process.env.APP_URL
        ? `${process.env.APP_URL}/proxy/electron-filterlists`
        : "https://localhost:3000/proxy/electron-filterlists";
    const blocker = await ElectronBlocker.fromLists(fetch, [filterListUrl], {
        path: path.join(app.getPath("userData"), "engine.bin"),
        read: fs.readFile,
        write: fs.writeFile,
    });
    blocker.enableBlockingInSession(session.defaultSession);
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
