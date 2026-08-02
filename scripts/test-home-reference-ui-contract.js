const fs = require('fs')
const path = require('path')

const source = fs.readFileSync(path.join(
  __dirname, '..', 'entry', 'src', 'main', 'ets', 'pages', 'Index.ets'
), 'utf8')

function requirePattern(pattern, message) {
  if (!pattern.test(source)) throw new Error(message)
}

requirePattern(/import\s*\{\s*FunctionTile\s*\}/, 'Home must use FunctionTile')
requirePattern(/app\.media\.ui_hero_home/, 'Home must use the reference hero asset')
for (const asset of ['image', 'document', 'video', 'audio', 'image_edit', 'archive', 'unit', 'pdf']) {
  requirePattern(new RegExp(`app\\.media\\.ui_tool_${asset}`), `Home is missing ui_tool_${asset}`)
}
requirePattern(/columnsTemplate\([^)]*gridColumns/, 'Home must use responsive grid columns')
requirePattern(/gridColumns[^\n]*'1fr 1fr'|return\s*'1fr 1fr'/, 'Home must use two phone columns')
requirePattern(/1fr 1fr 1fr 1fr/, 'Home must use four large-screen columns')
requirePattern(/onAreaChange/, 'Home must derive layout from onAreaChange')
requirePattern(/Tabs\(/, 'Home must retain tab navigation')
requirePattern(/tab_home/, 'Home tab must remain present')
requirePattern(/tab_about/, 'About tab must remain present')
if (/iconText|[\u{1F300}-\u{1FAFF}]/u.test(source)) {
  throw new Error('Home must not use emoji presentation icons')
}

console.log('HOME REFERENCE UI CONTRACT PASSED')
