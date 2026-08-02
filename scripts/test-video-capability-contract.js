const fs = require('fs')
const path = require('path')

const pagePath = path.join(__dirname, '..', 'entry', 'src', 'main', 'ets', 'pages', 'VideoConvertPage.ets')
const source = fs.readFileSync(pagePath, 'utf8')
const indexPath = path.join(__dirname, '..', 'entry', 'src', 'main', 'ets', 'pages', 'Index.ets')
const indexSource = fs.readFileSync(indexPath, 'utf8')

function assert(condition, message) {
  if (!condition) {
    throw new Error(message)
  }
}

assert(
  /extension:\s*'mp3'[\s\S]*?nativeSupported:\s*false/.test(source),
  'MP3 must be marked unsupported because API 22 AVTranscoder emits AAC in an MP4 container'
)
assert(
  !source.includes('支持 MP4 输出和 MP3 音频提取'),
  'The page must not advertise MP3 extraction as supported'
)
assert(
  /const SUPPORTED:\s*string\[\]\s*=\s*\['mp4',\s*'m4a'\]/.test(source),
  'Only MP4 and M4A may enter the video conversion paths'
)
assert(
  indexSource.includes('MOV 转 MP4 / 提取 M4A') && !indexSource.includes('提取 MP3'),
  'The home page must advertise verified M4A extraction without claiming MP3 support'
)
assert(
  source.includes('视频格式或当前设备的 MP4 编码器不支持'),
  'Prepare failures must explain the input/device capability boundary'
)
assert(
  /finally\s*\{[\s\S]*?transcoder[\s\S]*?release\(\)/.test(source),
  'The transcoder must be released when prepare or start fails'
)

console.log('VIDEO CAPABILITY CONTRACT PASSED')
