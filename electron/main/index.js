const { app, BrowserWindow, dialog, ipcMain, net } = require('electron')
const { spawn, spawnSync } = require('child_process')
const fs = require('fs')
const http = require('http')
const path = require('path')
const netModule = require('net')

// 加载 .env 配置
function loadEnv() {
  const dotenv = require('dotenv')
  
  // 定义搜索路径顺序（优先级从高到低）
  const searchPaths = []
  
  if (app.isPackaged) {
    const exePath = app.getPath('exe')
    const exeDir = path.dirname(exePath)
    
    // 调试日志：输出当前搜索路径
    console.log(`Executable Path: ${exePath}`)
    console.log(`Executable Directory: ${exeDir}`)

    // 1. 程序同级目录 (app-1.0.0/EasyStore.exe 旁边)
    searchPaths.push(path.join(exeDir, '.env'))
    
    // 2. 安装根目录 (Squirrel: Local/easystore 目录下)
    // 通常 exe 在 app-1.0.0 目录下，向上退一级就是安装根目录
    searchPaths.push(path.join(exeDir, '..', '.env'))
    
    // 3. 用户数据目录 (AppData/Roaming/easystore 目录下)
    searchPaths.push(path.join(app.getPath('userData'), '.env'))
    
    // 4. 资源目录 (app-1.0.0/resources 目录下)
    searchPaths.push(path.join(process.resourcesPath, '.env'))
  } else {
    // 开发环境下
    searchPaths.push(path.join(__dirname, '..', '.env'))
  }

  for (const p of searchPaths) {
    if (fs.existsSync(p)) {
      dotenv.config({ path: p })
      console.log(`Loaded env from: ${p}`)
      break // 找到第一个就停止
    }
  }
}

loadEnv()

if (require('electron-squirrel-startup')) {
  app.quit()
}

const HOST = '127.0.0.1'
let PORT = 8000
const HEALTH_CHECK_PATH = '/health'

// 寻找可用端口
async function findAvailablePort(startPort) {
  return new Promise((resolve) => {
    const server = netModule.createServer()
    server.unref()
    server.on('error', () => {
      resolve(findAvailablePort(startPort + 1))
    })
    server.listen(startPort, HOST, () => {
      server.close(() => {
        resolve(startPort)
      })
    })
  })
}

let mainWindow = null
let backendProcess = null
let isQuitting = false
let isBackendReady = false
let backendLogs = []

function getAppHome() {
  // 优先从环境变量读取
  if (process.env.EASYSTORE_APP_HOME) {
    const customHome = path.isAbsolute(process.env.EASYSTORE_APP_HOME)
      ? process.env.EASYSTORE_APP_HOME
      : path.join(process.resourcesPath, process.env.EASYSTORE_APP_HOME)
    fs.mkdirSync(customHome, { recursive: true })
    return customHome
  }
  const appHome = app.getPath('userData')
  fs.mkdirSync(appHome, { recursive: true })
  return appHome
}

function getBackendExecutable() {
  const backendRoot = app.isPackaged
    ? path.join(process.resourcesPath, 'backend')
    : path.join(__dirname, '..', '.stage', 'backend')

  return path.join(backendRoot, 'easystore-server.exe')
}

function getRendererEntry() {
  const rendererRoot = app.isPackaged
    ? path.join(process.resourcesPath, 'renderer')
    : path.join(__dirname, '..', '.stage', 'renderer')

  return path.join(rendererRoot, 'index.html')
}

function getWindowIcon() {
  return path.join(__dirname, '..', 'build', 'icon.ico')
}

function createMainWindow() {
  mainWindow = new BrowserWindow({
    width: 1440,
    height: 900,
    minWidth: 1200,
    minHeight: 760,
    show: false,
    autoHideMenuBar: true,
    backgroundColor: '#fff7eb',
    icon: getWindowIcon(),
    webPreferences: {
      preload: path.join(__dirname, '..', 'preload', 'index.js'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false, // 改为 false 以允许 preload 脚本使用一些 electron 功能
      spellcheck: false
    }
  })

  mainWindow.on('closed', () => {
    mainWindow = null
  })
}

function loadLoadingScreen() {
  if (!mainWindow) {
    createMainWindow()
  }

  const loadingHtml = `
    <!DOCTYPE html>
    <html lang="zh-CN">
      <head>
        <meta charset="UTF-8" />
        <title>EasyStore</title>
        <style>
          body {
            margin: 0;
            font-family: "Microsoft YaHei", sans-serif;
            background: linear-gradient(135deg, #fff7eb 0%, #ffedd5 100%);
            color: #9a3412;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
          }

          .card {
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 16px;
            padding: 32px 40px;
            border-radius: 24px;
            background: rgba(255, 255, 255, 0.88);
            box-shadow: 0 20px 50px rgba(249, 115, 22, 0.12);
          }

          .logo {
            width: 72px;
            height: 72px;
          }

          .title {
            font-size: 24px;
            font-weight: 700;
          }

          .desc {
            font-size: 14px;
            color: #c2410c;
          }
        </style>
      </head>
      <body>
        <div class="card">
          <img class="logo" src="file://${path.join(__dirname, '..', 'build', 'icon.png').replace(/\\/g, '/')}" alt="EasyStore" />
          <div class="title">EasyStore</div>
          <div class="desc">正在启动本地服务，请稍候...</div>
        </div>
      </body>
    </html>
  `

  mainWindow.loadURL(`data:text/html;charset=utf-8,${encodeURIComponent(loadingHtml)}`)
  mainWindow.show()
}

function requestHealthCheck() {
  return new Promise((resolve, reject) => {
    const req = http.get(
      {
        host: HOST,
        port: PORT,
        path: HEALTH_CHECK_PATH,
        timeout: 2000
      },
      (res) => {
        let body = ''
        res.on('data', (chunk) => {
          body += chunk
        })
        res.on('end', () => {
          if (res.statusCode !== 200) {
            reject(new Error(`Unexpected status code: ${res.statusCode}`))
            return
          }

          try {
            const data = JSON.parse(body)
            if (data.status === 'ok') {
              resolve(true)
              return
            }
          } catch (error) {
          }

          reject(new Error('Health check failed'))
        })
      }
    )

    req.on('error', reject)
    req.on('timeout', () => {
      req.destroy(new Error('Health check timeout'))
    })
  })
}

async function waitForServerReady(timeoutMs = 45000) {
  const startedAt = Date.now()

  while (Date.now() - startedAt < timeoutMs) {
    if (backendProcess && backendProcess.exitCode !== null) {
      throw new Error('后端服务启动失败')
    }

    try {
      await requestHealthCheck()
      isBackendReady = true
      if (mainWindow) {
        mainWindow.webContents.send('backend:ready')
      }
      return
    } catch (error) {
      await new Promise((resolve) => setTimeout(resolve, 500))
    }
  }

  throw new Error('后端服务启动超时')
}

function startBackend() {
  if (backendProcess) {
    return
  }

  const backendExecutable = getBackendExecutable()
  if (!fs.existsSync(backendExecutable)) {
    throw new Error(`未找到后端程序：${backendExecutable}`)
  }

  backendProcess = spawn(backendExecutable, [], {
    windowsHide: true,
    env: {
      ...process.env,
      EASYSTORE_APP_HOME: getAppHome(),
      EASYSTORE_PORT: PORT.toString(),
      PYTHONUTF8: '1'
    },
    stdio: ['ignore', 'pipe', 'pipe']
  })

  backendProcess.stdout.on('data', (data) => {
    const log = data.toString()
    backendLogs.push(log)
    if (mainWindow) {
      mainWindow.webContents.send('backend:log', log)
    }
  })

  backendProcess.stderr.on('data', (data) => {
    const log = data.toString()
    backendLogs.push(log)
    if (mainWindow) {
      mainWindow.webContents.send('backend:log', log)
    }
  })

  backendProcess.once('exit', (code) => {
    backendProcess = null
    isBackendReady = false

    if (!isQuitting) {
      dialog.showErrorBox('EasyStore', `后端服务已退出，退出码：${code ?? 'unknown'}`)
      app.quit()
    }
  })
}

function stopBackend() {
  if (!backendProcess || backendProcess.pid === undefined) {
    return
  }

  spawnSync('taskkill', ['/pid', `${backendProcess.pid}`, '/t', '/f'], {
    windowsHide: true
  })
  backendProcess = null
}

// 注册 IPC 监听器
function registerIpcHandlers() {
  ipcMain.handle('backend:check-status', () => {
    return isBackendReady
  })
  ipcMain.handle('backend:get-port', () => {
    return PORT
  })
}

async function bootstrap() {
  // 如果 .env 中指定了固定端口，则使用它，否则寻找可用端口
  if (process.env.EASYSTORE_PORT) {
    PORT = parseInt(process.env.EASYSTORE_PORT, 10)
  } else {
    PORT = await findAvailablePort(8000)
  }
  
  loadLoadingScreen()
  startBackend()
  registerIpcHandlers()
  await waitForServerReady()

  if (!mainWindow) {
    createMainWindow()
  }

  const rendererEntry = getRendererEntry()
  if (!fs.existsSync(rendererEntry)) {
    throw new Error(`未找到前端资源：${rendererEntry}`)
  }

  // 使用 URL 对象构造带参数的路径
  const rendererUrl = `file:///${rendererEntry.replace(/\\/g, '/')}`
  mainWindow.loadURL(`${rendererUrl}?port=${PORT}`)
  mainWindow.show()
}

const hasSingleInstanceLock = app.requestSingleInstanceLock()

if (!hasSingleInstanceLock) {
  app.quit()
} else {
  app.on('second-instance', () => {
    if (mainWindow) {
      if (mainWindow.isMinimized()) {
        mainWindow.restore()
      }
      mainWindow.focus()
    }
  })

  app.whenReady().then(async () => {
    try {
      await bootstrap()
    } catch (error) {
      dialog.showErrorBox('EasyStore', error instanceof Error ? error.message : '启动失败')
      app.quit()
    }
  })

  app.on('window-all-closed', () => {
    app.quit()
  })

  app.on('before-quit', () => {
    isQuitting = true
    stopBackend()
  })

  app.on('activate', async () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      try {
        await bootstrap()
      } catch (error) {
        dialog.showErrorBox('EasyStore', error instanceof Error ? error.message : '启动失败')
        app.quit()
      }
    }
  })
}
