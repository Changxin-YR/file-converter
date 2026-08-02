const assert = require('assert')
const fs = require('fs')

const source = fs.readFileSync('entry/src/main/ets/services/FilePickerService.ets', 'utf8')
const pickImages = source.match(/async pickImages[\s\S]*?\n  }/)

assert.ok(pickImages, 'pickImages implementation must exist')
assert.match(pickImages[0], /DocumentSelectOptions/, 'image input must use the file picker so local Downloads are accessible')
assert.match(pickImages[0], /\.png.*\.jpg.*\.jpeg.*\.webp.*\.bmp.*\.heif.*\.heic/s, 'image picker must constrain supported suffixes')
assert.doesNotMatch(pickImages[0], /PhotoViewPicker/, 'image input must not require gallery indexing')

console.log('IMAGE PICKER CONTRACT PASSED')
