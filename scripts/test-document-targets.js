const assert = require('assert')
const fs = require('fs')
const os = require('os')
const path = require('path')
const ts = require('C:/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/ets/build-tools/ets-loader/node_modules/typescript')

const sourceRoot = path.resolve('entry/src/main/ets/common')
const tempRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'format-converter-test-'))

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

  const csvTargets = DocumentTargetResolver.resolve(['csv']).map((format) => format.extension)
  assert.deepStrictEqual(csvTargets, ['pdf', 'doc', 'json', 'xml', 'md', 'html', 'txt'])

  const mixedTargets = DocumentTargetResolver.resolve(['csv', 'json']).map((format) => format.extension)
  assert.deepStrictEqual(mixedTargets, ['pdf', 'doc', 'xml', 'md', 'html', 'txt'])

  const markdownTargets = DocumentTargetResolver.resolve(['md']).map((format) => format.extension)
  assert.deepStrictEqual(markdownTargets, ['pdf', 'doc', 'html', 'txt'])

  const textHtml = DocumentMatrix.convert('txt', 'html', 'line one\n<tag> & line two')
  assert.strictEqual(textHtml.success, true)
  assert.strictEqual(textHtml.text, '<p>line one<br/>&lt;tag&gt; &amp; line two</p>')

  console.log('DOCUMENT TARGET TESTS PASSED')
} finally {
  fs.rmSync(tempRoot, { recursive: true, force: true })
}
