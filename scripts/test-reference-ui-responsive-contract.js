const fs = require('fs')
const path = require('path')

const pagesDir = path.join(__dirname, '..', 'entry', 'src', 'main', 'ets', 'pages')
const independentPages = [
  'ImageConvertPage.ets', 'DocumentConvertPage.ets',
  'VideoConvertPage.ets', 'ImageToolsPage.ets', 'ArchiveTimePage.ets',
  'UnitConverterPage.ets', 'PdfToolsPage.ets', 'AboutPage.ets'
]

function read(name) {
  return fs.readFileSync(path.join(pagesDir, name), 'utf8')
}

function requireText(source, expected, message) {
  if (!source.includes(expected)) throw new Error(message)
}

for (const fileName of independentPages) {
  const source = read(fileName)
  requireText(source, 'NavigationMode.Stack', `${fileName} must use stack navigation`)
  requireText(source, 'UiConstants.CONTENT_MAX_WIDTH', `${fileName} must constrain wide layouts`)
  requireText(source, "app.color.page_background", `${fileName} must use the shared page background`)
  if (/#[0-9A-Fa-f]{3,8}/.test(source)) {
    throw new Error(`${fileName} must not hard-code hexadecimal colors`)
  }
  if (/[🌀-🫿]/u.test(source)) {
    throw new Error(`${fileName} must not use emoji presentation icons`)
  }
}

const index = read('Index.ets')
for (const responsiveToken of ['gridColumns', 'onAreaChange', 'UiConstants.CONTENT_MAX_WIDTH', 'app.color.page_background']) {
  requireText(index, responsiveToken, `Index.ets must retain ${responsiveToken}`)
}

const allPages = independentPages.concat(['Index.ets']).map(read).join('\n')
for (const placeholder of ['support@maxtools.com', 'maxtools.com/privacy']) {
  if (allPages.includes(placeholder)) {
    throw new Error(`Placeholder contact data must be removed: ${placeholder}`)
  }
}

console.log('REFERENCE UI RESPONSIVE CONTRACT PASSED')
