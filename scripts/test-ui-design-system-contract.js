const fs = require('fs')
const path = require('path')

const root = path.resolve(__dirname, '..')
const colorPath = path.join(root, 'entry/src/main/resources/base/element/color.json')
const constantsPath = path.join(root, 'entry/src/main/ets/common/UiConstants.ets')

const requiredColors = [
  'page_background', 'surface_primary', 'surface_secondary',
  'brand_primary', 'brand_strong', 'text_primary', 'text_secondary',
  'text_tertiary', 'text_disabled', 'border_subtle',
  'control_selected', 'control_disabled', 'success', 'error'
]

const requiredConstants = [
  'PAGE_PADDING_PHONE', 'PAGE_PADDING_LARGE', 'CONTENT_MAX_WIDTH',
  'CARD_RADIUS', 'CONTROL_RADIUS', 'ACTION_HEIGHT', 'TOUCH_MIN_HEIGHT',
  'BREAKPOINT_MEDIUM', 'BREAKPOINT_LARGE'
]

const colors = JSON.parse(fs.readFileSync(colorPath, 'utf8')).color
const colorNames = new Set(colors.map((entry) => entry.name))
const missingColors = requiredColors.filter((name) => !colorNames.has(name))

let constantsSource = ''
if (fs.existsSync(constantsPath)) {
  constantsSource = fs.readFileSync(constantsPath, 'utf8')
}
const missingConstants = requiredConstants.filter((name) => {
  return !new RegExp(`static\\s+readonly\\s+${name}\\s*:`).test(constantsSource)
})

if (missingColors.length > 0) {
  throw new Error(`Missing UI color resources: ${missingColors.join(', ')}`)
}
if (missingConstants.length > 0) {
  throw new Error(`Missing UiConstants: ${missingConstants.join(', ')}`)
}

console.log('UI DESIGN SYSTEM CONTRACT PASSED')
