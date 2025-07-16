// Debounced Configuration Manager for Glass Components
class GlassConfigManager {
    constructor() {
        this.pendingUpdates = new Map();
        this.updateTimers = new Map();
        this.defaultDebounceTime = 300; // 300ms debounce for config changes
        this.batchUpdateTimer = undefined;
        this.batchSize = 5; // Maximum updates to process in one batch
    }

    // Schedule a debounced update for a glass component
    scheduleUpdate(
        element,
        updateFunction,
        debounceTime = this.defaultDebounceTime,
    ) {
        // Clear existing timer
        if (this.updateTimers.has(element)) {
            clearTimeout(this.updateTimers.get(element));
        }

        // Store the update function
        this.pendingUpdates.set(element, updateFunction);

        // Set new timer
        const timer = setTimeout(() => {
            this.processUpdate(element);
        }, debounceTime);

        this.updateTimers.set(element, timer);
    }

    // Process a single update
    processUpdate(element) {
        const updateFunction = this.pendingUpdates.get(element);
        if (updateFunction) {
            try {
                updateFunction();
            } catch (error) {
                console.error(
                    "[GlassConfigManager] Error processing update:",
                    error,
                );
            }

            this.pendingUpdates.delete(element);
            this.updateTimers.delete(element);
        }
    }

    // Batch process multiple updates for better performance
    scheduleBatchUpdate(updates) {
        // Cancel existing batch timer
        if (this.batchUpdateTimer) {
            clearTimeout(this.batchUpdateTimer);
        }

        // Add updates to pending
        for (const { element, updateFn } of updates) {
            this.pendingUpdates.set(element, updateFn);
        }

        // Process batch after debounce
        this.batchUpdateTimer = setTimeout(() => {
            this.processBatch();
        }, this.defaultDebounceTime);
    }

    // Process updates in batches to avoid overwhelming the browser
    processBatch() {
        const updates = [...this.pendingUpdates.entries()];
        const batches = [];

        // Split into batches
        for (let index = 0; index < updates.length; index += this.batchSize) {
            batches.push(updates.slice(index, index + this.batchSize));
        }

        // Process batches with RAF to avoid blocking
        let batchIndex = 0;
        const processNextBatch = () => {
            if (batchIndex < batches.length) {
                const batch = batches[batchIndex];

                for (const [, updateFunction] of batch) {
                    try {
                        updateFunction();
                    } catch (error) {
                        console.error(
                            "[GlassConfigManager] Error in batch update:",
                            error,
                        );
                    }
                }

                batchIndex++;
                requestAnimationFrame(processNextBatch);
            }
        };

        if (batches.length > 0) {
            requestAnimationFrame(processNextBatch);
        }

        // Clear pending updates
        this.pendingUpdates.clear();
        this.updateTimers.clear();
    }

    // Cancel all pending updates for an element
    cancelUpdates(element) {
        if (this.updateTimers.has(element)) {
            clearTimeout(this.updateTimers.get(element));
            this.updateTimers.delete(element);
        }
        this.pendingUpdates.delete(element);
    }

    // Get stats about pending updates
    getStats() {
        return {
            pendingUpdates: this.pendingUpdates.size,
            activeTimers: this.updateTimers.size,
            batchMode: !!this.batchUpdateTimer,
        };
    }

    // Clean up for element removal
    cleanup(element) {
        this.cancelUpdates(element);
    }

    // Destroy the manager
    destroy() {
        // Cancel all timers
        for (const timer of this.updateTimers.values()) {
            clearTimeout(timer);
        }

        if (this.batchUpdateTimer) {
            clearTimeout(this.batchUpdateTimer);
        }

        this.pendingUpdates.clear();
        this.updateTimers.clear();
    }
}

// Global singleton instance
export const glassConfigManager = new GlassConfigManager();
