import { Container } from "./container.js";

class Button extends Container {
    constructor(options = {}) {
        const text = options.text === undefined ? "Button" : options.text;
        const fontSize = Number.parseInt(options.size) || 48;
        const onClick = options.onClick || undefined;
        const type = options.type || "rounded"; // "rounded", "circle", or "pill"
        const warp = options.warp === undefined ? false : options.warp; // Center warping disabled by default
        const tintOpacity =
            options.tintOpacity === undefined ? 0.2 : options.tintOpacity;
        const iconHTML = options.iconHTML || undefined;

        // Call parent constructor (border radius will be set in setSizeFromText)
        super({
            borderRadius: fontSize,
            type: type,
            tintOpacity: tintOpacity,
        });

        this.text = text;
        this.fontSize = fontSize;
        this.onClick = onClick;
        this.type = type;
        this.warp = warp;
        this.parent = undefined; // Will be set if added to container
        this.isNestedGlass = false;
        this.iconHTML = iconHTML;
        this.isDestroyed = false;
        this._clickHandler = undefined;
        this._renderLoopId = undefined;

        // Add button-specific styling and content
        this.element.classList.add("glass-button");
        this.element.style.position = "relative";
        this.element.style.cursor = "pointer";
        this.element.style.pointerEvents = "auto"; // Ensure clicks work
        if (this.type === "circle") {
            this.element.classList.add("glass-button-circle");
        }
        this.createTextElement();
        this.setupClickHandler();
        this.setSizeFromText();
    }

    setSizeFromText() {
        let width, height;

        // Handle different button types
        if (this.type === "circle") {
            // For circles, use consistent sizing with pill buttons
            const circleSize = this.fontSize * 2.2; // Match pill button sizing
            width = circleSize;
            height = circleSize;
            this.borderRadius = circleSize / 2; // 50% for perfect circle

            // Force exact square dimensions for circles
            this.element.style.width = width + "px";
            this.element.style.height = height + "px";
            this.element.style.minWidth = width + "px";
            this.element.style.minHeight = height + "px";
            this.element.style.maxWidth = width + "px";
            this.element.style.maxHeight = height + "px";
        } else if (this.type === "pill") {
            // For pill buttons in sidebar, force perfect circles regardless of content
            if (!this.text || this.text.trim() === "") {
                // Icon-only button: force perfect circle
                const size = Math.ceil(this.fontSize * 2.2); // Slightly larger for better proportions
                width = size;
                height = size;
                this.borderRadius = size / 2; // Perfect circle
            } else {
                const textMetrics = Button.measureText(
                    this.text,
                    this.fontSize,
                );
                width = Math.ceil(textMetrics.width + this.fontSize * 2);
                height = Math.ceil(this.fontSize + this.fontSize * 1.2); // Slightly less padding for pills
                this.borderRadius = height / 2; // Half height for perfect capsule proportions
            }
            this.element.style.minWidth = width + "px";
            this.element.style.minHeight = height + "px";
        } else {
            // For rounded buttons, calculate dimensions from text
            if (!this.text || this.text.trim() === "") {
                // Icon-only button: use reasonable dimensions for sidebar
                width = Math.ceil(this.fontSize * 1.8); // Reduced from 2.5
                height = Math.ceil(this.fontSize * 1.8); // Reduced from 2.5
                this.borderRadius = this.fontSize * 0.5; // Smaller border radius
            } else {
                const textMetrics = Button.measureText(
                    this.text,
                    this.fontSize,
                );
                width = Math.ceil(textMetrics.width + this.fontSize * 2);
                height = Math.ceil(this.fontSize + this.fontSize * 1.5);
                this.borderRadius = this.fontSize;
            }
            this.element.style.minWidth = width + "px";
            this.element.style.minHeight = height + "px";
        }

        // Apply border radius to element
        this.element.style.borderRadius = this.borderRadius + "px";

        // Update canvas border radius to match
        if (this.canvas) {
            this.canvas.style.borderRadius = this.borderRadius + "px";
        }

        // For circles and pills, set internal dimensions directly to ensure shader gets exact dimensions
        if (this.type === "circle") {
            this.width = width;
            this.height = height;

            // Update canvas to exact square dimensions for perfect circle rendering
            if (this.canvas) {
                this.canvas.width = width;
                this.canvas.height = height;
                this.canvas.style.width = width + "px";
                this.canvas.style.height = height + "px";

                // Update WebGL viewport if initialized
                if (this.gl_refs.gl) {
                    this.gl_refs.gl.viewport(0, 0, width, height);
                    this.gl_refs.gl.uniform2f(
                        this.gl_refs.resolutionLoc,
                        width,
                        height,
                    );
                    this.gl_refs.gl.uniform1f(
                        this.gl_refs.borderRadiusLoc,
                        this.borderRadius,
                    );
                }
            }
        } else if (this.type === "pill") {
            this.width = width;
            this.height = height;

            // Force exact pill dimensions for perfect capsule rendering
            this.element.style.width = width + "px";
            this.element.style.height = height + "px";
            this.element.style.maxWidth = width + "px";
            this.element.style.maxHeight = height + "px";

            if (this.canvas) {
                this.canvas.width = width;
                this.canvas.height = height;
                this.canvas.style.width = width + "px";
                this.canvas.style.height = height + "px";

                // Update WebGL viewport if initialized
                if (this.gl_refs.gl) {
                    this.gl_refs.gl.viewport(0, 0, width, height);
                    this.gl_refs.gl.uniform2f(
                        this.gl_refs.resolutionLoc,
                        width,
                        height,
                    );
                    this.gl_refs.gl.uniform1f(
                        this.gl_refs.borderRadiusLoc,
                        this.borderRadius,
                    );
                }
            }
        } else {
            // Update size from DOM after CSS applies
            this.updateSizeFromDOM();
        }
    }

    setupAsNestedGlass() {
        if (this.parent && !this.isNestedGlass) {
            this.isNestedGlass = true;
            // Reinitialize with nested glass shader when parent is ready
            if (this.webglInitialized) {
                this.initWebGL();
            }
        }
    }

    static measureText(text, fontSize) {
        const canvas = document.createElement("canvas");
        const context = canvas.getContext("2d");
        context.font = `${fontSize}px system-ui, -apple-system, sans-serif`;
        return context.measureText(text);
    }

    createTextElement() {
        console.log(
            "Creating text element with text:",
            JSON.stringify(this.text),
            "iconHTML:",
            !!this.iconHTML,
        );

        this.textElement = document.createElement("div");
        this.textElement.className = "glass-button-text";
        this.textElement.style.position = "relative";
        this.textElement.style.display = "flex";
        this.textElement.style.alignItems = "center";
        this.textElement.style.justifyContent = "center";
        this.textElement.style.width = "100%";
        this.textElement.style.height = "100%";
        this.textElement.style.zIndex = "2"; // Above canvas
        this.textElement.style.pointerEvents = "none"; // Let clicks pass through to button element

        if (this.iconHTML) {
            // Insert the SVG icon directly without any modifications
            const temporary = document.createElement("div");
            temporary.innerHTML = this.iconHTML;
            // Move all SVGs (if multiple) to the text element without changing them
            for (const svg of temporary.querySelectorAll("svg")) {
                this.textElement.append(svg);
            }
        }

        // Only add text if it's not empty
        if (this.text && this.text.trim() !== "") {
            console.log("Adding text node:", this.text);
            this.textElement.append(document.createTextNode(this.text));
        } else {
            console.log("Skipping text node - text is empty or whitespace");
        }

        this.textElement.style.fontSize = this.fontSize + "px";
        this.element.append(this.textElement);
    }

    setupClickHandler() {
        if (this.onClick && this.element) {
            this._clickHandler = (event) => {
                event.preventDefault();
                event.stopPropagation();
                console.log(
                    "Button clicked:",
                    this.text || "icon-only",
                    "onClick:",
                    typeof this.onClick,
                );
                if (typeof this.onClick === "function") {
                    this.onClick(this.text);
                }
            };
            this.element.addEventListener("click", this._clickHandler);
            this.element.addEventListener("touchstart", this._clickHandler, {
                passive: false,
            });

            // Debug: verify click handler is attached
            console.log(
                "Click handler attached to button:",
                this.text || "icon-only",
                "element:",
                this.element,
            );
        } else {
            console.warn(
                "No onClick handler provided for button:",
                this.text || "icon-only",
            );
        }
    }

    // Override initWebGL to choose between standalone and nested glass
    initWebGL() {
        if (!Container.pageSnapshot || !this.gl) return;

        if (this.parent && this.isNestedGlass) {
            // Use nested glass (parent container's texture)
            this.initNestedGlass();
        } else {
            // Use standalone glass (page snapshot)
            super.initWebGL();
        }
    }

    initNestedGlass() {
        if (!this.parent.webglInitialized) {
            // Parent not ready, wait and try again
            setTimeout(() => this.initNestedGlass(), 100);
            return;
        }

        // Parent is ready, set up nested glass
        this.setupDynamicNestedShader();
        this.webglInitialized = true;
    }

    setupDynamicNestedShader() {
        const gl = this.gl;

        const vsSource = `
      attribute vec2 a_position;
      attribute vec2 a_texcoord;
      varying vec2 v_texcoord;

      void main() {
        gl_Position = vec4(a_position, 0, 1);
        v_texcoord = a_texcoord;
      }
    `;

        const fsSource = `
      precision mediump float;
      uniform sampler2D u_image;
      uniform vec2 u_resolution;
      uniform vec2 u_textureSize;
      uniform float u_blurRadius;
      uniform float u_borderRadius;
      uniform vec2 u_buttonPosition;
      uniform vec2 u_containerPosition;
      uniform vec2 u_containerSize;
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
        
        // Calculate button position within container space
        vec2 buttonSize = u_resolution;
        vec2 containerSize = u_containerSize;
        
        // Convert screen positions to container-relative coordinates
        // Container position is center, convert to top-left
        vec2 containerTopLeft = u_containerPosition - containerSize * 0.5;
        vec2 buttonTopLeft = u_buttonPosition - buttonSize * 0.5;
        
        // Get button's position relative to container's top-left
        vec2 buttonRelativePos = buttonTopLeft - containerTopLeft;
        
        // Current pixel position within the button (0 to buttonSize)
        vec2 buttonPixel = coord * buttonSize;
        
        // Absolute pixel position in container space
        vec2 containerPixel = buttonRelativePos + buttonPixel;
        
        // Convert to texture coordinates (0 to 1)
        vec2 baseTextureCoord = containerPixel / containerSize;
        
        // BUTTON'S SOPHISTICATED GLASS EFFECTS on top of container's glass
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
          distFromEdgeShape = -roundedRectDistance(coord, u_resolution, u_borderRadius);
          vec2 center = vec2(0.5, 0.5);
          shapeNormal = normalize(coord - center);
        }
        distFromEdgeShape = max(distFromEdgeShape, 0.0);
        
        float distFromLeft = coord.x;
        float distFromRight = 1.0 - coord.x;
        float distFromTop = coord.y;
        float distFromBottom = 1.0 - coord.y;
        float distFromEdge = distFromEdgeShape / min(u_resolution.x, u_resolution.y);
        
        // MULTI-LAYER BUTTON GLASS REFRACTION using shape-aware normal
        float normalizedDistance = distFromEdge * min(u_resolution.x, u_resolution.y);
        float baseIntensity = 1.0 - exp(-normalizedDistance * u_baseDistance);
        float edgeIntensity = exp(-normalizedDistance * u_edgeDistance);
        float rimIntensity = exp(-normalizedDistance * u_rimDistance);
        
        // Apply center warping only if warp is enabled, keep edge and rim effects always
        float baseComponent = u_warp > 0.5 ? baseIntensity * u_baseIntensity : 0.0;
        float totalIntensity = baseComponent + edgeIntensity * u_edgeIntensity + rimIntensity * u_rimIntensity;
        
        vec2 baseRefraction = shapeNormal * totalIntensity;
        
        // Corner enhancement for buttons
        float cornerProximityX = min(distFromLeft, distFromRight);
        float cornerProximityY = min(distFromTop, distFromBottom);
        float cornerDistance = max(cornerProximityX, cornerProximityY);
        float cornerNormalized = cornerDistance * min(u_resolution.x, u_resolution.y);
        
        float cornerBoost = exp(-cornerNormalized * 0.3) * u_cornerBoost;
        vec2 cornerRefraction = shapeNormal * cornerBoost;
        
        // Button ripple texture
        vec2 perpendicular = vec2(-shapeNormal.y, shapeNormal.x);
        float rippleEffect = sin(distFromEdge * 30.0) * u_rippleEffect * rimIntensity;
        vec2 textureRefraction = perpendicular * rippleEffect;
        
        vec2 totalRefraction = baseRefraction + cornerRefraction + textureRefraction;
        vec2 textureCoord = baseTextureCoord + totalRefraction;
        
        // HIGH-QUALITY BUTTON BLUR on container texture
        vec4 color = vec4(0.0);
        vec2 texelSize = 1.0 / containerSize;
        float sigma = u_blurRadius / 3.0; // More substantial blur
        vec2 blurStep = texelSize * sigma;
        
        float totalWeight = 0.0;
        
        // 9x9 blur for buttons (more samples for quality)
        for(float i = -4.0; i <= 4.0; i += 1.0) {
          for(float j = -4.0; j <= 4.0; j += 1.0) {
            float distance = length(vec2(i, j));
            if(distance > 4.0) continue;
            
            float weight = exp(-(distance * distance) / (2.0 * sigma * sigma));
            
            vec2 offset = vec2(i, j) * blurStep;
            color += texture2D(u_image, textureCoord + offset) * weight;
            totalWeight += weight;
          }
        }
        
        color /= totalWeight;
        
        // BUTTON'S OWN GRADIENT LAYERS (same sophistication as container)
        float gradientPosition = coord.y;
        
        // Primary button gradient
        vec3 topTint = vec3(1.0, 1.0, 1.0);
        vec3 bottomTint = vec3(0.7, 0.7, 0.7);
        vec3 gradientTint = mix(topTint, bottomTint, gradientPosition);
        vec3 tintedColor = mix(color.rgb, gradientTint, u_tintOpacity * 0.7);
        color = vec4(tintedColor, color.a);
        
        // SECOND BUTTON GRADIENT - sampling from container's texture for variation
        vec2 viewportCenter = u_buttonPosition;
        float topY = max(0.0, (viewportCenter.y - buttonSize.y * 0.4) / containerSize.y);
        float midY = viewportCenter.y / containerSize.y;
        float bottomY = min(1.0, (viewportCenter.y + buttonSize.y * 0.4) / containerSize.y);
        
        vec3 topColor = texture2D(u_image, vec2(0.5, topY)).rgb;
        vec3 midColor = texture2D(u_image, vec2(0.5, midY)).rgb;
        vec3 bottomColor = texture2D(u_image, vec2(0.5, bottomY)).rgb;
        
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
        
        vec3 secondTinted = mix(color.rgb, sampledGradient, u_tintOpacity * 0.4);
        
        // Button highlighting/shadow system
        vec3 buttonTopTint = vec3(1.08, 1.08, 1.08);    
        vec3 buttonBottomTint = vec3(0.92, 0.92, 0.92); 
        vec3 buttonGradient = mix(buttonTopTint, buttonBottomTint, gradientPosition);
        vec3 finalTinted = secondTinted * buttonGradient;
        
        // Shape mask (rounded rectangle, circle, or pill)
        float maskDistance;
        if (isPill(u_resolution, u_borderRadius)) {
          maskDistance = pillDistance(coord, u_resolution, u_borderRadius);
        } else if (isCircle(u_resolution, u_borderRadius)) {
          maskDistance = circleDistance(coord, u_resolution, u_borderRadius);
        } else {
          maskDistance = roundedRectDistance(coord, u_resolution, u_borderRadius);
        }
        float mask = 1.0 - smoothstep(-1.0, 1.0, maskDistance);
        
        gl_FragColor = vec4(finalTinted, mask);
      }
    `;

        const program = this.createProgram(gl, vsSource, fsSource);
        if (!program) return;

        gl.useProgram(program);

        // Set up geometry (same as parent)
        const positionBuffer = gl.createBuffer();
        gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
        gl.bufferData(
            gl.ARRAY_BUFFER,
            new Float32Array([-1, -1, 1, -1, -1, 1, -1, 1, 1, -1, 1, 1]),
            gl.STATIC_DRAW,
        );

        const texcoordBuffer = gl.createBuffer();
        gl.bindBuffer(gl.ARRAY_BUFFER, texcoordBuffer);
        gl.bufferData(
            gl.ARRAY_BUFFER,
            new Float32Array([0, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 0]),
            gl.STATIC_DRAW,
        );

        // Get locations
        const positionLoc = gl.getAttribLocation(program, "a_position");
        const texcoordLoc = gl.getAttribLocation(program, "a_texcoord");
        const resolutionLoc = gl.getUniformLocation(program, "u_resolution");
        const textureSizeLoc = gl.getUniformLocation(program, "u_textureSize");
        const blurRadiusLoc = gl.getUniformLocation(program, "u_blurRadius");
        const borderRadiusLoc = gl.getUniformLocation(
            program,
            "u_borderRadius",
        );
        const buttonPositionLoc = gl.getUniformLocation(
            program,
            "u_buttonPosition",
        );
        const containerPositionLoc = gl.getUniformLocation(
            program,
            "u_containerPosition",
        );
        const containerSizeLoc = gl.getUniformLocation(
            program,
            "u_containerSize",
        );
        const warpLoc = gl.getUniformLocation(program, "u_warp");
        const edgeIntensityLoc = gl.getUniformLocation(
            program,
            "u_edgeIntensity",
        );
        const rimIntensityLoc = gl.getUniformLocation(
            program,
            "u_rimIntensity",
        );
        const baseIntensityLoc = gl.getUniformLocation(
            program,
            "u_baseIntensity",
        );
        const edgeDistanceLoc = gl.getUniformLocation(
            program,
            "u_edgeDistance",
        );
        const rimDistanceLoc = gl.getUniformLocation(program, "u_rimDistance");
        const baseDistanceLoc = gl.getUniformLocation(
            program,
            "u_baseDistance",
        );
        const cornerBoostLoc = gl.getUniformLocation(program, "u_cornerBoost");
        const rippleEffectLoc = gl.getUniformLocation(
            program,
            "u_rippleEffect",
        );
        const tintOpacityLoc = gl.getUniformLocation(program, "u_tintOpacity");
        const imageLoc = gl.getUniformLocation(program, "u_image");

        // Create texture that will be updated dynamically from container canvas
        const texture = gl.createTexture();
        gl.bindTexture(gl.TEXTURE_2D, texture);

        // Initialize with parent container's current canvas size
        const containerCanvas = this.parent.canvas;
        gl.texImage2D(
            gl.TEXTURE_2D,
            0,
            gl.RGBA,
            containerCanvas.width,
            containerCanvas.height,
            0,
            gl.RGBA,
            gl.UNSIGNED_BYTE,
            // eslint-disable-next-line unicorn/no-null -- WebGL API requires null for empty texture data
            null,
        );
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);

        // Store references
        this.gl_refs = {
            gl,
            texture,
            textureSizeLoc,
            positionLoc,
            texcoordLoc,
            resolutionLoc,
            blurRadiusLoc,
            borderRadiusLoc,
            buttonPositionLoc,
            containerPositionLoc,
            containerSizeLoc,
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
            positionBuffer,
            texcoordBuffer,
        };

        // Set up viewport and attributes
        gl.viewport(0, 0, this.canvas.width, this.canvas.height);
        gl.clearColor(0, 0, 0, 0);

        gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
        gl.enableVertexAttribArray(positionLoc);
        gl.vertexAttribPointer(positionLoc, 2, gl.FLOAT, false, 0, 0);

        gl.bindBuffer(gl.ARRAY_BUFFER, texcoordBuffer);
        gl.enableVertexAttribArray(texcoordLoc);
        gl.vertexAttribPointer(texcoordLoc, 2, gl.FLOAT, false, 0, 0);

        // Set uniforms
        gl.uniform2f(resolutionLoc, this.canvas.width, this.canvas.height);
        gl.uniform2f(
            textureSizeLoc,
            containerCanvas.width,
            containerCanvas.height,
        );
        gl.uniform1f(blurRadiusLoc, globalThis.glassControls?.blurRadius || 2); // Controlled blur for sharpness
        gl.uniform1f(borderRadiusLoc, this.borderRadius);
        gl.uniform1f(warpLoc, this.warp ? 1 : 0);
        gl.uniform1f(
            edgeIntensityLoc,
            globalThis.glassControls?.edgeIntensity || 0.01,
        );
        gl.uniform1f(
            rimIntensityLoc,
            globalThis.glassControls?.rimIntensity || 0.05,
        );
        gl.uniform1f(
            baseIntensityLoc,
            globalThis.glassControls?.baseIntensity || 0.01,
        );
        gl.uniform1f(
            edgeDistanceLoc,
            globalThis.glassControls?.edgeDistance || 0.15,
        );
        gl.uniform1f(
            rimDistanceLoc,
            globalThis.glassControls?.rimDistance || 0.8,
        );
        gl.uniform1f(
            baseDistanceLoc,
            globalThis.glglassControls?.baseDistance || 0.1,
        );
        gl.uniform1f(
            cornerBoostLoc,
            globalThis.glassControls?.cornerBoost || 0.02,
        );
        gl.uniform1f(
            rippleEffectLoc,
            globalThis.glassControls?.rippleEffect || 0.1,
        );
        gl.uniform1f(tintOpacityLoc, this.tintOpacity);

        // Set positions
        const buttonPosition = this.getPosition();
        const containerPosition = this.parent.getPosition();
        gl.uniform2f(buttonPositionLoc, buttonPosition.x, buttonPosition.y);
        gl.uniform2f(
            containerPositionLoc,
            containerPosition.x,
            containerPosition.y,
        );
        gl.uniform2f(containerSizeLoc, this.parent.width, this.parent.height);

        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, texture);
        gl.uniform1i(imageLoc, 0);

        // Start rendering
        this.startNestedRenderLoop();
    }

    startNestedRenderLoop() {
        const render = () => {
            if (!this.gl_refs.gl || !this.parent || this.isDestroyed) return;

            const gl = this.gl_refs.gl;

            // UPDATE TEXTURE FROM PARENT CONTAINER'S CURRENT RENDERED OUTPUT
            const containerCanvas = this.parent.canvas;
            gl.bindTexture(gl.TEXTURE_2D, this.gl_refs.texture);
            gl.texSubImage2D(
                gl.TEXTURE_2D,
                0,
                0,
                0,
                gl.RGBA,
                gl.UNSIGNED_BYTE,
                containerCanvas,
            );

            gl.clear(gl.COLOR_BUFFER_BIT);

            // Update button and container positions (in case layout changed)
            const buttonPosition = this.getPosition();
            const containerPosition = this.parent.getPosition();
            gl.uniform2f(
                this.gl_refs.buttonPositionLoc,
                buttonPosition.x,
                buttonPosition.y,
            );
            gl.uniform2f(
                this.gl_refs.containerPositionLoc,
                containerPosition.x,
                containerPosition.y,
            );

            gl.drawArrays(gl.TRIANGLES, 0, 6);
        };

        // Render every frame to keep sampling parent's live output
        const animationLoop = () => {
            if (this.isDestroyed) return;
            render();
            this._renderLoopId = requestAnimationFrame(animationLoop);
        };

        animationLoop();

        // Store render function for external calls
        this.render = render;
    }

    destroy() {
        if (this.isDestroyed) return;

        this.isDestroyed = true;

        // Clean up WebGL resources
        if (this.gl_refs.gl) {
            const gl = this.gl_refs.gl;
            if (this.gl_refs.texture) {
                gl.deleteTexture(this.gl_refs.texture);
            }
            if (this.gl_refs.positionBuffer) {
                gl.deleteBuffer(this.gl_refs.positionBuffer);
            }
            if (this.gl_refs.texcoordBuffer) {
                gl.deleteBuffer(this.gl_refs.texcoordBuffer);
            }
        }

        // Remove from parent
        if (this.parent) {
            this.remove();
        }

        // Remove event listeners
        if (this.element && this._clickHandler) {
            this.element.removeEventListener("click", this._clickHandler);
            this.element.removeEventListener("touchstart", this._clickHandler);
            this._clickHandler = undefined;
        }

        // Cancel any pending render loops
        if (this._renderLoopId) {
            cancelAnimationFrame(this._renderLoopId);
        }

        // Clear references
        this.gl_refs = {};
        this.gl = undefined;
        this.canvas = undefined;
        this.element = undefined;
        this.parent = undefined;
    }

    createProgram(gl, vsSource, fsSource) {
        const vs = this.compileShader(gl, gl.VERTEX_SHADER, vsSource);
        const fs = this.compileShader(gl, gl.FRAGMENT_SHADER, fsSource);
        if (!vs || !fs) return;

        const program = gl.createProgram();
        gl.attachShader(program, vs);
        gl.attachShader(program, fs);
        gl.linkProgram(program);

        if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
            console.error("Program link error:", gl.getProgramInfoLog(program));
            return;
        }

        return program;
    }

    compileShader(gl, type, source) {
        const shader = gl.createShader(type);
        gl.shaderSource(shader, source);
        gl.compileShader(shader);
        if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
            console.error("Shader compile error:", gl.getShaderInfoLog(shader));
            return;
        }
        return shader;
    }
}

// Do NOT export Container from this file, only export Button
export { Button };
