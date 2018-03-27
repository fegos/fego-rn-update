let bundleDiff = require('./bundleDiff');

let businessName = '';
let tempPath = '';
if (4 == process.argv.length) {
	businessName = process.argv[2];
	tempPath = process.argv[3];
}
new bundleDiff('common', businessName, tempPath);