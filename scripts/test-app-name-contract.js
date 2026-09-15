const assert = require('assert')
const fs = require('fs')
const path = require('path')

const root = path.resolve(__dirname, '..')
const expectedName = '文件格式盒'

function read(relativePath) {
  return fs.readFileSync(path.join(root, relativePath), 'utf8')
}

function readAppName(relativePath) {
  const resource = JSON.parse(read(relativePath))
  const appName = resource.string.find((item) => item.name === 'app_name')
  assert.ok(appName, `${relativePath} must define app_name`)
  return appName.value
}

assert.strictEqual(readAppName('AppScope/resources/base/element/string.json'), expectedName)
assert.strictEqual(readAppName('entry/src/main/resources/base/element/string.json'), expectedName)

const appConfig = read('AppScope/app.json5')
const moduleConfig = read('entry/src/main/module.json5')
assert.ok(appConfig.includes('"label": "$string:app_name"'), 'AppScope must use app_name as its label')
assert.ok(moduleConfig.includes('"label": "$string:app_name"'), 'entry must use app_name as its label')

for (const page of ['entry/src/main/ets/pages/Index.ets', 'entry/src/main/ets/pages/AboutPage.ets']) {
  assert.ok(!read(page).includes('万能格式转换'), `${page} must not retain the old application name`)
}

console.log('APP NAME CONTRACT PASSED')
