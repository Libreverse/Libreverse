import * as babel from '@babel/core';
import path from 'path';
import fs from 'fs';
import { spawn } from 'child_process';

const babelOptions = {
  presets: [
    ['@babel/preset-env', {
      targets: {
        ie: "11"
      },
      useBuiltIns: false,
      modules: false
    }]
  ]
};

const config = {
  entrypoints: ["app/javascript/application.js"],
  outdir: path.join(process.cwd(), "app/assets/builds"),
  minify: true,
  sourcemap: "external",
  plugins: [{
    name: "babel",
    setup(build) {
      build.onLoad({ filter: /\.js$/ }, async (args) => {
        const source = await fs.promises.readFile(args.path, 'utf8');
        const { code } = await babel.transformAsync(source, {
          ...babelOptions,
          filename: args.path,
        });
        return { contents: code };
      });
    },
  }],
};

const buildCSS = () => {
  return new Promise((resolve, reject) => {
    const process = spawn('bun', ['run', 'build:css'], { stdio: 'inherit' });
    process.on('close', (code) => {
      if (code === 0) {
        console.log('CSS build succeeded');
        resolve();
      } else {
        console.error('CSS build failed');
        reject();
      }
    });
  });
};

const build = async () => {
  const result = await Bun.build(config);
  if (!result.success) {
    console.error("JS build failed");
    for (const message of result.logs) {
      console.error(message);
    }
  } else {
    console.log("JS build succeeded");
    await buildCSS();
  }
};

(async () => {
  await build();

  if (process.argv.includes('--watch')) {
    console.log("Watching for changes...");
    fs.watch(path.join(process.cwd(), "app/javascript"), { recursive: true }, async (eventType, filename) => {
      console.log(`File changed: ${filename}. Rebuilding...`);
      await build();
    });

    fs.watch(path.join(process.cwd(), "app/assets/stylesheets"), { recursive: true }, async (eventType, filename) => {
      if (filename.endsWith('.css')) {
        console.log(`CSS file changed: ${filename}. Rebuilding CSS...`);
        await buildCSS();
      }
    });
  } else {
    process.exit(0);
  }
})();