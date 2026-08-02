const fs = require('fs')
const path = require('path')

const pagesDir = path.join(__dirname, '..', 'entry', 'src', 'main', 'ets', 'pages')

function page(name) {
  return fs.readFileSync(path.join(pagesDir, name), 'utf8')
}

function assertIncludes(source, expected, message) {
  if (!source.includes(expected)) {
    throw new Error(message)
  }
}

const pdf = page('PdfToolsPage.ets')
for (const component of ['AppPageHeader', 'ToolListItem', 'FilePickerPanel', 'PrimaryActionButton', 'StatusPanel']) {
  assertIncludes(pdf, component, `PdfToolsPage.ets must use ${component}`)
}
assertIncludes(pdf, "app.media.ui_hero_pdf", 'PDF tools must use the approved PDF hero')
assertIncludes(pdf, 'UiConstants.CONTENT_MAX_WIDTH', 'PDF tools must constrain wide layouts')
for (const workflow of ['jpg2pdf', 'word2pdf', 'html2pdf', 'pdf2word', 'pdf2md']) {
  assertIncludes(pdf, workflow, `PDF tools must retain ${workflow}`)
}

const archive = page('ArchiveTimePage.ets')
for (const component of ['AppPageHeader', 'SegmentedControl', 'FilePickerPanel', 'PrimaryActionButton', 'StatusPanel']) {
  assertIncludes(archive, component, `ArchiveTimePage.ets must use ${component}`)
}
assertIncludes(archive, "app.media.ui_globe", 'Timezone tools must use the approved globe artwork')
assertIncludes(archive, 'UiConstants.CONTENT_MAX_WIDTH', 'Archive/time tools must constrain wide layouts')
assertIncludes(archive, "key: 'zip', label: 'ZIP', enabled: true", 'ZIP must remain enabled')
for (const key of ['7z', 'tar.gz', 'rar']) {
  const pattern = new RegExp(`key:\\s*'${key.replace('.', '\\.')}'[\\s\\S]*?enabled:\\s*false`)
  if (!pattern.test(archive)) {
    throw new Error(`${key.toUpperCase()} must remain disabled and developing`)
  }
}
assertIncludes(archive, 'minute < 0 || minute > 59', 'Timezone conversion must retain minute validation')
assertIncludes(archive, 'saveExtractedFiles', 'ZIP extraction must retain recursive saving')

console.log('TOOLS REFERENCE UI CONTRACT PASSED')
