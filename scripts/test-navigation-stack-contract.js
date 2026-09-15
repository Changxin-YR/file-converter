const fs = require('fs')
const path = require('path')

const pages = [
  'AboutPage.ets',
  'ArchiveTimePage.ets',
  'DocumentConvertPage.ets',
  'ImageConvertPage.ets',
  'ImageToolsPage.ets',
  'PdfToolsPage.ets',
  'UnitConverterPage.ets',
  'VideoConvertPage.ets'
]

const pageDir = path.join(__dirname, '..', 'entry', 'src', 'main', 'ets', 'pages')
const missingStackMode = []

for (const page of pages) {
  const source = fs.readFileSync(path.join(pageDir, page), 'utf8')
  if (!/Navigation\(\)\s*\{[\s\S]*?\}\s*\.mode\(NavigationMode\.Stack\)/.test(source)) {
    missingStackMode.push(page)
  }
}

if (missingStackMode.length > 0) {
  throw new Error(
    `Standalone pages must force NavigationMode.Stack on tablet and 2in1: ${missingStackMode.join(', ')}`
  )
}

console.log('NAVIGATION STACK CONTRACT PASSED')
