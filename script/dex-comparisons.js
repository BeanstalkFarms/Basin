const fs = require('node:fs');
const readline = require('node:readline');

async function main() {
  const fileStream = fs.createReadStream('.dex-comparisons');

  const rl = readline.createInterface({
    input: fileStream,
    crlfDelay: Infinity,
  });

  let csvContent = 'DEX,PAIR,ACTION,AVERAGE\n';

  for await (const line of rl) {
    const uniqueTest = line
      .split('IntegrationTestGasComparisons:')[1]
      .split('testFuzz_')[1]
      .split('_');

    const dex = uniqueTest[0].toUpperCase();
    const pair = uniqueTest[1].toUpperCase();
    const test = uniqueTest[2].split('(uint256)');
    const testAction = test[0].toUpperCase();
    const testAverage = test[1]
      .split('(runs: 256, μ:')[1]
      .split(', ~: ')[0]
      .trim();

    csvContent +=
      dex + ',' + pair + ',' + testAction + ',' + testAverage + '\n';
  }

  try {
    fs.writeFileSync('./.dex-comparisons.csv', csvContent);
    console.log('Data written to file successfully.');
  } catch (err) {
    console.error('Failed to write to file: ' + err);
    throw err;
  } 
}

main()
  .then(() => process.exit(0))
  .then(() => process.exit(1));
