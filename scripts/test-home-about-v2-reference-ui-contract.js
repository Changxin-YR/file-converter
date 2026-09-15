const fs = require('fs')
const path = require('path')

const root = path.resolve(__dirname, '..')
const index = fs.readFileSync(path.join(root, 'entry/src/main/ets/pages/Index.ets'), 'utf8')
const about = fs.readFileSync(path.join(root, 'entry/src/main/ets/pages/AboutPage.ets'), 'utf8')
const tile = fs.readFileSync(path.join(root, 'entry/src/main/ets/components/FunctionTile.ets'), 'utf8')
const privacy = fs.readFileSync(path.join(root, 'entry/src/main/ets/components/PrivacyNoticeSection.ets'), 'utf8')
const mediaDir = path.join(root, 'entry/src/main/resources/base/media')

function requirePattern(source, pattern, message) {
  if (!pattern.test(source)) throw new Error(message)
}

requirePattern(index, /Text\(\$r\('app\.string\.app_name'\)\)[\s\S]*?\.fontSize\(32\)/,
  'Home title must use the approved 32vp size')
requirePattern(index, /app\.media\.ui_hero_home[\s\S]*?\.height\(156\)/,
  'Home hero must use the device-verified 156vp phone height')
requirePattern(tile, /\.height\(96\)/, 'Function tiles must use the approved 96vp phone height')
requirePattern(tile, /Stack\(\)[\s\S]*?\.width\(56\)[\s\S]*?\.borderRadius\(28\)/,
  'Function icons must sit on the approved circular backdrop')
requirePattern(tile, /Text\(this\.title\)[\s\S]*?\.fontSize\(15\)/,
  'Function titles must fit completely at the approved 15vp size')
requirePattern(tile, /this\.description\)[\s\S]*?\.fontSize\(10\)/,
  'Function descriptions must fit completely at the approved 10vp size')
requirePattern(index, /TabSelectionLine\(index\)/,
  'Bottom navigation must render the selected-tab underline')
requirePattern(index, /width >= UiConstants\.BREAKPOINT_MEDIUM[\s\S]*?gridColumns = '1fr 1fr 1fr'/,
  'Medium tablet widths must use the approved three-column grid')
requirePattern(index, /app\.media\.ui_about_app_icon/, 'Embedded About must use the approved arrow app icon')
requirePattern(about, /app\.media\.ui_about_app_icon/, 'Standalone About must use the approved arrow app icon')
requirePattern(about, /AppPageHeader\([\s\S]*?router\.back\(\)/,
  'Standalone About route must retain an explicit back action')
requirePattern(privacy, /constraintSize\(\{ minHeight: 58 \}\)/,
  'Shared privacy rows must use the approved compact height')
for (const source of [index, about]) {
  requirePattern(source, /PrivacyNoticeSection\(\)/,
    'Embedded and standalone About surfaces must render the shared privacy section')
}

const privacyAssets = [
  'ui_privacy_local.png',
  'ui_privacy_offline.png',
  'ui_privacy_storage.png',
  'ui_privacy_access.png'
]
for (const asset of privacyAssets) {
  if (!fs.existsSync(path.join(mediaDir, asset))) throw new Error(`${asset} is missing`)
  const resource = `app.media.${asset.replace('.png', '')}`
  if (!privacy.includes(resource)) {
    throw new Error(`${resource} must be used by the shared privacy section`)
  }
}

requirePattern(privacy, /PrivacyRow\([^,]+,\s*\$r\('app\.media\.ui_privacy_local'\)\)/,
  'Local processing row must use its reference icon')
requirePattern(privacy, /PrivacyRow\([^,]+,\s*\$r\('app\.media\.ui_privacy_offline'\)\)/,
  'Offline row must use its reference icon')
requirePattern(privacy, /PrivacyRow\([^,]+,\s*\$r\('app\.media\.ui_privacy_storage'\)\)/,
  'Storage row must use its reference icon')
requirePattern(privacy, /PrivacyRow\([^,]+,\s*\$r\('app\.media\.ui_privacy_access'\)\)/,
  'Access row must use its reference icon')

console.log('HOME ABOUT V2 REFERENCE UI CONTRACT PASSED')
