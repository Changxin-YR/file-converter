const fs = require('fs')
const path = require('path')

const pagePath = path.join(__dirname, '..', 'entry', 'src', 'main', 'ets', 'pages', 'ImageToolsPage.ets')
const source = fs.readFileSync(pagePath, 'utf8')

if (source.includes('点击色块可复制颜色值') || source.includes('已复制 ${this.pickedColor}')) {
  throw new Error('The color picker must not report clipboard success without writing to the clipboard')
}

console.log('IMAGE TOOLS CAPABILITY CONTRACT PASSED')
