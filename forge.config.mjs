// NOTE: Do NOT load v8-compile-cache in the Electron Forge config process.
// Under Node 25, it can break Vite's CJS shim (vite/index.cjs) which uses dynamic import,
// leading to: ERR_VM_DYNAMIC_IMPORT_CALLBACK_MISSING.
import { FusesPlugin } from "@electron-forge/plugin-fuses";
import { FuseV1Options, FuseVersion } from "@electron/fuses";

const isDevStart =
    process.env.LIBREVERSE_FORGE_DEV === "1" ||
    process.env.LIBREVERSE_FORGE_DEV === "true";

export default {
    packagerConfig: {
        asar: true,
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
            name: "@electron-forge/plugin-vite",
            config: {
                build: [
                    {
                        entry: "src/index.js",
                        config: "config/electron/vite.main.config.mjs",
                    },
                    {
                        entry: "src/preload.js",
                        config: "config/electron/vite.preload.config.mjs",
                    },
                ],
                renderer: [
                    {
                        name: "main_window",
                        config: "config/electron/vite.renderer.config.mjs",
                    },
                ],
            },
        },
        ...(isDevStart
            ? []
            : [
                  {
                      name: "@electron-forge/plugin-auto-unpack-natives",
                      config: {},
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
              ]),
    ],
};
