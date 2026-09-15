const assert = require('assert')
const fs = require('fs')
const path = require('path')

const root = path.join(__dirname, '..')
const videoSource = fs.readFileSync(
  path.join(root, 'entry', 'src', 'main', 'ets', 'pages', 'VideoConvertPage.ets'), 'utf8'
)
const archiveSource = fs.readFileSync(
  path.join(root, 'entry', 'src', 'main', 'ets', 'pages', 'ArchiveTimePage.ets'), 'utf8'
)

assert(
  videoSource.includes('private supportsSelectedM4aInput(): boolean'),
  'Video page must model the MP4-only M4A extraction input boundary'
)
assert(
  /isEnabled:\s*!this\.converting\s*&&\s*this\.selectedFiles\.length\s*>\s*0\s*&&\s*this\.supportsSelectedM4aInput\(\)/.test(videoSource),
  'M4A extraction must not be actionable for non-MP4 selections'
)
assert(
  videoSource.includes('M4A 提取仅支持 MP4 输入，请重新选择 MP4 文件'),
  'Video page must explain why M4A extraction is unavailable for the selected files'
)
assert(
  archiveSource.includes('FileUtils.makeUniqueFileName(fileName, stagedNames)'),
  'ZIP staging must disambiguate same-named source files before copying'
)

console.log('THIRD-ROUND VIDEO AND ARCHIVE CONTRACT PASSED')
