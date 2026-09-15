const fs = require('fs')
const path = require('path')

const formatsPath = path.join(__dirname, '..', 'entry', 'src', 'main', 'ets', 'common', 'FormatTypes.ets')
const formats = fs.readFileSync(formatsPath, 'utf8')
const pagePath = path.join(__dirname, '..', 'entry', 'src', 'main', 'ets', 'pages', 'ImageConvertPage.ets')
const page = fs.readFileSync(pagePath, 'utf8')
const indexPath = path.join(__dirname, '..', 'entry', 'src', 'main', 'ets', 'pages', 'Index.ets')
const index = fs.readFileSync(indexPath, 'utf8')

function assertAbsent(source, extension, label) {
  if (new RegExp(`extension:\\s*'${extension}'`).test(source)) {
    throw new Error(`${extension.toUpperCase()} must be absent from ${label}`)
  }
}

for (const verified of ['png', 'jpg', 'webp', 'bmp']) {
  if (!new RegExp(`extension:\\s*'${verified}'[\\s\\S]*?nativeSupported:\\s*true`).test(formats)) {
    throw new Error(`${verified.toUpperCase()} must remain in shared image formats`)
  }
}
for (const removed of ['heif', 'gif']) {
  assertAbsent(formats, removed, 'shared formats')
  assertAbsent(page, removed, 'image page formats')
}

if (!index.includes('PNG/JPG/WEBP/BMP 格式互转') || index.includes('HEIF') || index.includes('GIF')) {
  throw new Error('The home page must only advertise verified image output formats')
}
if (/const NATIVE_FORMATS:[\s\S]*?'heif'/.test(page)) {
  throw new Error('Image conversion execution allowlist must not contain HEIF')
}

console.log('IMAGE CAPABILITY CONTRACT PASSED')
