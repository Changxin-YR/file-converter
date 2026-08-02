const fs = require('fs')
const path = require('path')

const pagesDir = path.join(__dirname, '..', 'entry', 'src', 'main', 'ets', 'pages')

function page(name) {
  return fs.readFileSync(path.join(pagesDir, name), 'utf8')
}

function assertIncludes(source, value, message) {
  if (!source.includes(value)) throw new Error(message)
}

for (const fileName of ['ImageConvertPage.ets', 'DocumentConvertPage.ets']) {
  const source = page(fileName)
  for (const component of ['AppPageHeader', 'FilePickerPanel', 'FormatSelector', 'PrimaryActionButton', 'StatusPanel']) {
    assertIncludes(source, component, `${fileName} must use ${component}`)
  }
  assertIncludes(source, 'NavigationMode.Stack', `${fileName} must retain stack navigation`)
  assertIncludes(source, 'UiConstants.CONTENT_MAX_WIDTH', `${fileName} must constrain wide layouts`)
}

const image = page('ImageConvertPage.ets')
for (const behavior of ['quality', 'Slider', 'saveToAlbum', 'width', 'height']) {
  assertIncludes(image, behavior, `Image conversion must retain ${behavior}`)
}

const documentPage = page('DocumentConvertPage.ets')
for (const behavior of ['getTargetFormats', 'utf-8', 'gbk', 'utf-16le', 'sourceEncoding', 'SaveService']) {
  assertIncludes(documentPage, behavior, `Document conversion must retain ${behavior}`)
}

console.log('CONVERSION REFERENCE UI CONTRACT PASSED')
