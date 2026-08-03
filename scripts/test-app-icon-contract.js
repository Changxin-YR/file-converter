const crypto = require('crypto')
const fs = require('fs')
const path = require('path')

const root = path.resolve(__dirname, '..')
const iconPaths = [
  'AppScope/resources/base/media/app_icon.png',
  'entry/src/main/resources/base/media/app_icon.png',
  'entry/src/main/resources/base/media/ui_about_app_icon.png'
]

function crc32(data) {
  let crc = 0xffffffff
  for (const byte of data) {
    crc ^= byte
    for (let bit = 0; bit < 8; bit++) {
      crc = (crc >>> 1) ^ ((crc & 1) ? 0xedb88320 : 0)
    }
  }
  return (crc ^ 0xffffffff) >>> 0
}

function readPng(relativePath) {
  const absolutePath = path.join(root, relativePath)
  if (!fs.existsSync(absolutePath)) throw new Error(`${relativePath} is missing`)
  const data = fs.readFileSync(absolutePath)
  const signature = data.subarray(0, 8).toString('hex')
  if (signature !== '89504e470d0a1a0a') throw new Error(`${relativePath} is not a PNG`)

  let offset = 8
  let ihdr
  let sawEnd = false
  while (offset < data.length) {
    if (offset + 12 > data.length) throw new Error(`${relativePath} has a truncated PNG chunk`)
    const length = data.readUInt32BE(offset)
    const chunkEnd = offset + 12 + length
    if (chunkEnd > data.length) throw new Error(`${relativePath} has invalid PNG chunk length`)
    const type = data.subarray(offset + 4, offset + 8).toString('ascii')
    const payload = data.subarray(offset + 8, offset + 8 + length)
    const expectedCrc = data.readUInt32BE(offset + 8 + length)
    const actualCrc = crc32(data.subarray(offset + 4, offset + 8 + length))
    if (actualCrc !== expectedCrc) throw new Error(`${relativePath} has an invalid ${type} CRC`)
    if (type === 'IHDR') ihdr = payload
    if (type === 'IEND') {
      sawEnd = true
      if (length !== 0 || chunkEnd !== data.length) {
        throw new Error(`${relativePath} has an invalid PNG end chunk`)
      }
    }
    offset = chunkEnd
  }
  if (!ihdr || ihdr.length !== 13 || !sawEnd) {
    throw new Error(`${relativePath} is missing required PNG structure`)
  }

  return {
    width: ihdr.readUInt32BE(0),
    height: ihdr.readUInt32BE(4),
    bitDepth: ihdr[8],
    colorType: ihdr[9],
    compression: ihdr[10],
    filter: ihdr[11],
    interlace: ihdr[12],
    hash: crypto.createHash('sha256').update(data).digest('hex')
  }
}

const icons = iconPaths.map(readPng)
for (let index = 0; index < icons.length; index++) {
  const icon = icons[index]
  if (icon.width !== 1024 || icon.height !== 1024) {
    throw new Error(`${iconPaths[index]} must be 1024x1024, got ${icon.width}x${icon.height}`)
  }
  if (icon.bitDepth !== 8 || icon.colorType !== 6) {
    throw new Error(`${iconPaths[index]} must be an 8-bit RGBA PNG`)
  }
  if (icon.compression !== 0 || icon.filter !== 0 || icon.interlace !== 0) {
    throw new Error(`${iconPaths[index]} must use standard non-interlaced PNG encoding`)
  }
}

if (new Set(icons.map((icon) => icon.hash)).size !== 1) {
  throw new Error('Desktop, startup and About icons must use identical approved artwork')
}

const appConfig = fs.readFileSync(path.join(root, 'AppScope/app.json5'), 'utf8')
const moduleConfig = fs.readFileSync(path.join(root, 'entry/src/main/module.json5'), 'utf8')
if (!appConfig.includes('"icon": "$media:app_icon"')) {
  throw new Error('AppScope must reference app_icon')
}
if (!moduleConfig.includes('"icon": "$media:app_icon"') ||
    !moduleConfig.includes('"startWindowIcon": "$media:app_icon"')) {
  throw new Error('EntryAbility and start window must reference app_icon')
}

console.log('APP ICON CONTRACT PASSED')
