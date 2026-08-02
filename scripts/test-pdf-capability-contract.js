const fs = require('fs')
const path = require('path')

const pagePath = path.join(__dirname, '..', 'entry', 'src', 'main', 'ets', 'pages', 'PdfToolsPage.ets')
const source = fs.readFileSync(pagePath, 'utf8')
const indexPath = path.join(__dirname, '..', 'entry', 'src', 'main', 'ets', 'pages', 'Index.ets')
const indexSource = fs.readFileSync(indexPath, 'utf8')

function assert(condition, message) {
  if (!condition) {
    throw new Error(message)
  }
}

assert(
  /id:\s*'word2pdf'[\s\S]*?title:\s*'文本转PDF'[\s\S]*?available:\s*true/.test(source),
  'The text-only implementation must be labelled TXT/MD conversion, not Word conversion'
)
assert(
  /case\s*'word2pdf':\s*return\s*\['\.txt',\s*'\.md'\]/.test(source),
  'Binary DOC/DOCX files must not be accepted by the UTF-8 text reader'
)
assert(
  /id:\s*'pdf2word'[\s\S]*?description:\s*'项目自产文本PDF'[\s\S]*?available:\s*true/.test(source),
  'PDF to Word must accurately limit support to project-generated text PDFs'
)
assert(
  /id:\s*'pdf2md'[\s\S]*?description:\s*'项目自产文本PDF'[\s\S]*?available:\s*true/.test(source),
  'PDF to Markdown must accurately limit support to project-generated text PDFs'
)
assert(
  source.includes('PdfTextExtractor.extract') && !source.includes("'(无法提取文本内容)'"),
  'PDF reverse conversion must use the strict extractor and never emit placeholder text'
)
assert(
  indexSource.includes('文本PDF导出'),
  'The home page must describe the limited verified reverse conversion'
)

console.log('PDF CAPABILITY CONTRACT PASSED')
