const assert = require('assert')
const fs = require('fs')
const path = require('path')

const root = path.join(__dirname, '..')
const componentsDir = path.join(root, 'entry', 'src', 'main', 'ets', 'components')
const optionSource = fs.readFileSync(path.join(componentsDir, 'OptionChipGroup.ets'), 'utf8')
const selectorSource = fs.readFileSync(path.join(componentsDir, 'FormatSelector.ets'), 'utf8')
const pickerSource = fs.readFileSync(path.join(componentsDir, 'FilePickerPanel.ets'), 'utf8')
const resultListSource = fs.readFileSync(path.join(componentsDir, 'ConvertResultList.ets'), 'utf8')

assert(
  /enabled:\s*format\.nativeSupported/.test(selectorSource),
  'FormatSelector must keep capability separate from the parent temporary disabled state'
)
assert(
  optionSource.includes('private isSelectedAndEnabled(item: ChipItem): boolean'),
  'OptionChipGroup must expose one state predicate for an interactable selected option'
)
assert(
  pickerSource.includes('.constraintSize({ minHeight: 156 })') && !pickerSource.includes('.height(156)'),
  'FilePickerPanel must retain its 156vp baseline while allowing enlarged text to increase its height'
)
assert(
  resultListSource.includes('(path: string, index: number) => `${index}_${path}`'),
  'ConvertResultList keys must remain unique when two displayed paths are identical'
)
assert(
  optionSource.includes('this.isSelectedAndEnabled(item) ? $r(\'app.color.brand_primary\')'),
  'Only an enabled option may render the selected brand treatment'
)

const privacyPath = path.join(componentsDir, 'PrivacyNoticeSection.ets')
assert(fs.existsSync(privacyPath), 'Privacy notice must be implemented by one shared component')
const privacySource = fs.readFileSync(privacyPath, 'utf8')
for (const label of ['文件只在设备本地处理', '不联网、无后端、不上传', '不收集、不存储用户文件', '仅在使用时访问所选文件']) {
  assert(privacySource.includes(label), `Shared privacy component must retain: ${label}`)
}

for (const pageName of ['Index.ets', 'AboutPage.ets']) {
  const pageSource = fs.readFileSync(path.join(root, 'entry', 'src', 'main', 'ets', 'pages', pageName), 'utf8')
  assert(pageSource.includes("import { PrivacyNoticeSection }"), `${pageName} must import the shared privacy component`)
  assert(pageSource.includes('PrivacyNoticeSection()'), `${pageName} must render the shared privacy component`)
  assert(!pageSource.includes('PrivacyRow('), `${pageName} must not retain a duplicated privacy row builder`)
}

console.log('THIRD-ROUND COMPONENT CONTRACT PASSED')
