const { app, BrowserWindow, session } = require('electron');
const path = require('node:path');

// Set the app name early (before app.whenReady) for macOS dock, menus, etc.
app.setName('Libreverse');

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

const { ElectronBlocker } = require('@ghostery/adblocker-electron');
const fetch = require('cross-fetch');
const fs = require('fs').promises;

// This method will be called when Electron has finished initialization.
app.whenReady().then(async () => {
  // Set macOS dock icon
  if (process.platform === 'darwin') {
    app.dock.setIcon(path.join(__dirname, '../app/images/macos-icon.png'));
  }

  const mainWindow = createWindow({ isDev, url: process.env.APP_URL || 'http://localhost:3000' });

  // Load adblocker filters from our Rails proxy endpoint
  const filterListUrl = process.env.APP_URL ? `${process.env.APP_URL}/proxy/electron-filterlists` : 'http://localhost:3000/proxy/electron-filterlists';
  const blocker = await ElectronBlocker.fromLists(fetch, [filterListUrl], {
    path: path.join(app.getPath('userData'), 'engine.bin'),
    read: fs.readFile,
    write: fs.writeFile,
  });
  blocker.enableBlockingInSession(session.defaultSession);

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