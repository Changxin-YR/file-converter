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

const unit = page('UnitConverterPage.ets')
for (const component of ['AppPageHeader', 'MetricInputField', 'OptionChipGroup']) {
  assertIncludes(unit, component, `UnitConverterPage.ets must use ${component}`)
}
for (const responsiveToken of ['Grid()', 'categoryColumns', 'onAreaChange', 'UiConstants.BREAKPOINT_MEDIUM', 'UiConstants.CONTENT_MAX_WIDTH']) {
  assertIncludes(unit, responsiveToken, `UnitConverterPage.ets must retain responsive token ${responsiveToken}`)
}
for (const category of ['重量', '长度', '面积', '体积', '温度', '速度', '时间', '数据存储']) {
  assertIncludes(unit, `name: '${category}'`, `Unit converter must retain ${category}`)
}
assertIncludes(unit, 'convertTemperature', 'Unit converter must retain temperature conversion')

const imageTools = page('ImageToolsPage.ets')
for (const component of ['AppPageHeader', 'SegmentedControl', 'FilePickerPanel', 'MetricInputField', 'PrimaryActionButton', 'StatusPanel']) {
  assertIncludes(imageTools, component, `ImageToolsPage.ets must use ${component}`)
}
assertIncludes(imageTools, 'UiConstants.CONTENT_MAX_WIDTH', 'Image tools must constrain wide layouts')
for (const operation of ['doResize', 'doCrop', 'doColorPick']) {
  assertIncludes(imageTools, operation, `Image tools must retain ${operation}`)
}
assertIncludes(imageTools, 'pixelMap.crop', 'Image crop must retain real PixelMap cropping')
assertIncludes(imageTools, 'readPixelsToBuffer', 'Image color extraction must retain real pixel sampling')

console.log('TOOLS REFERENCE UI CONTRACT PASSED')
