/* import * as Sentry from "@sentry/browser";

Sentry.init({
  dsn: "",
}); */

import sxwjs from '@sxwjs/sxwjs';
sxwjs.printWarning('en');

import "@hotwired/turbo-rails";

import "./controllers";
import "./config";
import "./channels";
