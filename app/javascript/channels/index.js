// Load all the channels within this directory and all subdirectories
// This import is executed for its side effects only
(() => {
    import.meta.glob("./**/*_channel.js", { eager: true });
})();
