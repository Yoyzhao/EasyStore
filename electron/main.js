const { app, BrowserWindow } = require('electron');
const path = require('path');
const { spawn, execFile } = require('child_process');
const axios = require('axios');
const fs = require('fs');

let mainWindow;
let backendProcess;

// Backend executable name
const BACKEND_EXE = 'easystore-server.exe';
// Default backend URL
let backendUrl = 'http://localhost:8000';

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false,
    },
    title: "EasyStore",
    icon: path.join(__dirname, 'icon.ico'), // Use the ico file
  });

  // In production, load from the built web/dist folder
  let indexPath;
  if (app.isPackaged) {
    indexPath = path.join(__dirname, 'web/dist/index.html');
  } else {
    indexPath = path.join(__dirname, '../web/dist/index.html');
  }
  
  if (fs.existsSync(indexPath)) {
    mainWindow.loadFile(indexPath);
  } else {
    // If frontend dist not found, try pointing to dev server for testing
    // In final package, we MUST have the built files
    mainWindow.loadURL('http://localhost:5173');
  }

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

function startBackend() {
  const isDev = !app.isPackaged;
  let backendPath;

  if (isDev) {
    // In dev, we can run python directly or a pre-built exe
    backendPath = path.join(__dirname, '../server/dist/easystore-server/easystore-server.exe');
    if (!fs.existsSync(backendPath)) {
        console.log('Backend exe not found in dev, assuming manual python run');
        return;
    }
  } else {
    // In packaged app, exe is in the resources folder
    backendPath = path.join(process.resourcesPath, 'bin', 'easystore-server', BACKEND_EXE);
  }

  console.log(`Starting backend at: ${backendPath}`);
  
  backendProcess = execFile(backendPath, {
    cwd: path.dirname(backendPath),
    windowsHide: true,
  });

  backendProcess.stdout.on('data', (data) => {
    console.log(`Backend: ${data}`);
  });

  backendProcess.stderr.on('data', (data) => {
    console.error(`Backend Error: ${data}`);
  });

  backendProcess.on('close', (code) => {
    console.log(`Backend process exited with code ${code}`);
  });
}

// Check if backend is alive
async function checkBackendAlive() {
  try {
    const response = await axios.get(`${backendUrl}/health`);
    return response.status === 200;
  } catch (error) {
    return false;
  }
}

// Wait for backend and create window
async function init() {
  startBackend();
  
  // Wait up to 30 seconds for backend to start
  let attempts = 0;
  while (attempts < 60) {
    if (await checkBackendAlive()) {
      console.log('Backend is alive!');
      createWindow();
      return;
    }
    console.log('Waiting for backend...');
    await new Promise(resolve => setTimeout(resolve, 500));
    attempts++;
  }
  
  console.error('Failed to start backend after 30 seconds');
  createWindow(); // Create window anyway, it might show an error page
}

app.on('ready', init);

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    if (backendProcess) {
      backendProcess.kill();
    }
    app.quit();
  }
});

app.on('activate', () => {
  if (mainWindow === null) {
    createWindow();
  }
});

app.on('will-quit', () => {
  if (backendProcess) {
    backendProcess.kill();
  }
});
