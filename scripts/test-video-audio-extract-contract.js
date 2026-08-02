const fs = require('fs')
const path = require('path')

const root = path.join(__dirname, '..')
const nativeSource = fs.readFileSync(path.join(root, 'entry', 'src', 'main', 'cpp', 'native_audio.cpp'), 'utf8')
const cmake = fs.readFileSync(path.join(root, 'entry', 'src', 'main', 'cpp', 'CMakeLists.txt'), 'utf8')
const declarations = fs.readFileSync(
  path.join(root, 'entry', 'src', 'main', 'cpp', 'types', 'libnative_audio', 'index.d.ts'),
  'utf8'
)
const page = fs.readFileSync(path.join(root, 'entry', 'src', 'main', 'ets', 'pages', 'VideoConvertPage.ets'), 'utf8')

function assert(condition, message) {
  if (!condition) {
    throw new Error(message)
  }
}

assert(
  nativeSource.includes('extractMp4AudioToM4a'),
  'Native module must export extractMp4AudioToM4a'
)
assert(
  declarations.includes('extractMp4AudioToM4a') && declarations.includes('sourceSize: number'),
  'Native type declarations must expose sourceFd, sourceSize and targetFd'
)
assert(
  cmake.includes('libnative_media_avsource.so') && cmake.includes('libnative_media_avdemuxer.so'),
  'Native library must link AVSource and AVDemuxer'
)
assert(
  /extension:\s*'m4a'[\s\S]*?nativeSupported:\s*true/.test(page),
  'M4A audio extraction must be available on the video page'
)
assert(
  /extension:\s*'mp3'[\s\S]*?nativeSupported:\s*false/.test(page),
  'MP3 must remain unavailable'
)
assert(
  /const SUPPORTED:\s*string\[\]\s*=\s*\['mp4',\s*'m4a'\]/.test(page),
  'Only MP4 and M4A may enter video conversion execution paths'
)
assert(
  page.includes('VideoAudioExtractService') && page.includes("this.targetFormat === 'm4a'"),
  'The M4A branch must call the dedicated extraction service'
)

console.log('VIDEO AUDIO EXTRACT CONTRACT PASSED')
