const assert = require('assert')
const fs = require('fs')
const path = require('path')

const root = path.join(__dirname, '..')
const imageFiles = [
  'entry/src/main/ets/components/FilePickerPanel.ets',
  'entry/src/main/ets/components/FunctionTile.ets',
  'entry/src/main/ets/components/ToolListItem.ets',
  'entry/src/main/ets/components/PrivacyNoticeSection.ets',
  'entry/src/main/ets/pages/Index.ets',
  'entry/src/main/ets/pages/AboutPage.ets',
  'entry/src/main/ets/pages/ArchiveTimePage.ets',
  'entry/src/main/ets/pages/PdfToolsPage.ets'
]

for (const relativePath of imageFiles) {
  const absolutePath = path.join(root, relativePath)
  assert(fs.existsSync(absolutePath), `${relativePath} must exist`)
  const source = fs.readFileSync(absolutePath, 'utf8')
  assert(source.includes('.accessibilityText('), `${relativePath} must label its image content for screen readers`)
}

const headerSource = fs.readFileSync(
  path.join(root, 'entry', 'src', 'main', 'ets', 'components', 'AppPageHeader.ets'), 'utf8'
)
assert(headerSource.includes(".accessibilityText('返回')"), 'The icon-only back button must announce 返回')

console.log('THIRD-ROUND ACCESSIBILITY CONTRACT PASSED')
