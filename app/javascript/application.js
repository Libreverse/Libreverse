// Add js-loaded class to html element after page load to enable scrolling for pages
document.addEventListener("DOMContentLoaded", () => {
    document.documentElement.classList.add("js-loaded");
});

import sxwjs from "@sxwjs/sxwjs";
// Custom configuration
const myConfig = {
    stopColor: "red",
    stopFontWeight: "bold",
    cautionFontWeight: "bold",
    cautionFontSize: "15px",
};
sxwjs.setConfig(myConfig);

// Custom content
const myContent = {
    en: {
        stopText: `            uuuuuuuuuuuuuuuuuuuu
          u" uuuuuuuuuuuuuuuuuu "u
        u" u$$$$$$$$$$$$$$$$$$$$u "u
      u" u$$$$$$$$$$$$$$$$$$$$$$$$u "u
    u" u$$$$$$$$$$$$$$$$$$$$$$$$$$$$u "u
  u" u$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$u "u
u" u$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$u "u
$ $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ $
$ $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ $
$ $$$" ... "$...  ...$" ... "$$$  ... "$$$ $
$ $$$u \`"$$$$$$$  $$$  $$$$$  $$  $$$  $$$ $
$ $$$$$$uu "$$$$  $$$  $$$$$  $$  """ u$$$ $
$ $$$""$$$  $$$$  $$$u "$$$" u$$  $$$$$$$$ $
$ $$$$....,$$$$$..$$$$$....,$$$$..$$$$$$$$ $
$ $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ $
"u "$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$" u"
  "u "$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$" u"
    "u "$$$$$$$$$$$$$$$$$$$$$$$$$$$$" u"
      "u "$$$$$$$$$$$$$$$$$$$$$$$$" u"
        "u "$$$$$$$$$$$$$$$$$$$$" u"
          "u """""""""""""""""" u"
            """"""""""""""""""""`,
        cautionText: "IMPORTANT SECURITY WARNING ⬇",
        warningText:
            "This is a tool for web developers only.\n\nAnything entered here is code that will be run on your computer.\n\nSomeone may have told you to paste something here and press enter.\n\nTHIS IS A COMMON SCAM.\n\nAnyone who tells you to ignore this warning is trying to hack your account, no matter who you think they are.",
    },
};
sxwjs.setContent(myContent);

// Print the customized warning
sxwjs.printWarning("en");

import "@hotwired/turbo-rails";

import "./controllers";
import "./config";
import "./channels";
