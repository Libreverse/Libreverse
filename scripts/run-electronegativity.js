import run from '@doyensec/electronegativity';

console.log('Starting electronegativity scan...');

run({
  input: 'src/preload.js',
  output: 'security-scan-results.csv',
  isSarif: false,
  verbose: false
})
  .then(result => {
    console.log('Scan completed');
    console.log(`Global checks: ${result.globalChecks}`);
    console.log(`Atomic checks: ${result.atomicChecks}`);
    console.log(`Errors: ${result.errors.length}`);
    if (result.errors.length > 0) {
      console.log('Findings:');
      result.errors.forEach(error => {
        console.log(`- ${error.id}: ${error.description} (${error.file}:${error.location.line})`);
      });
    } else {
      console.log('No security issues found!');
    }
  })
  .catch(err => {
    console.error('Error running scan:', err);
  });