const { FusesPlugin } = require("@electron-forge/plugin-fuses");
const { FuseV1Options, FuseVersion } = require("@electron/fuses");

module.exports = {
    packagerConfig: {
        asar: true,
        // Bundle mimalloc as a non-ASAR resource so it can be preloaded via DYLD_INSERT_LIBRARIES.
        // The dylib is staged locally into ./mimalloc by scripts/prepare_mimalloc.rb.
        extraResource: ["mimalloc"],
    },
    rebuildConfig: {},
    makers: [
        {
            name: "@electron-forge/maker-squirrel",
            config: {},
        },
        {
            name: "@electron-forge/maker-zip",
            platforms: ["darwin"],
        },
        {
            name: "@electron-forge/maker-deb",
            config: {},
        },
        {
            name: "@electron-forge/maker-rpm",
            config: {},
        },
    ],
    plugins: [
        {
            name: "@electron-forge/plugin-auto-unpack-natives",
            config: {},
        },
        {
            name: "@electron-forge/plugin-vite",
            config: {
                build: [
                    {
                        entry: "src/index.js",
                        config: "config/electron/vite.main.config.js",
                    },
                    {
                        entry: "src/preload.js",
                        config: "config/electron/vite.preload.config.js",
                    },
                ],
                renderer: [
                    {
                        name: "main_window",
                        config: "config/electron/vite.renderer.config.js",
                    },
                ],
            },
        },
        // Fuses are used to enable/disable various Electron functionality
        // at package time, before code signing the application
        new FusesPlugin({
            version: FuseVersion.V1,
            [FuseV1Options.RunAsNode]: false,
            [FuseV1Options.EnableCookieEncryption]: true,
            [FuseV1Options.EnableNodeOptionsEnvironmentVariable]: false,
            [FuseV1Options.EnableNodeCliInspectArguments]: false,
            [FuseV1Options.EnableEmbeddedAsarIntegrityValidation]: true,
            [FuseV1Options.OnlyLoadAppFromAsar]: true,
        }),
    ],
};
