const path = require('path')

const electronOutDir = process.env.EASYSTORE_ELECTRON_OUT
  ? path.resolve(process.env.EASYSTORE_ELECTRON_OUT)
  : path.join(__dirname, 'out')

module.exports = {
  packagerConfig: {
    asar: true,
    executableName: 'EasyStore',
    icon: path.join(__dirname, 'build', 'icon.ico'),
    out: electronOutDir,
    extraResource: [
      path.join(__dirname, '.stage', 'backend'),
      path.join(__dirname, '.stage', 'renderer'),
      path.join(__dirname, '.env.example')
    ],
    win32metadata: {
      CompanyName: 'EasyStore',
      FileDescription: 'EasyStore Windows Client',
      OriginalFilename: 'EasyStore.exe',
      ProductName: 'EasyStore'
    }
  },
  makers: [
    {
      name: '@electron-forge/maker-squirrel',
      config: {
        name: 'easystore',
        setupExe: 'EasyStoreSetup.exe',
        setupIcon: path.join(__dirname, 'build', 'icon.ico')
      }
    },
    {
      name: '@electron-forge/maker-zip',
      platforms: ['win32']
    }
  ],
  plugins: [
    {
      name: '@electron-forge/plugin-auto-unpack-natives',
      config: {}
    }
  ]
}
