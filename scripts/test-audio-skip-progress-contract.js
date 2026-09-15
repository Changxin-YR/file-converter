const fs = require('fs')

if (fs.existsSync('entry/src/main/ets/pages/AudioConvertPage.ets')) {
  throw new Error('Audio conversion page must be absent after the audited M4A failure')
}
if (fs.existsSync('entry/src/main/ets/services/AudioConvertService.ets')) {
  throw new Error('Audio conversion service must be absent with the removed feature')
}

console.log('AUDIO FEATURE REMOVAL CONTRACT PASSED')
