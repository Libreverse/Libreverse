import ApplicationController from "./application_controller"
# Import the library code as a raw string using Vite's ?raw feature
import raindropFxLibraryCode from "raindrop-fx?raw"

###*
 * Manages an iframe containing the RaindropFX effect to isolate its context.
###
export default class extends ApplicationController
  @values = {
    backgroundUrl: String
    options: { type: Object, default: {} } # Allow passing other raindrop-fx options
  }

  @targets = ["iframe"]

  connect: ->
    super.connect()
    console.log "IFrame Raindrop controller: connect"
    @setupIframe()
    return

  disconnect: ->
    super.disconnect()
    console.log "IFrame Raindrop controller: disconnect"
    @teardownIframe()
    return

  setupIframe: ->
    unless @hasIframeTarget
      console.error "IFrame target not found."
      return

    unless @hasBackgroundUrlValue and @backgroundUrlValue.length > 0
      console.error "Background URL value is missing or empty."
      return

    # Prepare options
    raindropOptions = if typeof @optionsValue == "object" and @optionsValue != null then @optionsValue else {}
    optionsJsonString = JSON.stringify(raindropOptions)

    # Escape the background URL for JS string literal
    backgroundUrlJs = @backgroundUrlValue
      .replace(/\\/g, "\\\\") # Escape backslashes
      .replace(/`/g, "\\`")   # Escape backticks
      .replace(/\${/g, "\\${") # Escape ${ sequence

    # Encode the library code to Base64
    libraryDataUri = ""
    try
      # Ensure UTF-8 compatibility before Base64 encoding if needed, though btoa usually handles typical JS code
      libraryDataUri = "data:text/javascript;base64,#{btoa(raindropFxLibraryCode)}"
    catch e
      console.error "Error Base64 encoding library code:", e
      return # Can't proceed without the library code

    # Build iframe HTML content (Note: Inline JS is still JS, not CoffeeScript)
    iframeContent = """
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>RaindropFX Container</title>
  <style>
    /* Match the styling from the parent .hp-bg/.sp-bg containers */
    body, html {
      margin: 0;
      padding: 0;
      overflow: hidden;
      width: 100%;
      height: 100%;
      background-color: transparent; /* Keep body transparent */
    }
    #raindrop-canvas-iframe {
      display: block;
      position: fixed;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      object-fit: cover;
      z-index: -1;
      user-select: none;
    }
  </style>
</head>
<body>
  <canvas id="raindrop-canvas-iframe"></canvas>

  <!-- Shim for CommonJS module system -->
  <script>
    var module = { exports: {} };
    var exports = module.exports;
  </script>

  <!-- Script tag to load the library code from Base64 data URI -->
  <script src="#{libraryDataUri}"></script>

  <!-- Separate script for initialization, following official pattern -->
  <script type="module">
    // --- Debounce function ---
    function debounce(func, wait) {
      let timeout;
      return function executedFunction(...args) {
        const later = () => {
          clearTimeout(timeout);
          func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
      };
    }
    // --- End Debounce ---

    const RaindropFXLibrary = module.exports.default || module.exports;
    console.log("Module exports after load:", module.exports);

    if (typeof RaindropFXLibrary === 'function') {
      const canvas = document.getElementById('raindrop-canvas-iframe');
      const options = JSON.parse(`#{optionsJsonString}`);
      const backgroundUrl = `#{backgroundUrlJs}`;

      if (canvas) {
        try {
          // Set initial canvas dimensions based on layout
          const initialRect = canvas.getBoundingClientRect();
          canvas.width = initialRect.width;
          canvas.height = initialRect.height;
          console.log('Set initial canvas dimensions: ' + canvas.width + 'x' + canvas.height);

          console.log('Initializing RaindropFX inside iframe...');
          const fx = new RaindropFXLibrary({
            canvas: canvas,
            background: backgroundUrl,
            ...options
          });
          window.fxInstance = fx; // Store instance for resize access
          console.log('RaindropFX initialized.');

          // Start the effect
          if (typeof fx.start === 'function') {
            console.log('Calling fx.start()...');
            fx.start();
            console.log('fx.start() called.');
          } else {
            console.warn('fx.start() method not found.');
          }

          // Debounced Resize handler
          const handleResize = () => {
            if (window.fxInstance && typeof window.fxInstance.resize === 'function') {
              const currentRect = canvas.getBoundingClientRect();
              // Update canvas buffer size AND tell the library
              canvas.width = currentRect.width;
              canvas.height = currentRect.height;
              window.fxInstance.resize(currentRect.width, currentRect.height);
              console.log('Resized iframe canvas (debounced) to: ' + currentRect.width + 'x' + currentRect.height);
            }
          };
          const debouncedResize = debounce(handleResize, 250);
          window.addEventListener('resize', debouncedResize);

        } catch (error) {
          console.error('Error initializing or starting RaindropFX in iframe:', error);
        }
      } else {
        console.error('Canvas element not found in iframe.');
      }
    } else {
      console.error('RaindropFX class/function not found in module.exports after loading library script.', RaindropFXLibrary);
    }
  </script>
</body>
</html>"""

    # Set the srcdoc
    try
      @iframeTarget.srcdoc = iframeContent
      console.log "Iframe srcdoc set."
    catch e
      console.error "Error setting iframe srcdoc:", e
    return

  teardownIframe: ->
    if @hasIframeTarget
      # Setting src to about:blank is a common way to clear the iframe
      @iframeTarget.src = "about:blank"
      # Optionally remove the iframe completely if preferred
      # @iframeTarget.remove()
      console.log "Iframe torn down."
    return