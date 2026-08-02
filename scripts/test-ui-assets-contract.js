const fs = require('fs')
const path = require('path')

const root = path.resolve(__dirname, '..')
const mediaDir = path.join(root, 'entry/src/main/resources/base/media')
const requiredAssets = [
  'ui_hero_home.png', 'ui_picker_image.png', 'ui_picker_document.png',
  'ui_hero_pdf.png', 'ui_globe.png', 'ui_tool_image.png',
  'ui_tool_document.png', 'ui_tool_video.png', 'ui_tool_audio.png',
  'ui_tool_image_edit.png', 'ui_tool_archive.png', 'ui_tool_unit.png',
  'ui_tool_pdf.png', 'ui_pdf_image.png', 'ui_pdf_text.png',
  'ui_pdf_html.png', 'ui_pdf_word.png', 'ui_pdf_markdown.png'
]

function readPngDimensions(filePath) {
  const bytes = fs.readFileSync(filePath)
  const signature = bytes.subarray(0, 8).toString('hex')
  if (signature !== '89504e470d0a1a0a' || bytes.subarray(12, 16).toString('ascii') !== 'IHDR') {
    throw new Error(`${path.basename(filePath)} is not a valid PNG`)
  }
  return {
    width: bytes.readUInt32BE(16),
    height: bytes.readUInt32BE(20),
    size: bytes.length
  }
}

const failures = []
for (const asset of requiredAssets) {
  const filePath = path.join(mediaDir, asset)
  if (!fs.existsSync(filePath)) {
    failures.push(`${asset}: missing`)
    continue
  }
  try {
    const { width, height, size } = readPngDimensions(filePath)
    if (width < 192 || height < 192) failures.push(`${asset}: ${width}x${height} is below 192x192`)
    if (size <= 2048) failures.push(`${asset}: ${size} bytes is not larger than 2 KB`)
  } catch (error) {
    failures.push(error.message)
  }
}

const appIconPath = path.join(mediaDir, 'app_icon.png')
try {
  const { width, height } = readPngDimensions(appIconPath)
  if (width < 512 || height < 512) failures.push(`app_icon.png: ${width}x${height} is below 512x512`)
} catch (error) {
  failures.push(error.message)
}

if (failures.length > 0) {
  throw new Error(`UI asset contract failed:\n${failures.join('\n')}`)
}

console.log('UI ASSET CONTRACT PASSED')
