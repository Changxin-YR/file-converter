const assert = require('assert')
const fs = require('fs')
const os = require('os')
const path = require('path')
const ts = require('C:/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/ets/build-tools/ets-loader/node_modules/typescript')

const sourcePath = path.resolve('entry/src/main/ets/common/converters/BmpEncoder.ets')
assert.ok(fs.existsSync(sourcePath), 'BmpEncoder.ets must exist')

const tempRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'bmp-encoder-test-'))
try {
  const outputPath = path.join(tempRoot, 'BmpEncoder.js')
  const output = ts.transpileModule(fs.readFileSync(sourcePath, 'utf8'), {
    compilerOptions: {
      target: ts.ScriptTarget.ES2021,
      module: ts.ModuleKind.CommonJS
    }
  }).outputText
  fs.writeFileSync(outputPath, output)

  const { BmpEncoder } = require(outputPath)
  const rgba = Uint8Array.from([255, 0, 0, 255, 0, 255, 0, 255])
  const encoded = BmpEncoder.encode(rgba.buffer, 2, 1)
  const bytes = new Uint8Array(encoded)
  const view = new DataView(encoded)

  assert.strictEqual(bytes.length, 62)
  assert.strictEqual(String.fromCharCode(bytes[0], bytes[1]), 'BM')
  assert.strictEqual(view.getUint32(2, true), 62)
  assert.strictEqual(view.getUint32(10, true), 54)
  assert.strictEqual(view.getInt32(18, true), 2)
  assert.strictEqual(view.getInt32(22, true), -1)
  assert.strictEqual(view.getUint16(28, true), 32)
  assert.deepStrictEqual(Array.from(bytes.slice(54)), [0, 0, 255, 255, 0, 255, 0, 255])

  assert.throws(() => BmpEncoder.encode(new ArrayBuffer(4), 2, 1), /buffer length/i)
  assert.throws(() => BmpEncoder.encode(new ArrayBuffer(0), 0, 1), /dimensions/i)

  console.log('BMP ENCODER TESTS PASSED')
} finally {
  fs.rmSync(tempRoot, { recursive: true, force: true })
}
