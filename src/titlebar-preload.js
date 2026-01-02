const { contextBridge, ipcRenderer } = require('electron');

// Expose IPC methods to titlebar
contextBridge.exposeInMainWorld('electronAPI', {
    closeWindow: () => ipcRenderer.sendToHost('close-window'),
    minimizeWindow: () => ipcRenderer.sendToHost('minimize-window'),
    maximizeWindow: () => ipcRenderer.sendToHost('maximize-window')
});
