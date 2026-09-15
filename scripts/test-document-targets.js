const assert = require('assert')
const fs = require('fs')
const Module = require('module')
const os = require('os')
const path = require('path')
const ts = require('C:/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/ets/build-tools/ets-loader/node_modules/typescript')

const sourceRoot = path.resolve('entry/src/main/ets/common')
const tempRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'format-converter-test-'))
const originalLoad = Module._load

Module._load = function(request, parent, isMain) {
  if (request === '@kit.CoreFileKit') {
    return { fileIo: {} }
  }
  return originalLoad.call(this, request, parent, isMain)
}

function copyAsJavaScript(directory) {
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const sourcePath = path.join(directory, entry.name)
    const relativePath = path.relative(sourceRoot, sourcePath)
    if (entry.isDirectory()) {
      fs.mkdirSync(path.join(tempRoot, relativePath), { recursive: true })
      copyAsJavaScript(sourcePath)
      continue
    }
    if (!entry.name.endsWith('.ets')) {
      continue
    }
    const outputPath = path.join(tempRoot, relativePath.replace(/\.ets$/, '.js'))
    fs.mkdirSync(path.dirname(outputPath), { recursive: true })
    const source = fs.readFileSync(sourcePath, 'utf8')
    const output = ts.transpileModule(source, {
      compilerOptions: {
        target: ts.ScriptTarget.ES2021,
        module: ts.ModuleKind.CommonJS
      }
    }).outputText
    fs.writeFileSync(outputPath, output)
  }
}

try {
  copyAsJavaScript(sourceRoot)
  const { DocumentTargetResolver } = require(path.join(tempRoot, 'converters', 'DocumentTargetResolver.js'))
  const { DocumentMatrix } = require(path.join(tempRoot, 'converters', 'DocumentMatrix.js'))
  const { CsvConverter } = require(path.join(tempRoot, 'converters', 'CsvConverter.js'))
  const { FileUtils } = require(path.join(tempRoot, 'Utils.js'))

  const csvTargets = DocumentTargetResolver.resolve(['csv']).map((format) => format.extension)
  assert.deepStrictEqual(csvTargets, ['pdf', 'doc', 'json', 'xml', 'md', 'html', 'txt'])

  const mixedTargets = DocumentTargetResolver.resolve(['csv', 'json']).map((format) => format.extension)
  assert.deepStrictEqual(mixedTargets, ['pdf', 'doc', 'xml', 'md', 'html', 'txt'])

  const markdownTargets = DocumentTargetResolver.resolve(['md']).map((format) => format.extension)
  assert.deepStrictEqual(markdownTargets, ['pdf', 'doc', 'html', 'txt'])

  const textHtml = DocumentMatrix.convert('txt', 'html', 'line one\n<tag> & line two')
  assert.strictEqual(textHtml.success, true)
  assert.strictEqual(textHtml.text, '<p>line one<br/>&lt;tag&gt; &amp; line two</p>')

  const singleCrCsv = CsvConverter.parse('name,score\rAlice,10\rBob,20')
  assert.deepStrictEqual(singleCrCsv.headers, ['name', 'score'])
  assert.deepStrictEqual(singleCrCsv.rows, [['Alice', '10'], ['Bob', '20']])

  const singleQuotedLink = DocumentMatrix.convert('html', 'md', "<p><a href='https://example.test/path'>示例链接</a></p>")
  assert.strictEqual(singleQuotedLink.success, true)
  assert.strictEqual(singleQuotedLink.text, '[示例链接](https://example.test/path)')

  const stagedNames = []
  assert.strictEqual(FileUtils.makeUniqueFileName('report.txt', stagedNames), 'report.txt')
  assert.strictEqual(FileUtils.makeUniqueFileName('report.txt', stagedNames), 'report (2).txt')
  assert.strictEqual(FileUtils.makeUniqueFileName('report', stagedNames), 'report')
  assert.strictEqual(FileUtils.makeUniqueFileName('report', stagedNames), 'report (2)')

  console.log('DOCUMENT TARGET TESTS PASSED')
} finally {
  Module._load = originalLoad
  fs.rmSync(tempRoot, { recursive: true, force: true })
}
