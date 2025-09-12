import fs from 'fs';
import path from 'path';

const exts = new Set(['.dart','.md','.yaml','.yml','.json']);
let failed = false;

function isTextExt(p){ return exts.has(path.extname(p)); }

function checkFile(p){
  const buf = fs.readFileSync(p);
  // Heuristique simple: re-encode -> decode
  const txt = buf.toString('utf8');
  const back = Buffer.from(txt, 'utf8');
  if (back.length !== buf.length) {
    console.error(`[ENCODING] Non-UTF8 file: ${p}`);
    failed = true;
  }
}

function walk(dir){
  for (const e of fs.readdirSync(dir)) {
    const p = path.join(dir, e);
    const st = fs.statSync(p);
    if (st.isDirectory()) walk(p);
    else if (isTextExt(p)) checkFile(p);
  }
}

walk('.');
if (failed) process.exit(1);