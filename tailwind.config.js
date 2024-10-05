/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/assets/stylesheets/**/*.scss",
    "./app/views/**/*.erb",
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.js",
    "./app/components/**/*.html.erb",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}

