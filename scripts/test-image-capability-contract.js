const fs = require('fs')
const path = require('path')

const formatsPath = path.join(__dirname, '..', 'entry', 'src', 'main', 'ets', 'common', 'FormatTypes.ets')
const formats = fs.readFileSync(formatsPath, 'utf8')
const pagePath = path.join(__dirname, '..', 'entry', 'src', 'main', 'ets', 'pages', 'ImageConvertPage.ets')
const page = fs.readFileSync(pagePath, 'utf8')
const indexPath = path.join(__dirname, '..', 'entry', 'src', 'main', 'ets', 'pages', 'Index.ets')
const index = fs.readFileSync(indexPath, 'utf8')

function assertSupport(source, extension, supported, label) {
  const pattern = new RegExp(`\\{[^\\n]*extension:\\s*'${extension}'[^\\n]*nativeSupported:\\s*false[^\\n]*\\}`)
  const isUnsupported = pattern.test(source)
  if (isUnsupported === supported) {
    throw new Error(`${extension.toUpperCase()} support mismatch in ${label}`)
  }
}

assertSupport(formats, 'bmp', true, 'shared formats')
assertSupport(page, 'bmp', true, 'page formats')
assertSupport(formats, 'heif', false, 'shared formats')
assertSupport(page, 'heif', false, 'page formats')

if (!index.includes('PNG/JPG/WEBP/BMP 格式互转') || index.includes('PNG/JPG/WEBP/BMP/HEIF 格式互转')) {
  throw new Error('The home page must only advertise verified image output formats')
}

console.log('IMAGE CAPABILITY CONTRACT PASSED')
