const assert = require('assert')
const fs = require('fs')

const source = fs.readFileSync('entry/src/main/ets/pages/AudioConvertPage.ets', 'utf8')
const skipBranch = source.match(/if \(srcExt === this\.targetFormat\) \{[\s\S]*?\n      \}/)?.[0] ?? ''

assert.match(source, /let skippedCount = 0/, 'audio conversion must track same-format inputs')
assert.match(source, /let failedCount = 0/, 'audio conversion must track failed inputs')
assert.match(skipBranch, /skippedCount\+\+/, 'same-format inputs must increment the skip count')
assert.match(
  skipBranch,
  /this\.progress = Math\.round\(\(i \+ 1\) \/ total \* 100\)/,
  'same-format inputs must advance overall progress before continuing'
)
assert.match(
  source,
  /skippedCount > 0[\s\S]*?跳过.*同格式文件/,
  'completion feedback must report skipped same-format files'
)
assert.match(
  source,
  /failedCount > 0[\s\S]*?失败/,
  'mixed audio batches must report failures instead of overwriting them with a success summary'
)

console.log('AUDIO SKIP PROGRESS CONTRACT PASSED')
