const fs = require('fs')
const path = require('path')

const componentsDir = path.join(__dirname, '..', 'entry', 'src', 'main', 'ets', 'components')
const selectorSource = fs.readFileSync(path.join(componentsDir, 'FormatSelector.ets'), 'utf8')
const chipSource = fs.readFileSync(path.join(componentsDir, 'OptionChipGroup.ets'), 'utf8')

function assert(condition, message) {
  if (!condition) throw new Error(message)
}

assert(
  /developing:\s*!format\.nativeSupported/.test(selectorSource) &&
    chipSource.includes("Text('功能正在开发')"),
  'Unsupported format chips must visibly render 功能正在开发'
)
assert(
  /enabled:\s*!this\.disabled\s*&&\s*format\.nativeSupported/.test(selectorSource) &&
    chipSource.includes("$r('app.color.control_disabled')"),
  'Unsupported format chips must retain their disabled visual state'
)
assert(
  /if\s*\(\s*!this\.isEnabled\(item\)\s*\)\s*\{\s*return\s*\}/.test(chipSource),
  'Unsupported format chips must not invoke the selection callback'
)

console.log('DISABLED FORMAT STATUS CONTRACT PASSED')
