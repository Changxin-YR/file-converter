const fs = require('fs')
const path = require('path')

const selectorPath = path.join(
  __dirname,
  '..',
  'entry',
  'src',
  'main',
  'ets',
  'components',
  'FormatSelector.ets'
)
const source = fs.readFileSync(selectorPath, 'utf8')

function assert(condition, message) {
  if (!condition) {
    throw new Error(message)
  }
}

assert(
  /if\s*\(\s*!format\.nativeSupported\s*\)\s*\{[\s\S]*?Text\('功能正在开发'\)/.test(source),
  'Unsupported format chips must visibly render 功能正在开发'
)
assert(
  /\.opacity\(this\.isEnabled\(format\)\s*\?\s*1\s*:\s*0\.4\)/.test(source),
  'Unsupported format chips must retain their disabled visual state'
)
assert(
  /if\s*\(\s*!this\.isEnabled\(format\)\s*\)\s*\{\s*return\s*\}/.test(source),
  'Unsupported format chips must not invoke the selection callback'
)

console.log('DISABLED FORMAT STATUS CONTRACT PASSED')
