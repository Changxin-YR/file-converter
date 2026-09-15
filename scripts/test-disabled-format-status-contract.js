const fs = require('fs')
const path = require('path')

const etsDir = path.join(__dirname, '..', 'entry', 'src', 'main', 'ets')

function assert(condition, message) {
  if (!condition) throw new Error(message)
}

function readEtsFiles(dir) {
  const sources = []
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const entryPath = path.join(dir, entry.name)
    if (entry.isDirectory()) {
      sources.push(...readEtsFiles(entryPath))
    } else if (entry.name.endsWith('.ets')) {
      sources.push({ path: entryPath, source: fs.readFileSync(entryPath, 'utf8') })
    }
  }
  return sources
}

for (const file of readEtsFiles(etsDir)) {
  assert(!file.source.includes('功能正在开发'), `${file.path} must not advertise an unreleased feature`)
  assert(!file.source.includes('developing'), `${file.path} must not retain the unreleased feature state`)
  for (const match of file.source.matchAll(/\.fontSize\((\d+(?:\.\d+)?)\)/g)) {
    assert(Number(match[1]) >= 10, `${file.path} uses fontSize(${match[1]}), below the 10fp release minimum`)
  }
}

console.log('PUBLISHED CAPABILITY UI CONTRACT PASSED')
