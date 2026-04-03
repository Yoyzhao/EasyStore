const { contextBridge, ipcRenderer } = require('electron')

contextBridge.exposeInMainWorld('electronAPI', {
  platform: process.platform,
  checkBackendStatus: () => ipcRenderer.invoke('backend:check-status'),
  getBackendPort: () => ipcRenderer.invoke('backend:get-port'),
  restartBackend: () => ipcRenderer.invoke('backend:restart'),
  onBackendReady: (callback) => ipcRenderer.on('backend:ready', () => callback()),
  onBackendLog: (callback) => ipcRenderer.on('backend:log', (_event, log) => callback(log))
})

// 同时保留旧的名称以防万一，但主要使用 electronAPI
contextBridge.exposeInMainWorld('easyStoreDesktop', {
  platform: process.platform
})
