const assert = require('assert')
const fs = require('fs')
const os = require('os')
const path = require('path')
const ts = require('C:/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/ets/build-tools/ets-loader/node_modules/typescript')

const sourcePath = path.resolve('entry/src/main/ets/common/converters/PdfTextExtractor.ets')
assert.ok(fs.existsSync(sourcePath), 'PdfTextExtractor.ets must exist')

const tempRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'pdf-text-extractor-test-'))
try {
  const outputPath = path.join(tempRoot, 'PdfTextExtractor.js')
  const output = ts.transpileModule(fs.readFileSync(sourcePath, 'utf8'), {
    compilerOptions: {
      target: ts.ScriptTarget.ES2021,
      module: ts.ModuleKind.CommonJS
    }
  }).outputText
  fs.writeFileSync(outputPath, output)

  const { PdfTextExtractor } = require(outputPath)
  const asciiPdf = `%PDF-1.4
1 0 obj << /Length 80 >> stream
BT
(Hello \\(PDF\\) \\\\ path\\nnext) Tj T*
ET
endstream
endobj
%%EOF`
  const ascii = PdfTextExtractor.extract(asciiPdf)
  assert.strictEqual(ascii.success, true)
  assert.strictEqual(ascii.text, 'Hello (PDF) \\ path\nnext')

  const unicodePdf = `%PDF-1.4
1 0 obj << /Length 60 >> stream
BT
<FEFF4F60597D> Tj T*
ET
endstream
endobj
%%EOF`
  const unicode = PdfTextExtractor.extract(unicodePdf)
  assert.strictEqual(unicode.success, true)
  assert.strictEqual(unicode.text, '你好')

  const pagesPdf = `%PDF-1.4
1 0 obj << /Length 20 >> stream
BT (first) Tj ET
endstream endobj
2 0 obj << /Length 20 >> stream
BT (second) Tj ET
endstream endobj
%%EOF`
  assert.strictEqual(PdfTextExtractor.extract(pagesPdf).text, 'first\nsecond')

  const compressed = PdfTextExtractor.extract('%PDF-1.4\n<< /Filter /FlateDecode >>\nstream\nx\nendstream')
  assert.strictEqual(compressed.success, false)
  assert.match(compressed.errorMsg, /未压缩文本 PDF/)

  assert.strictEqual(PdfTextExtractor.extract('%PDF-1.4\n/Encrypt 4 0 R').success, false)
  assert.strictEqual(PdfTextExtractor.extract('%PDF-1.5\n/ObjStm').success, false)
  const empty = PdfTextExtractor.extract('%PDF-1.4\nBT ET\n%%EOF')
  assert.strictEqual(empty.success, false)
  assert.ok(!empty.text.includes('无法提取'))

  console.log('PDF TEXT EXTRACTOR TESTS PASSED')
} finally {
  fs.rmSync(tempRoot, { recursive: true, force: true })
}
