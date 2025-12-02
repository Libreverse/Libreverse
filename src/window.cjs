const { BrowserWindow, screen } = require("electron");
const path = require("node:path");

module.exports = ({
    isDev: isDevelopment = false,
    url = "http://localhost:3000",
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
        title: "Libreverse Desktop",
    });

    mainWindow.loadURL(url);

    mainWindow.once("ready-to-show", () => {
        mainWindow.show();
        mainWindow.focus();

        if (isDevelopment) {
            mainWindow.webContents.openDevTools({ mode: "right" });
        }
    });

    return mainWindow;
};
