import html2canvas from 'html2canvas';

class Container {
  static instances = []
  static pageSnapshot = null
  static isCapturing = false
  static waitingForSnapshot = []
  static resizeTimeout = null
  static isDestroying = false
  static lastCaptureTime = 0
  static captureDebounceDelay = 1000 // 1 second minimum between captures
  static debugMode = false // Global debug flag

  // Debug helper function
  static enableDebug() {
    Container.debugMode = true
    console.log('[Container] Debug mode enabled')
    // Force recompile of all shaders with debug flag
    Container.instances.forEach(instance => {
      if (instance.webglInitialized) {
        console.log('[Container] Recompiling shader with debug for instance')
        // We would need to recompile shaders here, but for now just log
      }
    })
  }

  static disableDebug() {
    Container.debugMode = false
    console.log('[Container] Debug mode disabled')
  }

  // Helper methods for creating containers with common parallax configurations
  static createSidebarContainer(options = {}) {
    return new Container({
      ...options,
      parallaxSpeed: 1.0, // Sidebar typically doesn't have parallax
      isParallaxElement: false,
      type: 'rounded',
      // Sidebar should sync with parallax backgrounds for proper transparency illusion
      syncWithParallax: options.syncWithParallax !== undefined ? options.syncWithParallax : true,
      backgroundParallaxSpeed: options.backgroundParallaxSpeed !== undefined ? options.backgroundParallaxSpeed : -2 // Standard parallax speed in your app
    })
  }

  // Helper for sidebar with custom corner rounding (no left corners rounded)
  static createSidebarContainerRightRounded(options = {}) {
    return new Container({
      ...options,
      parallaxSpeed: 1.0,
      isParallaxElement: false,
      type: 'rounded',
      syncWithParallax: options.syncWithParallax !== undefined ? options.syncWithParallax : true,
      backgroundParallaxSpeed: options.backgroundParallaxSpeed !== undefined ? options.backgroundParallaxSpeed : -2,
      // Only round right corners (for sidebars attached to left edge)
      roundedCorners: {
        topLeft: false,
        topRight: true,
        bottomLeft: false,
        bottomRight: true
      }
    })
  }

  static createParallaxContainer(parallaxSpeed = 0.5, options = {}) {
    return new Container({
      ...options,
      parallaxSpeed: parallaxSpeed,
      isParallaxElement: true,
      // Parallax elements typically don't need background compensation
      syncWithParallax: options.syncWithParallax !== undefined ? options.syncWithParallax : false,
      backgroundParallaxSpeed: 1.0
    })
  }

  static createFixedContainer(options = {}) {
    return new Container({
      ...options,
      parallaxSpeed: 1.0,
      isParallaxElement: false,
      // Fixed elements should sync with parallax backgrounds
      syncWithParallax: options.syncWithParallax !== undefined ? options.syncWithParallax : true,
      backgroundParallaxSpeed: options.backgroundParallaxSpeed !== undefined ? options.backgroundParallaxSpeed : -2 // Standard parallax speed
    })
  }

  constructor(options = {}) {
    this.width = 0 // Will be set from DOM
    this.height = 0 // Will be set from DOM
    this.borderRadius = options.borderRadius || 48
    this.type = options.type || 'rounded' // "rounded", "circle", or "pill"
    this.tintOpacity = options.tintOpacity !== undefined ? options.tintOpacity : 0.2
    
    // Selective corner rounding - which corners should be rounded
    this.roundedCorners = options.roundedCorners || {
      topLeft: true,
      topRight: true,
      bottomLeft: true,
      bottomRight: true
    }
    
    // Parallax configuration
    this.parallaxSpeed = options.parallaxSpeed !== undefined ? options.parallaxSpeed : 1.0 // 1.0 = normal scroll, 0.5 = half speed, 2.0 = double speed
    this.parallaxOffset = options.parallaxOffset || 0 // Additional offset for parallax elements
    this.isParallaxElement = options.isParallaxElement || false // Whether this container itself has parallax
    
    // Background parallax compensation - how to adjust texture sampling for parallax backgrounds
    this.backgroundParallaxSpeed = options.backgroundParallaxSpeed !== undefined ? options.backgroundParallaxSpeed : 1.0 // Speed of background elements behind this container
    this.syncWithParallax = options.syncWithParallax !== undefined ? options.syncWithParallax : false // Whether to sync texture sampling with parallax

    this.canvas = null
    this.element = null
    this.gl = null
    this.gl_refs = {}
    this.webglInitialized = false
    this.children = [] // Child buttons/components
    this.isDestroyed = false
    this.intersectionObserver = null // For visibility detection
    
    // Bind methods to preserve context
    this._handleResize = this._handleResize.bind(this)
    this._handleScroll = this._handleScroll.bind(this)
    this._handleSidebarResize = this._handleSidebarResize.bind(this)

    // Add to instances
    Container.instances.push(this)

    // Initialize
    this.init()
  }

  addChild(child) {
    this.children.push(child)
    child.parent = this

    // Add child's element to container
    if (child.element && this.element) {
      this.element.appendChild(child.element)
    }

    // If child has setupAsNestedGlass, set up nested glass (duck typing to avoid circular import)
    if (typeof child.setupAsNestedGlass === 'function') {
      child.setupAsNestedGlass()
    }

    // Update container size based on actual DOM size
    this.updateSizeFromDOM()

    return child
  }

  removeChild(child) {
    const index = this.children.indexOf(child)
    if (index > -1) {
      this.children.splice(index, 1)
      child.parent = null

      if (child.element && this.element.contains(child.element)) {
        this.element.removeChild(child.element)
      }

      // Update container size after removing child
      this.updateSizeFromDOM()
    }
  }

  updateSizeFromDOM() {
    // Wait for next frame to ensure DOM layout is complete
    requestAnimationFrame(() => {
      // Check if element still exists and is connected to DOM
      if (!this.element || !this.element.isConnected || this.isDestroyed) {
        return
      }

      const rect = this.element.getBoundingClientRect()
      let newWidth = Math.ceil(rect.width)
      let newHeight = Math.ceil(rect.height)

      // Apply type-specific sizing logic
      if (this.type === 'circle') {
        // For circles, ensure perfect square
        const size = Math.max(newWidth, newHeight)
        newWidth = size
        newHeight = size
        this.borderRadius = size / 2 // 50% for perfect circle

        // Force exact square dimensions
        this.element.style.width = size + 'px'
        this.element.style.height = size + 'px'
        this.element.style.borderRadius = this.borderRadius + 'px'
      } else if (this.type === 'pill') {
        // For pills, border radius is half the height
        this.borderRadius = newHeight / 2
        this.element.style.borderRadius = this.borderRadius + 'px'
      }

      if (newWidth !== this.width || newHeight !== this.height) {
        this.width = newWidth
        this.height = newHeight

        // Update canvas size to match actual DOM size
        this.canvas.width = newWidth
        this.canvas.height = newHeight
        this.canvas.style.width = newWidth + 'px'
        this.canvas.style.height = newHeight + 'px'
        this.canvas.style.borderRadius = this.borderRadius + 'px'

        // Update WebGL viewport if initialized
        if (this.gl_refs.gl) {
          this.gl_refs.gl.viewport(0, 0, newWidth, newHeight)
          this.gl_refs.gl.uniform2f(this.gl_refs.resolutionLoc, newWidth, newHeight)
          this.gl_refs.gl.uniform1f(this.gl_refs.borderRadiusLoc, this.borderRadius)
        }

        // Update any nested glass children when container size changes
        for (const child of this.children) {
          if (typeof child.isNestedGlass === 'boolean' && child.isNestedGlass && child.gl_refs && child.gl_refs.gl) {
            const gl = child.gl_refs.gl

            // Update child's texture to match new container size
            gl.bindTexture(gl.TEXTURE_2D, child.gl_refs.texture)
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, newWidth, newHeight, 0, gl.RGBA, gl.UNSIGNED_BYTE, null)

            // Update child's uniforms
            gl.uniform2f(child.gl_refs.textureSizeLoc, newWidth, newHeight)
            if (child.gl_refs.containerSizeLoc) {
              gl.uniform2f(child.gl_refs.containerSizeLoc, newWidth, newHeight)
            }
          }
        }
      }
    })
  }

  init() {
    // Set up global event handlers (only once)
    Container.setupGlobalEventHandlers()
    
    try {
      this.createElement()
      const webglSupported = this.setupCanvas()
      
      if (!webglSupported) {
        // WebGL not supported, use CSS fallback
        return
      }

      // Get initial size from DOM
      this.updateSizeFromDOM()
      
      // Set up resize observer for sidebar responsiveness
      this.setupSidebarResizeObserver()

      // Set up intersection observer to handle visibility
      this.setupIntersectionObserver()
    } catch (error) {
      console.error('Error initializing liquid glass container:', error)
      // Fall back to basic CSS styling
      this.setupFallback()
    }
  }

  setupFallback() {
    if (this.element) {
      this.element.style.backgroundColor = 'rgba(255, 255, 255, 0.1)'
      this.element.style.backdropFilter = 'blur(10px)'
      this.element.style.border = '1px solid rgba(255, 255, 255, 0.2)'
    }
  }

  createElement() {
    // Create wrapper element with CSS class
    this.element = document.createElement('div')
    this.element.className = 'glass-container'

    // Add type-specific classes
    if (this.type === 'circle') {
      this.element.classList.add('glass-container-circle')
    } else if (this.type === 'pill') {
      this.element.classList.add('glass-container-pill')
    }

    // Apply selective corner rounding to CSS
    if (!this.roundedCorners.topLeft || !this.roundedCorners.topRight || 
        !this.roundedCorners.bottomLeft || !this.roundedCorners.bottomRight) {
      const topLeft = this.roundedCorners.topLeft ? this.borderRadius : 0
      const topRight = this.roundedCorners.topRight ? this.borderRadius : 0
      const bottomRight = this.roundedCorners.bottomRight ? this.borderRadius : 0
      const bottomLeft = this.roundedCorners.bottomLeft ? this.borderRadius : 0
      this.element.style.borderRadius = `${topLeft}px ${topRight}px ${bottomRight}px ${bottomLeft}px`
    }

    // Create canvas (will be sized after DOM layout)
    this.canvas = document.createElement('canvas')
    
    // Apply selective corner rounding to canvas CSS
    if (!this.roundedCorners.topLeft || !this.roundedCorners.topRight || 
        !this.roundedCorners.bottomLeft || !this.roundedCorners.bottomRight) {
      const topLeft = this.roundedCorners.topLeft ? this.borderRadius : 0
      const topRight = this.roundedCorners.topRight ? this.borderRadius : 0
      const bottomRight = this.roundedCorners.bottomRight ? this.borderRadius : 0
      const bottomLeft = this.roundedCorners.bottomLeft ? this.borderRadius : 0
      this.canvas.style.borderRadius = `${topLeft}px ${topRight}px ${bottomRight}px ${bottomLeft}px`
    }
    this.canvas.style.position = 'absolute'
    this.canvas.style.top = '0'
    this.canvas.style.left = '0'
    this.canvas.style.width = '100%'
    this.canvas.style.height = '100%'
    this.canvas.style.boxShadow = '0 25px 50px rgba(0, 0, 0, 0.25)'
    this.canvas.style.zIndex = '1' // Canvas in front of background, behind content
    this.canvas.style.pointerEvents = 'none' // Allow clicks to pass through

    this.element.appendChild(this.canvas)
  }

  setupCanvas() {
    this.gl = this.canvas.getContext('webgl', { 
      preserveDrawingBuffer: true,
      alpha: true,
      premultipliedAlpha: false
    })
    if (!this.gl) {
      console.error('WebGL not supported, falling back to CSS glass effect')
      this.setupFallback()
      return false
    }
    
    // Enable alpha blending for glass effect
    this.gl.enable(this.gl.BLEND)
    this.gl.blendFunc(this.gl.SRC_ALPHA, this.gl.ONE_MINUS_SRC_ALPHA)
    
    console.log('WebGL context created successfully')
    return true
  }

  getPosition() {
    // Get actual screen position using getBoundingClientRect
    const rect = this.canvas.getBoundingClientRect()
    let x = rect.left + rect.width / 2
    let y = rect.top + rect.height / 2
    
    // Apply parallax correction if this container has parallax effects
    if (this.isParallaxElement && this.parallaxSpeed !== 1.0) {
      const currentScrollY = window.pageYOffset || document.documentElement.scrollTop || 0
      
      // Calculate how much this element has moved due to parallax
      const parallaxDelta = currentScrollY * (1.0 - this.parallaxSpeed)
      y += parallaxDelta + this.parallaxOffset
      
      if (Container.debugMode) {
        console.log('[Container Debug] Parallax correction:', {
          originalY: rect.top + rect.height / 2,
          correctedY: y,
          scrollY: currentScrollY,
          parallaxSpeed: this.parallaxSpeed,
          parallaxDelta: parallaxDelta,
          parallaxOffset: this.parallaxOffset
        })
      }
    }
    
    return { x, y }
  }


// ...existing code...

capturePageSnapshot() {
  console.log('Capturing page snapshot...')
  
  // Get the full page dimensions
  const pageWidth = Math.max(
    document.body.scrollWidth,
    document.body.offsetWidth,
    document.documentElement.clientWidth,
    document.documentElement.scrollWidth,
    document.documentElement.offsetWidth
  )
  
  const pageHeight = Math.max(
    document.body.scrollHeight,
    document.body.offsetHeight,
    document.documentElement.clientHeight,
    document.documentElement.scrollHeight,
    document.documentElement.offsetHeight
  )
  
  console.log(`Capturing full page: ${pageWidth}x${pageHeight}`)
  console.log(`Waiting containers: ${Container.waitingForSnapshot.length}`)
  
  html2canvas(document.body, {
    scale: 1,
    useCORS: true,
    allowTaint: true,
    backgroundColor: null,
    width: pageWidth,
    height: pageHeight,
    windowWidth: pageWidth,
    windowHeight: pageHeight,
    foreignObjectRendering: false,
    logging: true,
    proxy: null,
    removeContainer: false,
    ignoreElements: function (element) {
      // Ignore all glass elements
      return (
        element.classList.contains('glass-container') ||
        element.classList.contains('glass-button') ||
        element.classList.contains('glass-button-text')
      )
    }
  })
    .then(snapshot => {
      console.log(`Page snapshot captured: ${snapshot.width}x${snapshot.height}`)
      
      // Validate snapshot
      if (!snapshot || snapshot.width === 0 || snapshot.height === 0) {
        console.error('Invalid snapshot captured:', snapshot)
        Container.isCapturing = false
        Container.waitingForSnapshot = []
        return
      }
      
      Container.pageSnapshot = snapshot
      Container.isCapturing = false

      // Initialize WebGL for all waiting containers
      const waitingContainers = Container.waitingForSnapshot.slice()
      Container.waitingForSnapshot = []
      
      console.log(`Initializing WebGL for ${waitingContainers.length} waiting containers`)

      waitingContainers.forEach((container, index) => {
        if (!container.webglInitialized && !container.isDestroyed) {
          console.log(`Initializing WebGL for container ${index + 1}/${waitingContainers.length}`)
          container.initWebGL()
        }
      })
    })
    .catch(error => {
      console.error('html2canvas error:', error)
      Container.isCapturing = false
      Container.waitingForSnapshot = []
    })
}

  initWebGL() {
    if (!Container.pageSnapshot || !this.gl || this.isDestroyed) {
      console.error('initWebGL failed - missing requirements:', {
        hasSnapshot: !!Container.pageSnapshot,
        hasGL: !!this.gl,
        isDestroyed: this.isDestroyed
      })
      this.setupFallback()
      return
    }

    console.log('Starting WebGL initialization for container')

    try {
      const img = new Image()
      img.src = Container.pageSnapshot.toDataURL()
      img.onload = () => {
        try {
          console.log('Setting up WebGL shader for container:', this.element.className)
          this.setupShader(img)
          this.webglInitialized = true
          
          // Mark canvas as WebGL ready for CSS
          this.canvas.style.setProperty('--webgl-ready', 'true')
          
          console.log('WebGL initialization successful')
        } catch (error) {
          console.error('Error setting up WebGL shader:', error)
          this.setupFallback()
        }
      }
      img.onerror = () => {
        console.error('Error loading snapshot image')
        this.setupFallback()
      }
    } catch (error) {
      console.error('Error initializing WebGL:', error)
      this.setupFallback()
    }
  }

  setupShader(image) {
    const gl = this.gl

    const vsSource = `
    attribute vec2 a_position;
    attribute vec2 a_texcoord;
    varying vec2 v_texcoord;

    void main() {
      gl_Position = vec4(a_position, 0, 1);
      v_texcoord = a_texcoord;
    }
  `

    const fsSource = `
    precision mediump float;
    uniform sampler2D u_image;
    uniform vec2 u_resolution;
      uniform vec2 u_textureSize;
      uniform float u_scrollY;
      uniform float u_pageHeight;
      uniform float u_viewportHeight;
      uniform float u_blurRadius;
      uniform float u_borderRadius;
      uniform vec2 u_containerPosition;
      uniform float u_warp;
      uniform float u_edgeIntensity;
      uniform float u_rimIntensity;
      uniform float u_baseIntensity;
      uniform float u_edgeDistance;
      uniform float u_rimDistance;
      uniform float u_baseDistance;
      uniform float u_cornerBoost;
      uniform float u_rippleEffect;
      uniform float u_tintOpacity;
      // Selective corner rounding
      uniform vec4 u_roundedCorners; // (topLeft, topRight, bottomLeft, bottomRight)
    varying vec2 v_texcoord;

      // Function to calculate distance from rounded rectangle edge
      float roundedRectDistance(vec2 coord, vec2 size, float radius) {
        vec2 center = size * 0.5;
        vec2 pixelCoord = coord * size;
        vec2 toCorner = abs(pixelCoord - center) - (center - radius);
        float outsideCorner = length(max(toCorner, 0.0));
        float insideCorner = min(max(toCorner.x, toCorner.y), 0.0);
        return (outsideCorner + insideCorner - radius);
      }
      
      // Function to calculate distance from selectively rounded rectangle
      float selectiveRoundedRectDistance(vec2 coord, vec2 size, float radius, vec4 roundedCorners) {
        vec2 center = size * 0.5;
        vec2 pixelCoord = coord * size;
        
        // Determine which quadrant we're in
        bool isLeft = pixelCoord.x < center.x;
        bool isTop = pixelCoord.y < center.y;
        
        // Check if current corner should be rounded
        float cornerRadius = radius;
        if (isTop && isLeft && roundedCorners.x < 0.5) cornerRadius = 0.0;      // topLeft
        if (isTop && !isLeft && roundedCorners.y < 0.5) cornerRadius = 0.0;    // topRight  
        if (!isTop && isLeft && roundedCorners.z < 0.5) cornerRadius = 0.0;    // bottomLeft
        if (!isTop && !isLeft && roundedCorners.w < 0.5) cornerRadius = 0.0;   // bottomRight
        
        vec2 toCorner = abs(pixelCoord - center) - (center - cornerRadius);
        float outsideCorner = length(max(toCorner, 0.0));
        float insideCorner = min(max(toCorner.x, toCorner.y), 0.0);
        return (outsideCorner + insideCorner - cornerRadius);
      }
      
      // Function to calculate distance from circle edge (negative inside, positive outside)
      float circleDistance(vec2 coord, vec2 size, float radius) {
        vec2 center = vec2(0.5, 0.5);
        vec2 pixelCoord = coord * size;
        vec2 centerPixel = center * size;
        float distFromCenter = length(pixelCoord - centerPixel);
        return distFromCenter - radius;
      }
      
      // Check if this is a pill (border radius is approximately 50% of height AND width > height)
      bool isPill(vec2 size, float radius) {
        float heightRatioDiff = abs(radius - size.y * 0.5);
        bool radiusMatchesHeight = heightRatioDiff < 2.0;
        bool isWiderThanTall = size.x > size.y + 4.0; // Must be significantly wider
        return radiusMatchesHeight && isWiderThanTall;
      }
      
      // Check if this is a circle (border radius is approximately 50% of smaller dimension AND roughly square)
      bool isCircle(vec2 size, float radius) {
        float minDim = min(size.x, size.y);
        bool radiusMatchesMinDim = abs(radius - minDim * 0.5) < 1.0;
        bool isRoughlySquare = abs(size.x - size.y) < 4.0; // Width and height are similar
        return radiusMatchesMinDim && isRoughlySquare;
      }
      
      // Function to calculate distance from pill edge (capsule shape)
      float pillDistance(vec2 coord, vec2 size, float radius) {
        vec2 center = size * 0.5;
        vec2 pixelCoord = coord * size;
        
        // Proper capsule: line segment with radius
        // The capsule axis runs horizontally from (radius, center.y) to (size.x - radius, center.y)
        vec2 capsuleStart = vec2(radius, center.y);
        vec2 capsuleEnd = vec2(size.x - radius, center.y);
        
        // Project point onto the capsule axis (line segment)
        vec2 capsuleAxis = capsuleEnd - capsuleStart;
        float capsuleLength = length(capsuleAxis);
        
        if (capsuleLength > 0.0) {
          vec2 toPoint = pixelCoord - capsuleStart;
          float t = clamp(dot(toPoint, capsuleAxis) / dot(capsuleAxis, capsuleAxis), 0.0, 1.0);
          vec2 closestPointOnAxis = capsuleStart + t * capsuleAxis;
          return length(pixelCoord - closestPointOnAxis) - radius;
        } else {
          // Degenerate case: just a circle
          return length(pixelCoord - center) - radius;
        }
      }

    void main() {
        vec2 coord = v_texcoord;
        
        // Calculate which area of the page should be visible through the container
        float scrollY = u_scrollY;
        vec2 containerSize = u_resolution;
        vec2 textureSize = u_textureSize;
        
        // Container position in page coordinates (already accounts for scroll)
        vec2 containerCenter = u_containerPosition;
        
        // Convert container coordinates to page coordinates
        vec2 containerOffset = (coord - 0.5) * containerSize;
        vec2 pagePixel = containerCenter + containerOffset;
        
        // Convert to texture coordinate (0 to 1)
        vec2 textureCoord = pagePixel / textureSize;
        
        // Debug: Color-code texture coordinates to visualize mapping
        // Red = out of bounds left/top, Green = in bounds, Blue = out of bounds right/bottom
        vec3 debugColor = vec3(0.0);
        if (textureCoord.x < 0.0 || textureCoord.y < 0.0) {
          debugColor = vec3(1.0, 0.0, 0.0); // Red for negative coords
        } else if (textureCoord.x > 1.0 || textureCoord.y > 1.0) {
          debugColor = vec3(0.0, 0.0, 1.0); // Blue for coords > 1
        } else {
          debugColor = vec3(0.0, 1.0, 0.0); // Green for valid coords
        }
        
        // Show debug visualization in top-left corner of container (enable by adding ?debug=glass to URL)
        bool showDebug = false; // Temporarily disable debug to see actual effect
        // Simple debug check - you can enable this by setting a global flag
        #ifdef DEBUG_TEXTURE_COORDS
        showDebug = true;
        #endif
        
        if (showDebug && coord.x < 0.2 && coord.y < 0.2) {
          // Sample the actual texture at the calculated coordinate
          vec4 textureSample = texture2D(u_image, textureCoord);
          
          // Debug visualization:
          // Top-left corner: texture coordinate validity (green/red/blue)
          // Just below: actual texture sample
          if (coord.y < 0.1) {
            gl_FragColor = vec4(debugColor, 1.0);
          } else {
            // Show the actual texture sample - if it's black, texture has issues
            gl_FragColor = vec4(textureSample.rgb, 1.0);
          }
          return;
        }
        
        // Glass refraction effects
        float distFromEdgeShape;
        vec2 shapeNormal; // Normal vector pointing away from shape surface
        
        if (isPill(u_resolution, u_borderRadius)) {
          distFromEdgeShape = -pillDistance(coord, u_resolution, u_borderRadius);
          
          // Calculate normal for pill shape
          vec2 center = vec2(0.5, 0.5);
          vec2 pixelCoord = coord * u_resolution;
          vec2 capsuleStart = vec2(u_borderRadius, center.y * u_resolution.y);
          vec2 capsuleEnd = vec2(u_resolution.x - u_borderRadius, center.y * u_resolution.y);
          vec2 capsuleAxis = capsuleEnd - capsuleStart;
          float capsuleLength = length(capsuleAxis);
          
          if (capsuleLength > 0.0) {
            vec2 toPoint = pixelCoord - capsuleStart;
            float t = clamp(dot(toPoint, capsuleAxis) / dot(capsuleAxis, capsuleAxis), 0.0, 1.0);
            vec2 closestPointOnAxis = capsuleStart + t * capsuleAxis;
            vec2 normalDir = pixelCoord - closestPointOnAxis;
            shapeNormal = length(normalDir) > 0.0 ? normalize(normalDir) : vec2(0.0, 1.0);
          } else {
            shapeNormal = normalize(coord - center);
          }
        } else if (isCircle(u_resolution, u_borderRadius)) {
          distFromEdgeShape = -circleDistance(coord, u_resolution, u_borderRadius);
          vec2 center = vec2(0.5, 0.5);
          shapeNormal = normalize(coord - center);
        } else {
          distFromEdgeShape = -selectiveRoundedRectDistance(coord, u_resolution, u_borderRadius, u_roundedCorners);
          vec2 center = vec2(0.5, 0.5);
          shapeNormal = normalize(coord - center);
        }
        distFromEdgeShape = max(distFromEdgeShape, 0.0);
        
        float distFromLeft = coord.x;
        float distFromRight = 1.0 - coord.x;
        float distFromTop = coord.y;
        float distFromBottom = 1.0 - coord.y;
        float distFromEdge = distFromEdgeShape / min(u_resolution.x, u_resolution.y);
        
        // Smooth glass refraction using shape-aware normal
        float normalizedDistance = distFromEdge * min(u_resolution.x, u_resolution.y);
        float baseIntensity = 1.0 - exp(-normalizedDistance * u_baseDistance);
        float edgeIntensity = exp(-normalizedDistance * u_edgeDistance);
        float rimIntensity = exp(-normalizedDistance * u_rimDistance);
        
        // Apply center warping only if warp is enabled, keep edge and rim effects always
        float baseComponent = u_warp > 0.5 ? baseIntensity * u_baseIntensity : 0.0;
        float totalIntensity = baseComponent + edgeIntensity * u_edgeIntensity + rimIntensity * u_rimIntensity;
        
        vec2 baseRefraction = shapeNormal * totalIntensity;
        
        float cornerProximityX = min(distFromLeft, distFromRight);
        float cornerProximityY = min(distFromTop, distFromBottom);
        float cornerDistance = max(cornerProximityX, cornerProximityY);
        float cornerNormalized = cornerDistance * min(u_resolution.x, u_resolution.y);
        
        float cornerBoost = exp(-cornerNormalized * 0.3) * u_cornerBoost;
        vec2 cornerRefraction = shapeNormal * cornerBoost;
        
        vec2 perpendicular = vec2(-shapeNormal.y, shapeNormal.x);
        float rippleEffect = sin(distFromEdge * 25.0) * u_rippleEffect * rimIntensity;
        vec2 textureRefraction = perpendicular * rippleEffect;
        
        vec2 totalRefraction = baseRefraction + cornerRefraction + textureRefraction;
        textureCoord += totalRefraction;
        
        // Clamp texture coordinates to prevent sampling outside bounds
        textureCoord = clamp(textureCoord, vec2(0.001), vec2(0.999));
        
        // Gaussian blur with bounds checking
        vec4 color = vec4(0.0);
        vec2 texelSize = 1.0 / u_textureSize;
        float sigma = u_blurRadius / 2.0;
        vec2 blurStep = texelSize * sigma;
        
        float totalWeight = 0.0;
        
        for(float i = -6.0; i <= 6.0; i += 1.0) {
          for(float j = -6.0; j <= 6.0; j += 1.0) {
            float distance = length(vec2(i, j));
            if(distance > 6.0) continue;
            
            float weight = exp(-(distance * distance) / (2.0 * sigma * sigma));
            
            vec2 offset = vec2(i, j) * blurStep;
            vec2 sampleCoord = textureCoord + offset;
            
            // Clamp sample coordinates to texture bounds
            sampleCoord = clamp(sampleCoord, vec2(0.0), vec2(1.0));
            
            color += texture2D(u_image, sampleCoord) * weight;
            totalWeight += weight;
          }
        }
        
        color /= totalWeight;
        
        // Simple vertical gradient
        float gradientPosition = coord.y;
        vec3 topTint = vec3(1.0, 1.0, 1.0);
        vec3 bottomTint = vec3(0.7, 0.7, 0.7);
        vec3 gradientTint = mix(topTint, bottomTint, gradientPosition);
        vec3 tintedColor = mix(color.rgb, gradientTint, u_tintOpacity);
        color = vec4(tintedColor, color.a);
        
        // Sampled gradient
        vec2 pageCenter = containerCenter;
        float topY = (pageCenter.y - containerSize.y * 0.4) / textureSize.y;
        float midY = pageCenter.y / textureSize.y;
        float bottomY = (pageCenter.y + containerSize.y * 0.4) / textureSize.y;
        
        vec3 topColor = vec3(0.0);
        vec3 midColor = vec3(0.0);
        vec3 bottomColor = vec3(0.0);
        
        float sampleCount = 0.0;
        for(float x = 0.0; x < 1.0; x += 0.05) {
          for(float yOffset = -5.0; yOffset <= 5.0; yOffset += 1.0) {
            vec2 topSample = vec2(x, topY + yOffset * texelSize.y);
            vec2 midSample = vec2(x, midY + yOffset * texelSize.y);
            vec2 bottomSample = vec2(x, bottomY + yOffset * texelSize.y);
            
            // Clamp all sample coordinates to texture bounds
            topSample = clamp(topSample, vec2(0.0), vec2(1.0));
            midSample = clamp(midSample, vec2(0.0), vec2(1.0));
            bottomSample = clamp(bottomSample, vec2(0.0), vec2(1.0));
            
            topColor += texture2D(u_image, topSample).rgb;
            midColor += texture2D(u_image, midSample).rgb;
            bottomColor += texture2D(u_image, bottomSample).rgb;
            sampleCount += 1.0;
          }
        }
        
        topColor /= sampleCount;
        midColor /= sampleCount;
        bottomColor /= sampleCount;
        
        vec3 sampledGradient;
        if (gradientPosition < 0.1) {
          sampledGradient = topColor;
        } else if (gradientPosition > 0.9) {
          sampledGradient = bottomColor;
        } else {
          float transitionPos = (gradientPosition - 0.1) / 0.8;
          if (transitionPos < 0.5) {
            float t = transitionPos * 2.0;
            sampledGradient = mix(topColor, midColor, t);
          } else {
            float t = (transitionPos - 0.5) * 2.0;
            sampledGradient = mix(midColor, bottomColor, t);
          }
        }
        
        vec3 finalTinted = mix(color.rgb, sampledGradient, u_tintOpacity * 0.3);
        color = vec4(finalTinted, color.a);
        
        // Shape mask (rounded rectangle, circle, or pill)
        float maskDistance;
        if (isPill(u_resolution, u_borderRadius)) {
          maskDistance = pillDistance(coord, u_resolution, u_borderRadius);
        } else if (isCircle(u_resolution, u_borderRadius)) {
          maskDistance = circleDistance(coord, u_resolution, u_borderRadius);
        } else {
          maskDistance = selectiveRoundedRectDistance(coord, u_resolution, u_borderRadius, u_roundedCorners);
        }
        float mask = 1.0 - smoothstep(-1.0, 1.0, maskDistance);
        
        gl_FragColor = vec4(color.rgb, mask);
      }
    `

    const program = this.createProgram(gl, vsSource, fsSource)
    if (!program) return

    gl.useProgram(program)

    // Set up geometry
    const positionBuffer = gl.createBuffer()
    gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer)
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 1, -1, -1, 1, -1, 1, 1, -1, 1, 1]), gl.STATIC_DRAW)

    const texcoordBuffer = gl.createBuffer()
    gl.bindBuffer(gl.ARRAY_BUFFER, texcoordBuffer)
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([0, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 0]), gl.STATIC_DRAW)

    // Get locations
    const positionLoc = gl.getAttribLocation(program, 'a_position')
    const texcoordLoc = gl.getAttribLocation(program, 'a_texcoord')
    const resolutionLoc = gl.getUniformLocation(program, 'u_resolution')
    const textureSizeLoc = gl.getUniformLocation(program, 'u_textureSize')
    const scrollYLoc = gl.getUniformLocation(program, 'u_scrollY')
    const pageHeightLoc = gl.getUniformLocation(program, 'u_pageHeight')
    const viewportHeightLoc = gl.getUniformLocation(program, 'u_viewportHeight')
    const blurRadiusLoc = gl.getUniformLocation(program, 'u_blurRadius')
    const borderRadiusLoc = gl.getUniformLocation(program, 'u_borderRadius')
    const containerPositionLoc = gl.getUniformLocation(program, 'u_containerPosition')
    const warpLoc = gl.getUniformLocation(program, 'u_warp')
    const edgeIntensityLoc = gl.getUniformLocation(program, 'u_edgeIntensity')
    const rimIntensityLoc = gl.getUniformLocation(program, 'u_rimIntensity')
    const baseIntensityLoc = gl.getUniformLocation(program, 'u_baseIntensity')
    const edgeDistanceLoc = gl.getUniformLocation(program, 'u_edgeDistance')
    const rimDistanceLoc = gl.getUniformLocation(program, 'u_rimDistance')
    const baseDistanceLoc = gl.getUniformLocation(program, 'u_baseDistance')
    const cornerBoostLoc = gl.getUniformLocation(program, 'u_cornerBoost')
    const rippleEffectLoc = gl.getUniformLocation(program, 'u_rippleEffect')
    const tintOpacityLoc = gl.getUniformLocation(program, 'u_tintOpacity')
    const imageLoc = gl.getUniformLocation(program, 'u_image')
    const roundedCornersLoc = gl.getUniformLocation(program, 'u_roundedCorners')

    // Create texture
    const texture = gl.createTexture()
    gl.bindTexture(gl.TEXTURE_2D, texture)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)

    // Debug: Check texture creation
    console.log('[Container Debug] Texture creation:', {
      imageWidth: image.width,
      imageHeight: image.height,
      imageSrc: image.src.substring(0, 100) + '...', // First 100 chars of data URL
      textureCreated: !!texture,
      glError: gl.getError()
    })
    
    // Debug: Test texture by reading pixels from different locations
    try {
      const framebuffer = gl.createFramebuffer()
      gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer)
      gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0)
      
      if (gl.checkFramebufferStatus(gl.FRAMEBUFFER) === gl.FRAMEBUFFER_COMPLETE) {
        // Sample pixels from different locations
        const locations = [
          {name: 'top-left (0,0)', x: 0, y: 0},
          {name: 'center', x: Math.floor(image.width/2), y: Math.floor(image.height/2)},
          {name: 'bottom-right', x: image.width-1, y: image.height-1},
          {name: 'quarter-way', x: Math.floor(image.width/4), y: Math.floor(image.height/4)}
        ]
        
        for (const loc of locations) {
          const pixels = new Uint8Array(4) // RGBA for 1 pixel
          gl.readPixels(loc.x, loc.y, 1, 1, gl.RGBA, gl.UNSIGNED_BYTE, pixels)
          console.log(`[Container Debug] Texture pixel sample ${loc.name} (${loc.x},${loc.y}):`, {
            r: pixels[0],
            g: pixels[1], 
            b: pixels[2],
            a: pixels[3]
          })
        }
      } else {
        console.warn('[Container Debug] Framebuffer not complete for texture reading')
      }
      
      gl.bindFramebuffer(gl.FRAMEBUFFER, null)
      gl.deleteFramebuffer(framebuffer)
    } catch (error) {
      console.warn('[Container Debug] Could not read texture pixels:', error)
    }

    // Store references
    this.gl_refs = {
      gl,
      texture,
      textureSizeLoc,
      scrollYLoc,
      positionLoc,
      texcoordLoc,
      resolutionLoc,
      pageHeightLoc,
      viewportHeightLoc,
      blurRadiusLoc,
      borderRadiusLoc,
      containerPositionLoc,
      warpLoc,
      edgeIntensityLoc,
      rimIntensityLoc,
      baseIntensityLoc,
      edgeDistanceLoc,
      rimDistanceLoc,
      baseDistanceLoc,
      cornerBoostLoc,
      rippleEffectLoc,
      tintOpacityLoc,
      imageLoc,
      roundedCornersLoc,
      positionBuffer,
      texcoordBuffer,
      // Store texture dimensions for later use
      textureWidth: image.width,
      textureHeight: image.height
    }

    // Set up viewport and attributes
    console.log('Setting up WebGL viewport:', {
      canvasWidth: this.canvas.width,
      canvasHeight: this.canvas.height,
      elementWidth: this.width,
      elementHeight: this.height
    })
    
    // Ensure canvas has proper dimensions
    if (this.canvas.width === 0 || this.canvas.height === 0) {
      console.warn('Canvas has zero dimensions, forcing size update')
      this.canvas.width = this.width || 300
      this.canvas.height = this.height || 200
    }
    
    gl.viewport(0, 0, this.canvas.width, this.canvas.height)
    gl.clearColor(0, 0, 0, 0)

    gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer)
    gl.enableVertexAttribArray(positionLoc)
    gl.vertexAttribPointer(positionLoc, 2, gl.FLOAT, false, 0, 0)

    gl.bindBuffer(gl.ARRAY_BUFFER, texcoordBuffer)
    gl.enableVertexAttribArray(texcoordLoc)
    gl.vertexAttribPointer(texcoordLoc, 2, gl.FLOAT, false, 0, 0)

    // Set uniforms
    gl.uniform2f(resolutionLoc, this.canvas.width, this.canvas.height)
    gl.uniform2f(textureSizeLoc, image.width, image.height)
    
    // Debug: Log texture and canvas dimensions
    console.log('[Container Debug] Shader setup:', {
      canvasWidth: this.canvas.width,
      canvasHeight: this.canvas.height,
      textureWidth: image.width,
      textureHeight: image.height,
      borderRadius: this.borderRadius,
      tintOpacity: this.tintOpacity
    })
    
    gl.uniform1f(blurRadiusLoc, window.glassControls?.blurRadius || 5.0)
    gl.uniform1f(borderRadiusLoc, this.borderRadius)
    gl.uniform1f(warpLoc, this.warp ? 1.0 : 0.0)
    gl.uniform1f(edgeIntensityLoc, window.glassControls?.edgeIntensity || 0.01)
    gl.uniform1f(rimIntensityLoc, window.glassControls?.rimIntensity || 0.05)
    gl.uniform1f(baseIntensityLoc, window.glassControls?.baseIntensity || 0.01)
    gl.uniform1f(edgeDistanceLoc, window.glassControls?.edgeDistance || 0.15)
    gl.uniform1f(rimDistanceLoc, window.glassControls?.rimDistance || 0.8)
    gl.uniform1f(baseDistanceLoc, window.glassControls?.baseDistance || 0.1)
    gl.uniform1f(cornerBoostLoc, window.glassControls?.cornerBoost || 0.02)
    gl.uniform1f(rippleEffectLoc, window.glassControls?.rippleEffect || 0.1)
    gl.uniform1f(tintOpacityLoc, this.tintOpacity)
    
    // Set rounded corners uniform
    gl.uniform4f(roundedCornersLoc, 
      this.roundedCorners.topLeft ? 1.0 : 0.0,
      this.roundedCorners.topRight ? 1.0 : 0.0, 
      this.roundedCorners.bottomLeft ? 1.0 : 0.0,
      this.roundedCorners.bottomRight ? 1.0 : 0.0
    )

    // Set initial position (will be updated in render loop)
    const position = this.getPosition()
    const initialScrollY = window.pageYOffset || document.documentElement.scrollTop || 0
    const initialPageX = position.x
    const initialPageY = position.y + initialScrollY
    
    // Debug: Log initial position setup
    console.log('[Container Debug] Initial position setup:', {
      viewportX: position.x,
      viewportY: position.y,
      scrollY: initialScrollY,
      pageX: initialPageX,
      pageY: initialPageY
    })
    
    gl.uniform2f(containerPositionLoc, initialPageX, initialPageY)

    const pageHeight = Math.max(document.body.scrollHeight, document.documentElement.scrollHeight)
    const viewportHeight = window.innerHeight
    gl.uniform1f(pageHeightLoc, pageHeight)
    gl.uniform1f(viewportHeightLoc, viewportHeight)

    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, texture)
    gl.uniform1i(imageLoc, 0)

    // Start rendering
    this.startRenderLoop()
  }

  startRenderLoop() {
    const render = () => {
      if (!this.gl_refs.gl || this.isDestroyed) return

      const gl = this.gl_refs.gl
      gl.clear(gl.COLOR_BUFFER_BIT)

      // Update scroll position - compatible with Locomotive Scroll
      let scrollY = 0
      if (window.locomotiveScroll && window.locomotiveScroll.scroll) {
        // Locomotive Scroll instance
        scrollY = window.locomotiveScroll.scroll.instance.scroll.y || 0
      } else if (window.pageYOffset !== undefined) {
        // Fallback to native scroll
        scrollY = window.pageYOffset || document.documentElement.scrollTop || 0
      }
      
      gl.uniform1f(this.gl_refs.scrollYLoc, scrollY)

      // Get container position in viewport
      const position = this.getPosition()
      
      // Calculate the base page position (where the container is in the full page)
      let pageX = position.x
      let pageY = position.y + scrollY
      
      // IMPORTANT: For texture sampling, we want the ACTUAL position of the container
      // in the page, not any parallax-adjusted position. The parallax effects should
      // only affect WHERE the container is rendered, not WHAT part of the page it shows.
      
      // If this container itself has parallax (moves at different speed than scroll)
      if (this.isParallaxElement && this.parallaxSpeed !== 1.0) {
        // The container's actual position in the page is different from where it appears
        // We need to reverse the parallax calculation to find the true page position
        const parallaxOffset = scrollY * (1.0 - this.parallaxSpeed)
        // Remove the parallax offset to get the original page position
        pageY = position.y + scrollY - parallaxOffset
        
        if (Math.random() < 0.01) {
          console.log('[Container Debug] Parallax element position correction:', {
            viewportY: position.y,
            scrollY: scrollY,
            apparentPageY: position.y + scrollY,
            parallaxOffset: parallaxOffset,
            truePageY: pageY
          })
        }
      }
      
      // Background parallax compensation should NOT affect the texture coordinates
      // It should only be used if we want the glass to "stick" to a parallax background
      // This is a visual effect decision, not a coordinate mapping issue
      
      if (this.syncWithParallax && this.backgroundParallaxSpeed !== 1.0) {
        // This is for visual effect only - making the glass appear to be part of
        // a parallax background layer. It should NOT change the basic coordinate mapping.
        // Commenting this out for now as it's likely causing the issue
        /*
        const parallaxOffset = scrollY * this.backgroundParallaxSpeed * 0.1
        pageY = position.y + scrollY + parallaxOffset
        */
      }
      
      // Debug: Verify texture coordinate mapping
      if (Math.random() < 0.01) {
        // Get the actual texture dimensions from the stored texture size uniform
        const textureWidth = this.gl_refs.textureWidth || Container.pageSnapshot?.width || 1
        const textureHeight = this.gl_refs.textureHeight || Container.pageSnapshot?.height || 1
        const viewportHeight = window.innerHeight
        const pageHeight = Math.max(
          document.body.scrollHeight,
          document.documentElement.scrollHeight
        )
        
        // At scroll = 0, a container at viewport top should map to texture coord 0
        // At max scroll, a container at viewport bottom should map to texture coord 1
        const maxScroll = pageHeight - viewportHeight
        const expectedBottomY = maxScroll + viewportHeight
        const currentBottomY = scrollY + viewportHeight
        
        console.log('[Container Debug] Texture coordinate check:', {
          scrollY: scrollY,
          containerPageY: pageY,
          textureWidth: textureWidth,
          textureHeight: textureHeight,
          pageHeight: pageHeight,
          viewportHeight: viewportHeight,
          maxScroll: maxScroll,
          currentBottomY: currentBottomY,
          expectedBottomY: expectedBottomY,
          textureCoordY: pageY / textureHeight,
          bottomTextureCoord: currentBottomY / textureHeight,
          isAtBottom: Math.abs(scrollY - maxScroll) < 10
        })
      }
      
      gl.uniform2f(this.gl_refs.containerPositionLoc, pageX, pageY)

      gl.drawArrays(gl.TRIANGLES, 0, 6)
    }

    // Initial render
    render()

    // Set up continuous rendering for glass effect
    const animationLoop = () => {
      if (this.isDestroyed) return
      render()
      this._animationId = requestAnimationFrame(animationLoop)
    }
    
    // Start the animation loop
    animationLoop()

    // Enhanced scroll handling for Locomotive Scroll
    const scrollHandler = () => {
      if (!this.isDestroyed) {
        render()
      }
    }

    // Native scroll event (fallback)
    window.addEventListener('scroll', scrollHandler, { passive: true })
    
    // Locomotive Scroll events - try multiple approaches
    if (window.locomotiveScroll) {
      if (typeof window.locomotiveScroll.on === 'function') {
        window.locomotiveScroll.on('scroll', scrollHandler)
      }
    }
    
    // Also listen for locomotive scroll events on document
    document.addEventListener('locomotive-scroll', scrollHandler, { passive: true })

    // Store handlers for cleanup
    this._scrollHandler = scrollHandler
    this._hasLocomotiveScroll = !!window.locomotiveScroll

    // Store render function for external calls
    this.render = render
  }

  destroy() {
    if (this.isDestroyed) return
    
    this.isDestroyed = true
    
    // Disconnect intersection observer
    if (this.intersectionObserver) {
      this.intersectionObserver.disconnect()
      this.intersectionObserver = null
    }
    
    // Cancel animation loop
    if (this._animationId) {
      cancelAnimationFrame(this._animationId)
    }
    
    // Clean up resize observer
    if (this.resizeObserver) {
      this.resizeObserver.disconnect()
      this.resizeObserver = null
    }
    
    // Clean up resize timeout
    if (this.resizeTimeout) {
      clearTimeout(this.resizeTimeout)
      this.resizeTimeout = null
    }
    
    // Remove from instances array
    const index = Container.instances.indexOf(this)
    if (index > -1) {
      Container.instances.splice(index, 1)
    }
    
    // Clean up WebGL resources
    if (this.gl_refs.gl) {
      const gl = this.gl_refs.gl
      if (this.gl_refs.texture) {
        gl.deleteTexture(this.gl_refs.texture)
      }
      if (this.gl_refs.positionBuffer) {
        gl.deleteBuffer(this.gl_refs.positionBuffer)
      }
      if (this.gl_refs.texcoordBuffer) {
        gl.deleteBuffer(this.gl_refs.texcoordBuffer)
      }
    }
    
    // Remove event listeners
    if (this._scrollHandler) {
      window.removeEventListener('scroll', this._scrollHandler)
      document.removeEventListener('locomotive-scroll', this._scrollHandler)
      
      // Clean up Locomotive Scroll listeners
      if (this._hasLocomotiveScroll && window.locomotiveScroll) {
        if (typeof window.locomotiveScroll.off === 'function') {
          window.locomotiveScroll.off('scroll', this._scrollHandler)
        }
      }
    }
    
    // Clean up children
    for (const child of this.children) {
      if (child.destroy) {
        child.destroy()
      }
    }
    this.children = []
    
    // Clear references
    this.gl_refs = {}
    this.gl = null
    this.canvas = null
    this.element = null
  }

  setupIntersectionObserver() {
    if (!this.element) return

    const options = {
      root: null, // Use the viewport as the root
      rootMargin: '0px',
      threshold: 0.01 // Trigger when at least 1% of the element is visible
    }

    this.intersectionObserver = new IntersectionObserver((entries, observer) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          // Element is visible, proceed with WebGL initialization
          console.log('Container is visible, initializing WebGL...')
          this.handleVisibility()
          // Stop observing once it's visible to avoid re-triggering
          observer.unobserve(this.element)
        }
      })
    }, options)

    this.intersectionObserver.observe(this.element)
  }

  handleVisibility() {
    // Debounced snapshot logic
    const initAction = () => {
      if (Container.pageSnapshot && !Container.isDestroying) {
        this.initWebGL()
      } else if (Container.isCapturing) {
        Container.waitingForSnapshot.push(this)
      } else if (!Container.isDestroying) {
        Container.isCapturing = true
        Container.waitingForSnapshot.push(this)
        
        // Use requestIdleCallback for smarter scheduling
        if ('requestIdleCallback' in window) {
          requestIdleCallback(() => this.capturePageSnapshot(), { timeout: 2000 })
        } else {
          setTimeout(() => this.capturePageSnapshot(), 200) // Fallback
        }
      }
    }
    
    // A small delay to ensure animations/transitions are complete
    setTimeout(initAction, 100)
  }

  _handleSidebarResize() {
    // Check if this container is inside a sidebar and needs to resize
    if (this.element && this.element.closest('.sidebar')) {
      console.log('Sidebar resize detected, updating container size')
      this.updateSizeFromDOM()
      
      // Update WebGL viewport if initialized
      if (this.webglInitialized && this.gl && this.canvas) {
        this.gl.viewport(0, 0, this.canvas.width, this.canvas.height)
        this.gl.uniform2f(this.gl_refs.resolutionLoc, this.canvas.width, this.canvas.height)
      }
    }
  }

  setupSidebarResizeObserver() {
    // Set up ResizeObserver to detect when the container size changes
    if (typeof ResizeObserver !== 'undefined' && this.element) {
      this.resizeObserver = new ResizeObserver(entries => {
        for (const entry of entries) {
          if (entry.target === this.element) {
            // Debounce resize handling
            clearTimeout(this.resizeTimeout)
            this.resizeTimeout = setTimeout(() => {
              this._handleSidebarResize()
            }, 50)
          }
        }
      })
      
      this.resizeObserver.observe(this.element)
    }
  }

  static setupGlobalEventHandlers() {
    // Set up global resize handler with debouncing (like the author's implementation)
    if (!Container._globalHandlersSetup) {
      Container._globalHandlersSetup = true
      
      window.addEventListener('resize', Container._handleGlobalResize)
      
      // Handle Turbo navigation for Hotwire compatibility
      document.addEventListener('turbo:before-cache', Container._handleTurboBeforeCache)
      document.addEventListener('turbo:load', Container._handleTurboLoad)
    }
  }

  static isDevelopmentMode() {
    return import.meta.hot || window.__vite_is_modern_browser || process.env.NODE_ENV === 'development'
  }

  static _handleGlobalResize() {
    // In development, increase debounce delay to reduce captures during hot reload
    const debounceDelay = Container.isDevelopmentMode() ? 1000 : 300
    
    // Debounce resize events to avoid excessive recapturing (like author's implementation)
    clearTimeout(Container.resizeTimeout)
    Container.resizeTimeout = setTimeout(() => {
      console.log('Window resized, recapturing page snapshot...')
      Container._recapturePageSnapshot()
    }, debounceDelay)
  }

  static _handleTurboBeforeCache() {
    // Clean up before Turbo caches the page
    Container.isDestroying = true
    for (const instance of Container.instances) {
      if (!instance.isDestroyed) {
        instance.destroy()
      }
    }
    Container.instances = []
  }

  static _handleTurboLoad() {
    // Reset state after Turbo navigation
    Container.isDestroying = false
    Container.pageSnapshot = null
    Container.isCapturing = false
    Container.waitingForSnapshot = []
  }

  static _recapturePageSnapshot() {
    if (Container.isCapturing || Container.isDestroying) return
    
    // Debounce captures to prevent excessive calling
    const now = Date.now()
    if (now - Container.lastCaptureTime < Container.captureDebounceDelay) {
      console.log('Skipping page recapture - too soon since last capture')
      return
    }
    
    Container.lastCaptureTime = now
    
    // Reset snapshot state
    Container.pageSnapshot = null
    Container.isCapturing = true
    Container.waitingForSnapshot = Container.instances.slice() // All instances need update

    // Get full page dimensions for recapture
    const pageHeight = Math.max(
      document.body.scrollHeight,
      document.body.offsetHeight,
      document.documentElement.clientHeight,
      document.documentElement.scrollHeight,
      document.documentElement.offsetHeight
    )
    const pageWidth = Math.max(
      document.body.scrollWidth,
      document.body.offsetWidth,
      document.documentElement.clientWidth,
      document.documentElement.scrollWidth,
      document.documentElement.offsetWidth
    )

    // Recapture page snapshot
    html2canvas(document.body, {
      scale: 1,
      useCORS: true,
      allowTaint: true,
      backgroundColor: null,
      width: pageWidth,
      height: pageHeight,
      // Don't force scroll position - capture from current position
      // scrollX: 0,
      // scrollY: 0,
      ignoreElements: function (element) {
        // Ignore all glass elements
        return (
          element.classList.contains('glass-container') ||
          element.classList.contains('glass-button') ||
          element.classList.contains('glass-button-text')
        )
      }
    })
      .then(snapshot => {
        console.log(`Page snapshot recaptured after resize: ${snapshot.width}x${snapshot.height}`)
        Container.pageSnapshot = snapshot
        Container.isCapturing = false

        // Create new image and update all glass instances
        const img = new Image()
        img.src = snapshot.toDataURL()
        img.onload = () => {
          for (const instance of Container.instances) {
            if (instance.gl_refs && instance.gl_refs.gl && !instance.isDestroyed) {
              // Update with new page snapshot
              const gl = instance.gl_refs.gl
              gl.bindTexture(gl.TEXTURE_2D, instance.gl_refs.texture)
              gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, img)

              // Update texture size uniform
              gl.uniform2f(instance.gl_refs.textureSizeLoc, img.width, img.height)

              // Force re-render
              if (instance.render) {
                instance.render()
              }
            }
            
            // Update nested glass children
            for (const child of instance.children) {
              if (child.gl_refs && child.gl_refs.gl && child.isNestedGlass) {
                const gl = child.gl_refs.gl
                const containerCanvas = instance.canvas

                // Resize the button's texture to match new container canvas size
                gl.bindTexture(gl.TEXTURE_2D, child.gl_refs.texture)
                gl.texImage2D(
                  gl.TEXTURE_2D,
                  0,
                  gl.RGBA,
                  containerCanvas.width,
                  containerCanvas.height,
                  0,
                  gl.RGBA,
                  gl.UNSIGNED_BYTE,
                  null
                )

                // Update texture size uniform to new container dimensions
                gl.uniform2f(child.gl_refs.textureSizeLoc, containerCanvas.width, containerCanvas.height)

                // Update container size uniform for sampling calculations
                if (child.gl_refs.containerSizeLoc) {
                  gl.uniform2f(child.gl_refs.containerSizeLoc, instance.width, instance.height)
                }

                console.log(`Updated nested button texture: ${containerCanvas.width}x${containerCanvas.height}`)

                // Force re-render for nested glass
                if (child.render) {
                  child.render()
                }
              }
            }
          }
        }

        // Clear waiting queue
        Container.waitingForSnapshot = []
      })
      .catch(error => {
        console.error('html2canvas error on resize:', error)
        Container.isCapturing = false
        Container.waitingForSnapshot = []
      })
  }

  _handleResize() {
    if (this.isDestroyed) return
    this.updateSizeFromDOM()
  }

  _handleScroll() {
    if (this.isDestroyed || !this.render) return
    this.render()
  }

  createProgram(gl, vsSource, fsSource) {
    const vs = this.compileShader(gl, gl.VERTEX_SHADER, vsSource)
    const fs = this.compileShader(gl, gl.FRAGMENT_SHADER, fsSource)
    if (!vs || !fs) return null

    const program = gl.createProgram()
    gl.attachShader(program, vs)
    gl.attachShader(program, fs)
    gl.linkProgram(program)

    if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
      console.error('Program link error:', gl.getProgramInfoLog(program))
      return null
    }

    return program
  }

  compileShader(gl, type, source) {
    const shader = gl.createShader(type)
    gl.shaderSource(shader, source)
    gl.compileShader(shader)
    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
      console.error('Shader compile error:', gl.getShaderInfoLog(shader))
      return null
    }
    return shader
  }

  // ...existing code...
}

export { Container }