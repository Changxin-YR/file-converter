const assert = require('assert')
const fs = require('fs')

const source = fs.readFileSync('entry/src/main/ets/pages/DocumentConvertPage.ets', 'utf8')
const engine = fs.readFileSync('entry/src/main/ets/engines/NativeTextEngine.ets', 'utf8')
const pdfTools = fs.readFileSync('entry/src/main/ets/pages/PdfToolsPage.ets', 'utf8')

assert.match(source, /statSync\(file\.fd\)/, 'document reader must stat the opened file descriptor')
assert.match(source, /const bytesRead[^\n]*readSync/, 'document reader must retain the actual byte count')
assert.match(source, /buffer\.slice\(0, bytesRead\)/, 'document reader must decode only bytes that were read')
assert.doesNotMatch(engine, /statSync\(task\.sourcePath\)/, 'text engine must stat the opened file descriptor')
assert.match(engine, /buffer\.slice\(0, bytesRead\)/, 'text engine must decode only bytes that were read')
assert.doesNotMatch(pdfTools, /statSync\(uri\)/, 'PDF tools must stat opened file descriptors')
assert.ok((pdfTools.match(/buffer\.slice\(0, bytesRead\)/g) || []).length >= 3, 'PDF tools must decode actual bytes in all three text paths')

console.log('DOCUMENT READ CONTRACT PASSED')
