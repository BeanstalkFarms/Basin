const fs = require('node:fs');
const readline = require('node:readline');

const FUZZ_RUNS = 5000;

const estimateGasUSD = (gasLimit) => {
  const BASE_FEE = 30e-9; // 30 gwei
  const PRIO_FEE = 1e-9; // 1 gwei
  const ETH_PRICE_USD = 1500; // $1500
  return gasLimit * (BASE_FEE + PRIO_FEE) * ETH_PRICE_USD;
}

async function main() {
  const fileStream = fs.createReadStream('.dex-comparisons');

  const rl = readline.createInterface({
    input: fileStream,
    crlfDelay: Infinity,
  });

  let csvContent = 'DEX,PAIR,ACTION,AVERAGE,"EST. COST"\n';

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
      .split(`(runs: ${FUZZ_RUNS}, μ:`)[1]
      .split(', ~: ')[0]
      .trim();

    csvContent +=
      dex + ',' + pair + ',' + testAction + ',' + testAverage + ',' + `$${estimateGasUSD(parseInt(testAverage)).toFixed(2)}` + '\n';
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
