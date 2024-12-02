echo "====================="
echo "Rubocop results"
echo "====================="
bundle exec rubocop -A
echo "====================="
echo "ESLint results"
echo "====================="
bunx eslint . --fix
echo "====================="
echo "Prettier results"
echo "====================="
bunx prettier . --write
echo "====================="
echo "Stylelint results"
echo "====================="
bunx stylelint "**/*.scss" --fix
echo "====================="
echo "All static analysis checks performed"
echo "====================="