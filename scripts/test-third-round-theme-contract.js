const assert = require('assert')
const fs = require('fs')
const path = require('path')

const root = path.join(__dirname, '..')
const baseColors = JSON.parse(fs.readFileSync(
  path.join(root, 'entry', 'src', 'main', 'resources', 'base', 'element', 'color.json'), 'utf8'
)).color
const darkColors = JSON.parse(fs.readFileSync(
  path.join(root, 'entry', 'src', 'main', 'resources', 'dark', 'element', 'color.json'), 'utf8'
)).color
const darkNames = new Set(darkColors.map((entry) => entry.name))
const missingDarkNames = baseColors.map((entry) => entry.name).filter((name) => !darkNames.has(name))

assert.deepStrictEqual(
  missingDarkNames,
  [],
  `Dark theme must define every base color and avoid fallback: ${missingDarkNames.join(', ')}`
)

function luminance(hex) {
  const channels = [1, 3, 5].map((index) => parseInt(hex.slice(index, index + 2), 16) / 255)
  const linear = channels.map((value) => value <= 0.04045 ? value / 12.92 : Math.pow((value + 0.055) / 1.055, 2.4))
  return linear[0] * 0.2126 + linear[1] * 0.7152 + linear[2] * 0.0722
}

function contrast(first, second) {
  const firstLum = luminance(first)
  const secondLum = luminance(second)
  return (Math.max(firstLum, secondLum) + 0.05) / (Math.min(firstLum, secondLum) + 0.05)
}

const baseTertiary = baseColors.find((entry) => entry.name === 'text_tertiary')
assert(baseTertiary, 'Base theme must define text_tertiary')
assert(
  contrast(baseTertiary.value, '#FFFFFF') >= 4.5,
  'Light theme text_tertiary must meet WCAG AA contrast on primary surfaces'
)

const progressSource = fs.readFileSync(
  path.join(root, 'entry', 'src', 'main', 'ets', 'components', 'ConvertProgressBar.ets'), 'utf8'
)
assert(progressSource.includes("$r('app.color.brand_primary')"), 'Progress bars must use the shared brand_primary token')

console.log('THIRD-ROUND THEME CONTRACT PASSED')
