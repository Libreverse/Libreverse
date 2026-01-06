// vite.config.mjs
import "file:///Users/george/Libreverse/node_modules/.pnpm/v8-compile-cache@2.4.0/node_modules/v8-compile-cache/v8-compile-cache.js";
import { defineConfig } from "file:///Users/george/Libreverse/node_modules/vite/dist/node/index.js";
import path from "node:path";
import fs2 from "node:fs";
import { execSync } from "node:child_process";
import { viteStaticCopy } from "file:///Users/george/Libreverse/node_modules/vite-plugin-static-copy/dist/index.js";
import rubyPlugin from "file:///Users/george/Libreverse/node_modules/vite-plugin-ruby/dist/index.js";
import fullReload from "file:///Users/george/Libreverse/node_modules/.pnpm/vite-plugin-full-reload@1.2.0/node_modules/vite-plugin-full-reload/dist/index.js";
import stimulusHMR from "file:///Users/george/Libreverse/node_modules/.pnpm/vite-plugin-stimulus-hmr@3.0.0/node_modules/vite-plugin-stimulus-hmr/dist/index.js";
import babel from "file:///Users/george/Libreverse/node_modules/vite-plugin-babel/dist/index.mjs";
import postcssInlineRtl from "file:///Users/george/Libreverse/node_modules/.pnpm/postcss-inline-rtl@0.9.8/node_modules/postcss-inline-rtl/index.js";
import cssnano from "file:///Users/george/Libreverse/node_modules/.pnpm/cssnano@7.1.1_postcss@8.5.6/node_modules/cssnano/src/index.js";
import postcssUrl from "file:///Users/george/Libreverse/node_modules/.pnpm/postcss-url@10.1.3_postcss@8.5.6/node_modules/postcss-url/src/index.js";

// plugins/coffeescript.js
import CoffeeScript from "file:///Users/george/Libreverse/node_modules/.pnpm/coffeescript@2.7.0/node_modules/coffeescript/lib/coffeescript/index.js";
function coffeescript(userOptions = {}) {
  const baseOptions = {
    bare: true,
    sourceMap: false
  };
  return {
    name: "coffeescript",
    enforce: "pre",
    transform(code, id) {
      if (!id.endsWith(".coffee")) return;
      const options = { ...baseOptions, ...userOptions, filename: id };
      try {
        const compiled = CoffeeScript.compile(code, options);
        if (typeof compiled === "string") {
          return { code: compiled, map: void 0 };
        }
        const map = compiled.v3SourceMap || compiled.sourceMap || void 0;
        return { code: compiled.js, map };
      } catch (error) {
        this.error(error);
      }
    }
  };
}

// plugins/typehints.js
import * as ts from "file:///Users/george/Libreverse/node_modules/.pnpm/typescript@5.9.3/node_modules/typescript/lib/typescript.js";
import { parse } from "file:///Users/george/Libreverse/node_modules/.pnpm/@babel+parser@7.28.4/node_modules/@babel/parser/lib/index.js";
import traverseModule from "file:///Users/george/Libreverse/node_modules/.pnpm/@babel+traverse@7.28.4/node_modules/@babel/traverse/lib/index.js";
import generateModule from "file:///Users/george/Libreverse/node_modules/.pnpm/@babel+generator@7.28.5/node_modules/@babel/generator/lib/index.js";
import templateModule from "file:///Users/george/Libreverse/node_modules/@babel/template/lib/index.js";
import * as t from "file:///Users/george/Libreverse/node_modules/@babel/types/lib/index.js";
import fs from "node:fs";
var traverse = (
  /** @type {any} */
  (typeof traverseModule === "function" ? traverseModule : (
    /** @type {any} */
    traverseModule && traverseModule.default
  )) || /** fallback noop to avoid hard crash */
  function() {
  }.bind()
);
var generate = (
  /** @type {any} */
  typeof generateModule === "function" ? generateModule : (
    /** @type {any} */
    generateModule && generateModule.default
  )
);
var template = (
  /** @type {any} */
  typeof templateModule === "function" ? templateModule : (
    /** @type {any} */
    templateModule && templateModule.default
  )
);
function compactError(error, id) {
  try {
    const name = error?.name || "Error";
    const baseMessage = error?.message ? String(error.message) : String(error);
    const firstLine = baseMessage.split("\n")[0].slice(0, 300);
    const loc = error?.loc && typeof error.loc.line === "number" ? ` (${error.loc.line}:${error.loc.column ?? 0})` : "";
    let out = `[vite-plugin-v8-type-hints-with-ts] ${name}${loc} in ${id}: ${firstLine}`;
    if (error?.stack) {
      const frames = String(error.stack).split("\n").slice(1).filter(
        (l) => !l.includes("node:internal") && !l.includes("node_modules")
      ).slice(0, 2);
      if (frames.length > 0) out += "\n" + frames.join("\n");
    }
    const MAX = 600;
    if (out.length > MAX) out = out.slice(0, MAX) + "\u2026";
    return out;
  } catch {
    return `[vite-plugin-v8-type-hints-with-ts] Error in ${id}`;
  }
}
function getParameterName(parameter) {
  return t.isIdentifier(parameter) ? parameter.name : "param";
}
function ensureContext(context) {
  return context || {
    depth: 0,
    seen: /* @__PURE__ */ new Set(),
    maxDepth: 3,
    maxProps: 20
  };
}
function tsTypeToJSDocument(checker, type, context) {
  context = ensureContext(context);
  if (!type) return "any";
  if (context.depth > context.maxDepth) return "any";
  try {
    const id = checker.typeToString(type);
    if (context.seen.has(id)) return "any";
    context.seen.add(id);
  } catch {
  }
  const typeString = checker.typeToString(type);
  if (typeString === "number") return "number";
  if (typeString === "string") return "string";
  if (typeString === "boolean") return "boolean";
  try {
    if (checker.isArrayLikeType && checker.isArrayLikeType(type)) {
      const elementType = checker.getArrayElementType && checker.getArrayElementType(type) || checker.getElementTypeOfArrayType && checker.getElementTypeOfArrayType(type) || void 0;
      const element = elementType ? tsTypeToJSDocument(checker, elementType, {
        ...context,
        depth: context.depth + 1
      }) : "any";
      return `${element}[]`;
    }
  } catch {
  }
  if ((type.flags & ts.TypeFlags.Object) !== 0) {
    return "object";
  }
  if (type.getCallSignatures && type.getCallSignatures().length > 0)
    return "Function";
  return typeString || "any";
}
function addTypeCoercion(path2, typeString) {
  if (typeString !== "number") return false;
  const node = path2.node;
  let targetNode = node.init || node.argument || node.expression || node.left;
  if (!targetNode) return false;
  const build = template.expression("((EXPR)) | 0");
  const coerced = build({ EXPR: targetNode });
  if (node.init) node.init = coerced;
  if (node.argument) node.argument = coerced;
  if (node.expression) node.expression = coerced;
  if (node.left) node.left = coerced;
  return true;
}
function typehints(options = {}) {
  const {
    includeNodeModules = true,
    enableCoercions = true,
    processEverything = true,
    // Preferred option names (backward compatible mapping applied below)
    variableDocumentation = options.variableDocumentation ?? options.variableDocs ?? true,
    objectShapeDocumentation = options.objectShapeDocumentation ?? options.objectShapeDocs ?? true,
    maxObjectProperties = options.maxObjectProperties ?? options.maxObjectProps ?? 8,
    parameterHoistCoercions = options.parameterHoistCoercions ?? options.paramHoistCoercions ?? false
  } = options;
  let isBuild = false;
  return {
    name: "vite-plugin-v8-type-hints-with-ts",
    // Only run during static builds
    apply: "build",
    configResolved(config) {
      isBuild = config.command === "build";
    },
    async transform(code, id) {
      if (!isBuild) return;
      const cleanId = String(id).split("?")[0];
      if (!/\.([cm]?jsx?)$/i.test(cleanId)) return;
      if (!processEverything && !includeNodeModules && cleanId.includes("node_modules"))
        return;
      const MAX_FILE_BYTES = 15e4;
      if (!processEverything) {
        if (code && code.length > MAX_FILE_BYTES) return;
        if (cleanId.includes("/app/javascript/libs/")) return;
        if (cleanId.includes("/dist/") || /\.min\.js$/i.test(cleanId))
          return;
      }
      try {
        let addBlockDocument2 = function(pathOrNode, text) {
          if (!text) return;
          const node = pathOrNode.node || pathOrNode;
          const existing = (node.leadingComments || []).some(
            (c) => c.type === "CommentBlock" && (c.value.includes("@type") || c.value.includes("@returns"))
          );
          if (existing) return;
          if (pathOrNode.addComment) {
            pathOrNode.addComment("leading", `! ${text}`, false);
          } else {
            node.leadingComments = [
              ...node.leadingComments || [],
              { type: "CommentBlock", value: `! ${text}` }
            ];
          }
        }, inferObjectShape2 = function(babelObjectExpr) {
          if (!objectShapeDocumentation) return;
          if (!t.isObjectExpression(babelObjectExpr)) return;
          const properties = babelObjectExpr.properties.filter(
            (p) => t.isObjectProperty(p) && (t.isIdentifier(p.key) || t.isStringLiteral(p.key))
          );
          if (properties.length === 0 || properties.length > maxObjectProperties)
            return;
          const parts = [];
          for (const property of properties) {
            const key = t.isIdentifier(property.key) ? property.key.name : property.key.value;
            let valueNode = property.value;
            let typePart = "any";
            if (t.isNumericLiteral(valueNode)) typePart = "number";
            else if (t.isStringLiteral(valueNode))
              typePart = "string";
            else if (t.isBooleanLiteral(valueNode))
              typePart = "boolean";
            else if (t.isNullLiteral(valueNode)) typePart = "any";
            else if (t.isArrayExpression(valueNode)) {
              if (valueNode.elements.length === 0)
                typePart = "any[]";
              else {
                const first = valueNode.elements[0];
                if (t.isNumericLiteral(first))
                  typePart = "number[]";
                else if (t.isStringLiteral(first))
                  typePart = "string[]";
                else if (t.isBooleanLiteral(first))
                  typePart = "boolean[]";
                else typePart = "any[]";
              }
            } else if (t.isObjectExpression(valueNode))
              typePart = "object";
            else if (t.isTemplateLiteral(valueNode))
              typePart = "string";
            else if (t.isUnaryExpression(valueNode) && valueNode.operator === "+")
              typePart = "number";
            else if (t.isBinaryExpression(valueNode) && [
              "+",
              "-",
              "*",
              "/",
              "%",
              "|",
              "&",
              "^",
              "<<",
              ">>",
              ">>>"
            ].includes(valueNode.operator))
              typePart = "number";
            else if (t.isCallExpression(valueNode)) {
              if (t.isMemberExpression(valueNode.callee) && t.isIdentifier(valueNode.callee.object, {
                name: "Math"
              }))
                typePart = "number";
              else if (t.isIdentifier(valueNode.callee, {
                name: "Number"
              }))
                typePart = "number";
              else if (t.isIdentifier(valueNode.callee, {
                name: "String"
              }))
                typePart = "string";
              else if (t.isIdentifier(valueNode.callee, {
                name: "Boolean"
              }))
                typePart = "boolean";
            }
            parts.push(`${key}: ${typePart}`);
          }
          if (parts.length === 0) return;
          return `{ ${parts.join(", ")} }`;
        }, findTSNodeAtPosition2 = function(sourceFile2, pos) {
          let result;
          function visit(node) {
            if (pos < node.pos || pos >= node.end) return;
            result = node;
            node.forEachChild(visit);
          }
          visit(sourceFile2);
          return result;
        };
        var addBlockDocument = addBlockDocument2, inferObjectShape = inferObjectShape2, findTSNodeAtPosition = findTSNodeAtPosition2;
        let didChange = false;
        let bailOut = false;
        const compilerOptions = {
          allowJs: true,
          checkJs: true,
          noEmit: true,
          target: ts.ScriptTarget.Latest,
          module: ts.ModuleKind.ESNext,
          strict: false
        };
        const filePath = cleanId;
        const program = ts.createProgram([filePath], compilerOptions);
        const sourceFile = program.getSourceFile(filePath) || ts.createSourceFile(
          filePath,
          fs.existsSync(filePath) ? fs.readFileSync(filePath, "utf8") : code,
          ts.ScriptTarget.Latest,
          true,
          ts.ScriptKind.JS
        );
        const checker = program.getTypeChecker();
        const babelAst = parse(code, {
          sourceType: "module",
          plugins: [
            "jsx",
            "dynamicImport",
            "importMeta",
            // Babel 7 supports importAssertions; newer imports may need importAttributes in newer Babel
            "importAssertions",
            "topLevelAwait"
          ],
          sourceFilename: id
        });
        if (typeof traverse !== "function" || !template) {
          return;
        }
        const inferredVariableTypes = /* @__PURE__ */ new Map();
        traverse(babelAst, {
          FunctionDeclaration(path2) {
            if (!path2.node.id) return;
            const tsNode = findTSNodeAtPosition2(
              sourceFile,
              path2.node.id.start
            );
            if (!tsNode) return;
            let functionType;
            try {
              functionType = checker.getTypeAtLocation(tsNode);
            } catch {
              bailOut = true;
              return;
            }
            let sigs;
            try {
              sigs = checker.getSignaturesOfType ? checker.getSignaturesOfType(
                functionType,
                ts.SignatureKind.Call
              ) : functionType.getCallSignatures ? functionType.getCallSignatures() : [];
            } catch {
              bailOut = true;
              return;
            }
            const sig = sigs && sigs.length > 0 ? sigs[0] : void 0;
            if (!sig) return;
            let parameterTypes;
            try {
              parameterTypes = sig.parameters.map((parameter) => {
                const decl = parameter.valueDeclaration || parameter.declarations?.[0];
                const pType = decl ? checker.getTypeOfSymbolAtLocation(
                  parameter,
                  decl
                ) : void 0;
                return tsTypeToJSDocument(checker, pType);
              });
            } catch {
              bailOut = true;
              return;
            }
            let returnType = "any";
            try {
              returnType = tsTypeToJSDocument(
                checker,
                checker.getReturnTypeOfSignature(sig)
              );
            } catch {
            }
            const isMeaningful = returnType !== "any" || parameterTypes.some((t_) => t_ !== "any");
            if (!isMeaningful) return;
            const parameterDocumentation = path2.node.params.map(
              (parameter, index) => `@param {${parameterTypes[index] || "any"}} ${getParameterName(parameter)}`
            );
            const document_ = `! ${[...parameterDocumentation, `@returns {${returnType}}`].join(" ")}`;
            const existingLead = path2.node.leadingComments || [];
            const alreadyHasJSDocument = existingLead.some(
              (c) => c.type === "CommentBlock" && (c.value.includes("@returns") || c.value.startsWith("!"))
            );
            if (!alreadyHasJSDocument) {
              path2.addComment("leading", document_, false);
              didChange = true;
            }
            if (enableCoercions && parameterHoistCoercions && path2.node.body && Array.isArray(path2.node.params)) {
              const coercionStatements = [];
              let index = 0;
              for (const p of path2.node.params) {
                if (parameterTypes[index] === "number" && t.isIdentifier(p)) {
                  coercionStatements.push(
                    template.statement(
                      `${p.name} = (${p.name}) | 0;`
                    )()
                  );
                }
                index += 1;
              }
              if (coercionStatements.length > 0) {
                path2.node.body.body.unshift(
                  ...coercionStatements
                );
                didChange = true;
              }
            }
            if (enableCoercions) {
              path2.traverse({
                BinaryExpression(subPath) {
                  const parameterNode = path2.node.params.find(
                    (p) => t.isIdentifier(p) && t.isIdentifier(subPath.node.left) && p.name === subPath.node.left.name
                  );
                  if (parameterNode && parameterTypes[path2.node.params.indexOf(
                    parameterNode
                  )] === "number" && addTypeCoercion(subPath, "number"))
                    didChange = true;
                },
                ReturnStatement(subPath) {
                  if (subPath.node.argument && returnType === "number" && addTypeCoercion(subPath, "number"))
                    didChange = true;
                }
              });
            }
          },
          VariableDeclarator(path2) {
            const tsNode = findTSNodeAtPosition2(
              sourceFile,
              path2.node.id.start
            );
            if (!tsNode || !path2.node.init) return;
            let variableType;
            try {
              variableType = checker.getTypeAtLocation(tsNode);
            } catch {
              return;
            }
            const typeString = tsTypeToJSDocument(
              checker,
              variableType
            );
            if (t.isIdentifier(path2.node.id)) {
              inferredVariableTypes.set(
                path2.node.id.name,
                typeString
              );
            }
            if (variableDocumentation && t.isIdentifier(path2.node.id)) {
              let documentType = typeString;
              if (documentType === "object" && objectShapeDocumentation && t.isObjectExpression(path2.node.init)) {
                const shape = inferObjectShape2(path2.node.init);
                if (shape) documentType = shape;
              }
              if (t.isArrayExpression(path2.node.init)) {
                if (path2.node.init.elements.length === 0)
                  documentType = "any[]";
                else {
                  const first = path2.node.init.elements[0];
                  if (t.isNumericLiteral(first))
                    documentType = "number[]";
                  else if (t.isStringLiteral(first))
                    documentType = "string[]";
                  else if (t.isBooleanLiteral(first))
                    documentType = "boolean[]";
                  else documentType = "any[]";
                }
              }
              if (documentType && documentType !== "any") {
                addBlockDocument2(
                  path2,
                  `@type {${documentType}}`
                );
                didChange = true;
              }
            }
            if (enableCoercions && typeString === "number" && addTypeCoercion(path2, "number"))
              didChange = true;
          },
          ForOfStatement(path2) {
            let leftId;
            if (t.isVariableDeclaration(path2.node.left)) {
              const first = path2.node.left.declarations?.[0];
              if (first && t.isIdentifier(first.id))
                leftId = first.id;
            } else if (t.isIdentifier(path2.node.left)) {
              leftId = path2.node.left;
            }
            if (!leftId) return;
            const rightTSNode = findTSNodeAtPosition2(
              sourceFile,
              path2.node.right.start
            );
            if (!rightTSNode) return;
            let arrayType;
            try {
              arrayType = checker.getTypeAtLocation(rightTSNode);
            } catch {
              return;
            }
            let elementType;
            try {
              elementType = checker.getArrayElementType && checker.getArrayElementType(arrayType) || checker.getElementTypeOfArrayType && checker.getElementTypeOfArrayType(
                arrayType
              ) || void 0;
            } catch {
            }
            const elementString = tsTypeToJSDocument(
              checker,
              elementType
            );
            if (enableCoercions && elementString === "number") {
              path2.traverse({
                BinaryExpression(subPath) {
                  if (t.isIdentifier(subPath.node.left) && t.isIdentifier(leftId) && subPath.node.left.name === leftId.name && addTypeCoercion(subPath, "number"))
                    didChange = true;
                }
              });
            }
          },
          // Deopt warning: Dynamic props
          AssignmentExpression(path2) {
            if (path2.node.left?.computed && path2.node.left.property?.type !== "Identifier") {
              const line = path2.node.loc && path2.node.loc.start ? path2.node.loc.start.line : "?";
            }
          }
        });
        if (bailOut || !didChange) return;
        const { code: transformedCode, map } = generate(babelAst, {
          sourceMaps: true,
          sourceFileName: id
        });
        return {
          code: transformedCode,
          map
        };
      } catch (error) {
        const error_ = error instanceof Error ? error : new Error(String(error));
        if (isBuild) {
          this.error(compactError(error_, id));
        } else {
          console.error(compactError(error_, id));
        }
        return;
      }
    }
    // No HMR behavior; plugin only applies in build
  };
}

// vite.config.mjs
import postcssRemoveRoot from "file:///Users/george/Libreverse/node_modules/.pnpm/postcss-remove-root@0.0.2/node_modules/postcss-remove-root/index.js";
import cssMqpacker from "file:///Users/george/Libreverse/node_modules/.pnpm/css-mqpacker@7.0.0/node_modules/css-mqpacker/index.js";
import stylehacks from "file:///Users/george/Libreverse/node_modules/.pnpm/stylehacks@7.0.7_postcss@8.5.6/node_modules/stylehacks/src/index.js";
import postcssMqOptimize from "file:///Users/george/Libreverse/node_modules/.pnpm/postcss-mq-optimize@2.1.0_postcss@8.5.6/node_modules/postcss-mq-optimize/index.js";
import autoprefixer from "file:///Users/george/Libreverse/node_modules/.pnpm/autoprefixer@10.4.21_postcss@8.5.6/node_modules/autoprefixer/lib/autoprefixer.js";

// plugins/postcss-remove-prefix.js
function removePrefix() {
  return {
    postcssPlugin: "remove-prefix",
    Declaration(decl) {
      decl.prop = decl.prop.replace(/^-\w+-/, "");
    }
  };
}
removePrefix.postcss = true;
var postcss_remove_prefix_default = removePrefix;

// vite.config.mjs
import nodePolyfills from "file:///Users/george/Libreverse/node_modules/.pnpm/rollup-plugin-polyfill-node@0.13.0_rollup@4.53.4/node_modules/rollup-plugin-polyfill-node/dist/index.js";
import legacy from "file:///Users/george/Libreverse/node_modules/vite-plugin-legacy-swc/dist/index.js";
import vitePluginBundleObfuscator from "file:///Users/george/Libreverse/node_modules/vite-plugin-bundle-obfuscator/dist/index.mjs";
import { purgePolyfills } from "file:///Users/george/Libreverse/node_modules/.pnpm/unplugin-purge-polyfills@0.1.0/node_modules/unplugin-purge-polyfills/dist/index.js";
import replacements from "file:///Users/george/Libreverse/vendor/javascript/unplugin-replacements/lib/vite.js";

// config/vite/common.js
var allObfuscatorConfig = {
  excludes: [],
  enable: true,
  log: true,
  autoExcludeNodeModules: true,
  threadPool: true,
  options: {
    compact: true,
    controlFlowFlattening: true,
    controlFlowFlatteningThreshold: 1,
    deadCodeInjection: false,
    debugProtection: false,
    debugProtectionInterval: 0,
    disableConsoleOutput: false,
    identifierNamesGenerator: "hexadecimal",
    log: false,
    numbersToExpressions: false,
    renameGlobals: false,
    selfDefending: true,
    simplify: true,
    splitStrings: false,
    ignoreImports: true,
    stringArray: true,
    stringArrayCallsTransform: true,
    stringArrayCallsTransformThreshold: 0.5,
    stringArrayEncoding: [],
    stringArrayIndexShift: true,
    stringArrayRotate: true,
    stringArrayShuffle: true,
    stringArrayWrappersCount: 1,
    stringArrayWrappersChainedCalls: true,
    stringArrayWrappersParametersMaxCount: 2,
    stringArrayWrappersType: "variable",
    stringArrayThreshold: 0.75,
    unicodeEscapeSequence: false
  }
};
function withInstrumentation(p) {
  let modified = 0;
  return {
    ...p,
    async transform(code, id) {
      const out = await p.transform.call(this, code, id);
      if (out && out.code && out.code !== code) modified += 1;
      return out;
    },
    buildEnd() {
      this.info(`[typehints] Files modified: ${modified}`);
      if (p.buildEnd) return p.buildEnd.call(this);
    }
  };
}
function createTypehintPlugin(typehintsPluginFactory) {
  return withInstrumentation(
    typehintsPluginFactory({
      variableDocumentation: true,
      objectShapeDocumentation: true,
      maxObjectProperties: 6,
      enableCoercions: true,
      parameterHoistCoercions: false
    })
  );
}
function createEsbuildConfig(isDevelopment) {
  return {
    target: "es2020",
    // Modern target
    keepNames: false,
    treeShaking: isDevelopment ? false : true,
    // Disable tree shaking in development for faster builds
    legalComments: isDevelopment ? "none" : "inline"
    // Skip legal comments in development
  };
}
function devViteSecurityHeaders() {
  const headers = {
    "Cache-Control": "no-store, no-cache, must-revalidate, max-age=0",
    // Dev-only convenience; production builds should use stricter policies.
    // This allows the Vite renderer (https://localhost:5173) to embed the Rails
    // UI (https://localhost:3000) without CORP/COEP confusion.
    "Cross-Origin-Resource-Policy": "cross-origin"
  };
  if (process.env.VITE_ENABLE_COEP === "1") {
    headers["Cross-Origin-Embedder-Policy"] = "credentialless";
  }
  return headers;
}
function createTerserOptions(isDevelopment) {
  if (isDevelopment) return void 0;
  return {
    parse: {
      bare_returns: false,
      html5_comments: false,
      shebang: false,
      ecma: 2020
      // Modern parsing
    },
    compress: {
      defaults: true,
      arrows: true,
      // Keep arrow functions
      arguments: true,
      booleans: true,
      booleans_as_integers: false,
      collapse_vars: true,
      comparisons: true,
      computed_props: true,
      conditionals: true,
      dead_code: true,
      directives: true,
      drop_console: true,
      drop_debugger: true,
      ecma: 2020,
      // Modern compression
      evaluate: true,
      expression: false,
      global_defs: {},
      hoist_funs: true,
      hoist_props: true,
      hoist_vars: true,
      if_return: true,
      inline: true,
      join_vars: true,
      keep_classnames: false,
      keep_fargs: true,
      keep_fnames: false,
      keep_infinity: false,
      loops: true,
      negate_iife: true,
      passes: 10,
      properties: true,
      pure_getters: "strict",
      pure_funcs: [
        "console.log",
        "console.info",
        "console.debug",
        "console.warn",
        "console.error",
        "console.trace",
        "console.dir",
        "console.dirxml",
        "console.group",
        "console.groupCollapsed",
        "console.groupEnd",
        "console.time",
        "console.timeEnd",
        "console.timeLog",
        "console.assert",
        "console.count",
        "console.countReset",
        "console.profile",
        "console.profileEnd",
        "console.table",
        "console.clear"
      ],
      reduce_vars: true,
      reduce_funcs: true,
      sequences: true,
      side_effects: true,
      switches: true,
      toplevel: true,
      top_retain: null,
      typeofs: true,
      unsafe: true,
      unsafe_arrows: true,
      unsafe_comps: true,
      unsafe_Function: true,
      unsafe_math: true,
      unsafe_symbols: true,
      unsafe_methods: true,
      unsafe_proto: true,
      unsafe_regexp: true,
      unsafe_undefined: true,
      unused: true
    },
    mangle: {
      eval: false,
      keep_classnames: false,
      keep_fnames: false,
      reserved: [],
      toplevel: true,
      safari10: false
    },
    format: {
      ascii_only: false,
      beautify: false,
      braces: false,
      comments: "some",
      ecma: 2020,
      indent_level: 0,
      inline_script: true,
      keep_numbers: false,
      keep_quoted_props: false,
      max_line_len: 0,
      quote_keys: false,
      preserve_annotations: false,
      safari10: false,
      semicolons: true,
      shebang: false,
      webkit: false,
      wrap_iife: false,
      wrap_func_args: false
    }
  };
}
function createRollupOutputConfig() {
  return {
    minifyInternalExports: true,
    inlineDynamicImports: false,
    compact: true,
    generatedCode: {
      preset: "es2015",
      arrowFunctions: true,
      constBindings: true,
      objectShorthand: true
    }
  };
}
function createCommonBuild({ isDevelopment, rollupInput } = {}) {
  const build = {
    cache: isDevelopment,
    rollupOptions: {
      output: createRollupOutputConfig(),
      external: [],
      treeshake: {
        moduleSideEffects: true,
        propertyReadSideEffects: false,
        tryCatchDeoptimization: false,
        unknownGlobalSideEffects: false
      }
    },
    target: ["es2020", "edge88", "firefox78", "chrome87", "safari14"],
    modulePreload: { polyfill: true },
    cssCodeSplit: true,
    assetsInlineLimit: 5e5,
    cssTarget: ["esnext"],
    sourcemap: false,
    chunkSizeWarningLimit: 2147483647,
    reportCompressedSize: false,
    minify: isDevelopment ? false : "terser",
    terserOptions: createTerserOptions(isDevelopment)
  };
  if (rollupInput) build.rollupOptions.input = rollupInput;
  return build;
}
function createOptimizeDepsForce(isDevelopment) {
  return {
    force: isDevelopment && process.env.VITE_FORCE_DEPS === "true"
  };
}
var commonDefine = {
  global: "globalThis"
};
var commonLegacyOptions = {
  targets: ["chrome 142"],
  renderLegacyChunks: false,
  modernTargets: ["chrome 142"],
  modernPolyfills: true
};
function createBabelOptions(pathModule) {
  return {
    filter: (id) => {
      const base = pathModule.basename(id || "").toLowerCase();
      if (base === "textcomplete.min.js" || base === "ort-web.min.js") {
        return false;
      }
      return !id.includes("@hotwired/stimulus") && !id.includes("@huggingface/jinja") && !id.includes("onnxruntime-web") && /\.(js|coffee)$/.test(id);
    },
    babelConfig: {
      ignore: [/node_modules[\\/]locomotive-scroll/],
      // Exclude locomotive-scroll from all Babel processing to preserve sparse arrays
      babelrc: false,
      configFile: false,
      plugins: [
        ["closure-elimination"],
        ["module:faster.js"],
        [
          "object-to-json-parse",
          {
            minJSONStringSize: 1024
          }
        ]
      ]
    }
  };
}

// vite.config.mjs
var mkcertDefaults = {
  cert: process.env.MKCERT_CERT_PATH || "/tmp/mkcert-dev-certs/localhost.pem",
  key: process.env.MKCERT_KEY_PATH || "/tmp/mkcert-dev-certs/localhost-key.pem"
};
function buildHttpsOptions() {
  if (!fs2.existsSync(mkcertDefaults.cert) || !fs2.existsSync(mkcertDefaults.key)) {
    return void 0;
  }
  return {
    cert: fs2.readFileSync(mkcertDefaults.cert),
    key: fs2.readFileSync(mkcertDefaults.key)
  };
}
var vite_config_default = defineConfig(({ mode }) => {
  const isDevelopment = mode === "development";
  const typehintPlugin = createTypehintPlugin(typehints);
  const gemRoot = (name) => {
    try {
      return execSync(`bundle show ${name}`, {
        stdio: ["pipe", "pipe", "ignore"]
      }).toString().trim();
    } catch (error) {
      return null;
    }
  };
  const staticCopyTargets = [];
  const gemojiRoot = gemRoot("gemoji");
  if (gemojiRoot) {
    const gemojiSvgs = path.join(gemojiRoot, "assets/images/emoji/unicode");
    if (fs2.existsSync(gemojiSvgs)) {
      staticCopyTargets.push({
        src: path.join(gemojiSvgs, "*.svg"),
        dest: "static/gems/gemoji/emoji"
      });
    }
  }
  return {
    esbuild: createEsbuildConfig(isDevelopment),
    resolve: {
      extensions: [".js", ".json", ".coffee", ".scss", ".snappy", ".es6"],
      // Workaround for js-cookie packaging (dist folder not present in some installs)
      // Map to ESM source file so Vite can bundle successfully
      alias: {
        // Use explicit path into node_modules since package exports field hides src/*
        "js-cookie": path.resolve(
          process.cwd(),
          "node_modules/js-cookie/index.js"
        )
        // NOTE: timeago_js, thredded_js, thredded_vendor aliases removed
        // All gem JS is now compiled via Sprockets (see app/assets/javascripts/thredded.js)
      }
    },
    build: createCommonBuild({
      isDevelopment,
      rollupInput: {
        application: "app/javascript/application.js",
        emails: "app/stylesheets/emails.scss"
      }
    }),
    server: {
      host: process.env.VITE_DEV_SERVER_HOST || "127.0.0.1",
      port: Number(process.env.VITE_DEV_SERVER_PORT || 3001),
      strictPort: true,
      https: isDevelopment ? buildHttpsOptions() : void 0,
      hmr: {
        overlay: true,
        protocol: isDevelopment && buildHttpsOptions() ? "wss" : "ws",
        host: "localhost",
        port: Number(process.env.VITE_DEV_SERVER_PORT || 3001),
        clientPort: Number(process.env.VITE_DEV_SERVER_PORT || 3001)
      },
      origin: isDevelopment && buildHttpsOptions() ? `https://localhost:${process.env.VITE_DEV_SERVER_PORT || 3001}` : void 0,
      headers: isDevelopment ? devViteSecurityHeaders() : {},
      fs: { strict: false }
      // More lenient file system access for development
    },
    assetsInclude: ["**/*.snappy", "**/*.gguf", "**/*.wasm"],
    css: {
      preprocessorOptions: {
        scss: {
          api: "modern-compiler",
          includePaths: ["node_modules", "./node_modules"]
        }
      },
      postcss: {
        plugins: [
          postcss_remove_prefix_default(),
          stylehacks({ lint: false }),
          postcssInlineRtl(),
          postcssUrl([
            {
              filter: "**/*.woff2",
              url: "inline",
              encodeType: "base64",
              maxSize: 2147483647
            },
            {
              url: "inline",
              maxSize: 2147483647,
              encodeType: "encodeURIComponent",
              optimizeSvgEncode: true,
              ignoreFragmentWarning: true
            }
          ]),
          postcssRemoveRoot(),
          cssMqpacker({
            sort: true
          }),
          postcssMqOptimize(),
          cssnano({
            preset: [
              "advanced",
              {
                autoprefixer: false,
                discardComments: {
                  removeAllButCopyright: true
                },
                discardUnused: true,
                reduceIdents: true,
                mergeIndents: true,
                zindex: true
              }
            ]
          }),
          autoprefixer()
        ]
      }
    },
    define: commonDefine,
    optimizeDeps: {
      // Force inclusion of dependencies that might not be detected
      include: [
        "debounced",
        "foundation-sites",
        "what-input",
        "@fingerprintjs/botd",
        "@rails/ujs",
        "js-cookie",
        "@sentry/browser",
        "turbo_power",
        "@rails/activestorage",
        "stimulus_reflex",
        "cable_ready",
        "@rails/actioncable",
        "@rails/request.js",
        "stimulus-store",
        "@hotwired/turbo-rails",
        "leaflet",
        "leaflet.offline",
        "leaflet-ajax",
        "leaflet-spin",
        "leaflet-sleep",
        "leaflet.a11y",
        "leaflet.translate",
        "stimulus-use/hotkeys",
        "jquery"
      ],
      exclude: ["@hotwired/turbo"],
      // Force reoptimization in development
      ...createOptimizeDepsForce(isDevelopment)
    },
    plugins: [
      coffeescript(),
      nodePolyfills(),
      purgePolyfills.vite(),
      replacements(),
      staticCopyTargets.length ? viteStaticCopy({ targets: staticCopyTargets }) : null,
      legacy(commonLegacyOptions),
      babel(createBabelOptions(path)),
      rubyPlugin(),
      stimulusHMR(),
      fullReload([
        "config/routes.rb",
        "app/views/**/*",
        "app/javascript/src/**/*"
      ]),
      !isDevelopment ? vitePluginBundleObfuscator(allObfuscatorConfig) : null,
      !isDevelopment ? typehintPlugin : null
    ]
  };
});
export {
  vite_config_default as default
};
//# sourceMappingURL=data:application/json;base64,ewogICJ2ZXJzaW9uIjogMywKICAic291cmNlcyI6IFsidml0ZS5jb25maWcubWpzIiwgInBsdWdpbnMvY29mZmVlc2NyaXB0LmpzIiwgInBsdWdpbnMvdHlwZWhpbnRzLmpzIiwgInBsdWdpbnMvcG9zdGNzcy1yZW1vdmUtcHJlZml4LmpzIiwgImNvbmZpZy92aXRlL2NvbW1vbi5qcyJdLAogICJzb3VyY2VzQ29udGVudCI6IFsiY29uc3QgX192aXRlX2luamVjdGVkX29yaWdpbmFsX2Rpcm5hbWUgPSBcIi9Vc2Vycy9nZW9yZ2UvTGlicmV2ZXJzZVwiO2NvbnN0IF9fdml0ZV9pbmplY3RlZF9vcmlnaW5hbF9maWxlbmFtZSA9IFwiL1VzZXJzL2dlb3JnZS9MaWJyZXZlcnNlL3ZpdGUuY29uZmlnLm1qc1wiO2NvbnN0IF9fdml0ZV9pbmplY3RlZF9vcmlnaW5hbF9pbXBvcnRfbWV0YV91cmwgPSBcImZpbGU6Ly8vVXNlcnMvZ2VvcmdlL0xpYnJldmVyc2Uvdml0ZS5jb25maWcubWpzXCI7aW1wb3J0IFwidjgtY29tcGlsZS1jYWNoZVwiO1xuaW1wb3J0IHsgZGVmaW5lQ29uZmlnIH0gZnJvbSBcInZpdGVcIjtcbmltcG9ydCBwYXRoIGZyb20gXCJub2RlOnBhdGhcIjtcbmltcG9ydCBmcyBmcm9tIFwibm9kZTpmc1wiO1xuaW1wb3J0IHsgZXhlY1N5bmMgfSBmcm9tIFwibm9kZTpjaGlsZF9wcm9jZXNzXCI7XG5pbXBvcnQgeyB2aXRlU3RhdGljQ29weSB9IGZyb20gXCJ2aXRlLXBsdWdpbi1zdGF0aWMtY29weVwiO1xuaW1wb3J0IHJ1YnlQbHVnaW4gZnJvbSBcInZpdGUtcGx1Z2luLXJ1YnlcIjtcbmltcG9ydCBmdWxsUmVsb2FkIGZyb20gXCJ2aXRlLXBsdWdpbi1mdWxsLXJlbG9hZFwiO1xuaW1wb3J0IHN0aW11bHVzSE1SIGZyb20gXCJ2aXRlLXBsdWdpbi1zdGltdWx1cy1obXJcIjtcbmltcG9ydCBiYWJlbCBmcm9tIFwidml0ZS1wbHVnaW4tYmFiZWxcIjtcbmltcG9ydCBwb3N0Y3NzSW5saW5lUnRsIGZyb20gXCJwb3N0Y3NzLWlubGluZS1ydGxcIjtcbmltcG9ydCBjc3NuYW5vIGZyb20gXCJjc3NuYW5vXCI7XG5pbXBvcnQgcG9zdGNzc1VybCBmcm9tIFwicG9zdGNzcy11cmxcIjtcbmltcG9ydCBjb2ZmZWVzY3JpcHQgZnJvbSBcIi4vcGx1Z2lucy9jb2ZmZWVzY3JpcHQuanNcIjtcbmltcG9ydCB0eXBlaGludHMgZnJvbSBcIi4vcGx1Z2lucy90eXBlaGludHMuanNcIjtcbmltcG9ydCBwb3N0Y3NzUmVtb3ZlUm9vdCBmcm9tIFwicG9zdGNzcy1yZW1vdmUtcm9vdFwiO1xuaW1wb3J0IGNzc01xcGFja2VyIGZyb20gXCJjc3MtbXFwYWNrZXJcIjtcbmltcG9ydCBzdHlsZWhhY2tzIGZyb20gXCJzdHlsZWhhY2tzXCI7XG5pbXBvcnQgcG9zdGNzc01xT3B0aW1pemUgZnJvbSBcInBvc3Rjc3MtbXEtb3B0aW1pemVcIjtcbmltcG9ydCBhdXRvcHJlZml4ZXIgZnJvbSBcImF1dG9wcmVmaXhlclwiO1xuaW1wb3J0IHJlbW92ZVByZWZpeCBmcm9tIFwiLi9wbHVnaW5zL3Bvc3Rjc3MtcmVtb3ZlLXByZWZpeC5qc1wiO1xuaW1wb3J0IG5vZGVQb2x5ZmlsbHMgZnJvbSBcInJvbGx1cC1wbHVnaW4tcG9seWZpbGwtbm9kZVwiO1xuaW1wb3J0IGxlZ2FjeSBmcm9tIFwidml0ZS1wbHVnaW4tbGVnYWN5LXN3Y1wiO1xuaW1wb3J0IHZpdGVQbHVnaW5CdW5kbGVPYmZ1c2NhdG9yIGZyb20gXCJ2aXRlLXBsdWdpbi1idW5kbGUtb2JmdXNjYXRvclwiO1xuaW1wb3J0IHsgcHVyZ2VQb2x5ZmlsbHMgfSBmcm9tIFwidW5wbHVnaW4tcHVyZ2UtcG9seWZpbGxzXCI7XG5pbXBvcnQgcmVwbGFjZW1lbnRzIGZyb20gXCJAZTE4ZS91bnBsdWdpbi1yZXBsYWNlbWVudHMvdml0ZVwiO1xuaW1wb3J0IHtcbiAgICBhbGxPYmZ1c2NhdG9yQ29uZmlnLFxuICAgIGNvbW1vbkRlZmluZSxcbiAgICBjb21tb25MZWdhY3lPcHRpb25zLFxuICAgIGNyZWF0ZUJhYmVsT3B0aW9ucyxcbiAgICBjcmVhdGVDb21tb25CdWlsZCxcbiAgICBjcmVhdGVFc2J1aWxkQ29uZmlnLFxuICAgIGNyZWF0ZU9wdGltaXplRGVwc0ZvcmNlLFxuICAgIGNyZWF0ZVR5cGVoaW50UGx1Z2luLFxuICAgIGRldlZpdGVTZWN1cml0eUhlYWRlcnMsXG59IGZyb20gXCIuL2NvbmZpZy92aXRlL2NvbW1vbi5qc1wiO1xuXG5jb25zdCBta2NlcnREZWZhdWx0cyA9IHtcbiAgICBjZXJ0OiBwcm9jZXNzLmVudi5NS0NFUlRfQ0VSVF9QQVRIIHx8IFwiL3RtcC9ta2NlcnQtZGV2LWNlcnRzL2xvY2FsaG9zdC5wZW1cIixcbiAgICBrZXk6IHByb2Nlc3MuZW52Lk1LQ0VSVF9LRVlfUEFUSCB8fCBcIi90bXAvbWtjZXJ0LWRldi1jZXJ0cy9sb2NhbGhvc3Qta2V5LnBlbVwiLFxufTtcblxuZnVuY3Rpb24gYnVpbGRIdHRwc09wdGlvbnMoKSB7XG4gICAgaWYgKCFmcy5leGlzdHNTeW5jKG1rY2VydERlZmF1bHRzLmNlcnQpIHx8ICFmcy5leGlzdHNTeW5jKG1rY2VydERlZmF1bHRzLmtleSkpIHtcbiAgICAgICAgcmV0dXJuIHVuZGVmaW5lZDtcbiAgICB9XG4gICAgcmV0dXJuIHtcbiAgICAgICAgY2VydDogZnMucmVhZEZpbGVTeW5jKG1rY2VydERlZmF1bHRzLmNlcnQpLFxuICAgICAgICBrZXk6IGZzLnJlYWRGaWxlU3luYyhta2NlcnREZWZhdWx0cy5rZXkpLFxuICAgIH07XG59XG5cbmV4cG9ydCBkZWZhdWx0IGRlZmluZUNvbmZpZygoeyBtb2RlIH0pID0+IHtcbiAgICBjb25zdCBpc0RldmVsb3BtZW50ID0gbW9kZSA9PT0gXCJkZXZlbG9wbWVudFwiO1xuXG4gICAgY29uc3QgdHlwZWhpbnRQbHVnaW4gPSBjcmVhdGVUeXBlaGludFBsdWdpbih0eXBlaGludHMpO1xuXG4gICAgY29uc3QgZ2VtUm9vdCA9IChuYW1lKSA9PiB7XG4gICAgICAgIHRyeSB7XG4gICAgICAgICAgICByZXR1cm4gZXhlY1N5bmMoYGJ1bmRsZSBzaG93ICR7bmFtZX1gLCB7XG4gICAgICAgICAgICAgICAgc3RkaW86IFtcInBpcGVcIiwgXCJwaXBlXCIsIFwiaWdub3JlXCJdLFxuICAgICAgICAgICAgfSlcbiAgICAgICAgICAgICAgICAudG9TdHJpbmcoKVxuICAgICAgICAgICAgICAgIC50cmltKCk7XG4gICAgICAgIH0gY2F0Y2ggKGVycm9yKSB7XG4gICAgICAgICAgICByZXR1cm4gbnVsbDtcbiAgICAgICAgfVxuICAgIH07XG5cbiAgICBjb25zdCBzdGF0aWNDb3B5VGFyZ2V0cyA9IFtdO1xuXG4gICAgLy8gTk9URTogVGhyZWRkZWQgSlMgYW5kIHRpbWVhZ28gYXJlIGNvbXBpbGVkIHZpYSBTcHJvY2tldHMsIG5vdCBWaXRlXG4gICAgLy8gU2VlIGFwcC9hc3NldHMvamF2YXNjcmlwdHMvdGhyZWRkZWQuanMgYW5kIGNvbmZpZy9pbml0aWFsaXplcnMvc3Byb2NrZXRzX3RocmVkZGVkLnJiXG5cbiAgICBjb25zdCBnZW1vamlSb290ID0gZ2VtUm9vdChcImdlbW9qaVwiKTtcbiAgICBpZiAoZ2Vtb2ppUm9vdCkge1xuICAgICAgICBjb25zdCBnZW1vamlTdmdzID0gcGF0aC5qb2luKGdlbW9qaVJvb3QsIFwiYXNzZXRzL2ltYWdlcy9lbW9qaS91bmljb2RlXCIpO1xuICAgICAgICBpZiAoZnMuZXhpc3RzU3luYyhnZW1vamlTdmdzKSkge1xuICAgICAgICAgICAgc3RhdGljQ29weVRhcmdldHMucHVzaCh7XG4gICAgICAgICAgICAgICAgc3JjOiBwYXRoLmpvaW4oZ2Vtb2ppU3ZncywgXCIqLnN2Z1wiKSxcbiAgICAgICAgICAgICAgICBkZXN0OiBcInN0YXRpYy9nZW1zL2dlbW9qaS9lbW9qaVwiLFxuICAgICAgICAgICAgfSk7XG4gICAgICAgIH1cbiAgICB9XG5cbiAgICByZXR1cm4ge1xuICAgICAgICBlc2J1aWxkOiBjcmVhdGVFc2J1aWxkQ29uZmlnKGlzRGV2ZWxvcG1lbnQpLFxuICAgICAgICByZXNvbHZlOiB7XG4gICAgICAgICAgICBleHRlbnNpb25zOiBbXCIuanNcIiwgXCIuanNvblwiLCBcIi5jb2ZmZWVcIiwgXCIuc2Nzc1wiLCBcIi5zbmFwcHlcIiwgXCIuZXM2XCJdLFxuICAgICAgICAgICAgLy8gV29ya2Fyb3VuZCBmb3IganMtY29va2llIHBhY2thZ2luZyAoZGlzdCBmb2xkZXIgbm90IHByZXNlbnQgaW4gc29tZSBpbnN0YWxscylcbiAgICAgICAgICAgIC8vIE1hcCB0byBFU00gc291cmNlIGZpbGUgc28gVml0ZSBjYW4gYnVuZGxlIHN1Y2Nlc3NmdWxseVxuICAgICAgICAgICAgYWxpYXM6IHtcbiAgICAgICAgICAgICAgICAvLyBVc2UgZXhwbGljaXQgcGF0aCBpbnRvIG5vZGVfbW9kdWxlcyBzaW5jZSBwYWNrYWdlIGV4cG9ydHMgZmllbGQgaGlkZXMgc3JjLypcbiAgICAgICAgICAgICAgICBcImpzLWNvb2tpZVwiOiBwYXRoLnJlc29sdmUoXG4gICAgICAgICAgICAgICAgICAgIHByb2Nlc3MuY3dkKCksXG4gICAgICAgICAgICAgICAgICAgIFwibm9kZV9tb2R1bGVzL2pzLWNvb2tpZS9pbmRleC5qc1wiLFxuICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgLy8gTk9URTogdGltZWFnb19qcywgdGhyZWRkZWRfanMsIHRocmVkZGVkX3ZlbmRvciBhbGlhc2VzIHJlbW92ZWRcbiAgICAgICAgICAgICAgICAvLyBBbGwgZ2VtIEpTIGlzIG5vdyBjb21waWxlZCB2aWEgU3Byb2NrZXRzIChzZWUgYXBwL2Fzc2V0cy9qYXZhc2NyaXB0cy90aHJlZGRlZC5qcylcbiAgICAgICAgICAgIH0sXG4gICAgICAgIH0sXG4gICAgICAgIGJ1aWxkOiBjcmVhdGVDb21tb25CdWlsZCh7XG4gICAgICAgICAgICBpc0RldmVsb3BtZW50LFxuICAgICAgICAgICAgcm9sbHVwSW5wdXQ6IHtcbiAgICAgICAgICAgICAgICBhcHBsaWNhdGlvbjogXCJhcHAvamF2YXNjcmlwdC9hcHBsaWNhdGlvbi5qc1wiLFxuICAgICAgICAgICAgICAgIGVtYWlsczogXCJhcHAvc3R5bGVzaGVldHMvZW1haWxzLnNjc3NcIixcbiAgICAgICAgICAgIH0sXG4gICAgICAgIH0pLFxuICAgICAgICBzZXJ2ZXI6IHtcbiAgICAgICAgICAgIGhvc3Q6IHByb2Nlc3MuZW52LlZJVEVfREVWX1NFUlZFUl9IT1NUIHx8IFwiMTI3LjAuMC4xXCIsXG4gICAgICAgICAgICBwb3J0OiBOdW1iZXIocHJvY2Vzcy5lbnYuVklURV9ERVZfU0VSVkVSX1BPUlQgfHwgMzAwMSksXG4gICAgICAgICAgICBzdHJpY3RQb3J0OiB0cnVlLFxuICAgICAgICAgICAgaHR0cHM6IGlzRGV2ZWxvcG1lbnQgPyBidWlsZEh0dHBzT3B0aW9ucygpIDogdW5kZWZpbmVkLFxuICAgICAgICAgICAgaG1yOiB7XG4gICAgICAgICAgICAgICAgb3ZlcmxheTogdHJ1ZSxcbiAgICAgICAgICAgICAgICBwcm90b2NvbDogaXNEZXZlbG9wbWVudCAmJiBidWlsZEh0dHBzT3B0aW9ucygpID8gXCJ3c3NcIiA6IFwid3NcIixcbiAgICAgICAgICAgICAgICBob3N0OiBcImxvY2FsaG9zdFwiLFxuICAgICAgICAgICAgICAgIHBvcnQ6IE51bWJlcihwcm9jZXNzLmVudi5WSVRFX0RFVl9TRVJWRVJfUE9SVCB8fCAzMDAxKSxcbiAgICAgICAgICAgICAgICBjbGllbnRQb3J0OiBOdW1iZXIocHJvY2Vzcy5lbnYuVklURV9ERVZfU0VSVkVSX1BPUlQgfHwgMzAwMSksXG4gICAgICAgICAgICB9LFxuICAgICAgICAgICAgb3JpZ2luOiBpc0RldmVsb3BtZW50ICYmIGJ1aWxkSHR0cHNPcHRpb25zKCkgPyBgaHR0cHM6Ly9sb2NhbGhvc3Q6JHtwcm9jZXNzLmVudi5WSVRFX0RFVl9TRVJWRVJfUE9SVCB8fCAzMDAxfWAgOiB1bmRlZmluZWQsXG4gICAgICAgICAgICBoZWFkZXJzOiBpc0RldmVsb3BtZW50ID8gZGV2Vml0ZVNlY3VyaXR5SGVhZGVycygpIDoge30sXG4gICAgICAgICAgICBmczogeyBzdHJpY3Q6IGZhbHNlIH0sIC8vIE1vcmUgbGVuaWVudCBmaWxlIHN5c3RlbSBhY2Nlc3MgZm9yIGRldmVsb3BtZW50XG4gICAgICAgIH0sXG4gICAgICAgIGFzc2V0c0luY2x1ZGU6IFtcIioqLyouc25hcHB5XCIsIFwiKiovKi5nZ3VmXCIsIFwiKiovKi53YXNtXCJdLFxuICAgICAgICBjc3M6IHtcbiAgICAgICAgICAgIHByZXByb2Nlc3Nvck9wdGlvbnM6IHtcbiAgICAgICAgICAgICAgICBzY3NzOiB7XG4gICAgICAgICAgICAgICAgICAgIGFwaTogXCJtb2Rlcm4tY29tcGlsZXJcIixcbiAgICAgICAgICAgICAgICAgICAgaW5jbHVkZVBhdGhzOiBbXCJub2RlX21vZHVsZXNcIiwgXCIuL25vZGVfbW9kdWxlc1wiXSxcbiAgICAgICAgICAgICAgICB9LFxuICAgICAgICAgICAgfSxcbiAgICAgICAgICAgIHBvc3Rjc3M6IHtcbiAgICAgICAgICAgICAgICBwbHVnaW5zOiBbXG4gICAgICAgICAgICAgICAgICAgIHJlbW92ZVByZWZpeCgpLFxuICAgICAgICAgICAgICAgICAgICBzdHlsZWhhY2tzKHsgbGludDogZmFsc2UgfSksXG4gICAgICAgICAgICAgICAgICAgIHBvc3Rjc3NJbmxpbmVSdGwoKSxcbiAgICAgICAgICAgICAgICAgICAgcG9zdGNzc1VybChbXG4gICAgICAgICAgICAgICAgICAgICAgICB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZmlsdGVyOiBcIioqLyoud29mZjJcIixcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB1cmw6IFwiaW5saW5lXCIsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZW5jb2RlVHlwZTogXCJiYXNlNjRcIixcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBtYXhTaXplOiAyMTQ3NDgzNjQ3LFxuICAgICAgICAgICAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgICAgICAgICAgICAgIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB1cmw6IFwiaW5saW5lXCIsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbWF4U2l6ZTogMjE0NzQ4MzY0NyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBlbmNvZGVUeXBlOiBcImVuY29kZVVSSUNvbXBvbmVudFwiLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9wdGltaXplU3ZnRW5jb2RlOiB0cnVlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGlnbm9yZUZyYWdtZW50V2FybmluZzogdHJ1ZSxcbiAgICAgICAgICAgICAgICAgICAgICAgIH0sXG4gICAgICAgICAgICAgICAgICAgIF0pLFxuICAgICAgICAgICAgICAgICAgICBwb3N0Y3NzUmVtb3ZlUm9vdCgpLFxuICAgICAgICAgICAgICAgICAgICBjc3NNcXBhY2tlcih7XG4gICAgICAgICAgICAgICAgICAgICAgICBzb3J0OiB0cnVlLFxuICAgICAgICAgICAgICAgICAgICB9KSxcbiAgICAgICAgICAgICAgICAgICAgcG9zdGNzc01xT3B0aW1pemUoKSxcbiAgICAgICAgICAgICAgICAgICAgY3NzbmFubyh7XG4gICAgICAgICAgICAgICAgICAgICAgICBwcmVzZXQ6IFtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBcImFkdmFuY2VkXCIsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBhdXRvcHJlZml4ZXI6IGZhbHNlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkaXNjYXJkQ29tbWVudHM6IHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlbW92ZUFsbEJ1dENvcHlyaWdodDogdHJ1ZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZGlzY2FyZFVudXNlZDogdHJ1ZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVkdWNlSWRlbnRzOiB0cnVlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBtZXJnZUluZGVudHM6IHRydWUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHppbmRleDogdHJ1ZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgXSxcbiAgICAgICAgICAgICAgICAgICAgfSksXG4gICAgICAgICAgICAgICAgICAgIGF1dG9wcmVmaXhlcigpLFxuICAgICAgICAgICAgICAgIF0sXG4gICAgICAgICAgICB9LFxuICAgICAgICB9LFxuICAgICAgICBkZWZpbmU6IGNvbW1vbkRlZmluZSxcbiAgICAgICAgb3B0aW1pemVEZXBzOiB7XG4gICAgICAgICAgICAvLyBGb3JjZSBpbmNsdXNpb24gb2YgZGVwZW5kZW5jaWVzIHRoYXQgbWlnaHQgbm90IGJlIGRldGVjdGVkXG4gICAgICAgICAgICBpbmNsdWRlOiBbXG4gICAgICAgICAgICAgICAgXCJkZWJvdW5jZWRcIixcbiAgICAgICAgICAgICAgICBcImZvdW5kYXRpb24tc2l0ZXNcIixcbiAgICAgICAgICAgICAgICBcIndoYXQtaW5wdXRcIixcbiAgICAgICAgICAgICAgICBcIkBmaW5nZXJwcmludGpzL2JvdGRcIixcbiAgICAgICAgICAgICAgICBcIkByYWlscy91anNcIixcbiAgICAgICAgICAgICAgICBcImpzLWNvb2tpZVwiLFxuICAgICAgICAgICAgICAgIFwiQHNlbnRyeS9icm93c2VyXCIsXG4gICAgICAgICAgICAgICAgXCJ0dXJib19wb3dlclwiLFxuICAgICAgICAgICAgICAgIFwiQHJhaWxzL2FjdGl2ZXN0b3JhZ2VcIixcbiAgICAgICAgICAgICAgICBcInN0aW11bHVzX3JlZmxleFwiLFxuICAgICAgICAgICAgICAgIFwiY2FibGVfcmVhZHlcIixcbiAgICAgICAgICAgICAgICBcIkByYWlscy9hY3Rpb25jYWJsZVwiLFxuICAgICAgICAgICAgICAgIFwiQHJhaWxzL3JlcXVlc3QuanNcIixcbiAgICAgICAgICAgICAgICBcInN0aW11bHVzLXN0b3JlXCIsXG4gICAgICAgICAgICAgICAgXCJAaG90d2lyZWQvdHVyYm8tcmFpbHNcIixcbiAgICAgICAgICAgICAgICBcImxlYWZsZXRcIixcbiAgICAgICAgICAgICAgICBcImxlYWZsZXQub2ZmbGluZVwiLFxuICAgICAgICAgICAgICAgIFwibGVhZmxldC1hamF4XCIsXG4gICAgICAgICAgICAgICAgXCJsZWFmbGV0LXNwaW5cIixcbiAgICAgICAgICAgICAgICBcImxlYWZsZXQtc2xlZXBcIixcbiAgICAgICAgICAgICAgICBcImxlYWZsZXQuYTExeVwiLFxuICAgICAgICAgICAgICAgIFwibGVhZmxldC50cmFuc2xhdGVcIixcbiAgICAgICAgICAgICAgICBcInN0aW11bHVzLXVzZS9ob3RrZXlzXCIsXG4gICAgICAgICAgICAgICAgXCJqcXVlcnlcIixcbiAgICAgICAgICAgIF0sXG4gICAgICAgICAgICBleGNsdWRlOiBbXCJAaG90d2lyZWQvdHVyYm9cIl0sXG4gICAgICAgICAgICAvLyBGb3JjZSByZW9wdGltaXphdGlvbiBpbiBkZXZlbG9wbWVudFxuICAgICAgICAgICAgLi4uY3JlYXRlT3B0aW1pemVEZXBzRm9yY2UoaXNEZXZlbG9wbWVudCksXG4gICAgICAgIH0sXG4gICAgICAgIHBsdWdpbnM6IFtcbiAgICAgICAgICAgIGNvZmZlZXNjcmlwdCgpLFxuICAgICAgICAgICAgbm9kZVBvbHlmaWxscygpLFxuICAgICAgICAgICAgcHVyZ2VQb2x5ZmlsbHMudml0ZSgpLFxuICAgICAgICAgICAgcmVwbGFjZW1lbnRzKCksXG4gICAgICAgICAgICBzdGF0aWNDb3B5VGFyZ2V0cy5sZW5ndGhcbiAgICAgICAgICAgICAgICA/IHZpdGVTdGF0aWNDb3B5KHsgdGFyZ2V0czogc3RhdGljQ29weVRhcmdldHMgfSlcbiAgICAgICAgICAgICAgICA6IG51bGwsXG4gICAgICAgICAgICBsZWdhY3koY29tbW9uTGVnYWN5T3B0aW9ucyksXG4gICAgICAgICAgICBiYWJlbChjcmVhdGVCYWJlbE9wdGlvbnMocGF0aCkpLFxuICAgICAgICAgICAgcnVieVBsdWdpbigpLFxuICAgICAgICAgICAgc3RpbXVsdXNITVIoKSxcbiAgICAgICAgICAgIGZ1bGxSZWxvYWQoW1xuICAgICAgICAgICAgICAgIFwiY29uZmlnL3JvdXRlcy5yYlwiLFxuICAgICAgICAgICAgICAgIFwiYXBwL3ZpZXdzLyoqLypcIixcbiAgICAgICAgICAgICAgICBcImFwcC9qYXZhc2NyaXB0L3NyYy8qKi8qXCIsXG4gICAgICAgICAgICBdKSxcbiAgICAgICAgICAgICFpc0RldmVsb3BtZW50XG4gICAgICAgICAgICAgICAgPyB2aXRlUGx1Z2luQnVuZGxlT2JmdXNjYXRvcihhbGxPYmZ1c2NhdG9yQ29uZmlnKVxuICAgICAgICAgICAgICAgIDogbnVsbCxcbiAgICAgICAgICAgICFpc0RldmVsb3BtZW50ID8gdHlwZWhpbnRQbHVnaW4gOiBudWxsLFxuICAgICAgICBdLFxuICAgIH07XG59KTtcbiIsICJjb25zdCBfX3ZpdGVfaW5qZWN0ZWRfb3JpZ2luYWxfZGlybmFtZSA9IFwiL1VzZXJzL2dlb3JnZS9MaWJyZXZlcnNlL3BsdWdpbnNcIjtjb25zdCBfX3ZpdGVfaW5qZWN0ZWRfb3JpZ2luYWxfZmlsZW5hbWUgPSBcIi9Vc2Vycy9nZW9yZ2UvTGlicmV2ZXJzZS9wbHVnaW5zL2NvZmZlZXNjcmlwdC5qc1wiO2NvbnN0IF9fdml0ZV9pbmplY3RlZF9vcmlnaW5hbF9pbXBvcnRfbWV0YV91cmwgPSBcImZpbGU6Ly8vVXNlcnMvZ2VvcmdlL0xpYnJldmVyc2UvcGx1Z2lucy9jb2ZmZWVzY3JpcHQuanNcIjtpbXBvcnQgQ29mZmVlU2NyaXB0IGZyb20gXCJjb2ZmZWVzY3JpcHRcIjtcblxuLyoqXG4gKiBWaXRlIHBsdWdpbiB0byBjb21waWxlIC5jb2ZmZWUgZmlsZXMuXG4gKiBAcGFyYW0ge2ltcG9ydCgnY29mZmVlc2NyaXB0JykuQ29tcGlsZU9wdGlvbnN9IHVzZXJPcHRpb25zXG4gKiBAcmV0dXJucyB7aW1wb3J0KCd2aXRlJykuUGx1Z2lufVxuICovXG5cbmV4cG9ydCBkZWZhdWx0IGZ1bmN0aW9uIGNvZmZlZXNjcmlwdCh1c2VyT3B0aW9ucyA9IHt9KSB7XG4gICAgY29uc3QgYmFzZU9wdGlvbnMgPSB7XG4gICAgICAgIGJhcmU6IHRydWUsXG4gICAgICAgIHNvdXJjZU1hcDogZmFsc2UsXG4gICAgfTtcblxuICAgIHJldHVybiB7XG4gICAgICAgIG5hbWU6IFwiY29mZmVlc2NyaXB0XCIsXG4gICAgICAgIGVuZm9yY2U6IFwicHJlXCIsXG4gICAgICAgIHRyYW5zZm9ybShjb2RlLCBpZCkge1xuICAgICAgICAgICAgaWYgKCFpZC5lbmRzV2l0aChcIi5jb2ZmZWVcIikpIHJldHVybjtcblxuICAgICAgICAgICAgY29uc3Qgb3B0aW9ucyA9IHsgLi4uYmFzZU9wdGlvbnMsIC4uLnVzZXJPcHRpb25zLCBmaWxlbmFtZTogaWQgfTtcblxuICAgICAgICAgICAgdHJ5IHtcbiAgICAgICAgICAgICAgICBjb25zdCBjb21waWxlZCA9IENvZmZlZVNjcmlwdC5jb21waWxlKGNvZGUsIG9wdGlvbnMpO1xuICAgICAgICAgICAgICAgIGlmICh0eXBlb2YgY29tcGlsZWQgPT09IFwic3RyaW5nXCIpIHtcbiAgICAgICAgICAgICAgICAgICAgcmV0dXJuIHsgY29kZTogY29tcGlsZWQsIG1hcDogdW5kZWZpbmVkIH07XG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgIGNvbnN0IG1hcCA9XG4gICAgICAgICAgICAgICAgICAgIGNvbXBpbGVkLnYzU291cmNlTWFwIHx8IGNvbXBpbGVkLnNvdXJjZU1hcCB8fCB1bmRlZmluZWQ7XG4gICAgICAgICAgICAgICAgcmV0dXJuIHsgY29kZTogY29tcGlsZWQuanMsIG1hcCB9O1xuICAgICAgICAgICAgfSBjYXRjaCAoZXJyb3IpIHtcbiAgICAgICAgICAgICAgICB0aGlzLmVycm9yKGVycm9yKTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgfSxcbiAgICB9O1xufVxuIiwgImNvbnN0IF9fdml0ZV9pbmplY3RlZF9vcmlnaW5hbF9kaXJuYW1lID0gXCIvVXNlcnMvZ2VvcmdlL0xpYnJldmVyc2UvcGx1Z2luc1wiO2NvbnN0IF9fdml0ZV9pbmplY3RlZF9vcmlnaW5hbF9maWxlbmFtZSA9IFwiL1VzZXJzL2dlb3JnZS9MaWJyZXZlcnNlL3BsdWdpbnMvdHlwZWhpbnRzLmpzXCI7Y29uc3QgX192aXRlX2luamVjdGVkX29yaWdpbmFsX2ltcG9ydF9tZXRhX3VybCA9IFwiZmlsZTovLy9Vc2Vycy9nZW9yZ2UvTGlicmV2ZXJzZS9wbHVnaW5zL3R5cGVoaW50cy5qc1wiOy8vIFBsYWluIEpTIHBsdWdpbiB0aGF0IHVzZXMgdGhlIFR5cGVTY3JpcHQgY2hlY2tlciBmb3IgaW5mZXJlbmNlIG9ubHkuXG5pbXBvcnQgKiBhcyB0cyBmcm9tIFwidHlwZXNjcmlwdFwiO1xuaW1wb3J0IHsgcGFyc2UgfSBmcm9tIFwiQGJhYmVsL3BhcnNlclwiO1xuLy8gTm9ybWFsaXplIEVTTS9DSlMgaW50ZXJvcCBmb3IgQmFiZWwgdXRpbHMgd2hlbiBWaXRlIGJ1bmRsZXMgdGhlIGNvbmZpZ1xuaW1wb3J0IHRyYXZlcnNlTW9kdWxlIGZyb20gXCJAYmFiZWwvdHJhdmVyc2VcIjtcbmltcG9ydCBnZW5lcmF0ZU1vZHVsZSBmcm9tIFwiQGJhYmVsL2dlbmVyYXRvclwiO1xuaW1wb3J0IHRlbXBsYXRlTW9kdWxlIGZyb20gXCJAYmFiZWwvdGVtcGxhdGVcIjtcbmltcG9ydCAqIGFzIHQgZnJvbSBcIkBiYWJlbC90eXBlc1wiO1xuY29uc3QgdHJhdmVyc2UgPVxuICAgIC8qKiBAdHlwZSB7YW55fSAqLyAoXG4gICAgICAgIHR5cGVvZiB0cmF2ZXJzZU1vZHVsZSA9PT0gXCJmdW5jdGlvblwiXG4gICAgICAgICAgICA/IHRyYXZlcnNlTW9kdWxlXG4gICAgICAgICAgICA6IC8qKiBAdHlwZSB7YW55fSAqLyAodHJhdmVyc2VNb2R1bGUgJiYgdHJhdmVyc2VNb2R1bGUuZGVmYXVsdClcbiAgICApIHx8IC8qKiBmYWxsYmFjayBub29wIHRvIGF2b2lkIGhhcmQgY3Jhc2ggKi8gZnVuY3Rpb24gKCkge30uYmluZCgpO1xuY29uc3QgZ2VuZXJhdGUgPSAvKiogQHR5cGUge2FueX0gKi8gKFxuICAgIHR5cGVvZiBnZW5lcmF0ZU1vZHVsZSA9PT0gXCJmdW5jdGlvblwiXG4gICAgICAgID8gZ2VuZXJhdGVNb2R1bGVcbiAgICAgICAgOiAvKiogQHR5cGUge2FueX0gKi8gKGdlbmVyYXRlTW9kdWxlICYmIGdlbmVyYXRlTW9kdWxlLmRlZmF1bHQpXG4pO1xuY29uc3QgdGVtcGxhdGUgPSAvKiogQHR5cGUge2FueX0gKi8gKFxuICAgIHR5cGVvZiB0ZW1wbGF0ZU1vZHVsZSA9PT0gXCJmdW5jdGlvblwiXG4gICAgICAgID8gdGVtcGxhdGVNb2R1bGVcbiAgICAgICAgOiAvKiogQHR5cGUge2FueX0gKi8gKHRlbXBsYXRlTW9kdWxlICYmIHRlbXBsYXRlTW9kdWxlLmRlZmF1bHQpXG4pO1xuaW1wb3J0IGZzIGZyb20gXCJub2RlOmZzXCI7XG5cbi8vIENvbXBhY3QgZXJyb3Igb3V0cHV0IHRvIGtlZXAgbG9ncyBzaG9ydFxuZnVuY3Rpb24gY29tcGFjdEVycm9yKGVycm9yLCBpZCkge1xuICAgIHRyeSB7XG4gICAgICAgIGNvbnN0IG5hbWUgPSBlcnJvcj8ubmFtZSB8fCBcIkVycm9yXCI7XG4gICAgICAgIGNvbnN0IGJhc2VNZXNzYWdlID0gZXJyb3I/Lm1lc3NhZ2VcbiAgICAgICAgICAgID8gU3RyaW5nKGVycm9yLm1lc3NhZ2UpXG4gICAgICAgICAgICA6IFN0cmluZyhlcnJvcik7XG4gICAgICAgIGNvbnN0IGZpcnN0TGluZSA9IGJhc2VNZXNzYWdlLnNwbGl0KFwiXFxuXCIpWzBdLnNsaWNlKDAsIDMwMCk7XG4gICAgICAgIGNvbnN0IGxvYyA9XG4gICAgICAgICAgICBlcnJvcj8ubG9jICYmIHR5cGVvZiBlcnJvci5sb2MubGluZSA9PT0gXCJudW1iZXJcIlxuICAgICAgICAgICAgICAgID8gYCAoJHtlcnJvci5sb2MubGluZX06JHtlcnJvci5sb2MuY29sdW1uID8/IDB9KWBcbiAgICAgICAgICAgICAgICA6IFwiXCI7XG4gICAgICAgIGxldCBvdXQgPSBgW3ZpdGUtcGx1Z2luLXY4LXR5cGUtaGludHMtd2l0aC10c10gJHtuYW1lfSR7bG9jfSBpbiAke2lkfTogJHtmaXJzdExpbmV9YDtcbiAgICAgICAgaWYgKGVycm9yPy5zdGFjaykge1xuICAgICAgICAgICAgY29uc3QgZnJhbWVzID0gU3RyaW5nKGVycm9yLnN0YWNrKVxuICAgICAgICAgICAgICAgIC5zcGxpdChcIlxcblwiKVxuICAgICAgICAgICAgICAgIC5zbGljZSgxKVxuICAgICAgICAgICAgICAgIC5maWx0ZXIoXG4gICAgICAgICAgICAgICAgICAgIChsKSA9PlxuICAgICAgICAgICAgICAgICAgICAgICAgIWwuaW5jbHVkZXMoXCJub2RlOmludGVybmFsXCIpICYmXG4gICAgICAgICAgICAgICAgICAgICAgICAhbC5pbmNsdWRlcyhcIm5vZGVfbW9kdWxlc1wiKSxcbiAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICAgICAgLnNsaWNlKDAsIDIpO1xuICAgICAgICAgICAgaWYgKGZyYW1lcy5sZW5ndGggPiAwKSBvdXQgKz0gXCJcXG5cIiArIGZyYW1lcy5qb2luKFwiXFxuXCIpO1xuICAgICAgICB9XG4gICAgICAgIGNvbnN0IE1BWCA9IDYwMDtcbiAgICAgICAgaWYgKG91dC5sZW5ndGggPiBNQVgpIG91dCA9IG91dC5zbGljZSgwLCBNQVgpICsgXCJcdTIwMjZcIjtcbiAgICAgICAgcmV0dXJuIG91dDtcbiAgICB9IGNhdGNoIHtcbiAgICAgICAgcmV0dXJuIGBbdml0ZS1wbHVnaW4tdjgtdHlwZS1oaW50cy13aXRoLXRzXSBFcnJvciBpbiAke2lkfWA7XG4gICAgfVxufVxuXG4vLyBIZWxwZXI6IGh1bWFuLWZyaWVuZGx5IHBhcmFtZXRlciBuYW1lXG5mdW5jdGlvbiBnZXRQYXJhbWV0ZXJOYW1lKHBhcmFtZXRlcikge1xuICAgIHJldHVybiB0LmlzSWRlbnRpZmllcihwYXJhbWV0ZXIpID8gcGFyYW1ldGVyLm5hbWUgOiBcInBhcmFtXCI7XG59XG5cbi8vIE1hcCBUUyB0eXBlIHRvIEpTRG9jIHN0cmluZyAoaGFuZGxlcyBwcmltaXRpdmVzLCBhcnJheXMsIG9iamVjdHMsIGZ1bmN0aW9ucylcbmZ1bmN0aW9uIGVuc3VyZUNvbnRleHQoY29udGV4dCkge1xuICAgIHJldHVybiAoXG4gICAgICAgIGNvbnRleHQgfHwge1xuICAgICAgICAgICAgZGVwdGg6IDAsXG4gICAgICAgICAgICBzZWVuOiBuZXcgU2V0KCksXG4gICAgICAgICAgICBtYXhEZXB0aDogMyxcbiAgICAgICAgICAgIG1heFByb3BzOiAyMCxcbiAgICAgICAgfVxuICAgICk7XG59XG5cbmZ1bmN0aW9uIHRzVHlwZVRvSlNEb2N1bWVudChjaGVja2VyLCB0eXBlLCBjb250ZXh0KSB7XG4gICAgY29udGV4dCA9IGVuc3VyZUNvbnRleHQoY29udGV4dCk7XG4gICAgaWYgKCF0eXBlKSByZXR1cm4gXCJhbnlcIjtcbiAgICBpZiAoY29udGV4dC5kZXB0aCA+IGNvbnRleHQubWF4RGVwdGgpIHJldHVybiBcImFueVwiO1xuICAgIC8vIEN5Y2xlIGd1YXJkIGJ5IGlkIHN0cmluZ1xuICAgIHRyeSB7XG4gICAgICAgIGNvbnN0IGlkID0gY2hlY2tlci50eXBlVG9TdHJpbmcodHlwZSk7XG4gICAgICAgIGlmIChjb250ZXh0LnNlZW4uaGFzKGlkKSkgcmV0dXJuIFwiYW55XCI7XG4gICAgICAgIGNvbnRleHQuc2Vlbi5hZGQoaWQpO1xuICAgIH0gY2F0Y2gge1xuICAgICAgICAvKiBpZ25vcmUgKi9cbiAgICB9XG4gICAgY29uc3QgdHlwZVN0cmluZyA9IGNoZWNrZXIudHlwZVRvU3RyaW5nKHR5cGUpO1xuICAgIGlmICh0eXBlU3RyaW5nID09PSBcIm51bWJlclwiKSByZXR1cm4gXCJudW1iZXJcIjtcbiAgICBpZiAodHlwZVN0cmluZyA9PT0gXCJzdHJpbmdcIikgcmV0dXJuIFwic3RyaW5nXCI7XG4gICAgaWYgKHR5cGVTdHJpbmcgPT09IFwiYm9vbGVhblwiKSByZXR1cm4gXCJib29sZWFuXCI7XG4gICAgLy8gQXJyYXktbGlrZVxuICAgIHRyeSB7XG4gICAgICAgIGlmIChjaGVja2VyLmlzQXJyYXlMaWtlVHlwZSAmJiBjaGVja2VyLmlzQXJyYXlMaWtlVHlwZSh0eXBlKSkge1xuICAgICAgICAgICAgY29uc3QgZWxlbWVudFR5cGUgPVxuICAgICAgICAgICAgICAgIChjaGVja2VyLmdldEFycmF5RWxlbWVudFR5cGUgJiZcbiAgICAgICAgICAgICAgICAgICAgY2hlY2tlci5nZXRBcnJheUVsZW1lbnRUeXBlKHR5cGUpKSB8fFxuICAgICAgICAgICAgICAgIChjaGVja2VyLmdldEVsZW1lbnRUeXBlT2ZBcnJheVR5cGUgJiZcbiAgICAgICAgICAgICAgICAgICAgY2hlY2tlci5nZXRFbGVtZW50VHlwZU9mQXJyYXlUeXBlKHR5cGUpKSB8fFxuICAgICAgICAgICAgICAgIHVuZGVmaW5lZDtcbiAgICAgICAgICAgIGNvbnN0IGVsZW1lbnQgPSBlbGVtZW50VHlwZVxuICAgICAgICAgICAgICAgID8gdHNUeXBlVG9KU0RvY3VtZW50KGNoZWNrZXIsIGVsZW1lbnRUeXBlLCB7XG4gICAgICAgICAgICAgICAgICAgICAgLi4uY29udGV4dCxcbiAgICAgICAgICAgICAgICAgICAgICBkZXB0aDogY29udGV4dC5kZXB0aCArIDEsXG4gICAgICAgICAgICAgICAgICB9KVxuICAgICAgICAgICAgICAgIDogXCJhbnlcIjtcbiAgICAgICAgICAgIHJldHVybiBgJHtlbGVtZW50fVtdYDtcbiAgICAgICAgfVxuICAgIH0gY2F0Y2gge1xuICAgICAgICAvKiBpZ25vcmUgKi9cbiAgICB9XG4gICAgLy8gT2JqZWN0LWxpa2UgLT4ga2VlcCBmb290cHJpbnQgdGlueVxuICAgIGlmICgodHlwZS5mbGFncyAmIHRzLlR5cGVGbGFncy5PYmplY3QpICE9PSAwKSB7XG4gICAgICAgIHJldHVybiBcIm9iamVjdFwiO1xuICAgIH1cbiAgICBpZiAodHlwZS5nZXRDYWxsU2lnbmF0dXJlcyAmJiB0eXBlLmdldENhbGxTaWduYXR1cmVzKCkubGVuZ3RoID4gMClcbiAgICAgICAgcmV0dXJuIFwiRnVuY3Rpb25cIjtcbiAgICByZXR1cm4gdHlwZVN0cmluZyB8fCBcImFueVwiO1xufVxuXG4vLyBBZGQgY29lcmNpb24gQVNUIG5vZGUgKGZvciBudW1iZXJzOiB8IDA7IGV4dGVuZCBhcyBuZWVkZWQpXG5mdW5jdGlvbiBhZGRUeXBlQ29lcmNpb24ocGF0aCwgdHlwZVN0cmluZykge1xuICAgIGlmICh0eXBlU3RyaW5nICE9PSBcIm51bWJlclwiKSByZXR1cm4gZmFsc2U7XG4gICAgY29uc3Qgbm9kZSA9IHBhdGgubm9kZTtcbiAgICBsZXQgdGFyZ2V0Tm9kZSA9IG5vZGUuaW5pdCB8fCBub2RlLmFyZ3VtZW50IHx8IG5vZGUuZXhwcmVzc2lvbiB8fCBub2RlLmxlZnQ7XG4gICAgaWYgKCF0YXJnZXROb2RlKSByZXR1cm4gZmFsc2U7XG4gICAgLy8gV3JhcCB3aXRoIHwgMCB1c2luZyB0ZW1wbGF0ZSB0byBzcGxpY2UgYW4gYXJiaXRyYXJ5IGV4cHJlc3Npb25cbiAgICBjb25zdCBidWlsZCA9IHRlbXBsYXRlLmV4cHJlc3Npb24oXCIoKEVYUFIpKSB8IDBcIik7XG4gICAgY29uc3QgY29lcmNlZCA9IGJ1aWxkKHsgRVhQUjogdGFyZ2V0Tm9kZSB9KTtcbiAgICBpZiAobm9kZS5pbml0KSBub2RlLmluaXQgPSBjb2VyY2VkO1xuICAgIGlmIChub2RlLmFyZ3VtZW50KSBub2RlLmFyZ3VtZW50ID0gY29lcmNlZDtcbiAgICBpZiAobm9kZS5leHByZXNzaW9uKSBub2RlLmV4cHJlc3Npb24gPSBjb2VyY2VkO1xuICAgIGlmIChub2RlLmxlZnQpIG5vZGUubGVmdCA9IGNvZXJjZWQ7XG4gICAgcmV0dXJuIHRydWU7XG59XG5cbmV4cG9ydCBkZWZhdWx0IGZ1bmN0aW9uIHR5cGVoaW50cyhvcHRpb25zID0ge30pIHtcbiAgICBjb25zdCB7XG4gICAgICAgIGluY2x1ZGVOb2RlTW9kdWxlcyA9IHRydWUsXG4gICAgICAgIGVuYWJsZUNvZXJjaW9ucyA9IHRydWUsXG4gICAgICAgIHByb2Nlc3NFdmVyeXRoaW5nID0gdHJ1ZSxcbiAgICAgICAgLy8gUHJlZmVycmVkIG9wdGlvbiBuYW1lcyAoYmFja3dhcmQgY29tcGF0aWJsZSBtYXBwaW5nIGFwcGxpZWQgYmVsb3cpXG4gICAgICAgIHZhcmlhYmxlRG9jdW1lbnRhdGlvbiA9IG9wdGlvbnMudmFyaWFibGVEb2N1bWVudGF0aW9uID8/XG4gICAgICAgICAgICBvcHRpb25zLnZhcmlhYmxlRG9jcyA/P1xuICAgICAgICAgICAgdHJ1ZSxcbiAgICAgICAgb2JqZWN0U2hhcGVEb2N1bWVudGF0aW9uID0gb3B0aW9ucy5vYmplY3RTaGFwZURvY3VtZW50YXRpb24gPz9cbiAgICAgICAgICAgIG9wdGlvbnMub2JqZWN0U2hhcGVEb2NzID8/XG4gICAgICAgICAgICB0cnVlLFxuICAgICAgICBtYXhPYmplY3RQcm9wZXJ0aWVzID0gb3B0aW9ucy5tYXhPYmplY3RQcm9wZXJ0aWVzID8/XG4gICAgICAgICAgICBvcHRpb25zLm1heE9iamVjdFByb3BzID8/XG4gICAgICAgICAgICA4LFxuICAgICAgICBwYXJhbWV0ZXJIb2lzdENvZXJjaW9ucyA9IG9wdGlvbnMucGFyYW1ldGVySG9pc3RDb2VyY2lvbnMgPz9cbiAgICAgICAgICAgIG9wdGlvbnMucGFyYW1Ib2lzdENvZXJjaW9ucyA/P1xuICAgICAgICAgICAgZmFsc2UsXG4gICAgfSA9IG9wdGlvbnM7XG5cbiAgICAvLyBUcmFjayBpZiB3ZSdyZSBpbiBidWlsZCBtb2RlIHRvIGZhaWwgYnVpbGRzIG9uIGVycm9yc1xuICAgIGxldCBpc0J1aWxkID0gZmFsc2U7XG5cbiAgICByZXR1cm4ge1xuICAgICAgICBuYW1lOiBcInZpdGUtcGx1Z2luLXY4LXR5cGUtaGludHMtd2l0aC10c1wiLFxuICAgICAgICAvLyBPbmx5IHJ1biBkdXJpbmcgc3RhdGljIGJ1aWxkc1xuICAgICAgICBhcHBseTogXCJidWlsZFwiLFxuXG4gICAgICAgIGNvbmZpZ1Jlc29sdmVkKGNvbmZpZykge1xuICAgICAgICAgICAgaXNCdWlsZCA9IGNvbmZpZy5jb21tYW5kID09PSBcImJ1aWxkXCI7XG4gICAgICAgIH0sXG5cbiAgICAgICAgYXN5bmMgdHJhbnNmb3JtKGNvZGUsIGlkKSB7XG4gICAgICAgICAgICAvLyBIYXJkIG5vLW9wIGluIGRldiAoZXh0cmEgZ3VhcmQ7IGFwcGx5OiAnYnVpbGQnIGFscmVhZHkgbGltaXRzIHRoaXMpXG4gICAgICAgICAgICBpZiAoIWlzQnVpbGQpIHJldHVybjtcblxuICAgICAgICAgICAgLy8gTm9ybWFsaXplIHBhdGggYW5kIGV4dGVuc2lvblxuICAgICAgICAgICAgY29uc3QgY2xlYW5JZCA9IFN0cmluZyhpZCkuc3BsaXQoXCI/XCIpWzBdO1xuICAgICAgICAgICAgaWYgKCEvXFwuKFtjbV0/anN4PykkL2kudGVzdChjbGVhbklkKSkgcmV0dXJuO1xuICAgICAgICAgICAgaWYgKFxuICAgICAgICAgICAgICAgICFwcm9jZXNzRXZlcnl0aGluZyAmJlxuICAgICAgICAgICAgICAgICFpbmNsdWRlTm9kZU1vZHVsZXMgJiZcbiAgICAgICAgICAgICAgICBjbGVhbklkLmluY2x1ZGVzKFwibm9kZV9tb2R1bGVzXCIpXG4gICAgICAgICAgICApXG4gICAgICAgICAgICAgICAgcmV0dXJuO1xuXG4gICAgICAgICAgICAvLyBTa2lwIHZlcnkgbGFyZ2UgZmlsZXMgdG8gYXZvaWQgaGVhdnkgVFMgaW5mZXJlbmNlIChjb25maWd1cmFibGUgdmlhIGVudiBpbiB0aGUgZnV0dXJlKVxuICAgICAgICAgICAgY29uc3QgTUFYX0ZJTEVfQllURVMgPSAxNTBfMDAwOyAvLyB+MTUwIEtCXG4gICAgICAgICAgICBpZiAoIXByb2Nlc3NFdmVyeXRoaW5nKSB7XG4gICAgICAgICAgICAgICAgaWYgKGNvZGUgJiYgY29kZS5sZW5ndGggPiBNQVhfRklMRV9CWVRFUykgcmV0dXJuO1xuICAgICAgICAgICAgICAgIC8vIFNraXAgY29tbW9uIHZlbmRvci1saWtlIGRpcnMgaW4gYXBwIHRvIGF2b2lkIGRlZXAgdHlwZSByZWN1cnNpb25cbiAgICAgICAgICAgICAgICBpZiAoY2xlYW5JZC5pbmNsdWRlcyhcIi9hcHAvamF2YXNjcmlwdC9saWJzL1wiKSkgcmV0dXJuO1xuICAgICAgICAgICAgICAgIC8vIFNraXAgYnVpbHQgZGlzdCBidW5kbGVzIGNvbW1vbmx5IGxhcmdlIGluIG5vZGVfbW9kdWxlc1xuICAgICAgICAgICAgICAgIGlmIChjbGVhbklkLmluY2x1ZGVzKFwiL2Rpc3QvXCIpIHx8IC9cXC5taW5cXC5qcyQvaS50ZXN0KGNsZWFuSWQpKVxuICAgICAgICAgICAgICAgICAgICByZXR1cm47XG4gICAgICAgICAgICB9XG5cbiAgICAgICAgICAgIHRyeSB7XG4gICAgICAgICAgICAgICAgbGV0IGRpZENoYW5nZSA9IGZhbHNlO1xuICAgICAgICAgICAgICAgIGxldCBiYWlsT3V0ID0gZmFsc2U7XG4gICAgICAgICAgICAgICAgLy8gU3RlcCAxOiBDcmVhdGUgYSBUUyBQcm9ncmFtIHRoYXQgY2FuIHR5cGUtY2hlY2sgdGhpcyBKUyBmaWxlXG4gICAgICAgICAgICAgICAgY29uc3QgY29tcGlsZXJPcHRpb25zID0ge1xuICAgICAgICAgICAgICAgICAgICBhbGxvd0pzOiB0cnVlLFxuICAgICAgICAgICAgICAgICAgICBjaGVja0pzOiB0cnVlLFxuICAgICAgICAgICAgICAgICAgICBub0VtaXQ6IHRydWUsXG4gICAgICAgICAgICAgICAgICAgIHRhcmdldDogdHMuU2NyaXB0VGFyZ2V0LkxhdGVzdCxcbiAgICAgICAgICAgICAgICAgICAgbW9kdWxlOiB0cy5Nb2R1bGVLaW5kLkVTTmV4dCxcbiAgICAgICAgICAgICAgICAgICAgc3RyaWN0OiBmYWxzZSxcbiAgICAgICAgICAgICAgICB9O1xuXG4gICAgICAgICAgICAgICAgLy8gTm9ybWFsaXplIGlkIChzdHJpcCBxdWVyeSkgYW5kIHVzZSBmaWxlc3lzdGVtIGhvc3RcbiAgICAgICAgICAgICAgICBjb25zdCBmaWxlUGF0aCA9IGNsZWFuSWQ7XG4gICAgICAgICAgICAgICAgY29uc3QgcHJvZ3JhbSA9IHRzLmNyZWF0ZVByb2dyYW0oW2ZpbGVQYXRoXSwgY29tcGlsZXJPcHRpb25zKTtcbiAgICAgICAgICAgICAgICBjb25zdCBzb3VyY2VGaWxlID1cbiAgICAgICAgICAgICAgICAgICAgcHJvZ3JhbS5nZXRTb3VyY2VGaWxlKGZpbGVQYXRoKSB8fFxuICAgICAgICAgICAgICAgICAgICB0cy5jcmVhdGVTb3VyY2VGaWxlKFxuICAgICAgICAgICAgICAgICAgICAgICAgZmlsZVBhdGgsXG4gICAgICAgICAgICAgICAgICAgICAgICBmcy5leGlzdHNTeW5jKGZpbGVQYXRoKVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgID8gZnMucmVhZEZpbGVTeW5jKGZpbGVQYXRoLCBcInV0ZjhcIilcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICA6IGNvZGUsXG4gICAgICAgICAgICAgICAgICAgICAgICB0cy5TY3JpcHRUYXJnZXQuTGF0ZXN0LFxuICAgICAgICAgICAgICAgICAgICAgICAgdHJ1ZSxcbiAgICAgICAgICAgICAgICAgICAgICAgIHRzLlNjcmlwdEtpbmQuSlMsXG4gICAgICAgICAgICAgICAgICAgICk7XG4gICAgICAgICAgICAgICAgY29uc3QgY2hlY2tlciA9IHByb2dyYW0uZ2V0VHlwZUNoZWNrZXIoKTtcblxuICAgICAgICAgICAgICAgIC8vIFN0ZXAgMjogUGFyc2UgQmFiZWwgQVNUIGZvciB0cmFuc2Zvcm1hdGlvbiAodXNlIEJhYmVsIGZvciBjb2RlIGdlbilcbiAgICAgICAgICAgICAgICBjb25zdCBiYWJlbEFzdCA9IHBhcnNlKGNvZGUsIHtcbiAgICAgICAgICAgICAgICAgICAgc291cmNlVHlwZTogXCJtb2R1bGVcIixcbiAgICAgICAgICAgICAgICAgICAgcGx1Z2luczogW1xuICAgICAgICAgICAgICAgICAgICAgICAgXCJqc3hcIixcbiAgICAgICAgICAgICAgICAgICAgICAgIFwiZHluYW1pY0ltcG9ydFwiLFxuICAgICAgICAgICAgICAgICAgICAgICAgXCJpbXBvcnRNZXRhXCIsXG4gICAgICAgICAgICAgICAgICAgICAgICAvLyBCYWJlbCA3IHN1cHBvcnRzIGltcG9ydEFzc2VydGlvbnM7IG5ld2VyIGltcG9ydHMgbWF5IG5lZWQgaW1wb3J0QXR0cmlidXRlcyBpbiBuZXdlciBCYWJlbFxuICAgICAgICAgICAgICAgICAgICAgICAgXCJpbXBvcnRBc3NlcnRpb25zXCIsXG4gICAgICAgICAgICAgICAgICAgICAgICBcInRvcExldmVsQXdhaXRcIixcbiAgICAgICAgICAgICAgICAgICAgXSxcbiAgICAgICAgICAgICAgICAgICAgc291cmNlRmlsZW5hbWU6IGlkLFxuICAgICAgICAgICAgICAgIH0pO1xuXG4gICAgICAgICAgICAgICAgLy8gSWYgdHJhdmVyc2UvZ2VuZXJhdGUvdGVtcGxhdGUgZmFpbGVkIHRvIG5vcm1hbGl6ZSwgc2tpcCB0byBhdm9pZCBjcmFzaGluZ1xuICAgICAgICAgICAgICAgIGlmICh0eXBlb2YgdHJhdmVyc2UgIT09IFwiZnVuY3Rpb25cIiB8fCAhdGVtcGxhdGUpIHtcbiAgICAgICAgICAgICAgICAgICAgcmV0dXJuO1xuICAgICAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgICAgIC8vIFN0ZXAgMzogVHJhdmVyc2UgQmFiZWwgQVNUIGFuZCBpbmZlci9hZGQgaGludHMgdXNpbmcgVFMgY2hlY2tlclxuICAgICAgICAgICAgICAgIC8vIE5vdGU6IE1hcCBCYWJlbCBub2RlcyB0byBUUyBub2RlcyB2aWEgcG9zaXRpb25zIGZvciBnZXRUeXBlQXRMb2NhdGlvblxuICAgICAgICAgICAgICAgIC8vIFV0aWxpdHk6IGNyZWF0ZSAvKiEgLi4uICovIHN0eWxlIGJsb2NrIGNvbW1lbnQgb25seSBvbmNlXG4gICAgICAgICAgICAgICAgZnVuY3Rpb24gYWRkQmxvY2tEb2N1bWVudChwYXRoT3JOb2RlLCB0ZXh0KSB7XG4gICAgICAgICAgICAgICAgICAgIGlmICghdGV4dCkgcmV0dXJuO1xuICAgICAgICAgICAgICAgICAgICBjb25zdCBub2RlID0gcGF0aE9yTm9kZS5ub2RlIHx8IHBhdGhPck5vZGU7IC8vIGFjY2VwdCBwYXRoIG9yIG5vZGVcbiAgICAgICAgICAgICAgICAgICAgY29uc3QgZXhpc3RpbmcgPSAobm9kZS5sZWFkaW5nQ29tbWVudHMgfHwgW10pLnNvbWUoXG4gICAgICAgICAgICAgICAgICAgICAgICAoYykgPT5cbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBjLnR5cGUgPT09IFwiQ29tbWVudEJsb2NrXCIgJiZcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAoYy52YWx1ZS5pbmNsdWRlcyhcIkB0eXBlXCIpIHx8XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGMudmFsdWUuaW5jbHVkZXMoXCJAcmV0dXJuc1wiKSksXG4gICAgICAgICAgICAgICAgICAgICk7XG4gICAgICAgICAgICAgICAgICAgIGlmIChleGlzdGluZykgcmV0dXJuO1xuICAgICAgICAgICAgICAgICAgICBpZiAocGF0aE9yTm9kZS5hZGRDb21tZW50KSB7XG4gICAgICAgICAgICAgICAgICAgICAgICBwYXRoT3JOb2RlLmFkZENvbW1lbnQoXCJsZWFkaW5nXCIsIGAhICR7dGV4dH1gLCBmYWxzZSk7XG4gICAgICAgICAgICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAvLyBGYWxsYmFjazogcHVzaCBpbnRvIGxlYWRpbmdDb21tZW50cyBtYW51YWxseVxuICAgICAgICAgICAgICAgICAgICAgICAgbm9kZS5sZWFkaW5nQ29tbWVudHMgPSBbXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgLi4uKG5vZGUubGVhZGluZ0NvbW1lbnRzIHx8IFtdKSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB7IHR5cGU6IFwiQ29tbWVudEJsb2NrXCIsIHZhbHVlOiBgISAke3RleHR9YCB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgXTtcbiAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgICAgIC8vIEhldXJpc3RpYyBvYmplY3QgbGl0ZXJhbCBzaGFwZSBpbmZlcmVuY2UgKEJhYmVsIG5vZGUgYmFzZWQgdG8gc3RheSBmYXN0KVxuICAgICAgICAgICAgICAgIGZ1bmN0aW9uIGluZmVyT2JqZWN0U2hhcGUoYmFiZWxPYmplY3RFeHByKSB7XG4gICAgICAgICAgICAgICAgICAgIGlmICghb2JqZWN0U2hhcGVEb2N1bWVudGF0aW9uKSByZXR1cm47XG4gICAgICAgICAgICAgICAgICAgIGlmICghdC5pc09iamVjdEV4cHJlc3Npb24oYmFiZWxPYmplY3RFeHByKSkgcmV0dXJuO1xuICAgICAgICAgICAgICAgICAgICBjb25zdCBwcm9wZXJ0aWVzID0gYmFiZWxPYmplY3RFeHByLnByb3BlcnRpZXMuZmlsdGVyKFxuICAgICAgICAgICAgICAgICAgICAgICAgKHApID0+XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdC5pc09iamVjdFByb3BlcnR5KHApICYmXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgKHQuaXNJZGVudGlmaWVyKHAua2V5KSB8fCB0LmlzU3RyaW5nTGl0ZXJhbChwLmtleSkpLFxuICAgICAgICAgICAgICAgICAgICApO1xuICAgICAgICAgICAgICAgICAgICBpZiAoXG4gICAgICAgICAgICAgICAgICAgICAgICBwcm9wZXJ0aWVzLmxlbmd0aCA9PT0gMCB8fFxuICAgICAgICAgICAgICAgICAgICAgICAgcHJvcGVydGllcy5sZW5ndGggPiBtYXhPYmplY3RQcm9wZXJ0aWVzXG4gICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybjtcbiAgICAgICAgICAgICAgICAgICAgY29uc3QgcGFydHMgPSBbXTtcbiAgICAgICAgICAgICAgICAgICAgZm9yIChjb25zdCBwcm9wZXJ0eSBvZiBwcm9wZXJ0aWVzKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICBjb25zdCBrZXkgPSB0LmlzSWRlbnRpZmllcihwcm9wZXJ0eS5rZXkpXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgPyBwcm9wZXJ0eS5rZXkubmFtZVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIDogcHJvcGVydHkua2V5LnZhbHVlO1xuICAgICAgICAgICAgICAgICAgICAgICAgbGV0IHZhbHVlTm9kZSA9IHByb3BlcnR5LnZhbHVlO1xuICAgICAgICAgICAgICAgICAgICAgICAgbGV0IHR5cGVQYXJ0ID0gXCJhbnlcIjtcbiAgICAgICAgICAgICAgICAgICAgICAgIGlmICh0LmlzTnVtZXJpY0xpdGVyYWwodmFsdWVOb2RlKSkgdHlwZVBhcnQgPSBcIm51bWJlclwiO1xuICAgICAgICAgICAgICAgICAgICAgICAgZWxzZSBpZiAodC5pc1N0cmluZ0xpdGVyYWwodmFsdWVOb2RlKSlcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB0eXBlUGFydCA9IFwic3RyaW5nXCI7XG4gICAgICAgICAgICAgICAgICAgICAgICBlbHNlIGlmICh0LmlzQm9vbGVhbkxpdGVyYWwodmFsdWVOb2RlKSlcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB0eXBlUGFydCA9IFwiYm9vbGVhblwiO1xuICAgICAgICAgICAgICAgICAgICAgICAgZWxzZSBpZiAodC5pc051bGxMaXRlcmFsKHZhbHVlTm9kZSkpIHR5cGVQYXJ0ID0gXCJhbnlcIjtcbiAgICAgICAgICAgICAgICAgICAgICAgIGVsc2UgaWYgKHQuaXNBcnJheUV4cHJlc3Npb24odmFsdWVOb2RlKSkge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIC8vIFNpbXBsZSB1bmlmb3JtIHByaW1pdGl2ZSBkZXRlY3Rpb25cbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBpZiAodmFsdWVOb2RlLmVsZW1lbnRzLmxlbmd0aCA9PT0gMClcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdHlwZVBhcnQgPSBcImFueVtdXCI7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZWxzZSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbnN0IGZpcnN0ID0gdmFsdWVOb2RlLmVsZW1lbnRzWzBdO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBpZiAodC5pc051bWVyaWNMaXRlcmFsKGZpcnN0KSlcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHR5cGVQYXJ0ID0gXCJudW1iZXJbXVwiO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBlbHNlIGlmICh0LmlzU3RyaW5nTGl0ZXJhbChmaXJzdCkpXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB0eXBlUGFydCA9IFwic3RyaW5nW11cIjtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZWxzZSBpZiAodC5pc0Jvb2xlYW5MaXRlcmFsKGZpcnN0KSlcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHR5cGVQYXJ0ID0gXCJib29sZWFuW11cIjtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZWxzZSB0eXBlUGFydCA9IFwiYW55W11cIjtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgICAgICAgICB9IGVsc2UgaWYgKHQuaXNPYmplY3RFeHByZXNzaW9uKHZhbHVlTm9kZSkpXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdHlwZVBhcnQgPSBcIm9iamVjdFwiO1xuICAgICAgICAgICAgICAgICAgICAgICAgZWxzZSBpZiAodC5pc1RlbXBsYXRlTGl0ZXJhbCh2YWx1ZU5vZGUpKVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHR5cGVQYXJ0ID0gXCJzdHJpbmdcIjtcbiAgICAgICAgICAgICAgICAgICAgICAgIGVsc2UgaWYgKFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHQuaXNVbmFyeUV4cHJlc3Npb24odmFsdWVOb2RlKSAmJlxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlTm9kZS5vcGVyYXRvciA9PT0gXCIrXCJcbiAgICAgICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB0eXBlUGFydCA9IFwibnVtYmVyXCI7XG4gICAgICAgICAgICAgICAgICAgICAgICBlbHNlIGlmIChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB0LmlzQmluYXJ5RXhwcmVzc2lvbih2YWx1ZU5vZGUpICYmXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgW1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBcIitcIixcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgXCItXCIsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIFwiKlwiLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBcIi9cIixcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgXCIlXCIsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIFwifFwiLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBcIiZcIixcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgXCJeXCIsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIFwiPDxcIixcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgXCI+PlwiLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBcIj4+PlwiLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIF0uaW5jbHVkZXModmFsdWVOb2RlLm9wZXJhdG9yKVxuICAgICAgICAgICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHR5cGVQYXJ0ID0gXCJudW1iZXJcIjtcbiAgICAgICAgICAgICAgICAgICAgICAgIGVsc2UgaWYgKHQuaXNDYWxsRXhwcmVzc2lvbih2YWx1ZU5vZGUpKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgLy8gSGV1cmlzdGljOiBNYXRoLiogPT4gbnVtYmVyLCBTdHJpbmcvTnVtYmVyL0Jvb2xlYW4gY29uc3RydWN0b3JzXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgaWYgKFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB0LmlzTWVtYmVyRXhwcmVzc2lvbih2YWx1ZU5vZGUuY2FsbGVlKSAmJlxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB0LmlzSWRlbnRpZmllcih2YWx1ZU5vZGUuY2FsbGVlLm9iamVjdCwge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogXCJNYXRoXCIsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIH0pXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB0eXBlUGFydCA9IFwibnVtYmVyXCI7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZWxzZSBpZiAoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHQuaXNJZGVudGlmaWVyKHZhbHVlTm9kZS5jYWxsZWUsIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6IFwiTnVtYmVyXCIsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIH0pXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB0eXBlUGFydCA9IFwibnVtYmVyXCI7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZWxzZSBpZiAoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHQuaXNJZGVudGlmaWVyKHZhbHVlTm9kZS5jYWxsZWUsIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6IFwiU3RyaW5nXCIsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIH0pXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB0eXBlUGFydCA9IFwic3RyaW5nXCI7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZWxzZSBpZiAoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHQuaXNJZGVudGlmaWVyKHZhbHVlTm9kZS5jYWxsZWUsIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6IFwiQm9vbGVhblwiLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB9KVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdHlwZVBhcnQgPSBcImJvb2xlYW5cIjtcbiAgICAgICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICAgICAgICAgIHBhcnRzLnB1c2goYCR7a2V5fTogJHt0eXBlUGFydH1gKTtcbiAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgICBpZiAocGFydHMubGVuZ3RoID09PSAwKSByZXR1cm47XG4gICAgICAgICAgICAgICAgICAgIHJldHVybiBgeyAke3BhcnRzLmpvaW4oXCIsIFwiKX0gfWA7XG4gICAgICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICAgICAgLy8gVHJhY2sgdmFyaWFibGUgdHlwZXMgYnkgaWRlbnRpZmllciBuYW1lIChiZXN0LWVmZm9ydCkgZm9yIGxhdGVyIHBhcmFtIGNvZXJjaW9uIGRlY2lzaW9uc1xuICAgICAgICAgICAgICAgIGNvbnN0IGluZmVycmVkVmFyaWFibGVUeXBlcyA9IG5ldyBNYXAoKTtcblxuICAgICAgICAgICAgICAgIHRyYXZlcnNlKGJhYmVsQXN0LCB7XG4gICAgICAgICAgICAgICAgICAgIEZ1bmN0aW9uRGVjbGFyYXRpb24ocGF0aCkge1xuICAgICAgICAgICAgICAgICAgICAgICAgaWYgKCFwYXRoLm5vZGUuaWQpIHJldHVybjtcbiAgICAgICAgICAgICAgICAgICAgICAgIGNvbnN0IHRzTm9kZSA9IGZpbmRUU05vZGVBdFBvc2l0aW9uKFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNvdXJjZUZpbGUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcGF0aC5ub2RlLmlkLnN0YXJ0LFxuICAgICAgICAgICAgICAgICAgICAgICAgKTtcbiAgICAgICAgICAgICAgICAgICAgICAgIGlmICghdHNOb2RlKSByZXR1cm47XG4gICAgICAgICAgICAgICAgICAgICAgICBsZXQgZnVuY3Rpb25UeXBlO1xuICAgICAgICAgICAgICAgICAgICAgICAgdHJ5IHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBmdW5jdGlvblR5cGUgPSBjaGVja2VyLmdldFR5cGVBdExvY2F0aW9uKHRzTm9kZSk7XG4gICAgICAgICAgICAgICAgICAgICAgICB9IGNhdGNoIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBiYWlsT3V0ID0gdHJ1ZTtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZXR1cm47XG4gICAgICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgICAgICAgICBsZXQgc2lncztcbiAgICAgICAgICAgICAgICAgICAgICAgIHRyeSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgc2lncyA9IGNoZWNrZXIuZ2V0U2lnbmF0dXJlc09mVHlwZVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA/IGNoZWNrZXIuZ2V0U2lnbmF0dXJlc09mVHlwZShcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZnVuY3Rpb25UeXBlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB0cy5TaWduYXR1cmVLaW5kLkNhbGwsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA6IGZ1bmN0aW9uVHlwZS5nZXRDYWxsU2lnbmF0dXJlc1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgID8gZnVuY3Rpb25UeXBlLmdldENhbGxTaWduYXR1cmVzKClcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA6IFtdO1xuICAgICAgICAgICAgICAgICAgICAgICAgfSBjYXRjaCB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgYmFpbE91dCA9IHRydWU7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuO1xuICAgICAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgICAgICAgY29uc3Qgc2lnID1cbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzaWdzICYmIHNpZ3MubGVuZ3RoID4gMCA/IHNpZ3NbMF0gOiB1bmRlZmluZWQ7XG4gICAgICAgICAgICAgICAgICAgICAgICBpZiAoIXNpZykgcmV0dXJuO1xuXG4gICAgICAgICAgICAgICAgICAgICAgICAvLyBQYXJhbXMgZnJvbSBzaWduYXR1cmVcbiAgICAgICAgICAgICAgICAgICAgICAgIGxldCBwYXJhbWV0ZXJUeXBlcztcbiAgICAgICAgICAgICAgICAgICAgICAgIHRyeSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcGFyYW1ldGVyVHlwZXMgPSBzaWcucGFyYW1ldGVycy5tYXAoKHBhcmFtZXRlcikgPT4ge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb25zdCBkZWNsID1cbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHBhcmFtZXRlci52YWx1ZURlY2xhcmF0aW9uIHx8XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBwYXJhbWV0ZXIuZGVjbGFyYXRpb25zPy5bMF07XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbnN0IHBUeXBlID0gZGVjbFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgPyBjaGVja2VyLmdldFR5cGVPZlN5bWJvbEF0TG9jYXRpb24oXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBwYXJhbWV0ZXIsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkZWNsLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA6IHVuZGVmaW5lZDtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIHRzVHlwZVRvSlNEb2N1bWVudChjaGVja2VyLCBwVHlwZSk7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgfSk7XG4gICAgICAgICAgICAgICAgICAgICAgICB9IGNhdGNoIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBiYWlsT3V0ID0gdHJ1ZTtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZXR1cm47XG4gICAgICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgICAgICAgICBsZXQgcmV0dXJuVHlwZSA9IFwiYW55XCI7XG4gICAgICAgICAgICAgICAgICAgICAgICB0cnkge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJldHVyblR5cGUgPSB0c1R5cGVUb0pTRG9jdW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNoZWNrZXIsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNoZWNrZXIuZ2V0UmV0dXJuVHlwZU9mU2lnbmF0dXJlKHNpZyksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgKTtcbiAgICAgICAgICAgICAgICAgICAgICAgIH0gY2F0Y2gge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIC8qIGlnbm9yZSAqL1xuICAgICAgICAgICAgICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICAgICAgICAgICAgICAvLyBTa2lwIGVtaXR0aW5nIHdoZW4gZXZlcnl0aGluZyBpcyAnYW55JyB0byBtaW5pbWl6ZSBmb290cHJpbnRcbiAgICAgICAgICAgICAgICAgICAgICAgIGNvbnN0IGlzTWVhbmluZ2Z1bCA9XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuVHlwZSAhPT0gXCJhbnlcIiB8fFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHBhcmFtZXRlclR5cGVzLnNvbWUoKHRfKSA9PiB0XyAhPT0gXCJhbnlcIik7XG4gICAgICAgICAgICAgICAgICAgICAgICBpZiAoIWlzTWVhbmluZ2Z1bCkgcmV0dXJuO1xuXG4gICAgICAgICAgICAgICAgICAgICAgICAvLyBBZGQgSlNEb2MgKHByZXNlcnZlZCBieSB0ZXJzZXIgdmlhIC8qISAuLi4gKi87IHNpbmdsZS1saW5lIHRvIG1pbmltaXplIHNpemUpXG4gICAgICAgICAgICAgICAgICAgICAgICBjb25zdCBwYXJhbWV0ZXJEb2N1bWVudGF0aW9uID0gcGF0aC5ub2RlLnBhcmFtcy5tYXAoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgKHBhcmFtZXRlciwgaW5kZXgpID0+XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGBAcGFyYW0geyR7cGFyYW1ldGVyVHlwZXNbaW5kZXhdIHx8IFwiYW55XCJ9fSAke2dldFBhcmFtZXRlck5hbWUocGFyYW1ldGVyKX1gLFxuICAgICAgICAgICAgICAgICAgICAgICAgKTtcbiAgICAgICAgICAgICAgICAgICAgICAgIGNvbnN0IGRvY3VtZW50XyA9IGAhICR7Wy4uLnBhcmFtZXRlckRvY3VtZW50YXRpb24sIGBAcmV0dXJucyB7JHtyZXR1cm5UeXBlfX1gXS5qb2luKFwiIFwiKX1gO1xuICAgICAgICAgICAgICAgICAgICAgICAgLy8gT25seSBhZGQgb25jZVxuICAgICAgICAgICAgICAgICAgICAgICAgY29uc3QgZXhpc3RpbmdMZWFkID0gcGF0aC5ub2RlLmxlYWRpbmdDb21tZW50cyB8fCBbXTtcbiAgICAgICAgICAgICAgICAgICAgICAgIGNvbnN0IGFscmVhZHlIYXNKU0RvY3VtZW50ID0gZXhpc3RpbmdMZWFkLnNvbWUoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgKGMpID0+XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGMudHlwZSA9PT0gXCJDb21tZW50QmxvY2tcIiAmJlxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAoYy52YWx1ZS5pbmNsdWRlcyhcIkByZXR1cm5zXCIpIHx8XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjLnZhbHVlLnN0YXJ0c1dpdGgoXCIhXCIpKSxcbiAgICAgICAgICAgICAgICAgICAgICAgICk7XG4gICAgICAgICAgICAgICAgICAgICAgICBpZiAoIWFscmVhZHlIYXNKU0RvY3VtZW50KSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcGF0aC5hZGRDb21tZW50KFwibGVhZGluZ1wiLCBkb2N1bWVudF8sIGZhbHNlKTsgLy8gZmFsc2UgPT4gYmxvY2sgY29tbWVudCA9PiAvKiEgLi4uICovXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZGlkQ2hhbmdlID0gdHJ1ZTtcbiAgICAgICAgICAgICAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgICAgICAgICAgICAgLy8gT3B0aW9uYWw6IEluamVjdCBwYXJhbSBjb2VyY2lvbnMgYXQgdG9wIG9mIGZ1bmN0aW9uIGJvZHkgaWYgZW5hYmxlZFxuICAgICAgICAgICAgICAgICAgICAgICAgaWYgKFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGVuYWJsZUNvZXJjaW9ucyAmJlxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHBhcmFtZXRlckhvaXN0Q29lcmNpb25zICYmXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcGF0aC5ub2RlLmJvZHkgJiZcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBBcnJheS5pc0FycmF5KHBhdGgubm9kZS5wYXJhbXMpXG4gICAgICAgICAgICAgICAgICAgICAgICApIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb25zdCBjb2VyY2lvblN0YXRlbWVudHMgPSBbXTtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBsZXQgaW5kZXggPSAwO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGZvciAoY29uc3QgcCBvZiBwYXRoLm5vZGUucGFyYW1zKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGlmIChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHBhcmFtZXRlclR5cGVzW2luZGV4XSA9PT0gXCJudW1iZXJcIiAmJlxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdC5pc0lkZW50aWZpZXIocClcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb2VyY2lvblN0YXRlbWVudHMucHVzaChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB0ZW1wbGF0ZS5zdGF0ZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGAke3AubmFtZX0gPSAoJHtwLm5hbWV9KSB8IDA7YCxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICApKCksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICApO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGluZGV4ICs9IDE7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGlmIChjb2VyY2lvblN0YXRlbWVudHMubGVuZ3RoID4gMCkge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBwYXRoLm5vZGUuYm9keS5ib2R5LnVuc2hpZnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAuLi5jb2VyY2lvblN0YXRlbWVudHMsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICk7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRpZENoYW5nZSA9IHRydWU7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICAgICAgICAgICAgICAvLyBDb2VyY2UgcGFyYW1zL3JldHVybnMgaWYgbnVtYmVyXG4gICAgICAgICAgICAgICAgICAgICAgICBpZiAoZW5hYmxlQ29lcmNpb25zKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcGF0aC50cmF2ZXJzZSh7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIEJpbmFyeUV4cHJlc3Npb24oc3ViUGF0aCkge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgY29uc3QgcGFyYW1ldGVyTm9kZSA9IHBhdGgubm9kZS5wYXJhbXMuZmluZChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAocCkgPT5cbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdC5pc0lkZW50aWZpZXIocCkgJiZcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdC5pc0lkZW50aWZpZXIoc3ViUGF0aC5ub2RlLmxlZnQpICYmXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHAubmFtZSA9PT0gc3ViUGF0aC5ub2RlLmxlZnQubmFtZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICk7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBpZiAoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcGFyYW1ldGVyTm9kZSAmJlxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHBhcmFtZXRlclR5cGVzW1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBwYXRoLm5vZGUucGFyYW1zLmluZGV4T2YoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBwYXJhbWV0ZXJOb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgXSA9PT0gXCJudW1iZXJcIiAmJlxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGFkZFR5cGVDb2VyY2lvbihzdWJQYXRoLCBcIm51bWJlclwiKVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRpZENoYW5nZSA9IHRydWU7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJldHVyblN0YXRlbWVudChzdWJQYXRoKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBpZiAoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgc3ViUGF0aC5ub2RlLmFyZ3VtZW50ICYmXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuVHlwZSA9PT0gXCJudW1iZXJcIiAmJlxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGFkZFR5cGVDb2VyY2lvbihzdWJQYXRoLCBcIm51bWJlclwiKVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRpZENoYW5nZSA9IHRydWU7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgfSk7XG4gICAgICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgICAgIH0sXG4gICAgICAgICAgICAgICAgICAgIFZhcmlhYmxlRGVjbGFyYXRvcihwYXRoKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICBjb25zdCB0c05vZGUgPSBmaW5kVFNOb2RlQXRQb3NpdGlvbihcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzb3VyY2VGaWxlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHBhdGgubm9kZS5pZC5zdGFydCxcbiAgICAgICAgICAgICAgICAgICAgICAgICk7XG4gICAgICAgICAgICAgICAgICAgICAgICBpZiAoIXRzTm9kZSB8fCAhcGF0aC5ub2RlLmluaXQpIHJldHVybjtcbiAgICAgICAgICAgICAgICAgICAgICAgIGxldCB2YXJpYWJsZVR5cGU7XG4gICAgICAgICAgICAgICAgICAgICAgICB0cnkge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhcmlhYmxlVHlwZSA9IGNoZWNrZXIuZ2V0VHlwZUF0TG9jYXRpb24odHNOb2RlKTtcbiAgICAgICAgICAgICAgICAgICAgICAgIH0gY2F0Y2gge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybjtcbiAgICAgICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICAgICAgICAgIGNvbnN0IHR5cGVTdHJpbmcgPSB0c1R5cGVUb0pTRG9jdW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgY2hlY2tlcixcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YXJpYWJsZVR5cGUsXG4gICAgICAgICAgICAgICAgICAgICAgICApO1xuICAgICAgICAgICAgICAgICAgICAgICAgaWYgKHQuaXNJZGVudGlmaWVyKHBhdGgubm9kZS5pZCkpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBpbmZlcnJlZFZhcmlhYmxlVHlwZXMuc2V0KFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBwYXRoLm5vZGUuaWQubmFtZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdHlwZVN0cmluZyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICApO1xuICAgICAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgICAgICAgLy8gQWRkIHZhcmlhYmxlIGxldmVsIEpTRG9jIGlmIGVuYWJsZWQgJiBtZWFuaW5nZnVsXG4gICAgICAgICAgICAgICAgICAgICAgICBpZiAoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFyaWFibGVEb2N1bWVudGF0aW9uICYmXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdC5pc0lkZW50aWZpZXIocGF0aC5ub2RlLmlkKVxuICAgICAgICAgICAgICAgICAgICAgICAgKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbGV0IGRvY3VtZW50VHlwZSA9IHR5cGVTdHJpbmc7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgLy8gUmVmaW5lIGZvciBvYmplY3QgbGl0ZXJhbCB3aGVuIGdlbmVyaWMgJ29iamVjdCdcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBpZiAoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRvY3VtZW50VHlwZSA9PT0gXCJvYmplY3RcIiAmJlxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBvYmplY3RTaGFwZURvY3VtZW50YXRpb24gJiZcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdC5pc09iamVjdEV4cHJlc3Npb24ocGF0aC5ub2RlLmluaXQpXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbnN0IHNoYXBlID0gaW5mZXJPYmplY3RTaGFwZShwYXRoLm5vZGUuaW5pdCk7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGlmIChzaGFwZSkgZG9jdW1lbnRUeXBlID0gc2hhcGU7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIC8vIFJlZmluZSBmb3IgYXJyYXlzIG9mIHNpbXBsZSBwcmltaXRpdmVzIGZyb20gbGl0ZXJhbFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGlmICh0LmlzQXJyYXlFeHByZXNzaW9uKHBhdGgubm9kZS5pbml0KSkge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBpZiAocGF0aC5ub2RlLmluaXQuZWxlbWVudHMubGVuZ3RoID09PSAwKVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZG9jdW1lbnRUeXBlID0gXCJhbnlbXVwiO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBlbHNlIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbnN0IGZpcnN0ID0gcGF0aC5ub2RlLmluaXQuZWxlbWVudHNbMF07XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBpZiAodC5pc051bWVyaWNMaXRlcmFsKGZpcnN0KSlcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkb2N1bWVudFR5cGUgPSBcIm51bWJlcltdXCI7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBlbHNlIGlmICh0LmlzU3RyaW5nTGl0ZXJhbChmaXJzdCkpXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZG9jdW1lbnRUeXBlID0gXCJzdHJpbmdbXVwiO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZWxzZSBpZiAodC5pc0Jvb2xlYW5MaXRlcmFsKGZpcnN0KSlcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkb2N1bWVudFR5cGUgPSBcImJvb2xlYW5bXVwiO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZWxzZSBkb2N1bWVudFR5cGUgPSBcImFueVtdXCI7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgaWYgKGRvY3VtZW50VHlwZSAmJiBkb2N1bWVudFR5cGUgIT09IFwiYW55XCIpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgYWRkQmxvY2tEb2N1bWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHBhdGgsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBgQHR5cGUgeyR7ZG9jdW1lbnRUeXBlfX1gLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICApO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkaWRDaGFuZ2UgPSB0cnVlO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICAgICAgICAgIGlmIChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBlbmFibGVDb2VyY2lvbnMgJiZcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB0eXBlU3RyaW5nID09PSBcIm51bWJlclwiICYmXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgYWRkVHlwZUNvZXJjaW9uKHBhdGgsIFwibnVtYmVyXCIpXG4gICAgICAgICAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZGlkQ2hhbmdlID0gdHJ1ZTtcbiAgICAgICAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgICAgICAgICAgRm9yT2ZTdGF0ZW1lbnQocGF0aCkge1xuICAgICAgICAgICAgICAgICAgICAgICAgbGV0IGxlZnRJZDtcbiAgICAgICAgICAgICAgICAgICAgICAgIGlmICh0LmlzVmFyaWFibGVEZWNsYXJhdGlvbihwYXRoLm5vZGUubGVmdCkpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb25zdCBmaXJzdCA9IHBhdGgubm9kZS5sZWZ0LmRlY2xhcmF0aW9ucz8uWzBdO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGlmIChmaXJzdCAmJiB0LmlzSWRlbnRpZmllcihmaXJzdC5pZCkpXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGxlZnRJZCA9IGZpcnN0LmlkO1xuICAgICAgICAgICAgICAgICAgICAgICAgfSBlbHNlIGlmICh0LmlzSWRlbnRpZmllcihwYXRoLm5vZGUubGVmdCkpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBsZWZ0SWQgPSBwYXRoLm5vZGUubGVmdDtcbiAgICAgICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICAgICAgICAgIGlmICghbGVmdElkKSByZXR1cm47XG4gICAgICAgICAgICAgICAgICAgICAgICBjb25zdCByaWdodFRTTm9kZSA9IGZpbmRUU05vZGVBdFBvc2l0aW9uKFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNvdXJjZUZpbGUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcGF0aC5ub2RlLnJpZ2h0LnN0YXJ0LFxuICAgICAgICAgICAgICAgICAgICAgICAgKTtcbiAgICAgICAgICAgICAgICAgICAgICAgIGlmICghcmlnaHRUU05vZGUpIHJldHVybjtcbiAgICAgICAgICAgICAgICAgICAgICAgIGxldCBhcnJheVR5cGU7XG4gICAgICAgICAgICAgICAgICAgICAgICB0cnkge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGFycmF5VHlwZSA9IGNoZWNrZXIuZ2V0VHlwZUF0TG9jYXRpb24ocmlnaHRUU05vZGUpO1xuICAgICAgICAgICAgICAgICAgICAgICAgfSBjYXRjaCB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuO1xuICAgICAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgICAgICAgbGV0IGVsZW1lbnRUeXBlO1xuICAgICAgICAgICAgICAgICAgICAgICAgdHJ5IHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBlbGVtZW50VHlwZSA9XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIChjaGVja2VyLmdldEFycmF5RWxlbWVudFR5cGUgJiZcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNoZWNrZXIuZ2V0QXJyYXlFbGVtZW50VHlwZShhcnJheVR5cGUpKSB8fFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAoY2hlY2tlci5nZXRFbGVtZW50VHlwZU9mQXJyYXlUeXBlICYmXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjaGVja2VyLmdldEVsZW1lbnRUeXBlT2ZBcnJheVR5cGUoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgYXJyYXlUeXBlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgKSkgfHxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdW5kZWZpbmVkO1xuICAgICAgICAgICAgICAgICAgICAgICAgfSBjYXRjaCB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgLyogaWdub3JlICovXG4gICAgICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgICAgICAgICBjb25zdCBlbGVtZW50U3RyaW5nID0gdHNUeXBlVG9KU0RvY3VtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNoZWNrZXIsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZWxlbWVudFR5cGUsXG4gICAgICAgICAgICAgICAgICAgICAgICApO1xuICAgICAgICAgICAgICAgICAgICAgICAgaWYgKGVuYWJsZUNvZXJjaW9ucyAmJiBlbGVtZW50U3RyaW5nID09PSBcIm51bWJlclwiKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcGF0aC50cmF2ZXJzZSh7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIEJpbmFyeUV4cHJlc3Npb24oc3ViUGF0aCkge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgaWYgKFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHQuaXNJZGVudGlmaWVyKHN1YlBhdGgubm9kZS5sZWZ0KSAmJlxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHQuaXNJZGVudGlmaWVyKGxlZnRJZCkgJiZcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBzdWJQYXRoLm5vZGUubGVmdC5uYW1lID09PVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBsZWZ0SWQubmFtZSAmJlxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGFkZFR5cGVDb2VyY2lvbihzdWJQYXRoLCBcIm51bWJlclwiKVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRpZENoYW5nZSA9IHRydWU7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgfSk7XG4gICAgICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgICAgIH0sXG4gICAgICAgICAgICAgICAgICAgIC8vIERlb3B0IHdhcm5pbmc6IER5bmFtaWMgcHJvcHNcbiAgICAgICAgICAgICAgICAgICAgQXNzaWdubWVudEV4cHJlc3Npb24ocGF0aCkge1xuICAgICAgICAgICAgICAgICAgICAgICAgaWYgKFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHBhdGgubm9kZS5sZWZ0Py5jb21wdXRlZCAmJlxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHBhdGgubm9kZS5sZWZ0LnByb3BlcnR5Py50eXBlICE9PSBcIklkZW50aWZpZXJcIlxuICAgICAgICAgICAgICAgICAgICAgICAgKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgLy9lc2xpbnQtZGlzYWJsZS1uZXh0LWxpbmUgbm8tdW51c2VkLXZhcnNcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb25zdCBsaW5lID1cbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcGF0aC5ub2RlLmxvYyAmJiBwYXRoLm5vZGUubG9jLnN0YXJ0XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA/IHBhdGgubm9kZS5sb2Muc3RhcnQubGluZVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgOiBcIj9cIjtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAvKlxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbnNvbGUud2FybihcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgYFBvdGVudGlhbCBWOCBkZW9wdGltaXphdGlvbjogRHluYW1pYyBwcm9wZXJ0eSBhdCBsaW5lICR7bGluZX1gLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICk7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgKi9cbiAgICAgICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgICAgICB9KTtcblxuICAgICAgICAgICAgICAgIC8vIEhlbHBlcjogRmluZCBUUyBub2RlIGF0IEJhYmVsIHBvc2l0aW9uIChhcHByb3hpbWF0ZSB2aWEgcG9zKVxuICAgICAgICAgICAgICAgIGZ1bmN0aW9uIGZpbmRUU05vZGVBdFBvc2l0aW9uKHNvdXJjZUZpbGUsIHBvcykge1xuICAgICAgICAgICAgICAgICAgICBsZXQgcmVzdWx0O1xuICAgICAgICAgICAgICAgICAgICBmdW5jdGlvbiB2aXNpdChub2RlKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICBpZiAocG9zIDwgbm9kZS5wb3MgfHwgcG9zID49IG5vZGUuZW5kKSByZXR1cm47XG4gICAgICAgICAgICAgICAgICAgICAgICByZXN1bHQgPSBub2RlO1xuICAgICAgICAgICAgICAgICAgICAgICAgbm9kZS5mb3JFYWNoQ2hpbGQodmlzaXQpO1xuICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgICAgIHZpc2l0KHNvdXJjZUZpbGUpO1xuICAgICAgICAgICAgICAgICAgICByZXR1cm4gcmVzdWx0O1xuICAgICAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgICAgIGlmIChiYWlsT3V0IHx8ICFkaWRDaGFuZ2UpIHJldHVybjtcbiAgICAgICAgICAgICAgICAvLyBTdGVwIDQ6IEdlbmVyYXRlIHRyYW5zZm9ybWVkIGNvZGUgd2l0aCBzb3VyY2UgbWFwIChvbmx5IGlmIGNoYW5nZWQpXG4gICAgICAgICAgICAgICAgY29uc3QgeyBjb2RlOiB0cmFuc2Zvcm1lZENvZGUsIG1hcCB9ID0gZ2VuZXJhdGUoYmFiZWxBc3QsIHtcbiAgICAgICAgICAgICAgICAgICAgc291cmNlTWFwczogdHJ1ZSxcbiAgICAgICAgICAgICAgICAgICAgc291cmNlRmlsZU5hbWU6IGlkLFxuICAgICAgICAgICAgICAgIH0pO1xuXG4gICAgICAgICAgICAgICAgcmV0dXJuIHtcbiAgICAgICAgICAgICAgICAgICAgY29kZTogdHJhbnNmb3JtZWRDb2RlLFxuICAgICAgICAgICAgICAgICAgICBtYXAsXG4gICAgICAgICAgICAgICAgfTtcbiAgICAgICAgICAgIH0gY2F0Y2ggKGVycm9yKSB7XG4gICAgICAgICAgICAgICAgY29uc3QgZXJyb3JfID1cbiAgICAgICAgICAgICAgICAgICAgZXJyb3IgaW5zdGFuY2VvZiBFcnJvciA/IGVycm9yIDogbmV3IEVycm9yKFN0cmluZyhlcnJvcikpO1xuICAgICAgICAgICAgICAgIGlmIChpc0J1aWxkKSB7XG4gICAgICAgICAgICAgICAgICAgIC8vIEZhaWwgdGhlIGJ1aWxkIHdpdGggY29tcGFjdCBtZXNzYWdlXG4gICAgICAgICAgICAgICAgICAgIHRoaXMuZXJyb3IoY29tcGFjdEVycm9yKGVycm9yXywgaWQpKTtcbiAgICAgICAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgICAgICAgICAvLyBLZWVwIGRldiBzZXJ2ZXIgcnVubmluZyB3aXRoIGNvbXBhY3QgbWVzc2FnZVxuICAgICAgICAgICAgICAgICAgICBjb25zb2xlLmVycm9yKGNvbXBhY3RFcnJvcihlcnJvcl8sIGlkKSk7XG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgIHJldHVybjsgLy8gR3JhY2VmdWwgZmFsbGJhY2sgaW4gZGV2XG4gICAgICAgICAgICB9XG4gICAgICAgIH0sXG4gICAgICAgIC8vIE5vIEhNUiBiZWhhdmlvcjsgcGx1Z2luIG9ubHkgYXBwbGllcyBpbiBidWlsZFxuICAgIH07XG59XG4iLCAiY29uc3QgX192aXRlX2luamVjdGVkX29yaWdpbmFsX2Rpcm5hbWUgPSBcIi9Vc2Vycy9nZW9yZ2UvTGlicmV2ZXJzZS9wbHVnaW5zXCI7Y29uc3QgX192aXRlX2luamVjdGVkX29yaWdpbmFsX2ZpbGVuYW1lID0gXCIvVXNlcnMvZ2VvcmdlL0xpYnJldmVyc2UvcGx1Z2lucy9wb3N0Y3NzLXJlbW92ZS1wcmVmaXguanNcIjtjb25zdCBfX3ZpdGVfaW5qZWN0ZWRfb3JpZ2luYWxfaW1wb3J0X21ldGFfdXJsID0gXCJmaWxlOi8vL1VzZXJzL2dlb3JnZS9MaWJyZXZlcnNlL3BsdWdpbnMvcG9zdGNzcy1yZW1vdmUtcHJlZml4LmpzXCI7ZnVuY3Rpb24gcmVtb3ZlUHJlZml4KCkge1xuICAgIHJldHVybiB7XG4gICAgICAgIHBvc3Rjc3NQbHVnaW46IFwicmVtb3ZlLXByZWZpeFwiLFxuICAgICAgICBEZWNsYXJhdGlvbihkZWNsKSB7XG4gICAgICAgICAgICBkZWNsLnByb3AgPSBkZWNsLnByb3AucmVwbGFjZSgvXi1cXHcrLS8sIFwiXCIpO1xuICAgICAgICB9LFxuICAgIH07XG59XG5yZW1vdmVQcmVmaXgucG9zdGNzcyA9IHRydWU7XG5leHBvcnQgZGVmYXVsdCByZW1vdmVQcmVmaXg7XG4iLCAiY29uc3QgX192aXRlX2luamVjdGVkX29yaWdpbmFsX2Rpcm5hbWUgPSBcIi9Vc2Vycy9nZW9yZ2UvTGlicmV2ZXJzZS9jb25maWcvdml0ZVwiO2NvbnN0IF9fdml0ZV9pbmplY3RlZF9vcmlnaW5hbF9maWxlbmFtZSA9IFwiL1VzZXJzL2dlb3JnZS9MaWJyZXZlcnNlL2NvbmZpZy92aXRlL2NvbW1vbi5qc1wiO2NvbnN0IF9fdml0ZV9pbmplY3RlZF9vcmlnaW5hbF9pbXBvcnRfbWV0YV91cmwgPSBcImZpbGU6Ly8vVXNlcnMvZ2VvcmdlL0xpYnJldmVyc2UvY29uZmlnL3ZpdGUvY29tbW9uLmpzXCI7Ly8gU2hhcmVkIFZpdGUgY29uZmlnIGhlbHBlcnMgdXNlZCBieSBib3RoIHRoZSBSYWlscyBWaXRlIGRldiBzZXJ2ZXIgYW5kIEVsZWN0cm9uIEZvcmdlLlxuLy8gS2VlcCB0aGlzIGZpbGUgZGVwZW5kZW5jeS1mcmVlIChiZXNpZGVzIE5vZGUgYnVpbHRpbnMpIHNvIGl0IGNhbiBiZSBpbXBvcnRlZCBmcm9tIGNvbmZpZyBmaWxlcy5cblxuZXhwb3J0IGNvbnN0IGFsbE9iZnVzY2F0b3JDb25maWcgPSB7XG4gICAgZXhjbHVkZXM6IFtdLFxuICAgIGVuYWJsZTogdHJ1ZSxcbiAgICBsb2c6IHRydWUsXG4gICAgYXV0b0V4Y2x1ZGVOb2RlTW9kdWxlczogdHJ1ZSxcbiAgICB0aHJlYWRQb29sOiB0cnVlLFxuICAgIG9wdGlvbnM6IHtcbiAgICAgICAgY29tcGFjdDogdHJ1ZSxcbiAgICAgICAgY29udHJvbEZsb3dGbGF0dGVuaW5nOiB0cnVlLFxuICAgICAgICBjb250cm9sRmxvd0ZsYXR0ZW5pbmdUaHJlc2hvbGQ6IDEsXG4gICAgICAgIGRlYWRDb2RlSW5qZWN0aW9uOiBmYWxzZSxcbiAgICAgICAgZGVidWdQcm90ZWN0aW9uOiBmYWxzZSxcbiAgICAgICAgZGVidWdQcm90ZWN0aW9uSW50ZXJ2YWw6IDAsXG4gICAgICAgIGRpc2FibGVDb25zb2xlT3V0cHV0OiBmYWxzZSxcbiAgICAgICAgaWRlbnRpZmllck5hbWVzR2VuZXJhdG9yOiBcImhleGFkZWNpbWFsXCIsXG4gICAgICAgIGxvZzogZmFsc2UsXG4gICAgICAgIG51bWJlcnNUb0V4cHJlc3Npb25zOiBmYWxzZSxcbiAgICAgICAgcmVuYW1lR2xvYmFsczogZmFsc2UsXG4gICAgICAgIHNlbGZEZWZlbmRpbmc6IHRydWUsXG4gICAgICAgIHNpbXBsaWZ5OiB0cnVlLFxuICAgICAgICBzcGxpdFN0cmluZ3M6IGZhbHNlLFxuICAgICAgICBpZ25vcmVJbXBvcnRzOiB0cnVlLFxuICAgICAgICBzdHJpbmdBcnJheTogdHJ1ZSxcbiAgICAgICAgc3RyaW5nQXJyYXlDYWxsc1RyYW5zZm9ybTogdHJ1ZSxcbiAgICAgICAgc3RyaW5nQXJyYXlDYWxsc1RyYW5zZm9ybVRocmVzaG9sZDogMC41LFxuICAgICAgICBzdHJpbmdBcnJheUVuY29kaW5nOiBbXSxcbiAgICAgICAgc3RyaW5nQXJyYXlJbmRleFNoaWZ0OiB0cnVlLFxuICAgICAgICBzdHJpbmdBcnJheVJvdGF0ZTogdHJ1ZSxcbiAgICAgICAgc3RyaW5nQXJyYXlTaHVmZmxlOiB0cnVlLFxuICAgICAgICBzdHJpbmdBcnJheVdyYXBwZXJzQ291bnQ6IDEsXG4gICAgICAgIHN0cmluZ0FycmF5V3JhcHBlcnNDaGFpbmVkQ2FsbHM6IHRydWUsXG4gICAgICAgIHN0cmluZ0FycmF5V3JhcHBlcnNQYXJhbWV0ZXJzTWF4Q291bnQ6IDIsXG4gICAgICAgIHN0cmluZ0FycmF5V3JhcHBlcnNUeXBlOiBcInZhcmlhYmxlXCIsXG4gICAgICAgIHN0cmluZ0FycmF5VGhyZXNob2xkOiAwLjc1LFxuICAgICAgICB1bmljb2RlRXNjYXBlU2VxdWVuY2U6IGZhbHNlLFxuICAgIH0sXG59O1xuXG5leHBvcnQgZnVuY3Rpb24gd2l0aEluc3RydW1lbnRhdGlvbihwKSB7XG4gICAgbGV0IG1vZGlmaWVkID0gMDtcbiAgICByZXR1cm4ge1xuICAgICAgICAuLi5wLFxuICAgICAgICBhc3luYyB0cmFuc2Zvcm0oY29kZSwgaWQpIHtcbiAgICAgICAgICAgIGNvbnN0IG91dCA9IGF3YWl0IHAudHJhbnNmb3JtLmNhbGwodGhpcywgY29kZSwgaWQpO1xuICAgICAgICAgICAgaWYgKG91dCAmJiBvdXQuY29kZSAmJiBvdXQuY29kZSAhPT0gY29kZSkgbW9kaWZpZWQgKz0gMTtcbiAgICAgICAgICAgIHJldHVybiBvdXQ7XG4gICAgICAgIH0sXG4gICAgICAgIGJ1aWxkRW5kKCkge1xuICAgICAgICAgICAgdGhpcy5pbmZvKGBbdHlwZWhpbnRzXSBGaWxlcyBtb2RpZmllZDogJHttb2RpZmllZH1gKTtcbiAgICAgICAgICAgIGlmIChwLmJ1aWxkRW5kKSByZXR1cm4gcC5idWlsZEVuZC5jYWxsKHRoaXMpO1xuICAgICAgICB9LFxuICAgIH07XG59XG5cbmV4cG9ydCBmdW5jdGlvbiBjcmVhdGVUeXBlaGludFBsdWdpbih0eXBlaGludHNQbHVnaW5GYWN0b3J5KSB7XG4gICAgcmV0dXJuIHdpdGhJbnN0cnVtZW50YXRpb24oXG4gICAgICAgIHR5cGVoaW50c1BsdWdpbkZhY3Rvcnkoe1xuICAgICAgICAgICAgdmFyaWFibGVEb2N1bWVudGF0aW9uOiB0cnVlLFxuICAgICAgICAgICAgb2JqZWN0U2hhcGVEb2N1bWVudGF0aW9uOiB0cnVlLFxuICAgICAgICAgICAgbWF4T2JqZWN0UHJvcGVydGllczogNixcbiAgICAgICAgICAgIGVuYWJsZUNvZXJjaW9uczogdHJ1ZSxcbiAgICAgICAgICAgIHBhcmFtZXRlckhvaXN0Q29lcmNpb25zOiBmYWxzZSxcbiAgICAgICAgfSksXG4gICAgKTtcbn1cblxuZXhwb3J0IGZ1bmN0aW9uIGNyZWF0ZUVzYnVpbGRDb25maWcoaXNEZXZlbG9wbWVudCkge1xuICAgIHJldHVybiB7XG4gICAgICAgIHRhcmdldDogXCJlczIwMjBcIiwgLy8gTW9kZXJuIHRhcmdldFxuICAgICAgICBrZWVwTmFtZXM6IGZhbHNlLFxuICAgICAgICB0cmVlU2hha2luZzogaXNEZXZlbG9wbWVudCA/IGZhbHNlIDogdHJ1ZSwgLy8gRGlzYWJsZSB0cmVlIHNoYWtpbmcgaW4gZGV2ZWxvcG1lbnQgZm9yIGZhc3RlciBidWlsZHNcbiAgICAgICAgbGVnYWxDb21tZW50czogaXNEZXZlbG9wbWVudCA/IFwibm9uZVwiIDogXCJpbmxpbmVcIiwgLy8gU2tpcCBsZWdhbCBjb21tZW50cyBpbiBkZXZlbG9wbWVudFxuICAgIH07XG59XG5cbi8vIFNoYXJlZCBkZXZlbG9wbWVudCBoZWFkZXJzIGZvciBWaXRlIGRldiBzZXJ2ZXJzLlxuLy9cbi8vIFRoZXNlIGhlbHAgd2hlbiB0aGUgcmVuZGVyZXIgdXNlcyBDT0VQL2NyZWRlbnRpYWxsZXNzIGFuZCBlbWJlZHMgY29udGVudCBmcm9tXG4vLyBvdGhlciBsb2NhbCBvcmlnaW5zIChkaWZmZXJlbnQgcG9ydCksIHdoaWNoIGNhbiBvdGhlcndpc2UgY2F1c2UgQ09SUC9DT0VQXG4vLyBibG9ja2luZyBpbiBDaHJvbWl1bS9FbGVjdHJvbi5cbmV4cG9ydCBmdW5jdGlvbiBkZXZWaXRlU2VjdXJpdHlIZWFkZXJzKCkge1xuICAgIGNvbnN0IGhlYWRlcnMgPSB7XG4gICAgICAgIFwiQ2FjaGUtQ29udHJvbFwiOiBcIm5vLXN0b3JlLCBuby1jYWNoZSwgbXVzdC1yZXZhbGlkYXRlLCBtYXgtYWdlPTBcIixcbiAgICAgICAgLy8gRGV2LW9ubHkgY29udmVuaWVuY2U7IHByb2R1Y3Rpb24gYnVpbGRzIHNob3VsZCB1c2Ugc3RyaWN0ZXIgcG9saWNpZXMuXG4gICAgICAgIC8vIFRoaXMgYWxsb3dzIHRoZSBWaXRlIHJlbmRlcmVyIChodHRwczovL2xvY2FsaG9zdDo1MTczKSB0byBlbWJlZCB0aGUgUmFpbHNcbiAgICAgICAgLy8gVUkgKGh0dHBzOi8vbG9jYWxob3N0OjMwMDApIHdpdGhvdXQgQ09SUC9DT0VQIGNvbmZ1c2lvbi5cbiAgICAgICAgXCJDcm9zcy1PcmlnaW4tUmVzb3VyY2UtUG9saWN5XCI6IFwiY3Jvc3Mtb3JpZ2luXCIsXG4gICAgfTtcblxuICAgIC8vIENPRVAgbWFrZXMgdGhlIGRvY3VtZW50IGNyb3NzLW9yaWdpbiBpc29sYXRlZCBhbmQgZm9yY2VzIENPUlAvQ09SUyBydWxlc1xuICAgIC8vIG9uIGVtYmVkZGVkIHJlc291cmNlcyAoaW5jbHVkaW5nIGlmcmFtZXMpLiBUaGlzIGlzIHVzZWZ1bCBmb3IgZmVhdHVyZXNcbiAgICAvLyBsaWtlIFNoYXJlZEFycmF5QnVmZmVyLCBidXQgaXQgY2FuIGJyZWFrIHRoZSBFbGVjdHJvbiBkZXYgc2hlbGwgd2hlbiB0aGVcbiAgICAvLyBSYWlscyBVSSBpcyBlbWJlZGRlZCBmcm9tIGFub3RoZXIgb3JpZ2luL3BvcnQuXG4gICAgLy9cbiAgICAvLyBFbmFibGUgZXhwbGljaXRseSB3aGVuIG5lZWRlZDpcbiAgICAvLyAgIFZJVEVfRU5BQkxFX0NPRVA9MVxuICAgIGlmIChwcm9jZXNzLmVudi5WSVRFX0VOQUJMRV9DT0VQID09PSBcIjFcIikge1xuICAgICAgICBoZWFkZXJzW1wiQ3Jvc3MtT3JpZ2luLUVtYmVkZGVyLVBvbGljeVwiXSA9IFwiY3JlZGVudGlhbGxlc3NcIjtcbiAgICB9XG5cbiAgICByZXR1cm4gaGVhZGVycztcbn1cblxuZXhwb3J0IGZ1bmN0aW9uIGNyZWF0ZVRlcnNlck9wdGlvbnMoaXNEZXZlbG9wbWVudCkge1xuICAgIGlmIChpc0RldmVsb3BtZW50KSByZXR1cm4gdW5kZWZpbmVkO1xuXG4gICAgcmV0dXJuIHtcbiAgICAgICAgcGFyc2U6IHtcbiAgICAgICAgICAgIGJhcmVfcmV0dXJuczogZmFsc2UsXG4gICAgICAgICAgICBodG1sNV9jb21tZW50czogZmFsc2UsXG4gICAgICAgICAgICBzaGViYW5nOiBmYWxzZSxcbiAgICAgICAgICAgIGVjbWE6IDIwMjAsIC8vIE1vZGVybiBwYXJzaW5nXG4gICAgICAgIH0sXG4gICAgICAgIGNvbXByZXNzOiB7XG4gICAgICAgICAgICBkZWZhdWx0czogdHJ1ZSxcbiAgICAgICAgICAgIGFycm93czogdHJ1ZSwgLy8gS2VlcCBhcnJvdyBmdW5jdGlvbnNcbiAgICAgICAgICAgIGFyZ3VtZW50czogdHJ1ZSxcbiAgICAgICAgICAgIGJvb2xlYW5zOiB0cnVlLFxuICAgICAgICAgICAgYm9vbGVhbnNfYXNfaW50ZWdlcnM6IGZhbHNlLFxuICAgICAgICAgICAgY29sbGFwc2VfdmFyczogdHJ1ZSxcbiAgICAgICAgICAgIGNvbXBhcmlzb25zOiB0cnVlLFxuICAgICAgICAgICAgY29tcHV0ZWRfcHJvcHM6IHRydWUsXG4gICAgICAgICAgICBjb25kaXRpb25hbHM6IHRydWUsXG4gICAgICAgICAgICBkZWFkX2NvZGU6IHRydWUsXG4gICAgICAgICAgICBkaXJlY3RpdmVzOiB0cnVlLFxuICAgICAgICAgICAgZHJvcF9jb25zb2xlOiB0cnVlLFxuICAgICAgICAgICAgZHJvcF9kZWJ1Z2dlcjogdHJ1ZSxcbiAgICAgICAgICAgIGVjbWE6IDIwMjAsIC8vIE1vZGVybiBjb21wcmVzc2lvblxuICAgICAgICAgICAgZXZhbHVhdGU6IHRydWUsXG4gICAgICAgICAgICBleHByZXNzaW9uOiBmYWxzZSxcbiAgICAgICAgICAgIGdsb2JhbF9kZWZzOiB7fSxcbiAgICAgICAgICAgIGhvaXN0X2Z1bnM6IHRydWUsXG4gICAgICAgICAgICBob2lzdF9wcm9wczogdHJ1ZSxcbiAgICAgICAgICAgIGhvaXN0X3ZhcnM6IHRydWUsXG4gICAgICAgICAgICBpZl9yZXR1cm46IHRydWUsXG4gICAgICAgICAgICBpbmxpbmU6IHRydWUsXG4gICAgICAgICAgICBqb2luX3ZhcnM6IHRydWUsXG4gICAgICAgICAgICBrZWVwX2NsYXNzbmFtZXM6IGZhbHNlLFxuICAgICAgICAgICAga2VlcF9mYXJnczogdHJ1ZSxcbiAgICAgICAgICAgIGtlZXBfZm5hbWVzOiBmYWxzZSxcbiAgICAgICAgICAgIGtlZXBfaW5maW5pdHk6IGZhbHNlLFxuICAgICAgICAgICAgbG9vcHM6IHRydWUsXG4gICAgICAgICAgICBuZWdhdGVfaWlmZTogdHJ1ZSxcbiAgICAgICAgICAgIHBhc3NlczogMTAsXG4gICAgICAgICAgICBwcm9wZXJ0aWVzOiB0cnVlLFxuICAgICAgICAgICAgcHVyZV9nZXR0ZXJzOiBcInN0cmljdFwiLFxuICAgICAgICAgICAgcHVyZV9mdW5jczogW1xuICAgICAgICAgICAgICAgIFwiY29uc29sZS5sb2dcIixcbiAgICAgICAgICAgICAgICBcImNvbnNvbGUuaW5mb1wiLFxuICAgICAgICAgICAgICAgIFwiY29uc29sZS5kZWJ1Z1wiLFxuICAgICAgICAgICAgICAgIFwiY29uc29sZS53YXJuXCIsXG4gICAgICAgICAgICAgICAgXCJjb25zb2xlLmVycm9yXCIsXG4gICAgICAgICAgICAgICAgXCJjb25zb2xlLnRyYWNlXCIsXG4gICAgICAgICAgICAgICAgXCJjb25zb2xlLmRpclwiLFxuICAgICAgICAgICAgICAgIFwiY29uc29sZS5kaXJ4bWxcIixcbiAgICAgICAgICAgICAgICBcImNvbnNvbGUuZ3JvdXBcIixcbiAgICAgICAgICAgICAgICBcImNvbnNvbGUuZ3JvdXBDb2xsYXBzZWRcIixcbiAgICAgICAgICAgICAgICBcImNvbnNvbGUuZ3JvdXBFbmRcIixcbiAgICAgICAgICAgICAgICBcImNvbnNvbGUudGltZVwiLFxuICAgICAgICAgICAgICAgIFwiY29uc29sZS50aW1lRW5kXCIsXG4gICAgICAgICAgICAgICAgXCJjb25zb2xlLnRpbWVMb2dcIixcbiAgICAgICAgICAgICAgICBcImNvbnNvbGUuYXNzZXJ0XCIsXG4gICAgICAgICAgICAgICAgXCJjb25zb2xlLmNvdW50XCIsXG4gICAgICAgICAgICAgICAgXCJjb25zb2xlLmNvdW50UmVzZXRcIixcbiAgICAgICAgICAgICAgICBcImNvbnNvbGUucHJvZmlsZVwiLFxuICAgICAgICAgICAgICAgIFwiY29uc29sZS5wcm9maWxlRW5kXCIsXG4gICAgICAgICAgICAgICAgXCJjb25zb2xlLnRhYmxlXCIsXG4gICAgICAgICAgICAgICAgXCJjb25zb2xlLmNsZWFyXCIsXG4gICAgICAgICAgICBdLFxuICAgICAgICAgICAgcmVkdWNlX3ZhcnM6IHRydWUsXG4gICAgICAgICAgICByZWR1Y2VfZnVuY3M6IHRydWUsXG4gICAgICAgICAgICBzZXF1ZW5jZXM6IHRydWUsXG4gICAgICAgICAgICBzaWRlX2VmZmVjdHM6IHRydWUsXG4gICAgICAgICAgICBzd2l0Y2hlczogdHJ1ZSxcbiAgICAgICAgICAgIHRvcGxldmVsOiB0cnVlLFxuICAgICAgICAgICAgdG9wX3JldGFpbjogbnVsbCxcbiAgICAgICAgICAgIHR5cGVvZnM6IHRydWUsXG4gICAgICAgICAgICB1bnNhZmU6IHRydWUsXG4gICAgICAgICAgICB1bnNhZmVfYXJyb3dzOiB0cnVlLFxuICAgICAgICAgICAgdW5zYWZlX2NvbXBzOiB0cnVlLFxuICAgICAgICAgICAgdW5zYWZlX0Z1bmN0aW9uOiB0cnVlLFxuICAgICAgICAgICAgdW5zYWZlX21hdGg6IHRydWUsXG4gICAgICAgICAgICB1bnNhZmVfc3ltYm9sczogdHJ1ZSxcbiAgICAgICAgICAgIHVuc2FmZV9tZXRob2RzOiB0cnVlLFxuICAgICAgICAgICAgdW5zYWZlX3Byb3RvOiB0cnVlLFxuICAgICAgICAgICAgdW5zYWZlX3JlZ2V4cDogdHJ1ZSxcbiAgICAgICAgICAgIHVuc2FmZV91bmRlZmluZWQ6IHRydWUsXG4gICAgICAgICAgICB1bnVzZWQ6IHRydWUsXG4gICAgICAgIH0sXG4gICAgICAgIG1hbmdsZToge1xuICAgICAgICAgICAgZXZhbDogZmFsc2UsXG4gICAgICAgICAgICBrZWVwX2NsYXNzbmFtZXM6IGZhbHNlLFxuICAgICAgICAgICAga2VlcF9mbmFtZXM6IGZhbHNlLFxuICAgICAgICAgICAgcmVzZXJ2ZWQ6IFtdLFxuICAgICAgICAgICAgdG9wbGV2ZWw6IHRydWUsXG4gICAgICAgICAgICBzYWZhcmkxMDogZmFsc2UsXG4gICAgICAgIH0sXG4gICAgICAgIGZvcm1hdDoge1xuICAgICAgICAgICAgYXNjaWlfb25seTogZmFsc2UsXG4gICAgICAgICAgICBiZWF1dGlmeTogZmFsc2UsXG4gICAgICAgICAgICBicmFjZXM6IGZhbHNlLFxuICAgICAgICAgICAgY29tbWVudHM6IFwic29tZVwiLFxuICAgICAgICAgICAgZWNtYTogMjAyMCxcbiAgICAgICAgICAgIGluZGVudF9sZXZlbDogMCxcbiAgICAgICAgICAgIGlubGluZV9zY3JpcHQ6IHRydWUsXG4gICAgICAgICAgICBrZWVwX251bWJlcnM6IGZhbHNlLFxuICAgICAgICAgICAga2VlcF9xdW90ZWRfcHJvcHM6IGZhbHNlLFxuICAgICAgICAgICAgbWF4X2xpbmVfbGVuOiAwLFxuICAgICAgICAgICAgcXVvdGVfa2V5czogZmFsc2UsXG4gICAgICAgICAgICBwcmVzZXJ2ZV9hbm5vdGF0aW9uczogZmFsc2UsXG4gICAgICAgICAgICBzYWZhcmkxMDogZmFsc2UsXG4gICAgICAgICAgICBzZW1pY29sb25zOiB0cnVlLFxuICAgICAgICAgICAgc2hlYmFuZzogZmFsc2UsXG4gICAgICAgICAgICB3ZWJraXQ6IGZhbHNlLFxuICAgICAgICAgICAgd3JhcF9paWZlOiBmYWxzZSxcbiAgICAgICAgICAgIHdyYXBfZnVuY19hcmdzOiBmYWxzZSxcbiAgICAgICAgfSxcbiAgICB9O1xufVxuXG5leHBvcnQgZnVuY3Rpb24gY3JlYXRlUm9sbHVwT3V0cHV0Q29uZmlnKCkge1xuICAgIHJldHVybiB7XG4gICAgICAgIG1pbmlmeUludGVybmFsRXhwb3J0czogdHJ1ZSxcbiAgICAgICAgaW5saW5lRHluYW1pY0ltcG9ydHM6IGZhbHNlLFxuICAgICAgICBjb21wYWN0OiB0cnVlLFxuICAgICAgICBnZW5lcmF0ZWRDb2RlOiB7XG4gICAgICAgICAgICBwcmVzZXQ6IFwiZXMyMDE1XCIsXG4gICAgICAgICAgICBhcnJvd0Z1bmN0aW9uczogdHJ1ZSxcbiAgICAgICAgICAgIGNvbnN0QmluZGluZ3M6IHRydWUsXG4gICAgICAgICAgICBvYmplY3RTaG9ydGhhbmQ6IHRydWUsXG4gICAgICAgIH0sXG4gICAgfTtcbn1cblxuZXhwb3J0IGZ1bmN0aW9uIGNyZWF0ZUNvbW1vbkJ1aWxkKHsgaXNEZXZlbG9wbWVudCwgcm9sbHVwSW5wdXQgfSA9IHt9KSB7XG4gICAgY29uc3QgYnVpbGQgPSB7XG4gICAgICAgIGNhY2hlOiBpc0RldmVsb3BtZW50LFxuICAgICAgICByb2xsdXBPcHRpb25zOiB7XG4gICAgICAgICAgICBvdXRwdXQ6IGNyZWF0ZVJvbGx1cE91dHB1dENvbmZpZygpLFxuICAgICAgICAgICAgZXh0ZXJuYWw6IFtdLFxuICAgICAgICAgICAgdHJlZXNoYWtlOiB7XG4gICAgICAgICAgICAgICAgbW9kdWxlU2lkZUVmZmVjdHM6IHRydWUsXG4gICAgICAgICAgICAgICAgcHJvcGVydHlSZWFkU2lkZUVmZmVjdHM6IGZhbHNlLFxuICAgICAgICAgICAgICAgIHRyeUNhdGNoRGVvcHRpbWl6YXRpb246IGZhbHNlLFxuICAgICAgICAgICAgICAgIHVua25vd25HbG9iYWxTaWRlRWZmZWN0czogZmFsc2UsXG4gICAgICAgICAgICB9LFxuICAgICAgICB9LFxuICAgICAgICB0YXJnZXQ6IFtcImVzMjAyMFwiLCBcImVkZ2U4OFwiLCBcImZpcmVmb3g3OFwiLCBcImNocm9tZTg3XCIsIFwic2FmYXJpMTRcIl0sXG4gICAgICAgIG1vZHVsZVByZWxvYWQ6IHsgcG9seWZpbGw6IHRydWUgfSxcbiAgICAgICAgY3NzQ29kZVNwbGl0OiB0cnVlLFxuICAgICAgICBhc3NldHNJbmxpbmVMaW1pdDogNTAwMDAwLFxuICAgICAgICBjc3NUYXJnZXQ6IFtcImVzbmV4dFwiXSxcbiAgICAgICAgc291cmNlbWFwOiBmYWxzZSxcbiAgICAgICAgY2h1bmtTaXplV2FybmluZ0xpbWl0OiAyMTQ3NDgzNjQ3LFxuICAgICAgICByZXBvcnRDb21wcmVzc2VkU2l6ZTogZmFsc2UsXG4gICAgICAgIG1pbmlmeTogaXNEZXZlbG9wbWVudCA/IGZhbHNlIDogXCJ0ZXJzZXJcIixcbiAgICAgICAgdGVyc2VyT3B0aW9uczogY3JlYXRlVGVyc2VyT3B0aW9ucyhpc0RldmVsb3BtZW50KSxcbiAgICB9O1xuXG4gICAgaWYgKHJvbGx1cElucHV0KSBidWlsZC5yb2xsdXBPcHRpb25zLmlucHV0ID0gcm9sbHVwSW5wdXQ7XG5cbiAgICByZXR1cm4gYnVpbGQ7XG59XG5cbmV4cG9ydCBmdW5jdGlvbiBjcmVhdGVPcHRpbWl6ZURlcHNGb3JjZShpc0RldmVsb3BtZW50KSB7XG4gICAgcmV0dXJuIHtcbiAgICAgICAgZm9yY2U6IGlzRGV2ZWxvcG1lbnQgJiYgcHJvY2Vzcy5lbnYuVklURV9GT1JDRV9ERVBTID09PSBcInRydWVcIixcbiAgICB9O1xufVxuXG5leHBvcnQgY29uc3QgY29tbW9uRGVmaW5lID0ge1xuICAgIGdsb2JhbDogXCJnbG9iYWxUaGlzXCIsXG59O1xuXG5leHBvcnQgY29uc3QgY29tbW9uTGVnYWN5T3B0aW9ucyA9IHtcbiAgICB0YXJnZXRzOiBbXCJjaHJvbWUgMTQyXCJdLFxuICAgIHJlbmRlckxlZ2FjeUNodW5rczogZmFsc2UsXG4gICAgbW9kZXJuVGFyZ2V0czogW1wiY2hyb21lIDE0MlwiXSxcbiAgICBtb2Rlcm5Qb2x5ZmlsbHM6IHRydWUsXG59O1xuXG5leHBvcnQgZnVuY3Rpb24gY3JlYXRlQmFiZWxPcHRpb25zKHBhdGhNb2R1bGUpIHtcbiAgICByZXR1cm4ge1xuICAgICAgICBmaWx0ZXI6IChpZCkgPT4ge1xuICAgICAgICAgICAgY29uc3QgYmFzZSA9IHBhdGhNb2R1bGUuYmFzZW5hbWUoaWQgfHwgXCJcIikudG9Mb3dlckNhc2UoKTtcbiAgICAgICAgICAgIGlmIChiYXNlID09PSBcInRleHRjb21wbGV0ZS5taW4uanNcIiB8fCBiYXNlID09PSBcIm9ydC13ZWIubWluLmpzXCIpIHtcbiAgICAgICAgICAgICAgICByZXR1cm4gZmFsc2U7XG4gICAgICAgICAgICB9XG4gICAgICAgICAgICByZXR1cm4gKFxuICAgICAgICAgICAgICAgICFpZC5pbmNsdWRlcyhcIkBob3R3aXJlZC9zdGltdWx1c1wiKSAmJlxuICAgICAgICAgICAgICAgICFpZC5pbmNsdWRlcyhcIkBodWdnaW5nZmFjZS9qaW5qYVwiKSAmJlxuICAgICAgICAgICAgICAgICFpZC5pbmNsdWRlcyhcIm9ubnhydW50aW1lLXdlYlwiKSAmJlxuICAgICAgICAgICAgICAgIC9cXC4oanN8Y29mZmVlKSQvLnRlc3QoaWQpXG4gICAgICAgICAgICApO1xuICAgICAgICB9LFxuICAgICAgICBiYWJlbENvbmZpZzoge1xuICAgICAgICAgICAgaWdub3JlOiBbL25vZGVfbW9kdWxlc1tcXFxcL11sb2NvbW90aXZlLXNjcm9sbC9dLCAvLyBFeGNsdWRlIGxvY29tb3RpdmUtc2Nyb2xsIGZyb20gYWxsIEJhYmVsIHByb2Nlc3NpbmcgdG8gcHJlc2VydmUgc3BhcnNlIGFycmF5c1xuICAgICAgICAgICAgYmFiZWxyYzogZmFsc2UsXG4gICAgICAgICAgICBjb25maWdGaWxlOiBmYWxzZSxcbiAgICAgICAgICAgIHBsdWdpbnM6IFtcbiAgICAgICAgICAgICAgICBbXCJjbG9zdXJlLWVsaW1pbmF0aW9uXCJdLFxuICAgICAgICAgICAgICAgIFtcIm1vZHVsZTpmYXN0ZXIuanNcIl0sXG4gICAgICAgICAgICAgICAgW1xuICAgICAgICAgICAgICAgICAgICBcIm9iamVjdC10by1qc29uLXBhcnNlXCIsXG4gICAgICAgICAgICAgICAgICAgIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIG1pbkpTT05TdHJpbmdTaXplOiAxMDI0LFxuICAgICAgICAgICAgICAgICAgICB9LFxuICAgICAgICAgICAgICAgIF0sXG4gICAgICAgICAgICBdLFxuICAgICAgICB9LFxuICAgIH07XG59XG5cbmV4cG9ydCBmdW5jdGlvbiBjcmVhdGVDb21tb25Dc3MocmVtb3ZlUHJlZml4UGx1Z2luRmFjdG9yeSkge1xuICAgIHJldHVybiB7XG4gICAgICAgIHByZXByb2Nlc3Nvck9wdGlvbnM6IHtcbiAgICAgICAgICAgIHNjc3M6IHtcbiAgICAgICAgICAgICAgICBhcGk6IFwibW9kZXJuLWNvbXBpbGVyXCIsXG4gICAgICAgICAgICAgICAgaW5jbHVkZVBhdGhzOiBbXCJub2RlX21vZHVsZXNcIiwgXCIuL25vZGVfbW9kdWxlc1wiXSxcbiAgICAgICAgICAgIH0sXG4gICAgICAgIH0sXG4gICAgICAgIHBvc3Rjc3M6IHtcbiAgICAgICAgICAgIHBsdWdpbnM6IFtcbiAgICAgICAgICAgICAgICByZW1vdmVQcmVmaXhQbHVnaW5GYWN0b3J5KCksXG4gICAgICAgICAgICAgICAgLy8gVGhlIHJlc3QgYXJlIGNvbmZpZ3VyZWQgYnkgY2FsbGVyIGJlY2F1c2UgdGhleSBpbXBvcnQgZGlmZmVyZW50IG1vZHVsZXMuXG4gICAgICAgICAgICBdLFxuICAgICAgICB9LFxuICAgIH07XG59XG4iXSwKICAibWFwcGluZ3MiOiAiO0FBQTRQLE9BQU87QUFDblEsU0FBUyxvQkFBb0I7QUFDN0IsT0FBTyxVQUFVO0FBQ2pCLE9BQU9BLFNBQVE7QUFDZixTQUFTLGdCQUFnQjtBQUN6QixTQUFTLHNCQUFzQjtBQUMvQixPQUFPLGdCQUFnQjtBQUN2QixPQUFPLGdCQUFnQjtBQUN2QixPQUFPLGlCQUFpQjtBQUN4QixPQUFPLFdBQVc7QUFDbEIsT0FBTyxzQkFBc0I7QUFDN0IsT0FBTyxhQUFhO0FBQ3BCLE9BQU8sZ0JBQWdCOzs7QUNaNlAsT0FBTyxrQkFBa0I7QUFROVIsU0FBUixhQUE4QixjQUFjLENBQUMsR0FBRztBQUNuRCxRQUFNLGNBQWM7QUFBQSxJQUNoQixNQUFNO0FBQUEsSUFDTixXQUFXO0FBQUEsRUFDZjtBQUVBLFNBQU87QUFBQSxJQUNILE1BQU07QUFBQSxJQUNOLFNBQVM7QUFBQSxJQUNULFVBQVUsTUFBTSxJQUFJO0FBQ2hCLFVBQUksQ0FBQyxHQUFHLFNBQVMsU0FBUyxFQUFHO0FBRTdCLFlBQU0sVUFBVSxFQUFFLEdBQUcsYUFBYSxHQUFHLGFBQWEsVUFBVSxHQUFHO0FBRS9ELFVBQUk7QUFDQSxjQUFNLFdBQVcsYUFBYSxRQUFRLE1BQU0sT0FBTztBQUNuRCxZQUFJLE9BQU8sYUFBYSxVQUFVO0FBQzlCLGlCQUFPLEVBQUUsTUFBTSxVQUFVLEtBQUssT0FBVTtBQUFBLFFBQzVDO0FBQ0EsY0FBTSxNQUNGLFNBQVMsZUFBZSxTQUFTLGFBQWE7QUFDbEQsZUFBTyxFQUFFLE1BQU0sU0FBUyxJQUFJLElBQUk7QUFBQSxN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QUEsWUFDSixRQUFRO0FBQUEsY0FDSjtBQUFBLGNBQ0E7QUFBQSxnQkFDSSxjQUFjO0FBQUEsZ0JBQ2QsaUJBQWlCO0FBQUEsa0JBQ2IsdUJBQXVCO0FBQUEsZ0JBQzNCO0FBQUEsZ0JBQ0EsZUFBZTtBQUFBLGdCQUNmLGNBQWM7QUFBQSxnQkFDZCxjQUFjO0FBQUEsZ0JBQ2QsUUFBUTtBQUFBLGNBQ1o7QUFBQSxZQUNKO0FBQUEsVUFDSixDQUFDO0FBQUEsVUFDRCxhQUFhO0FBQUEsUUFDakI7QUFBQSxNQUNKO0FBQUEsSUFDSjtBQUFBLElBQ0EsUUFBUTtBQUFBLElBQ1IsY0FBYztBQUFBO0FBQUEsTUFFVixTQUFTO0FBQUEsUUFDTDtBQUFBLFFBQ0E7QUFBQSxRQUNBO0FBQUEsUUFDQTtBQUFBLFFBQ0E7QUFBQSxRQUNBO0FBQUEsUUFDQTtBQUFBLFFBQ0E7QUFBQSxRQUNBO0FBQUEsUUFDQTtBQUFBLFFBQ0E7QUFBQSxRQUNBO0FBQUEsUUFDQTtBQUFBLFFBQ0E7QUFBQSxRQUNBO0FBQUEsUUFDQTtBQUFBLFFBQ0E7QUFBQSxRQUNBO0FBQUEsUUFDQTtBQUFBLFFBQ0E7QUFBQSxRQUNBO0FBQUEsUUFDQTtBQUFBLFFBQ0E7QUFBQSxRQUNBO0FBQUEsTUFDSjtBQUFBLE1BQ0EsU0FBUyxDQUFDLGlCQUFpQjtBQUFBO0FBQUEsTUFFM0IsR0FBRyx3QkFBd0IsYUFBYTtBQUFBLElBQzVDO0FBQUEsSUFDQSxTQUFTO0FBQUEsTUFDTCxhQUFhO0FBQUEsTUFDYixjQUFjO0FBQUEsTUFDZCxlQUFlLEtBQUs7QUFBQSxNQUNwQixhQUFhO0FBQUEsTUFDYixrQkFBa0IsU0FDWixlQUFlLEVBQUUsU0FBUyxrQkFBa0IsQ0FBQyxJQUM3QztBQUFBLE1BQ04sT0FBTyxtQkFBbUI7QUFBQSxNQUMxQixNQUFNLG1CQUFtQixJQUFJLENBQUM7QUFBQSxNQUM5QixXQUFXO0FBQUEsTUFDWCxZQUFZO0FBQUEsTUFDWixXQUFXO0FBQUEsUUFDUDtBQUFBLFFBQ0E7QUFBQSxRQUNBO0FBQUEsTUFDSixDQUFDO0FBQUEsTUFDRCxDQUFDLGdCQUNLLDJCQUEyQixtQkFBbUIsSUFDOUM7QUFBQSxNQUNOLENBQUMsZ0JBQWdCLGlCQUFpQjtBQUFBLElBQ3RDO0FBQUEsRUFDSjtBQUNKLENBQUM7IiwKICAibmFtZXMiOiBbImZzIiwgInBhdGgiLCAiYWRkQmxvY2tEb2N1bWVudCIsICJpbmZlck9iamVjdFNoYXBlIiwgImZpbmRUU05vZGVBdFBvc2l0aW9uIiwgInNvdXJjZUZpbGUiLCAiZnMiXQp9Cg==
