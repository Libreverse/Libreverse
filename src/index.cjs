const { app, BrowserWindow } = require('electron');
const path = require('node:path');
const { Menu } = require('electron');

Menu.setApplicationMenu(null)

// Handle creating/removing shortcuts on Windows when installing/uninstalling.
if (require('electron-squirrel-startup')) {
  app.quit();
}

// apply CLI switches from a small config to keep this file concise
const flags = require('./flags.cjs');
flags.forEach(f => {
  if (Array.isArray(f)) app.commandLine.appendSwitch(f[0], f[1]);
  else app.commandLine.appendSwitch(f);
});

// ensure single instance and focus existing window on second-instance
const gotLock = app.requestSingleInstanceLock();
if (!gotLock) {
  app.quit();
  return;
}
app.on('second-instance', () => {
  const win = BrowserWindow.getAllWindows()[0];
  if (win) {
    if (win.isMinimized()) win.restore();
    win.focus();
  }
});

const createWindow = require('./window.cjs');
const isDev = process.env.NODE_ENV === 'development';

// This method will be called when Electron has finished initialization.
app.whenReady().then(() => {
  const mainWindow = createWindow({ isDev, url: process.env.APP_URL || 'http://localhost:3000' });

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow({ isDev, url: process.env.APP_URL || 'http://localhost:3000' });
    } else if (mainWindow && mainWindow.isMinimized()) {
      mainWindow.restore();
      mainWindow.focus();
    }
  });
});

// Quit when all windows are closed.
app.on('window-all-closed', () => {
    app.quit();
});

// In this file you can include the rest of your app's specific main process
// code. You can also put them in separate files and import them here.