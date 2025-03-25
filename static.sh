echo "====================="
echo "Rubocop results"
echo "====================="
bundle exec rubocop -A

echo "====================="
echo "Fasterer results"
echo "====================="
fasterer

echo "====================="
echo "erb_lint results"
echo "====================="
bundle exec erb_lint --lint-all --format compact --autocorrect

echo "====================="
echo "erb-formatter results"
echo "====================="
erb-format app/views/**/*.html.erb --write

echo "====================="
echo "eslint results"
echo "====================="
bun eslint . --fix

echo "====================="
echo "Stylelint results"
echo "====================="
bun stylelint "**/*.scss" --fix

echo "====================="
echo "markdownlint results"
echo "====================="
bun markdownlint-cli2 '**/*.md' '!**/node_modules/**' '!**/licenses/**' --fix --config .markdownlint.json

echo "====================="
echo "Prettier results"
echo "====================="
SH_TIMEOUT=30000 bun prettier --write . | grep -v "unchanged"

echo "====================="
echo "Typos results"
echo "====================="
typos

echo "====================="
echo "Jest results"
echo "====================="
bun test

echo "====================="
echo "Rails test results"
echo "====================="
bundle exec rails test

echo "====================="
echo "Brakeman results"
echo "====================="
brakeman --quiet --no-summary

echo "====================="
echo "All static analysis checks performed"
echo "====================="
