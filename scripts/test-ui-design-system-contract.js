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

const componentContracts = {
  'AppPageHeader.ets': ['title'],
  'PrimaryActionButton.ets': ['label', 'enabled', 'loading', 'onTap'],
  'FilePickerPanel.ets': ['title', 'description', 'asset', 'buttonLabel', 'enabled', 'onPick'],
  'SegmentedControl.ets': ['SegmentItem', 'items', 'selectedKey', 'onSelect'],
  'OptionChipGroup.ets': ['ChipItem', 'items', 'selectedKey', 'onSelect'],
  'ToolListItem.ets': ['ToolListData', 'data', 'onTap'],
  'MetricInputField.ets': ['label', 'value', 'onChange'],
  'StatusPanel.ets': ['message'],
  'FunctionTile.ets': ['title', 'description', 'asset', 'enabled', 'onTap']
}
const componentsDir = path.join(root, 'entry/src/main/ets/components')
const componentFailures = []
for (const [fileName, tokens] of Object.entries(componentContracts)) {
  const filePath = path.join(componentsDir, fileName)
  if (!fs.existsSync(filePath)) {
    componentFailures.push(`${fileName}: missing`)
    continue
  }
  const source = fs.readFileSync(filePath, 'utf8')
  if (!source.includes("../common/UiConstants")) {
    componentFailures.push(`${fileName}: does not import UiConstants`)
  }
  if (/#[0-9A-Fa-f]{3,8}\b/.test(source)) {
    componentFailures.push(`${fileName}: contains a raw hex color`)
  }
  for (const token of tokens) {
    if (!source.includes(token)) componentFailures.push(`${fileName}: missing API token ${token}`)
  }
}

if (missingColors.length > 0) {
  throw new Error(`Missing UI color resources: ${missingColors.join(', ')}`)
}
if (missingConstants.length > 0) {
  throw new Error(`Missing UiConstants: ${missingConstants.join(', ')}`)
}
if (componentFailures.length > 0) {
  throw new Error(`UI component contract failed:\n${componentFailures.join('\n')}`)
}

console.log('UI DESIGN SYSTEM CONTRACT PASSED')
