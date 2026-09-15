const fs = require('fs')
const path = require('path')

const pagesDir = path.join(__dirname, '..', 'entry', 'src', 'main', 'ets', 'pages')
const commonDir = path.join(__dirname, '..', 'entry', 'src', 'main', 'ets', 'common')

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

for (const fileName of ['VideoConvertPage.ets']) {
  const source = page(fileName)
  for (const component of ['AppPageHeader', 'FilePickerPanel', 'FormatSelector', 'PrimaryActionButton', 'StatusPanel']) {
    assertIncludes(source, component, `${fileName} must use ${component}`)
  }
  assertIncludes(source, 'NavigationMode.Stack', `${fileName} must retain stack navigation`)
  assertIncludes(source, 'UiConstants.CONTENT_MAX_WIDTH', `${fileName} must constrain wide layouts`)
}

if (fs.existsSync(path.join(pagesDir, 'AudioConvertPage.ets'))) {
  throw new Error('Audio conversion page must be removed from the release')
}
const formatTypes = fs.readFileSync(path.join(commonDir, 'FormatTypes.ets'), 'utf8')
if (formatTypes.includes('AUDIO_FORMATS')) {
  throw new Error('Audio capability matrix must be removed with the audio feature')
}

const video = page('VideoConvertPage.ets')
assertIncludes(video, "const SUPPORTED: string[] = ['mp4', 'm4a']", 'Video conversion must preserve the MP4/M4A execution allowlist')
if (video.includes("extension: 'mp3'")) {
  throw new Error('Video conversion must not retain MP3 as a developing item')
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
