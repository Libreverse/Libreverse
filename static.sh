echo "====================="
echo "Rubocop results"
echo "====================="
bundle exec rubocop -A
echo "====================="
echo "erb_lint results"
echo "====================="
bundle exec erb_lint --lint-all --format compact
echo "====================="
echo "eslint results"
echo "====================="
bunx eslint . --fix
echo "====================="
echo "Stylelint results"
echo "====================="
bunx stylelint "**/*.scss" --fix
echo "====================="
echo "Prettier results"
echo "====================="
bunx prettier . --write
echo "====================="
echo "All static analysis checks performed"
echo "====================="