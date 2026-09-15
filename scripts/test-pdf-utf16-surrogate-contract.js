const assert = require('assert')
const fs = require('fs')
const os = require('os')
const path = require('path')
const ts = require('C:/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/ets/build-tools/ets-loader/node_modules/typescript')

const sourcePath = path.join(__dirname, '..', 'entry', 'src', 'main', 'ets', 'common', 'converters', 'PdfGenerator.ets')
const tempRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'pdf-utf16-contract-'))

try {
  const source = fs.readFileSync(sourcePath, 'utf8')
  const compiled = ts.transpileModule(source, {
    compilerOptions: { target: ts.ScriptTarget.ES2021, module: ts.ModuleKind.CommonJS }
  }).outputText
  const modulePath = path.join(tempRoot, 'PdfGenerator.js')
  fs.writeFileSync(modulePath, compiled)
  const { PdfGenerator } = require(modulePath)
  const bytes = new Uint8Array(PdfGenerator.generate('Emoji 😀'))
  let pdf = ''
  for (const byte of bytes) {
    pdf += String.fromCharCode(byte)
  }

  assert(
    pdf.includes('<FEFF0045006D006F006A00690020D83DDE00>'),
    'PDF UTF-16BE output must preserve an astral Unicode character as its two UTF-16 surrogate code units'
  )

  console.log('PDF UTF-16 SURROGATE CONTRACT PASSED')
} finally {
  fs.rmSync(tempRoot, { recursive: true, force: true })
}
