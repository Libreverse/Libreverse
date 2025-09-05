// Keyboard lock handler for iframes
(function () {
    // Store original keyboard lock methods
    const originalLock = navigator.keyboard && navigator.keyboard.lock;
    const originalUnlock = navigator.keyboard && navigator.keyboard.unlock;

    // Override keyboard lock to communicate with parent
    if (navigator.keyboard) {
        navigator.keyboard.lock = function (keyCodes) {
            // Try to call from iframe first (might work in some cases)
            if (originalLock) {
                try {
                    return originalLock.call(this, keyCodes);
                } catch (error) {
                    console.warn("Direct keyboard lock failed:", error.message);
                }
            }

            // Fallback: request parent to lock keyboard
            return globalThis.parent && globalThis.parent !== globalThis
                ? new Promise((resolve, reject) => {
                      const messageId = Date.now() + Math.random();

                      const messageHandler = (event) => {
                          // Add origin check for security
                          if (event.origin !== globalThis.location.origin) {
                              return;
                          }
                          if (
                              event.data.type === "keyboard-lock-response" &&
                              event.data.messageId === messageId
                          ) {
                              globalThis.removeEventListener(
                                  "message",
                                  messageHandler,
                              );
                              if (event.data.success) {
                                  resolve();
                              } else {
                                  reject(
                                      new Error(
                                          event.data.error ||
                                              "Keyboard lock failed",
                                      ),
                                  );
                              }
                          }
                      };

                      globalThis.addEventListener("message", messageHandler);

                      // Request parent to lock keyboard
                      globalThis.parent.postMessage(
                          {
                              type: "keyboard-lock-request",
                              messageId: messageId,
                              keyCodes: keyCodes,
                          },
                          globalThis.location.origin,
                      );

                      // Timeout after 5 seconds
                      setTimeout(() => {
                          globalThis.removeEventListener(
                              "message",
                              messageHandler,
                          );
                          reject(new Error("Keyboard lock request timeout"));
                      }, 5000);
                  })
                : Promise.reject(
                      new Error("No parent window available for keyboard lock"),
                  );
        };

        navigator.keyboard.unlock = function () {
            // Try to call from iframe first
            if (originalUnlock) {
                try {
                    return originalUnlock.call(this);
                } catch (error) {
                    console.warn(
                        "Direct keyboard unlock failed:",
                        error.message,
                    );
                }
            }

            // Fallback: request parent to unlock keyboard
            if (globalThis.parent && globalThis.parent !== globalThis) {
                globalThis.parent.postMessage(
                    {
                        type: "keyboard-unlock-request",
                    },
                    globalThis.location.origin,
                );
            }
        };
    }

    // Listen for responses from parent
    globalThis.addEventListener("message", (event) => {
        // Verify origin for security
        if (event.origin !== globalThis.location.origin) {
            return;
        }
        if (event.data.type === "keyboard-lock-response") {
            // Response handled by the promise resolver above
        }
    });
})();
