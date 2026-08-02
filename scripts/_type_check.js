// 临时完整类型检查：纯逻辑 .ets → 复制为 .ts → 用 SDK 捆绑 TS + 真实 @kit d.ts 类型检查
const fs = require('fs');
const os = require('os');
const path = require('path');
const ts = require('C:/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/ets/build-tools/ets-loader/node_modules/typescript');

const SDK = 'C:/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/ets/api';
const SDK_KITS = 'C:/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/ets/kits';
const SRC = path.resolve('entry/src/main/ets');
const SKIP_DIRS = ['pages', 'components', 'entryability'];

function walk(d) {
  return fs.readdirSync(d, { withFileTypes: true }).flatMap((e) => {
    if (e.isDirectory()) return walk(path.join(d, e.name));
    return [path.join(d, e.name)];
  });
}

const files = walk(SRC)
  .filter((f) => f.endsWith('.ets'))
  .filter((f) => !SKIP_DIRS.some((dir) => f.split(path.sep).includes(dir)));

// 临时目录：复制为 .ts 并保持目录结构
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'arktc-'));
const rootNames = [];
for (const f of files) {
  const rel = path.relative(SRC, f);
  const tsPath = path.join(tmp, rel.replace(/\.ets$/, '.ts'));
  fs.mkdirSync(path.dirname(tsPath), { recursive: true });
  fs.copyFileSync(f, tsPath);
  rootNames.push(tsPath);
}

// 把导入 @kit.X 也复制进临时目录（指向 SDK 原始文件会因相对 reference 解析混乱,直接用路径映射）
const options = {
  target: ts.ScriptTarget.ES2021,
  module: ts.ModuleKind.ESNext,
  moduleResolution: ts.ModuleResolutionKind.NodeJs,
  experimentalDecorators: true,
  strict: true,
  noEmit: true,
  skipLibCheck: true,
  types: [],
  baseUrl: tmp,
  paths: {
    '@kit.*': [path.join(SDK_KITS, '@kit.*.d.ts')],
    '@ohos.*': [path.join(SDK, '@ohos.*.d.ts')]
  }
};

const program = ts.createProgram(rootNames, options);
const diags = ts.getPreEmitDiagnostics(program);
const errors = diags.filter((d) => d.category === ts.DiagnosticCategory.Error);
if (errors.length === 0) {
  console.log('TYPE OK (' + rootNames.length + ' files)');
} else {
  for (const d of errors) {
    const fn = d.file ? path.basename(d.file.fileName) : '?';
    const pos = d.file && d.start !== undefined ? d.file.getLineAndCharacterOfPosition(d.start) : null;
    console.log(`${fn}:${pos ? pos.line + 1 : '?'}:${pos ? pos.character + 1 : '?'} [${d.code}] ${ts.flattenDiagnosticMessageText(d.messageText, ' ')}`);
  }
}
try { fs.rmSync(tmp, { recursive: true, force: true }); } catch (e) {}
process.exit(errors.length === 0 ? 0 : 1);
