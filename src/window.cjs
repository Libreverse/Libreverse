const { BrowserWindow, screen } = require('electron');
const path = require('node:path');

module.exports = ({ isDev = false, url = 'http://localhost:3000' } = {}) => {
  const primary = screen.getPrimaryDisplay();
  const { width, height } = primary.size;

  const titleBarOptions = process.platform === 'darwin' ? {
      titleBarStyle: 'hiddenInset',
    } : {
      titleBarOverlay: {
        color: '#00000000',
        symbolColor: 'white',
      },
    };

  const mainWindow = new BrowserWindow({
    width,
    height,
    ...titleBarOptions,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
    },
    show: false,
    title: 'Libreverse Desktop',
  });

  mainWindow.loadURL(url);

  mainWindow.once('ready-to-show', () => {
    mainWindow.show();

    if (isDev) {
      mainWindow.webContents.openDevTools({ mode: 'right' });
    }
  });

  return mainWindow;
};
