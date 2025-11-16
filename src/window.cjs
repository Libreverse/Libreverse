const { BrowserWindow, screen } = require("electron");
const path = require("node:path");

module.exports = ({ isDev: isDevelopment = false, url = "http://localhost:3000" } = {}) => {
    const primary = screen.getPrimaryDisplay();
    const { width, height } = primary.size;

    const mainWindow = new BrowserWindow({
        width,
        height,
        frame: false,
        webPreferences: {
            preload: path.join(__dirname, "preload.js"),
        },
        show: false,
        title: "Libreverse Desktop",
    });

    mainWindow.loadURL(url);

    mainWindow.once("ready-to-show", () => {
        mainWindow.show();

        if (isDevelopment) {
            mainWindow.webContents.openDevTools({ mode: "right" });
        }
    });

    return mainWindow;
};
