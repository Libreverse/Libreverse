import * as Sentry from "@sentry/browser";

Sentry.init({
  dsn: "https://464a84695ee24afbb22817b94618d577@glitchtip-cs40w800ggw0gs0k804skcc0.geor.me/5",
  tracesSampleRate: 1.0,
});

import "@hotwired/turbo-rails";
import TurboPower from "turbo_power";
TurboPower.initialize(Turbo.StreamActions);

import "./controllers";
