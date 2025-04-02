/* import * as Sentry from "@sentry/browser";

Sentry.init({
  dsn: "",
}); */

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

// Add js-loaded class to html element after page load to enable scrolling for auth pages
document.addEventListener("DOMContentLoaded", () => {
    document.documentElement.classList.add("js-loaded");
    
    // Add sanitization helper for potentially dangerous content
    window.sanitizeContent = function(unsafeText) {
        const div = document.createElement('div');
        div.textContent = unsafeText;
        return div.innerHTML;
    };
    
    // Override innerHTML usage where possible
    const saferSetHTML = (element, htmlContent) => {
        if (!element || typeof htmlContent !== 'string') return;
        
        try {
            // Create a template element to sanitize content
            const template = document.createElement('template');
            template.innerHTML = htmlContent.trim();
            
            // Clear the target element
            while (element.firstChild) {
                element.removeChild(element.firstChild);
            }
            
            // Append the sanitized content
            element.appendChild(template.content);
        } catch (e) {
            console.error('Error setting HTML safely:', e);
        }
    };
    
    // Make this available globally
    window.saferSetHTML = saferSetHTML;
});
