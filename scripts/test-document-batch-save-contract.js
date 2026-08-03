const assert = require('assert')
const fs = require('fs')

const page = fs.readFileSync('entry/src/main/ets/pages/DocumentConvertPage.ets', 'utf8')
const service = fs.readFileSync('entry/src/main/ets/services/SaveService.ets', 'utf8')

assert.match(
  service,
  /async getSavePaths\(defaultFileNames: string\[\]\): Promise<string\[\]>/,
  'SaveService must expose one batch save operation'
)
assert.match(
  service,
  /options\.newFileNames = defaultFileNames/,
  'batch save must submit every default file name in one picker request'
)
assert.match(
  service,
  /result\.length !== defaultFileNames\.length/,
  'batch save must reject an ambiguous target URI mapping'
)
assert.match(service, /用户取消保存或保存选择器失败/, 'picker rejection must preserve cancellation/failure semantics')
assert.match(page, /批量保存未完成/, 'the page must report a whole-batch save cancellation separately')
assert.doesNotMatch(
  page,
  /saveService\.getSavePath\(/,
  'document conversion must not open one save dialog per file'
)
assert.strictEqual(
  (page.match(/saveService\.getSavePaths\(/g) || []).length,
  1,
  'document conversion must open exactly one batch save dialog'
)
assert.match(page, /context\.cacheDir/, 'document conversion must stage results in the sandbox cache')
assert.match(page, /sourceIndex: number/, 'staged outputs must retain their original source index')
assert.match(page, /FileUtils\.copyFile\(output\.tempPath, targetUris\[i\]\)/, 'staged results must map to picker URIs by index')
assert.match(page, /fs\.unlinkSync\(targetUris\[i\]\)/, 'failed copies must remove the newly created empty or partial target')
assert.match(page, /output\.sourceIndex \+ 1/, 'save failures must report the original source position')
assert.match(page, /finally\s*\{[\s\S]*?fs\.unlinkSync\(output\.tempPath\)/, 'staged results must always be cleaned')

console.log('DOCUMENT BATCH SAVE CONTRACT PASSED')
