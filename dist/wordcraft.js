#!/usr/bin/env node
// WordCraft CLI 启动器：将 Node 的 argv 转换为 MoonBit 期望的格式
// Node: [node, script, ...args] → MoonBit: [prog, ...args]
process.argv = ['wordcraft', ...process.argv.slice(2)];
require('./wordcraft-lib.js');
