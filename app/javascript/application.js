// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import $ from 'jquery';
import 'what-input';
import 'motion-ui';
import * as Foundation from 'foundation-sites';
window.$ = window.jQuery = $;
document.addEventListener('DOMContentLoaded', () => {
  $(document).foundation();
});
import "./controllers"