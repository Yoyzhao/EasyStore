import fs from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

import pngToIco from 'png-to-ico'
import sharp from 'sharp'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

const electronDir = path.resolve(__dirname, '..')
const sourceSvg = path.join(electronDir, 'icon1.svg')
const buildDir = path.join(electronDir, 'build')
const outputPng = path.join(buildDir, 'icon.png')
const outputIco = path.join(buildDir, 'icon.ico')

await fs.mkdir(buildDir, { recursive: true })

await sharp(sourceSvg)
  .resize(512, 512, {
    fit: 'contain',
    background: { r: 0, g: 0, b: 0, alpha: 0 }
  })
  .png()
  .toFile(outputPng)

const icoBuffer = await pngToIco(outputPng)
await fs.writeFile(outputIco, icoBuffer)
