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
        overlay: false,
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
//# sourceMappingURL=data:application/json;base64,ewogICJ2ZXJzaW9uIjogMywKICAic291cmNlcyI6IFsidml0ZS5jb25maWcubWpzIiwgInBsdWdpbnMvY29mZmVlc2NyaXB0LmpzIiwgInBsdWdpbnMvdHlwZWhpbnRzLmpzIiwgInBsdWdpbnMvcG9zdGNzcy1yZW1vdmUtcHJlZml4LmpzIiwgImNvbmZpZy92aXRlL2NvbW1vbi5qcyJdLAogICJzb3VyY2VzQ29udGVudCI6IFsiY29uc3QgX192aXRlX2luamVjdGVkX29yaWdpbmFsX2Rpcm5hbWUgPSBcIi9Vc2Vycy9nZW9yZ2UvTGlicmV2ZXJzZVwiO2NvbnN0IF9fdml0ZV9pbmplY3RlZF9vcmlnaW5hbF9maWxlbmFtZSA9IFwiL1VzZXJzL2dlb3JnZS9MaWJyZXZlcnNlL3ZpdGUuY29uZmlnLm1qc1wiO2NvbnN0IF9fdml0ZV9pbmplY3RlZF9vcmlnaW5hbF9pbXBvcnRfbWV0YV91cmwgPSBcImZpbGU6Ly8vVXNlcnMvZ2VvcmdlL0xpYnJldmVyc2Uvdml0ZS5jb25maWcubWpzXCI7aW1wb3J0IFwidjgtY29tcGlsZS1jYWNoZVwiO1xuaW1wb3J0IHsgZGVmaW5lQ29uZmlnIH0gZnJvbSBcInZpdGVcIjtcbmltcG9ydCBwYXRoIGZyb20gXCJub2RlOnBhdGhcIjtcbmltcG9ydCBmcyBmcm9tIFwibm9kZTpmc1wiO1xuaW1wb3J0IHsgZXhlY1N5bmMgfSBmcm9tIFwibm9kZTpjaGlsZF9wcm9jZXNzXCI7XG5pbXBvcnQgeyB2aXRlU3RhdGljQ29weSB9IGZyb20gXCJ2aXRlLXBsdWdpbi1zdGF0aWMtY29weVwiO1xuaW1wb3J0IHJ1YnlQbHVnaW4gZnJvbSBcInZpdGUtcGx1Z2luLXJ1YnlcIjtcbmltcG9ydCBmdWxsUmVsb2FkIGZyb20gXCJ2aXRlLXBsdWdpbi1mdWxsLXJlbG9hZFwiO1xuaW1wb3J0IHN0aW11bHVzSE1SIGZyb20gXCJ2aXRlLXBsdWdpbi1zdGltdWx1cy1obXJcIjtcbmltcG9ydCBiYWJlbCBmcm9tIFwidml0ZS1wbHVnaW4tYmFiZWxcIjtcbmltcG9ydCBwb3N0Y3NzSW5saW5lUnRsIGZyb20gXCJwb3N0Y3NzLWlubGluZS1ydGxcIjtcbmltcG9ydCBjc3NuYW5vIGZyb20gXCJjc3NuYW5vXCI7XG5pbXBvcnQgcG9zdGNzc1VybCBmcm9tIFwicG9zdGNzcy11cmxcIjtcbmltcG9ydCBjb2ZmZWVzY3JpcHQgZnJvbSBcIi4vcGx1Z2lucy9jb2ZmZWVzY3JpcHQuanNcIjtcbmltcG9ydCB0eXBlaGludHMgZnJvbSBcIi4vcGx1Z2lucy90eXBlaGludHMuanNcIjtcbmltcG9ydCBwb3N0Y3NzUmVtb3ZlUm9vdCBmcm9tIFwicG9zdGNzcy1yZW1vdmUtcm9vdFwiO1xuaW1wb3J0IGNzc01xcGFja2VyIGZyb20gXCJjc3MtbXFwYWNrZXJcIjtcbmltcG9ydCBzdHlsZWhhY2tzIGZyb20gXCJzdHlsZWhhY2tzXCI7XG5pbXBvcnQgcG9zdGNzc01xT3B0aW1pemUgZnJvbSBcInBvc3Rjc3MtbXEtb3B0aW1pemVcIjtcbmltcG9ydCBhdXRvcHJlZml4ZXIgZnJvbSBcImF1dG9wcmVmaXhlclwiO1xuaW1wb3J0IHJlbW92ZVByZWZpeCBmcm9tIFwiLi9wbHVnaW5zL3Bvc3Rjc3MtcmVtb3ZlLXByZWZpeC5qc1wiO1xuaW1wb3J0IG5vZGVQb2x5ZmlsbHMgZnJvbSBcInJvbGx1cC1wbHVnaW4tcG9seWZpbGwtbm9kZVwiO1xuaW1wb3J0IGxlZ2FjeSBmcm9tIFwidml0ZS1wbHVnaW4tbGVnYWN5LXN3Y1wiO1xuaW1wb3J0IHZpdGVQbHVnaW5CdW5kbGVPYmZ1c2NhdG9yIGZyb20gXCJ2aXRlLXBsdWdpbi1idW5kbGUtb2JmdXNjYXRvclwiO1xuaW1wb3J0IHsgcHVyZ2VQb2x5ZmlsbHMgfSBmcm9tIFwidW5wbHVnaW4tcHVyZ2UtcG9seWZpbGxzXCI7XG5pbXBvcnQgcmVwbGFjZW1lbnRzIGZyb20gXCJAZTE4ZS91bnBsdWdpbi1yZXBsYWNlbWVudHMvdml0ZVwiO1xuaW1wb3J0IHtcbiAgICBhbGxPYmZ1c2NhdG9yQ29uZmlnLFxuICAgIGNvbW1vbkRlZmluZSxcbiAgICBjb21tb25MZWdhY3lPcHRpb25zLFxuICAgIGNyZWF0ZUJhYmVsT3B0aW9ucyxcbiAgICBjcmVhdGVDb21tb25CdWlsZCxcbiAgICBjcmVhdGVFc2J1aWxkQ29uZmlnLFxuICAgIGNyZWF0ZU9wdGltaXplRGVwc0ZvcmNlLFxuICAgIGNyZWF0ZVR5cGVoaW50UGx1Z2luLFxuICAgIGRldlZpdGVTZWN1cml0eUhlYWRlcnMsXG59IGZyb20gXCIuL2NvbmZpZy92aXRlL2NvbW1vbi5qc1wiO1xuXG5jb25zdCBta2NlcnREZWZhdWx0cyA9IHtcbiAgICBjZXJ0OiBwcm9jZXNzLmVudi5NS0NFUlRfQ0VSVF9QQVRIIHx8IFwiL3RtcC9ta2NlcnQtZGV2LWNlcnRzL2xvY2FsaG9zdC5wZW1cIixcbiAgICBrZXk6IHByb2Nlc3MuZW52Lk1LQ0VSVF9LRVlfUEFUSCB8fCBcIi90bXAvbWtjZXJ0LWRldi1jZXJ0cy9sb2NhbGhvc3Qta2V5LnBlbVwiLFxufTtcblxuZnVuY3Rpb24gYnVpbGRIdHRwc09wdGlvbnMoKSB7XG4gICAgaWYgKCFmcy5leGlzdHNTeW5jKG1rY2VydERlZmF1bHRzLmNlcnQpIHx8ICFmcy5leGlzdHNTeW5jKG1rY2VydERlZmF1bHRzLmtleSkpIHtcbiAgICAgICAgcmV0dXJuIHVuZGVmaW5lZDtcbiAgICB9XG4gICAgcmV0dXJuIHtcbiAgICAgICAgY2VydDogZnMucmVhZEZpbGVTeW5jKG1rY2VydERlZmF1bHRzLmNlcnQpLFxuICAgICAgICBrZXk6IGZzLnJlYWRGaWxlU3luYyhta2NlcnREZWZhdWx0cy5rZXkpLFxuICAgIH07XG59XG5cbmV4cG9ydCBkZWZhdWx0IGRlZmluZUNvbmZpZygoeyBtb2RlIH0pID0+IHtcbiAgICBjb25zdCBpc0RldmVsb3BtZW50ID0gbW9kZSA9PT0gXCJkZXZlbG9wbWVudFwiO1xuXG4gICAgY29uc3QgdHlwZWhpbnRQbHVnaW4gPSBjcmVhdGVUeXBlaGludFBsdWdpbih0eXBlaGludHMpO1xuXG4gICAgY29uc3QgZ2VtUm9vdCA9IChuYW1lKSA9PiB7XG4gICAgICAgIHRyeSB7XG4gICAgICAgICAgICByZXR1cm4gZXhlY1N5bmMoYGJ1bmRsZSBzaG93ICR7bmFtZX1gLCB7XG4gICAgICAgICAgICAgICAgc3RkaW86IFtcInBpcGVcIiwgXCJwaXBlXCIsIFwiaWdub3JlXCJdLFxuICAgICAgICAgICAgfSlcbiAgICAgICAgICAgICAgICAudG9TdHJpbmcoKVxuICAgICAgICAgICAgICAgIC50cmltKCk7XG4gICAgICAgIH0gY2F0Y2ggKGVycm9yKSB7XG4gICAgICAgICAgICByZXR1cm4gbnVsbDtcbiAgICAgICAgfVxuICAgIH07XG5cbiAgICBjb25zdCBzdGF0aWNDb3B5VGFyZ2V0cyA9IFtdO1xuXG4gICAgLy8gTk9URTogVGhyZWRkZWQgSlMgYW5kIHRpbWVhZ28gYXJlIGNvbXBpbGVkIHZpYSBTcHJvY2tldHMsIG5vdCBWaXRlXG4gICAgLy8gU2VlIGFwcC9hc3NldHMvamF2YXNjcmlwdHMvdGhyZWRkZWQuanMgYW5kIGNvbmZpZy9pbml0aWFsaXplcnMvc3Byb2NrZXRzX3RocmVkZGVkLnJiXG5cbiAgICBjb25zdCBnZW1vamlSb290ID0gZ2VtUm9vdChcImdlbW9qaVwiKTtcbiAgICBpZiAoZ2Vtb2ppUm9vdCkge1xuICAgICAgICBjb25zdCBnZW1vamlTdmdzID0gcGF0aC5qb2luKGdlbW9qaVJvb3QsIFwiYXNzZXRzL2ltYWdlcy9lbW9qaS91bmljb2RlXCIpO1xuICAgICAgICBpZiAoZnMuZXhpc3RzU3luYyhnZW1vamlTdmdzKSkge1xuICAgICAgICAgICAgc3RhdGljQ29weVRhcmdldHMucHVzaCh7XG4gICAgICAgICAgICAgICAgc3JjOiBwYXRoLmpvaW4oZ2Vtb2ppU3ZncywgXCIqLnN2Z1wiKSxcbiAgICAgICAgICAgICAgICBkZXN0OiBcInN0YXRpYy9nZW1zL2dlbW9qaS9lbW9qaVwiLFxuICAgICAgICAgICAgfSk7XG4gICAgICAgIH1cbiAgICB9XG5cbiAgICByZXR1cm4ge1xuICAgICAgICBlc2J1aWxkOiBjcmVhdGVFc2J1aWxkQ29uZmlnKGlzRGV2ZWxvcG1lbnQpLFxuICAgICAgICByZXNvbHZlOiB7XG4gICAgICAgICAgICBleHRlbnNpb25zOiBbXCIuanNcIiwgXCIuanNvblwiLCBcIi5jb2ZmZWVcIiwgXCIuc2Nzc1wiLCBcIi5zbmFwcHlcIiwgXCIuZXM2XCJdLFxuICAgICAgICAgICAgLy8gV29ya2Fyb3VuZCBmb3IganMtY29va2llIHBhY2thZ2luZyAoZGlzdCBmb2xkZXIgbm90IHByZXNlbnQgaW4gc29tZSBpbnN0YWxscylcbiAgICAgICAgICAgIC8vIE1hcCB0byBFU00gc291cmNlIGZpbGUgc28gVml0ZSBjYW4gYnVuZGxlIHN1Y2Nlc3NmdWxseVxuICAgICAgICAgICAgYWxpYXM6IHtcbiAgICAgICAgICAgICAgICAvLyBVc2UgZXhwbGljaXQgcGF0aCBpbnRvIG5vZGVfbW9kdWxlcyBzaW5jZSBwYWNrYWdlIGV4cG9ydHMgZmllbGQgaGlkZXMgc3JjLypcbiAgICAgICAgICAgICAgICBcImpzLWNvb2tpZVwiOiBwYXRoLnJlc29sdmUoXG4gICAgICAgICAgICAgICAgICAgIHByb2Nlc3MuY3dkKCksXG4gICAgICAgICAgICAgICAgICAgIFwibm9kZV9tb2R1bGVzL2pzLWNvb2tpZS9pbmRleC5qc1wiLFxuICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgLy8gTk9URTogdGltZWFnb19qcywgdGhyZWRkZWRfanMsIHRocmVkZGVkX3ZlbmRvciBhbGlhc2VzIHJlbW92ZWRcbiAgICAgICAgICAgICAgICAvLyBBbGwgZ2VtIEpTIGlzIG5vdyBjb21waWxlZCB2aWEgU3Byb2NrZXRzIChzZWUgYXBwL2Fzc2V0cy9qYXZhc2NyaXB0cy90aHJlZGRlZC5qcylcbiAgICAgICAgICAgIH0sXG4gICAgICAgIH0sXG4gICAgICAgIGJ1aWxkOiBjcmVhdGVDb21tb25CdWlsZCh7XG4gICAgICAgICAgICBpc0RldmVsb3BtZW50LFxuICAgICAgICAgICAgcm9sbHVwSW5wdXQ6IHtcbiAgICAgICAgICAgICAgICBhcHBsaWNhdGlvbjogXCJhcHAvamF2YXNjcmlwdC9hcHBsaWNhdGlvbi5qc1wiLFxuICAgICAgICAgICAgICAgIGVtYWlsczogXCJhcHAvc3R5bGVzaGVldHMvZW1haWxzLnNjc3NcIixcbiAgICAgICAgICAgIH0sXG4gICAgICAgIH0pLFxuICAgICAgICBzZXJ2ZXI6IHtcbiAgICAgICAgICAgIGhvc3Q6IHByb2Nlc3MuZW52LlZJVEVfREVWX1NFUlZFUl9IT1NUIHx8IFwiMTI3LjAuMC4xXCIsXG4gICAgICAgICAgICBwb3J0OiBOdW1iZXIocHJvY2Vzcy5lbnYuVklURV9ERVZfU0VSVkVSX1BPUlQgfHwgMzAwMSksXG4gICAgICAgICAgICBzdHJpY3RQb3J0OiB0cnVlLFxuICAgICAgICAgICAgaHR0cHM6IGlzRGV2ZWxvcG1lbnQgPyBidWlsZEh0dHBzT3B0aW9ucygpIDogdW5kZWZpbmVkLFxuICAgICAgICAgICAgaG1yOiB7XG4gICAgICAgICAgICAgICAgb3ZlcmxheTogZmFsc2UsXG4gICAgICAgICAgICAgICAgcHJvdG9jb2w6IGlzRGV2ZWxvcG1lbnQgJiYgYnVpbGRIdHRwc09wdGlvbnMoKSA/IFwid3NzXCIgOiBcIndzXCIsXG4gICAgICAgICAgICAgICAgaG9zdDogXCJsb2NhbGhvc3RcIixcbiAgICAgICAgICAgICAgICBwb3J0OiBOdW1iZXIocHJvY2Vzcy5lbnYuVklURV9ERVZfU0VSVkVSX1BPUlQgfHwgMzAwMSksXG4gICAgICAgICAgICAgICAgY2xpZW50UG9ydDogTnVtYmVyKHByb2Nlc3MuZW52LlZJVEVfREVWX1NFUlZFUl9QT1JUIHx8IDMwMDEpLFxuICAgICAgICAgICAgfSxcbiAgICAgICAgICAgIG9yaWdpbjogaXNEZXZlbG9wbWVudCAmJiBidWlsZEh0dHBzT3B0aW9ucygpID8gYGh0dHBzOi8vbG9jYWxob3N0OiR7cHJvY2Vzcy5lbnYuVklURV9ERVZfU0VSVkVSX1BPUlQgfHwgMzAwMX1gIDogdW5kZWZpbmVkLFxuICAgICAgICAgICAgaGVhZGVyczogaXNEZXZlbG9wbWVudCA/IGRldlZpdGVTZWN1cml0eUhlYWRlcnMoKSA6IHt9LFxuICAgICAgICAgICAgZnM6IHsgc3RyaWN0OiBmYWxzZSB9LCAvLyBNb3JlIGxlbmllbnQgZmlsZSBzeXN0ZW0gYWNjZXNzIGZvciBkZXZlbG9wbWVudFxuICAgICAgICB9LFxuICAgICAgICBhc3NldHNJbmNsdWRlOiBbXCIqKi8qLnNuYXBweVwiLCBcIioqLyouZ2d1ZlwiLCBcIioqLyoud2FzbVwiXSxcbiAgICAgICAgY3NzOiB7XG4gICAgICAgICAgICBwcmVwcm9jZXNzb3JPcHRpb25zOiB7XG4gICAgICAgICAgICAgICAgc2Nzczoge1xuICAgICAgICAgICAgICAgICAgICBhcGk6IFwibW9kZXJuLWNvbXBpbGVyXCIsXG4gICAgICAgICAgICAgICAgICAgIGluY2x1ZGVQYXRoczogW1wibm9kZV9tb2R1bGVzXCIsIFwiLi9ub2RlX21vZHVsZXNcIl0sXG4gICAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgIH0sXG4gICAgICAgICAgICBwb3N0Y3NzOiB7XG4gICAgICAgICAgICAgICAgcGx1Z2luczogW1xuICAgICAgICAgICAgICAgICAgICByZW1vdmVQcmVmaXgoKSxcbiAgICAgICAgICAgICAgICAgICAgc3R5bGVoYWNrcyh7IGxpbnQ6IGZhbHNlIH0pLFxuICAgICAgICAgICAgICAgICAgICBwb3N0Y3NzSW5saW5lUnRsKCksXG4gICAgICAgICAgICAgICAgICAgIHBvc3Rjc3NVcmwoW1xuICAgICAgICAgICAgICAgICAgICAgICAge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGZpbHRlcjogXCIqKi8qLndvZmYyXCIsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdXJsOiBcImlubGluZVwiLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGVuY29kZVR5cGU6IFwiYmFzZTY0XCIsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbWF4U2l6ZTogMjE0NzQ4MzY0NyxcbiAgICAgICAgICAgICAgICAgICAgICAgIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdXJsOiBcImlubGluZVwiLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG1heFNpemU6IDIxNDc0ODM2NDcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZW5jb2RlVHlwZTogXCJlbmNvZGVVUklDb21wb25lbnRcIixcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvcHRpbWl6ZVN2Z0VuY29kZTogdHJ1ZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBpZ25vcmVGcmFnbWVudFdhcm5pbmc6IHRydWUsXG4gICAgICAgICAgICAgICAgICAgICAgICB9LFxuICAgICAgICAgICAgICAgICAgICBdKSxcbiAgICAgICAgICAgICAgICAgICAgcG9zdGNzc1JlbW92ZVJvb3QoKSxcbiAgICAgICAgICAgICAgICAgICAgY3NzTXFwYWNrZXIoe1xuICAgICAgICAgICAgICAgICAgICAgICAgc29ydDogdHJ1ZSxcbiAgICAgICAgICAgICAgICAgICAgfSksXG4gICAgICAgICAgICAgICAgICAgIHBvc3Rjc3NNcU9wdGltaXplKCksXG4gICAgICAgICAgICAgICAgICAgIGNzc25hbm8oe1xuICAgICAgICAgICAgICAgICAgICAgICAgcHJlc2V0OiBbXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgXCJhZHZhbmNlZFwiLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgYXV0b3ByZWZpeGVyOiBmYWxzZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZGlzY2FyZENvbW1lbnRzOiB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZW1vdmVBbGxCdXRDb3B5cmlnaHQ6IHRydWUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRpc2NhcmRVbnVzZWQ6IHRydWUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZHVjZUlkZW50czogdHJ1ZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbWVyZ2VJbmRlbnRzOiB0cnVlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB6aW5kZXg6IHRydWUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgICAgICAgICAgICAgIF0sXG4gICAgICAgICAgICAgICAgICAgIH0pLFxuICAgICAgICAgICAgICAgICAgICBhdXRvcHJlZml4ZXIoKSxcbiAgICAgICAgICAgICAgICBdLFxuICAgICAgICAgICAgfSxcbiAgICAgICAgfSxcbiAgICAgICAgZGVmaW5lOiBjb21tb25EZWZpbmUsXG4gICAgICAgIG9wdGltaXplRGVwczoge1xuICAgICAgICAgICAgLy8gRm9yY2UgaW5jbHVzaW9uIG9mIGRlcGVuZGVuY2llcyB0aGF0IG1pZ2h0IG5vdCBiZSBkZXRlY3RlZFxuICAgICAgICAgICAgaW5jbHVkZTogW1xuICAgICAgICAgICAgICAgIFwiZGVib3VuY2VkXCIsXG4gICAgICAgICAgICAgICAgXCJmb3VuZGF0aW9uLXNpdGVzXCIsXG4gICAgICAgICAgICAgICAgXCJ3aGF0LWlucHV0XCIsXG4gICAgICAgICAgICAgICAgXCJAZmluZ2VycHJpbnRqcy9ib3RkXCIsXG4gICAgICAgICAgICAgICAgXCJAcmFpbHMvdWpzXCIsXG4gICAgICAgICAgICAgICAgXCJqcy1jb29raWVcIixcbiAgICAgICAgICAgICAgICBcIkBzZW50cnkvYnJvd3NlclwiLFxuICAgICAgICAgICAgICAgIFwidHVyYm9fcG93ZXJcIixcbiAgICAgICAgICAgICAgICBcIkByYWlscy9hY3RpdmVzdG9yYWdlXCIsXG4gICAgICAgICAgICAgICAgXCJzdGltdWx1c19yZWZsZXhcIixcbiAgICAgICAgICAgICAgICBcImNhYmxlX3JlYWR5XCIsXG4gICAgICAgICAgICAgICAgXCJAcmFpbHMvYWN0aW9uY2FibGVcIixcbiAgICAgICAgICAgICAgICBcIkByYWlscy9yZXF1ZXN0LmpzXCIsXG4gICAgICAgICAgICAgICAgXCJzdGltdWx1cy1zdG9yZVwiLFxuICAgICAgICAgICAgICAgIFwiQGhvdHdpcmVkL3R1cmJvLXJhaWxzXCIsXG4gICAgICAgICAgICAgICAgXCJsZWFmbGV0XCIsXG4gICAgICAgICAgICAgICAgXCJsZWFmbGV0Lm9mZmxpbmVcIixcbiAgICAgICAgICAgICAgICBcImxlYWZsZXQtYWpheFwiLFxuICAgICAgICAgICAgICAgIFwibGVhZmxldC1zcGluXCIsXG4gICAgICAgICAgICAgICAgXCJsZWFmbGV0LXNsZWVwXCIsXG4gICAgICAgICAgICAgICAgXCJsZWFmbGV0LmExMXlcIixcbiAgICAgICAgICAgICAgICBcImxlYWZsZXQudHJhbnNsYXRlXCIsXG4gICAgICAgICAgICAgICAgXCJzdGltdWx1cy11c2UvaG90a2V5c1wiLFxuICAgICAgICAgICAgICAgIFwianF1ZXJ5XCIsXG4gICAgICAgICAgICBdLFxuICAgICAgICAgICAgZXhjbHVkZTogW1wiQGhvdHdpcmVkL3R1cmJvXCJdLFxuICAgICAgICAgICAgLy8gRm9yY2UgcmVvcHRpbWl6YXRpb24gaW4gZGV2ZWxvcG1lbnRcbiAgICAgICAgICAgIC4uLmNyZWF0ZU9wdGltaXplRGVwc0ZvcmNlKGlzRGV2ZWxvcG1lbnQpLFxuICAgICAgICB9LFxuICAgICAgICBwbHVnaW5zOiBbXG4gICAgICAgICAgICBjb2ZmZWVzY3JpcHQoKSxcbiAgICAgICAgICAgIG5vZGVQb2x5ZmlsbHMoKSxcbiAgICAgICAgICAgIHB1cmdlUG9seWZpbGxzLnZpdGUoKSxcbiAgICAgICAgICAgIHJlcGxhY2VtZW50cygpLFxuICAgICAgICAgICAgc3RhdGljQ29weVRhcmdldHMubGVuZ3RoXG4gICAgICAgICAgICAgICAgPyB2aXRlU3RhdGljQ29weSh7IHRhcmdldHM6IHN0YXRpY0NvcHlUYXJnZXRzIH0pXG4gICAgICAgICAgICAgICAgOiBudWxsLFxuICAgICAgICAgICAgbGVnYWN5KGNvbW1vbkxlZ2FjeU9wdGlvbnMpLFxuICAgICAgICAgICAgYmFiZWwoY3JlYXRlQmFiZWxPcHRpb25zKHBhdGgpKSxcbiAgICAgICAgICAgIHJ1YnlQbHVnaW4oKSxcbiAgICAgICAgICAgIHN0aW11bHVzSE1SKCksXG4gICAgICAgICAgICBmdWxsUmVsb2FkKFtcbiAgICAgICAgICAgICAgICBcImNvbmZpZy9yb3V0ZXMucmJcIixcbiAgICAgICAgICAgICAgICBcImFwcC92aWV3cy8qKi8qXCIsXG4gICAgICAgICAgICAgICAgXCJhcHAvamF2YXNjcmlwdC9zcmMvKiovKlwiLFxuICAgICAgICAgICAgXSksXG4gICAgICAgICAgICAhaXNEZXZlbG9wbWVudFxuICAgICAgICAgICAgICAgID8gdml0ZVBsdWdpbkJ1bmRsZU9iZnVzY2F0b3IoYWxsT2JmdXNjYXRvckNvbmZpZylcbiAgICAgICAgICAgICAgICA6IG51bGwsXG4gICAgICAgICAgICAhaXNEZXZlbG9wbWVudCA/IHR5cGVoaW50UGx1Z2luIDogbnVsbCxcbiAgICAgICAgXSxcbiAgICB9O1xufSk7XG4iLCAiY29uc3QgX192aXRlX2luamVjdGVkX29yaWdpbmFsX2Rpcm5hbWUgPSBcIi9Vc2Vycy9nZW9yZ2UvTGlicmV2ZXJzZS9wbHVnaW5zXCI7Y29uc3QgX192aXRlX2luamVjdGVkX29yaWdpbmFsX2ZpbGVuYW1lID0gXCIvVXNlcnMvZ2VvcmdlL0xpYnJldmVyc2UvcGx1Z2lucy9jb2ZmZWVzY3JpcHQuanNcIjtjb25zdCBfX3ZpdGVfaW5qZWN0ZWRfb3JpZ2luYWxfaW1wb3J0X21ldGFfdXJsID0gXCJmaWxlOi8vL1VzZXJzL2dlb3JnZS9MaWJyZXZlcnNlL3BsdWdpbnMvY29mZmVlc2NyaXB0LmpzXCI7aW1wb3J0IENvZmZlZVNjcmlwdCBmcm9tIFwiY29mZmVlc2NyaXB0XCI7XG5cbi8qKlxuICogVml0ZSBwbHVnaW4gdG8gY29tcGlsZSAuY29mZmVlIGZpbGVzLlxuICogQHBhcmFtIHtpbXBvcnQoJ2NvZmZlZXNjcmlwdCcpLkNvbXBpbGVPcHRpb25zfSB1c2VyT3B0aW9uc1xuICogQHJldHVybnMge2ltcG9ydCgndml0ZScpLlBsdWdpbn1cbiAqL1xuXG5leHBvcnQgZGVmYXVsdCBmdW5jdGlvbiBjb2ZmZWVzY3JpcHQodXNlck9wdGlvbnMgPSB7fSkge1xuICAgIGNvbnN0IGJhc2VPcHRpb25zID0ge1xuICAgICAgICBiYXJlOiB0cnVlLFxuICAgICAgICBzb3VyY2VNYXA6IGZhbHNlLFxuICAgIH07XG5cbiAgICByZXR1cm4ge1xuICAgICAgICBuYW1lOiBcImNvZmZlZXNjcmlwdFwiLFxuICAgICAgICBlbmZvcmNlOiBcInByZVwiLFxuICAgICAgICB0cmFuc2Zvcm0oY29kZSwgaWQpIHtcbiAgICAgICAgICAgIGlmICghaWQuZW5kc1dpdGgoXCIuY29mZmVlXCIpKSByZXR1cm47XG5cbiAgICAgICAgICAgIGNvbnN0IG9wdGlvbnMgPSB7IC4uLmJhc2VPcHRpb25zLCAuLi51c2VyT3B0aW9ucywgZmlsZW5hbWU6IGlkIH07XG5cbiAgICAgICAgICAgIHRyeSB7XG4gICAgICAgICAgICAgICAgY29uc3QgY29tcGlsZWQgPSBDb2ZmZWVTY3JpcHQuY29tcGlsZShjb2RlLCBvcHRpb25zKTtcbiAgICAgICAgICAgICAgICBpZiAodHlwZW9mIGNvbXBpbGVkID09PSBcInN0cmluZ1wiKSB7XG4gICAgICAgICAgICAgICAgICAgIHJldHVybiB7IGNvZGU6IGNvbXBpbGVkLCBtYXA6IHVuZGVmaW5lZCB9O1xuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICBjb25zdCBtYXAgPVxuICAgICAgICAgICAgICAgICAgICBjb21waWxlZC52M1NvdXJjZU1hcCB8fCBjb21waWxlZC5zb3VyY2VNYXAgfHwgdW5kZWZpbmVkO1xuICAgICAgICAgICAgICAgIHJldHVybiB7IGNvZGU6IGNvbXBpbGVkLmpzLCBtYXAgfTtcbiAgICAgICAgICAgIH0gY2F0Y2ggKGVycm9yKSB7XG4gICAgICAgICAgICAgICAgdGhpcy5lcnJvcihlcnJvcik7XG4gICAgICAgICAgICB9XG4gICAgICAgIH0sXG4gICAgfTtcbn1cbiIsICJjb25zdCBfX3ZpdGVfaW5qZWN0ZWRfb3JpZ2luYWxfZGlybmFtZSA9IFwiL1VzZXJzL2dlb3JnZS9MaWJyZXZlcnNlL3BsdWdpbnNcIjtjb25zdCBfX3ZpdGVfaW5qZWN0ZWRfb3JpZ2luYWxfZmlsZW5hbWUgPSBcIi9Vc2Vycy9nZW9yZ2UvTGlicmV2ZXJzZS9wbHVnaW5zL3R5cGVoaW50cy5qc1wiO2NvbnN0IF9fdml0ZV9pbmplY3RlZF9vcmlnaW5hbF9pbXBvcnRfbWV0YV91cmwgPSBcImZpbGU6Ly8vVXNlcnMvZ2VvcmdlL0xpYnJldmVyc2UvcGx1Z2lucy90eXBlaGludHMuanNcIjsvLyBQbGFpbiBKUyBwbHVnaW4gdGhhdCB1c2VzIHRoZSBUeXBlU2NyaXB0IGNoZWNrZXIgZm9yIGluZmVyZW5jZSBvbmx5LlxuaW1wb3J0ICogYXMgdHMgZnJvbSBcInR5cGVzY3JpcHRcIjtcbmltcG9ydCB7IHBhcnNlIH0gZnJvbSBcIkBiYWJlbC9wYXJzZXJcIjtcbi8vIE5vcm1hbGl6ZSBFU00vQ0pTIGludGVyb3AgZm9yIEJhYmVsIHV0aWxzIHdoZW4gVml0ZSBidW5kbGVzIHRoZSBjb25maWdcbmltcG9ydCB0cmF2ZXJzZU1vZHVsZSBmcm9tIFwiQGJhYmVsL3RyYXZlcnNlXCI7XG5pbXBvcnQgZ2VuZXJhdGVNb2R1bGUgZnJvbSBcIkBiYWJlbC9nZW5lcmF0b3JcIjtcbmltcG9ydCB0ZW1wbGF0ZU1vZHVsZSBmcm9tIFwiQGJhYmVsL3RlbXBsYXRlXCI7XG5pbXBvcnQgKiBhcyB0IGZyb20gXCJAYmFiZWwvdHlwZXNcIjtcbmNvbnN0IHRyYXZlcnNlID1cbiAgICAvKiogQHR5cGUge2FueX0gKi8gKFxuICAgICAgICB0eXBlb2YgdHJhdmVyc2VNb2R1bGUgPT09IFwiZnVuY3Rpb25cIlxuICAgICAgICAgICAgPyB0cmF2ZXJzZU1vZHVsZVxuICAgICAgICAgICAgOiAvKiogQHR5cGUge2FueX0gKi8gKHRyYXZlcnNlTW9kdWxlICYmIHRyYXZlcnNlTW9kdWxlLmRlZmF1bHQpXG4gICAgKSB8fCAvKiogZmFsbGJhY2sgbm9vcCB0byBhdm9pZCBoYXJkIGNyYXNoICovIGZ1bmN0aW9uICgpIHt9LmJpbmQoKTtcbmNvbnN0IGdlbmVyYXRlID0gLyoqIEB0eXBlIHthbnl9ICovIChcbiAgICB0eXBlb2YgZ2VuZXJhdGVNb2R1bGUgPT09IFwiZnVuY3Rpb25cIlxuICAgICAgICA/IGdlbmVyYXRlTW9kdWxlXG4gICAgICAgIDogLyoqIEB0eXBlIHthbnl9ICovIChnZW5lcmF0ZU1vZHVsZSAmJiBnZW5lcmF0ZU1vZHVsZS5kZWZhdWx0KVxuKTtcbmNvbnN0IHRlbXBsYXRlID0gLyoqIEB0eXBlIHthbnl9ICovIChcbiAgICB0eXBlb2YgdGVtcGxhdGVNb2R1bGUgPT09IFwiZnVuY3Rpb25cIlxuICAgICAgICA/IHRlbXBsYXRlTW9kdWxlXG4gICAgICAgIDogLyoqIEB0eXBlIHthbnl9ICovICh0ZW1wbGF0ZU1vZHVsZSAmJiB0ZW1wbGF0ZU1vZHVsZS5kZWZhdWx0KVxuKTtcbmltcG9ydCBmcyBmcm9tIFwibm9kZTpmc1wiO1xuXG4vLyBDb21wYWN0IGVycm9yIG91dHB1dCB0byBrZWVwIGxvZ3Mgc2hvcnRcbmZ1bmN0aW9uIGNvbXBhY3RFcnJvcihlcnJvciwgaWQpIHtcbiAgICB0cnkge1xuICAgICAgICBjb25zdCBuYW1lID0gZXJyb3I/Lm5hbWUgfHwgXCJFcnJvclwiO1xuICAgICAgICBjb25zdCBiYXNlTWVzc2FnZSA9IGVycm9yPy5tZXNzYWdlXG4gICAgICAgICAgICA/IFN0cmluZyhlcnJvci5tZXNzYWdlKVxuICAgICAgICAgICAgOiBTdHJpbmcoZXJyb3IpO1xuICAgICAgICBjb25zdCBmaXJzdExpbmUgPSBiYXNlTWVzc2FnZS5zcGxpdChcIlxcblwiKVswXS5zbGljZSgwLCAzMDApO1xuICAgICAgICBjb25zdCBsb2MgPVxuICAgICAgICAgICAgZXJyb3I/LmxvYyAmJiB0eXBlb2YgZXJyb3IubG9jLmxpbmUgPT09IFwibnVtYmVyXCJcbiAgICAgICAgICAgICAgICA/IGAgKCR7ZXJyb3IubG9jLmxpbmV9OiR7ZXJyb3IubG9jLmNvbHVtbiA/PyAwfSlgXG4gICAgICAgICAgICAgICAgOiBcIlwiO1xuICAgICAgICBsZXQgb3V0ID0gYFt2aXRlLXBsdWdpbi12OC10eXBlLWhpbnRzLXdpdGgtdHNdICR7bmFtZX0ke2xvY30gaW4gJHtpZH06ICR7Zmlyc3RMaW5lfWA7XG4gICAgICAgIGlmIChlcnJvcj8uc3RhY2spIHtcbiAgICAgICAgICAgIGNvbnN0IGZyYW1lcyA9IFN0cmluZyhlcnJvci5zdGFjaylcbiAgICAgICAgICAgICAgICAuc3BsaXQoXCJcXG5cIilcbiAgICAgICAgICAgICAgICAuc2xpY2UoMSlcbiAgICAgICAgICAgICAgICAuZmlsdGVyKFxuICAgICAgICAgICAgICAgICAgICAobCkgPT5cbiAgICAgICAgICAgICAgICAgICAgICAgICFsLmluY2x1ZGVzKFwibm9kZTppbnRlcm5hbFwiKSAmJlxuICAgICAgICAgICAgICAgICAgICAgICAgIWwuaW5jbHVkZXMoXCJub2RlX21vZHVsZXNcIiksXG4gICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgIC5zbGljZSgwLCAyKTtcbiAgICAgICAgICAgIGlmIChmcmFtZXMubGVuZ3RoID4gMCkgb3V0ICs9IFwiXFxuXCIgKyBmcmFtZXMuam9pbihcIlxcblwiKTtcbiAgICAgICAgfVxuICAgICAgICBjb25zdCBNQVggPSA2MDA7XG4gICAgICAgIGlmIChvdXQubGVuZ3RoID4gTUFYKSBvdXQgPSBvdXQuc2xpY2UoMCwgTUFYKSArIFwiXHUyMDI2XCI7XG4gICAgICAgIHJldHVybiBvdXQ7XG4gICAgfSBjYXRjaCB7XG4gICAgICAgIHJldHVybiBgW3ZpdGUtcGx1Z2luLXY4LXR5cGUtaGludHMtd2l0aC10c10gRXJyb3IgaW4gJHtpZH1gO1xuICAgIH1cbn1cblxuLy8gSGVscGVyOiBodW1hbi1mcmllbmRseSBwYXJhbWV0ZXIgbmFtZVxuZnVuY3Rpb24gZ2V0UGFyYW1ldGVyTmFtZShwYXJhbWV0ZXIpIHtcbiAgICByZXR1cm4gdC5pc0lkZW50aWZpZXIocGFyYW1ldGVyKSA/IHBhcmFtZXRlci5uYW1lIDogXCJwYXJhbVwiO1xufVxuXG4vLyBNYXAgVFMgdHlwZSB0byBKU0RvYyBzdHJpbmcgKGhhbmRsZXMgcHJpbWl0aXZlcywgYXJyYXlzLCBvYmplY3RzLCBmdW5jdGlvbnMpXG5mdW5jdGlvbiBlbnN1cmVDb250ZXh0KGNvbnRleHQpIHtcbiAgICByZXR1cm4gKFxuICAgICAgICBjb250ZXh0IHx8IHtcbiAgICAgICAgICAgIGRlcHRoOiAwLFxuICAgICAgICAgICAgc2VlbjogbmV3IFNldCgpLFxuICAgICAgICAgICAgbWF4RGVwdGg6IDMsXG4gICAgICAgICAgICBtYXhQcm9wczogMjAsXG4gICAgICAgIH1cbiAgICApO1xufVxuXG5mdW5jdGlvbiB0c1R5cGVUb0pTRG9jdW1lbnQoY2hlY2tlciwgdHlwZSwgY29udGV4dCkge1xuICAgIGNvbnRleHQgPSBlbnN1cmVDb250ZXh0KGNvbnRleHQpO1xuICAgIGlmICghdHlwZSkgcmV0dXJuIFwiYW55XCI7XG4gICAgaWYgKGNvbnRleHQuZGVwdGggPiBjb250ZXh0Lm1heERlcHRoKSByZXR1cm4gXCJhbnlcIjtcbiAgICAvLyBDeWNsZSBndWFyZCBieSBpZCBzdHJpbmdcbiAgICB0cnkge1xuICAgICAgICBjb25zdCBpZCA9IGNoZWNrZXIudHlwZVRvU3RyaW5nKHR5cGUpO1xuICAgICAgICBpZiAoY29udGV4dC5zZWVuLmhhcyhpZCkpIHJldHVybiBcImFueVwiO1xuICAgICAgICBjb250ZXh0LnNlZW4uYWRkKGlkKTtcbiAgICB9IGNhdGNoIHtcbiAgICAgICAgLyogaWdub3JlICovXG4gICAgfVxuICAgIGNvbnN0IHR5cGVTdHJpbmcgPSBjaGVja2VyLnR5cGVUb1N0cmluZyh0eXBlKTtcbiAgICBpZiAodHlwZVN0cmluZyA9PT0gXCJudW1iZXJcIikgcmV0dXJuIFwibnVtYmVyXCI7XG4gICAgaWYgKHR5cGVTdHJpbmcgPT09IFwic3RyaW5nXCIpIHJldHVybiBcInN0cmluZ1wiO1xuICAgIGlmICh0eXBlU3RyaW5nID09PSBcImJvb2xlYW5cIikgcmV0dXJuIFwiYm9vbGVhblwiO1xuICAgIC8vIEFycmF5LWxpa2VcbiAgICB0cnkge1xuICAgICAgICBpZiAoY2hlY2tlci5pc0FycmF5TGlrZVR5cGUgJiYgY2hlY2tlci5pc0FycmF5TGlrZVR5cGUodHlwZSkpIHtcbiAgICAgICAgICAgIGNvbnN0IGVsZW1lbnRUeXBlID1cbiAgICAgICAgICAgICAgICAoY2hlY2tlci5nZXRBcnJheUVsZW1lbnRUeXBlICYmXG4gICAgICAgICAgICAgICAgICAgIGNoZWNrZXIuZ2V0QXJyYXlFbGVtZW50VHlwZSh0eXBlKSkgfHxcbiAgICAgICAgICAgICAgICAoY2hlY2tlci5nZXRFbGVtZW50VHlwZU9mQXJyYXlUeXBlICYmXG4gICAgICAgICAgICAgICAgICAgIGNoZWNrZXIuZ2V0RWxlbWVudFR5cGVPZkFycmF5VHlwZSh0eXBlKSkgfHxcbiAgICAgICAgICAgICAgICB1bmRlZmluZWQ7XG4gICAgICAgICAgICBjb25zdCBlbGVtZW50ID0gZWxlbWVudFR5cGVcbiAgICAgICAgICAgICAgICA/IHRzVHlwZVRvSlNEb2N1bWVudChjaGVja2VyLCBlbGVtZW50VHlwZSwge1xuICAgICAgICAgICAgICAgICAgICAgIC4uLmNvbnRleHQsXG4gICAgICAgICAgICAgICAgICAgICAgZGVwdGg6IGNvbnRleHQuZGVwdGggKyAxLFxuICAgICAgICAgICAgICAgICAgfSlcbiAgICAgICAgICAgICAgICA6IFwiYW55XCI7XG4gICAgICAgICAgICByZXR1cm4gYCR7ZWxlbWVudH1bXWA7XG4gICAgICAgIH1cbiAgICB9IGNhdGNoIHtcbiAgICAgICAgLyogaWdub3JlICovXG4gICAgfVxuICAgIC8vIE9iamVjdC1saWtlIC0+IGtlZXAgZm9vdHByaW50IHRpbnlcbiAgICBpZiAoKHR5cGUuZmxhZ3MgJiB0cy5UeXBlRmxhZ3MuT2JqZWN0KSAhPT0gMCkge1xuICAgICAgICByZXR1cm4gXCJvYmplY3RcIjtcbiAgICB9XG4gICAgaWYgKHR5cGUuZ2V0Q2FsbFNpZ25hdHVyZXMgJiYgdHlwZS5nZXRDYWxsU2lnbmF0dXJlcygpLmxlbmd0aCA+IDApXG4gICAgICAgIHJldHVybiBcIkZ1bmN0aW9uXCI7XG4gICAgcmV0dXJuIHR5cGVTdHJpbmcgfHwgXCJhbnlcIjtcbn1cblxuLy8gQWRkIGNvZXJjaW9uIEFTVCBub2RlIChmb3IgbnVtYmVyczogfCAwOyBleHRlbmQgYXMgbmVlZGVkKVxuZnVuY3Rpb24gYWRkVHlwZUNvZXJjaW9uKHBhdGgsIHR5cGVTdHJpbmcpIHtcbiAgICBpZiAodHlwZVN0cmluZyAhPT0gXCJudW1iZXJcIikgcmV0dXJuIGZhbHNlO1xuICAgIGNvbnN0IG5vZGUgPSBwYXRoLm5vZGU7XG4gICAgbGV0IHRhcmdldE5vZGUgPSBub2RlLmluaXQgfHwgbm9kZS5hcmd1bWVudCB8fCBub2RlLmV4cHJlc3Npb24gfHwgbm9kZS5sZWZ0O1xuICAgIGlmICghdGFyZ2V0Tm9kZSkgcmV0dXJuIGZhbHNlO1xuICAgIC8vIFdyYXAgd2l0aCB8IDAgdXNpbmcgdGVtcGxhdGUgdG8gc3BsaWNlIGFuIGFyYml0cmFyeSBleHByZXNzaW9uXG4gICAgY29uc3QgYnVpbGQgPSB0ZW1wbGF0ZS5leHByZXNzaW9uKFwiKChFWFBSKSkgfCAwXCIpO1xuICAgIGNvbnN0IGNvZXJjZWQgPSBidWlsZCh7IEVYUFI6IHRhcmdldE5vZGUgfSk7XG4gICAgaWYgKG5vZGUuaW5pdCkgbm9kZS5pbml0ID0gY29lcmNlZDtcbiAgICBpZiAobm9kZS5hcmd1bWVudCkgbm9kZS5hcmd1bWVudCA9IGNvZXJjZWQ7XG4gICAgaWYgKG5vZGUuZXhwcmVzc2lvbikgbm9kZS5leHByZXNzaW9uID0gY29lcmNlZDtcbiAgICBpZiAobm9kZS5sZWZ0KSBub2RlLmxlZnQgPSBjb2VyY2VkO1xuICAgIHJldHVybiB0cnVlO1xufVxuXG5leHBvcnQgZGVmYXVsdCBmdW5jdGlvbiB0eXBlaGludHMob3B0aW9ucyA9IHt9KSB7XG4gICAgY29uc3Qge1xuICAgICAgICBpbmNsdWRlTm9kZU1vZHVsZXMgPSB0cnVlLFxuICAgICAgICBlbmFibGVDb2VyY2lvbnMgPSB0cnVlLFxuICAgICAgICBwcm9jZXNzRXZlcnl0aGluZyA9IHRydWUsXG4gICAgICAgIC8vIFByZWZlcnJlZCBvcHRpb24gbmFtZXMgKGJhY2t3YXJkIGNvbXBhdGlibGUgbWFwcGluZyBhcHBsaWVkIGJlbG93KVxuICAgICAgICB2YXJpYWJsZURvY3VtZW50YXRpb24gPSBvcHRpb25zLnZhcmlhYmxlRG9jdW1lbnRhdGlvbiA/P1xuICAgICAgICAgICAgb3B0aW9ucy52YXJpYWJsZURvY3MgPz9cbiAgICAgICAgICAgIHRydWUsXG4gICAgICAgIG9iamVjdFNoYXBlRG9jdW1lbnRhdGlvbiA9IG9wdGlvbnMub2JqZWN0U2hhcGVEb2N1bWVudGF0aW9uID8/XG4gICAgICAgICAgICBvcHRpb25zLm9iamVjdFNoYXBlRG9jcyA/P1xuICAgICAgICAgICAgdHJ1ZSxcbiAgICAgICAgbWF4T2JqZWN0UHJvcGVydGllcyA9IG9wdGlvbnMubWF4T2JqZWN0UHJvcGVydGllcyA/P1xuICAgICAgICAgICAgb3B0aW9ucy5tYXhPYmplY3RQcm9wcyA/P1xuICAgICAgICAgICAgOCxcbiAgICAgICAgcGFyYW1ldGVySG9pc3RDb2VyY2lvbnMgPSBvcHRpb25zLnBhcmFtZXRlckhvaXN0Q29lcmNpb25zID8/XG4gICAgICAgICAgICBvcHRpb25zLnBhcmFtSG9pc3RDb2VyY2lvbnMgPz9cbiAgICAgICAgICAgIGZhbHNlLFxuICAgIH0gPSBvcHRpb25zO1xuXG4gICAgLy8gVHJhY2sgaWYgd2UncmUgaW4gYnVpbGQgbW9kZSB0byBmYWlsIGJ1aWxkcyBvbiBlcnJvcnNcbiAgICBsZXQgaXNCdWlsZCA9IGZhbHNlO1xuXG4gICAgcmV0dXJuIHtcbiAgICAgICAgbmFtZTogXCJ2aXRlLXBsdWdpbi12OC10eXBlLWhpbnRzLXdpdGgtdHNcIixcbiAgICAgICAgLy8gT25seSBydW4gZHVyaW5nIHN0YXRpYyBidWlsZHNcbiAgICAgICAgYXBwbHk6IFwiYnVpbGRcIixcblxuICAgICAgICBjb25maWdSZXNvbHZlZChjb25maWcpIHtcbiAgICAgICAgICAgIGlzQnVpbGQgPSBjb25maWcuY29tbWFuZCA9PT0gXCJidWlsZFwiO1xuICAgICAgICB9LFxuXG4gICAgICAgIGFzeW5jIHRyYW5zZm9ybShjb2RlLCBpZCkge1xuICAgICAgICAgICAgLy8gSGFyZCBuby1vcCBpbiBkZXYgKGV4dHJhIGd1YXJkOyBhcHBseTogJ2J1aWxkJyBhbHJlYWR5IGxpbWl0cyB0aGlzKVxuICAgICAgICAgICAgaWYgKCFpc0J1aWxkKSByZXR1cm47XG5cbiAgICAgICAgICAgIC8vIE5vcm1hbGl6ZSBwYXRoIGFuZCBleHRlbnNpb25cbiAgICAgICAgICAgIGNvbnN0IGNsZWFuSWQgPSBTdHJpbmcoaWQpLnNwbGl0KFwiP1wiKVswXTtcbiAgICAgICAgICAgIGlmICghL1xcLihbY21dP2pzeD8pJC9pLnRlc3QoY2xlYW5JZCkpIHJldHVybjtcbiAgICAgICAgICAgIGlmIChcbiAgICAgICAgICAgICAgICAhcHJvY2Vzc0V2ZXJ5dGhpbmcgJiZcbiAgICAgICAgICAgICAgICAhaW5jbHVkZU5vZGVNb2R1bGVzICYmXG4gICAgICAgICAgICAgICAgY2xlYW5JZC5pbmNsdWRlcyhcIm5vZGVfbW9kdWxlc1wiKVxuICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgIHJldHVybjtcblxuICAgICAgICAgICAgLy8gU2tpcCB2ZXJ5IGxhcmdlIGZpbGVzIHRvIGF2b2lkIGhlYXZ5IFRTIGluZmVyZW5jZSAoY29uZmlndXJhYmxlIHZpYSBlbnYgaW4gdGhlIGZ1dHVyZSlcbiAgICAgICAgICAgIGNvbnN0IE1BWF9GSUxFX0JZVEVTID0gMTUwXzAwMDsgLy8gfjE1MCBLQlxuICAgICAgICAgICAgaWYgKCFwcm9jZXNzRXZlcnl0aGluZykge1xuICAgICAgICAgICAgICAgIGlmIChjb2RlICYmIGNvZGUubGVuZ3RoID4gTUFYX0ZJTEVfQllURVMpIHJldHVybjtcbiAgICAgICAgICAgICAgICAvLyBTa2lwIGNvbW1vbiB2ZW5kb3ItbGlrZSBkaXJzIGluIGFwcCB0byBhdm9pZCBkZWVwIHR5cGUgcmVjdXJzaW9uXG4gICAgICAgICAgICAgICAgaWYgKGNsZWFuSWQuaW5jbHVkZXMoXCIvYXBwL2phdmFzY3JpcHQvbGlicy9cIikpIHJldHVybjtcbiAgICAgICAgICAgICAgICAvLyBTa2lwIGJ1aWx0IGRpc3QgYnVuZGxlcyBjb21tb25seSBsYXJnZSBpbiBub2RlX21vZHVsZXNcbiAgICAgICAgICAgICAgICBpZiAoY2xlYW5JZC5pbmNsdWRlcyhcIi9kaXN0L1wiKSB8fCAvXFwubWluXFwuanMkL2kudGVzdChjbGVhbklkKSlcbiAgICAgICAgICAgICAgICAgICAgcmV0dXJuO1xuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICB0cnkge1xuICAgICAgICAgICAgICAgIGxldCBkaWRDaGFuZ2UgPSBmYWxzZTtcbiAgICAgICAgICAgICAgICBsZXQgYmFpbE91dCA9IGZhbHNlO1xuICAgICAgICAgICAgICAgIC8vIFN0ZXAgMTogQ3JlYXRlIGEgVFMgUHJvZ3JhbSB0aGF0IGNhbiB0eXBlLWNoZWNrIHRoaXMgSlMgZmlsZVxuICAgICAgICAgICAgICAgIGNvbnN0IGNvbXBpbGVyT3B0aW9ucyA9IHtcbiAgICAgICAgICAgICAgICAgICAgYWxsb3dKczogdHJ1ZSxcbiAgICAgICAgICAgICAgICAgICAgY2hlY2tKczogdHJ1ZSxcbiAgICAgICAgICAgICAgICAgICAgbm9FbWl0OiB0cnVlLFxuICAgICAgICAgICAgICAgICAgICB0YXJnZXQ6IHRzLlNjcmlwdFRhcmdldC5MYXRlc3QsXG4gICAgICAgICAgICAgICAgICAgIG1vZHVsZTogdHMuTW9kdWxlS2luZC5FU05leHQsXG4gICAgICAgICAgICAgICAgICAgIHN0cmljdDogZmFsc2UsXG4gICAgICAgICAgICAgICAgfTtcblxuICAgICAgICAgICAgICAgIC8vIE5vcm1hbGl6ZSBpZCAoc3RyaXAgcXVlcnkpIGFuZCB1c2UgZmlsZXN5c3RlbSBob3N0XG4gICAgICAgICAgICAgICAgY29uc3QgZmlsZVBhdGggPSBjbGVhbklkO1xuICAgICAgICAgICAgICAgIGNvbnN0IHByb2dyYW0gPSB0cy5jcmVhdGVQcm9ncmFtKFtmaWxlUGF0aF0sIGNvbXBpbGVyT3B0aW9ucyk7XG4gICAgICAgICAgICAgICAgY29uc3Qgc291cmNlRmlsZSA9XG4gICAgICAgICAgICAgICAgICAgIHByb2dyYW0uZ2V0U291cmNlRmlsZShmaWxlUGF0aCkgfHxcbiAgICAgICAgICAgICAgICAgICAgdHMuY3JlYXRlU291cmNlRmlsZShcbiAgICAgICAgICAgICAgICAgICAgICAgIGZpbGVQYXRoLFxuICAgICAgICAgICAgICAgICAgICAgICAgZnMuZXhpc3RzU3luYyhmaWxlUGF0aClcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICA/IGZzLnJlYWRGaWxlU3luYyhmaWxlUGF0aCwgXCJ1dGY4XCIpXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgOiBjb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgdHMuU2NyaXB0VGFyZ2V0LkxhdGVzdCxcbiAgICAgICAgICAgICAgICAgICAgICAgIHRydWUsXG4gICAgICAgICAgICAgICAgICAgICAgICB0cy5TY3JpcHRLaW5kLkpTLFxuICAgICAgICAgICAgICAgICAgICApO1xuICAgICAgICAgICAgICAgIGNvbnN0IGNoZWNrZXIgPSBwcm9ncmFtLmdldFR5cGVDaGVja2VyKCk7XG5cbiAgICAgICAgICAgICAgICAvLyBTdGVwIDI6IFBhcnNlIEJhYmVsIEFTVCBmb3IgdHJhbnNmb3JtYXRpb24gKHVzZSBCYWJlbCBmb3IgY29kZSBnZW4pXG4gICAgICAgICAgICAgICAgY29uc3QgYmFiZWxBc3QgPSBwYXJzZShjb2RlLCB7XG4gICAgICAgICAgICAgICAgICAgIHNvdXJjZVR5cGU6IFwibW9kdWxlXCIsXG4gICAgICAgICAgICAgICAgICAgIHBsdWdpbnM6IFtcbiAgICAgICAgICAgICAgICAgICAgICAgIFwianN4XCIsXG4gICAgICAgICAgICAgICAgICAgICAgICBcImR5bmFtaWNJbXBvcnRcIixcbiAgICAgICAgICAgICAgICAgICAgICAgIFwiaW1wb3J0TWV0YVwiLFxuICAgICAgICAgICAgICAgICAgICAgICAgLy8gQmFiZWwgNyBzdXBwb3J0cyBpbXBvcnRBc3NlcnRpb25zOyBuZXdlciBpbXBvcnRzIG1heSBuZWVkIGltcG9ydEF0dHJpYnV0ZXMgaW4gbmV3ZXIgQmFiZWxcbiAgICAgICAgICAgICAgICAgICAgICAgIFwiaW1wb3J0QXNzZXJ0aW9uc1wiLFxuICAgICAgICAgICAgICAgICAgICAgICAgXCJ0b3BMZXZlbEF3YWl0XCIsXG4gICAgICAgICAgICAgICAgICAgIF0sXG4gICAgICAgICAgICAgICAgICAgIHNvdXJjZUZpbGVuYW1lOiBpZCxcbiAgICAgICAgICAgICAgICB9KTtcblxuICAgICAgICAgICAgICAgIC8vIElmIHRyYXZlcnNlL2dlbmVyYXRlL3RlbXBsYXRlIGZhaWxlZCB0byBub3JtYWxpemUsIHNraXAgdG8gYXZvaWQgY3Jhc2hpbmdcbiAgICAgICAgICAgICAgICBpZiAodHlwZW9mIHRyYXZlcnNlICE9PSBcImZ1bmN0aW9uXCIgfHwgIXRlbXBsYXRlKSB7XG4gICAgICAgICAgICAgICAgICAgIHJldHVybjtcbiAgICAgICAgICAgICAgICB9XG5cbiAgICAgICAgICAgICAgICAvLyBTdGVwIDM6IFRyYXZlcnNlIEJhYmVsIEFTVCBhbmQgaW5mZXIvYWRkIGhpbnRzIHVzaW5nIFRTIGNoZWNrZXJcbiAgICAgICAgICAgICAgICAvLyBOb3RlOiBNYXAgQmFiZWwgbm9kZXMgdG8gVFMgbm9kZXMgdmlhIHBvc2l0aW9ucyBmb3IgZ2V0VHlwZUF0TG9jYXRpb25cbiAgICAgICAgICAgICAgICAvLyBVdGlsaXR5OiBjcmVhdGUgLyohIC4uLiAqLyBzdHlsZSBibG9jayBjb21tZW50IG9ubHkgb25jZVxuICAgICAgICAgICAgICAgIGZ1bmN0aW9uIGFkZEJsb2NrRG9jdW1lbnQocGF0aE9yTm9kZSwgdGV4dCkge1xuICAgICAgICAgICAgICAgICAgICBpZiAoIXRleHQpIHJldHVybjtcbiAgICAgICAgICAgICAgICAgICAgY29uc3Qgbm9kZSA9IHBhdGhPck5vZGUubm9kZSB8fCBwYXRoT3JOb2RlOyAvLyBhY2NlcHQgcGF0aCBvciBub2RlXG4gICAgICAgICAgICAgICAgICAgIGNvbnN0IGV4aXN0aW5nID0gKG5vZGUubGVhZGluZ0NvbW1lbnRzIHx8IFtdKS5zb21lKFxuICAgICAgICAgICAgICAgICAgICAgICAgKGMpID0+XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgYy50eXBlID09PSBcIkNvbW1lbnRCbG9ja1wiICYmXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgKGMudmFsdWUuaW5jbHVkZXMoXCJAdHlwZVwiKSB8fFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjLnZhbHVlLmluY2x1ZGVzKFwiQHJldHVybnNcIikpLFxuICAgICAgICAgICAgICAgICAgICApO1xuICAgICAgICAgICAgICAgICAgICBpZiAoZXhpc3RpbmcpIHJldHVybjtcbiAgICAgICAgICAgICAgICAgICAgaWYgKHBhdGhPck5vZGUuYWRkQ29tbWVudCkge1xuICAgICAgICAgICAgICAgICAgICAgICAgcGF0aE9yTm9kZS5hZGRDb21tZW50KFwibGVhZGluZ1wiLCBgISAke3RleHR9YCwgZmFsc2UpO1xuICAgICAgICAgICAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgICAgICAgICAgICAgLy8gRmFsbGJhY2s6IHB1c2ggaW50byBsZWFkaW5nQ29tbWVudHMgbWFudWFsbHlcbiAgICAgICAgICAgICAgICAgICAgICAgIG5vZGUubGVhZGluZ0NvbW1lbnRzID0gW1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIC4uLihub2RlLmxlYWRpbmdDb21tZW50cyB8fCBbXSksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgeyB0eXBlOiBcIkNvbW1lbnRCbG9ja1wiLCB2YWx1ZTogYCEgJHt0ZXh0fWAgfSxcbiAgICAgICAgICAgICAgICAgICAgICAgIF07XG4gICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICB9XG5cbiAgICAgICAgICAgICAgICAvLyBIZXVyaXN0aWMgb2JqZWN0IGxpdGVyYWwgc2hhcGUgaW5mZXJlbmNlIChCYWJlbCBub2RlIGJhc2VkIHRvIHN0YXkgZmFzdClcbiAgICAgICAgICAgICAgICBmdW5jdGlvbiBpbmZlck9iamVjdFNoYXBlKGJhYmVsT2JqZWN0RXhwcikge1xuICAgICAgICAgICAgICAgICAgICBpZiAoIW9iamVjdFNoYXBlRG9jdW1lbnRhdGlvbikgcmV0dXJuO1xuICAgICAgICAgICAgICAgICAgICBpZiAoIXQuaXNPYmplY3RFeHByZXNzaW9uKGJhYmVsT2JqZWN0RXhwcikpIHJldHVybjtcbiAgICAgICAgICAgICAgICAgICAgY29uc3QgcHJvcGVydGllcyA9IGJhYmVsT2JqZWN0RXhwci5wcm9wZXJ0aWVzLmZpbHRlcihcbiAgICAgICAgICAgICAgICAgICAgICAgIChwKSA9PlxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHQuaXNPYmplY3RQcm9wZXJ0eShwKSAmJlxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICh0LmlzSWRlbnRpZmllcihwLmtleSkgfHwgdC5pc1N0cmluZ0xpdGVyYWwocC5rZXkpKSxcbiAgICAgICAgICAgICAgICAgICAgKTtcbiAgICAgICAgICAgICAgICAgICAgaWYgKFxuICAgICAgICAgICAgICAgICAgICAgICAgcHJvcGVydGllcy5sZW5ndGggPT09IDAgfHxcbiAgICAgICAgICAgICAgICAgICAgICAgIHByb3BlcnRpZXMubGVuZ3RoID4gbWF4T2JqZWN0UHJvcGVydGllc1xuICAgICAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICAgICAgICAgICAgICByZXR1cm47XG4gICAgICAgICAgICAgICAgICAgIGNvbnN0IHBhcnRzID0gW107XG4gICAgICAgICAgICAgICAgICAgIGZvciAoY29uc3QgcHJvcGVydHkgb2YgcHJvcGVydGllcykge1xuICAgICAgICAgICAgICAgICAgICAgICAgY29uc3Qga2V5ID0gdC5pc0lkZW50aWZpZXIocHJvcGVydHkua2V5KVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgID8gcHJvcGVydHkua2V5Lm5hbWVcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICA6IHByb3BlcnR5LmtleS52YWx1ZTtcbiAgICAgICAgICAgICAgICAgICAgICAgIGxldCB2YWx1ZU5vZGUgPSBwcm9wZXJ0eS52YWx1ZTtcbiAgICAgICAgICAgICAgICAgICAgICAgIGxldCB0eXBlUGFydCA9IFwiYW55XCI7XG4gICAgICAgICAgICAgICAgICAgICAgICBpZiAodC5pc051bWVyaWNMaXRlcmFsKHZhbHVlTm9kZSkpIHR5cGVQYXJ0ID0gXCJudW1iZXJcIjtcbiAgICAgICAgICAgICAgICAgICAgICAgIGVsc2UgaWYgKHQuaXNTdHJpbmdMaXRlcmFsKHZhbHVlTm9kZSkpXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdHlwZVBhcnQgPSBcInN0cmluZ1wiO1xuICAgICAgICAgICAgICAgICAgICAgICAgZWxzZSBpZiAodC5pc0Jvb2xlYW5MaXRlcmFsKHZhbHVlTm9kZSkpXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdHlwZVBhcnQgPSBcImJvb2xlYW5cIjtcbiAgICAgICAgICAgICAgICAgICAgICAgIGVsc2UgaWYgKHQuaXNOdWxsTGl0ZXJhbCh2YWx1ZU5vZGUpKSB0eXBlUGFydCA9IFwiYW55XCI7XG4gICAgICAgICAgICAgICAgICAgICAgICBlbHNlIGlmICh0LmlzQXJyYXlFeHByZXNzaW9uKHZhbHVlTm9kZSkpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAvLyBTaW1wbGUgdW5pZm9ybSBwcmltaXRpdmUgZGV0ZWN0aW9uXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgaWYgKHZhbHVlTm9kZS5lbGVtZW50cy5sZW5ndGggPT09IDApXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHR5cGVQYXJ0ID0gXCJhbnlbXVwiO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGVsc2Uge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb25zdCBmaXJzdCA9IHZhbHVlTm9kZS5lbGVtZW50c1swXTtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgaWYgKHQuaXNOdW1lcmljTGl0ZXJhbChmaXJzdCkpXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB0eXBlUGFydCA9IFwibnVtYmVyW11cIjtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZWxzZSBpZiAodC5pc1N0cmluZ0xpdGVyYWwoZmlyc3QpKVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdHlwZVBhcnQgPSBcInN0cmluZ1tdXCI7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGVsc2UgaWYgKHQuaXNCb29sZWFuTGl0ZXJhbChmaXJzdCkpXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB0eXBlUGFydCA9IFwiYm9vbGVhbltdXCI7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGVsc2UgdHlwZVBhcnQgPSBcImFueVtdXCI7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgICAgICAgfSBlbHNlIGlmICh0LmlzT2JqZWN0RXhwcmVzc2lvbih2YWx1ZU5vZGUpKVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHR5cGVQYXJ0ID0gXCJvYmplY3RcIjtcbiAgICAgICAgICAgICAgICAgICAgICAgIGVsc2UgaWYgKHQuaXNUZW1wbGF0ZUxpdGVyYWwodmFsdWVOb2RlKSlcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB0eXBlUGFydCA9IFwic3RyaW5nXCI7XG4gICAgICAgICAgICAgICAgICAgICAgICBlbHNlIGlmIChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB0LmlzVW5hcnlFeHByZXNzaW9uKHZhbHVlTm9kZSkgJiZcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZU5vZGUub3BlcmF0b3IgPT09IFwiK1wiXG4gICAgICAgICAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdHlwZVBhcnQgPSBcIm51bWJlclwiO1xuICAgICAgICAgICAgICAgICAgICAgICAgZWxzZSBpZiAoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdC5pc0JpbmFyeUV4cHJlc3Npb24odmFsdWVOb2RlKSAmJlxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgXCIrXCIsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIFwiLVwiLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBcIipcIixcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgXCIvXCIsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIFwiJVwiLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBcInxcIixcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgXCImXCIsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIFwiXlwiLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBcIjw8XCIsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIFwiPj5cIixcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgXCI+Pj5cIixcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBdLmluY2x1ZGVzKHZhbHVlTm9kZS5vcGVyYXRvcilcbiAgICAgICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB0eXBlUGFydCA9IFwibnVtYmVyXCI7XG4gICAgICAgICAgICAgICAgICAgICAgICBlbHNlIGlmICh0LmlzQ2FsbEV4cHJlc3Npb24odmFsdWVOb2RlKSkge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIC8vIEhldXJpc3RpYzogTWF0aC4qID0+IG51bWJlciwgU3RyaW5nL051bWJlci9Cb29sZWFuIGNvbnN0cnVjdG9yc1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGlmIChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdC5pc01lbWJlckV4cHJlc3Npb24odmFsdWVOb2RlLmNhbGxlZSkgJiZcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdC5pc0lkZW50aWZpZXIodmFsdWVOb2RlLmNhbGxlZS5vYmplY3QsIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6IFwiTWF0aFwiLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB9KVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdHlwZVBhcnQgPSBcIm51bWJlclwiO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGVsc2UgaWYgKFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB0LmlzSWRlbnRpZmllcih2YWx1ZU5vZGUuY2FsbGVlLCB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiBcIk51bWJlclwiLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB9KVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdHlwZVBhcnQgPSBcIm51bWJlclwiO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGVsc2UgaWYgKFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB0LmlzSWRlbnRpZmllcih2YWx1ZU5vZGUuY2FsbGVlLCB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiBcIlN0cmluZ1wiLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB9KVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdHlwZVBhcnQgPSBcInN0cmluZ1wiO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGVsc2UgaWYgKFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB0LmlzSWRlbnRpZmllcih2YWx1ZU5vZGUuY2FsbGVlLCB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiBcIkJvb2xlYW5cIixcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgfSlcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHR5cGVQYXJ0ID0gXCJib29sZWFuXCI7XG4gICAgICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgICAgICAgICBwYXJ0cy5wdXNoKGAke2tleX06ICR7dHlwZVBhcnR9YCk7XG4gICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICAgICAgaWYgKHBhcnRzLmxlbmd0aCA9PT0gMCkgcmV0dXJuO1xuICAgICAgICAgICAgICAgICAgICByZXR1cm4gYHsgJHtwYXJ0cy5qb2luKFwiLCBcIil9IH1gO1xuICAgICAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgICAgIC8vIFRyYWNrIHZhcmlhYmxlIHR5cGVzIGJ5IGlkZW50aWZpZXIgbmFtZSAoYmVzdC1lZmZvcnQpIGZvciBsYXRlciBwYXJhbSBjb2VyY2lvbiBkZWNpc2lvbnNcbiAgICAgICAgICAgICAgICBjb25zdCBpbmZlcnJlZFZhcmlhYmxlVHlwZXMgPSBuZXcgTWFwKCk7XG5cbiAgICAgICAgICAgICAgICB0cmF2ZXJzZShiYWJlbEFzdCwge1xuICAgICAgICAgICAgICAgICAgICBGdW5jdGlvbkRlY2xhcmF0aW9uKHBhdGgpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIGlmICghcGF0aC5ub2RlLmlkKSByZXR1cm47XG4gICAgICAgICAgICAgICAgICAgICAgICBjb25zdCB0c05vZGUgPSBmaW5kVFNOb2RlQXRQb3NpdGlvbihcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzb3VyY2VGaWxlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHBhdGgubm9kZS5pZC5zdGFydCxcbiAgICAgICAgICAgICAgICAgICAgICAgICk7XG4gICAgICAgICAgICAgICAgICAgICAgICBpZiAoIXRzTm9kZSkgcmV0dXJuO1xuICAgICAgICAgICAgICAgICAgICAgICAgbGV0IGZ1bmN0aW9uVHlwZTtcbiAgICAgICAgICAgICAgICAgICAgICAgIHRyeSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZnVuY3Rpb25UeXBlID0gY2hlY2tlci5nZXRUeXBlQXRMb2NhdGlvbih0c05vZGUpO1xuICAgICAgICAgICAgICAgICAgICAgICAgfSBjYXRjaCB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgYmFpbE91dCA9IHRydWU7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuO1xuICAgICAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgICAgICAgbGV0IHNpZ3M7XG4gICAgICAgICAgICAgICAgICAgICAgICB0cnkge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNpZ3MgPSBjaGVja2VyLmdldFNpZ25hdHVyZXNPZlR5cGVcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgPyBjaGVja2VyLmdldFNpZ25hdHVyZXNPZlR5cGUoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGZ1bmN0aW9uVHlwZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdHMuU2lnbmF0dXJlS2luZC5DYWxsLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgOiBmdW5jdGlvblR5cGUuZ2V0Q2FsbFNpZ25hdHVyZXNcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA/IGZ1bmN0aW9uVHlwZS5nZXRDYWxsU2lnbmF0dXJlcygpXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgOiBbXTtcbiAgICAgICAgICAgICAgICAgICAgICAgIH0gY2F0Y2gge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGJhaWxPdXQgPSB0cnVlO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybjtcbiAgICAgICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICAgICAgICAgIGNvbnN0IHNpZyA9XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgc2lncyAmJiBzaWdzLmxlbmd0aCA+IDAgPyBzaWdzWzBdIDogdW5kZWZpbmVkO1xuICAgICAgICAgICAgICAgICAgICAgICAgaWYgKCFzaWcpIHJldHVybjtcblxuICAgICAgICAgICAgICAgICAgICAgICAgLy8gUGFyYW1zIGZyb20gc2lnbmF0dXJlXG4gICAgICAgICAgICAgICAgICAgICAgICBsZXQgcGFyYW1ldGVyVHlwZXM7XG4gICAgICAgICAgICAgICAgICAgICAgICB0cnkge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHBhcmFtZXRlclR5cGVzID0gc2lnLnBhcmFtZXRlcnMubWFwKChwYXJhbWV0ZXIpID0+IHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgY29uc3QgZGVjbCA9XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBwYXJhbWV0ZXIudmFsdWVEZWNsYXJhdGlvbiB8fFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcGFyYW1ldGVyLmRlY2xhcmF0aW9ucz8uWzBdO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb25zdCBwVHlwZSA9IGRlY2xcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgID8gY2hlY2tlci5nZXRUeXBlT2ZTeW1ib2xBdExvY2F0aW9uKFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcGFyYW1ldGVyLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZGVjbCxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgOiB1bmRlZmluZWQ7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiB0c1R5cGVUb0pTRG9jdW1lbnQoY2hlY2tlciwgcFR5cGUpO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIH0pO1xuICAgICAgICAgICAgICAgICAgICAgICAgfSBjYXRjaCB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgYmFpbE91dCA9IHRydWU7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuO1xuICAgICAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgICAgICAgbGV0IHJldHVyblR5cGUgPSBcImFueVwiO1xuICAgICAgICAgICAgICAgICAgICAgICAgdHJ5IHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZXR1cm5UeXBlID0gdHNUeXBlVG9KU0RvY3VtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjaGVja2VyLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjaGVja2VyLmdldFJldHVyblR5cGVPZlNpZ25hdHVyZShzaWcpLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICk7XG4gICAgICAgICAgICAgICAgICAgICAgICB9IGNhdGNoIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAvKiBpZ25vcmUgKi9cbiAgICAgICAgICAgICAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgICAgICAgICAgICAgLy8gU2tpcCBlbWl0dGluZyB3aGVuIGV2ZXJ5dGhpbmcgaXMgJ2FueScgdG8gbWluaW1pemUgZm9vdHByaW50XG4gICAgICAgICAgICAgICAgICAgICAgICBjb25zdCBpc01lYW5pbmdmdWwgPVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJldHVyblR5cGUgIT09IFwiYW55XCIgfHxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBwYXJhbWV0ZXJUeXBlcy5zb21lKCh0XykgPT4gdF8gIT09IFwiYW55XCIpO1xuICAgICAgICAgICAgICAgICAgICAgICAgaWYgKCFpc01lYW5pbmdmdWwpIHJldHVybjtcblxuICAgICAgICAgICAgICAgICAgICAgICAgLy8gQWRkIEpTRG9jIChwcmVzZXJ2ZWQgYnkgdGVyc2VyIHZpYSAvKiEgLi4uICovOyBzaW5nbGUtbGluZSB0byBtaW5pbWl6ZSBzaXplKVxuICAgICAgICAgICAgICAgICAgICAgICAgY29uc3QgcGFyYW1ldGVyRG9jdW1lbnRhdGlvbiA9IHBhdGgubm9kZS5wYXJhbXMubWFwKFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIChwYXJhbWV0ZXIsIGluZGV4KSA9PlxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBgQHBhcmFtIHske3BhcmFtZXRlclR5cGVzW2luZGV4XSB8fCBcImFueVwifX0gJHtnZXRQYXJhbWV0ZXJOYW1lKHBhcmFtZXRlcil9YCxcbiAgICAgICAgICAgICAgICAgICAgICAgICk7XG4gICAgICAgICAgICAgICAgICAgICAgICBjb25zdCBkb2N1bWVudF8gPSBgISAke1suLi5wYXJhbWV0ZXJEb2N1bWVudGF0aW9uLCBgQHJldHVybnMgeyR7cmV0dXJuVHlwZX19YF0uam9pbihcIiBcIil9YDtcbiAgICAgICAgICAgICAgICAgICAgICAgIC8vIE9ubHkgYWRkIG9uY2VcbiAgICAgICAgICAgICAgICAgICAgICAgIGNvbnN0IGV4aXN0aW5nTGVhZCA9IHBhdGgubm9kZS5sZWFkaW5nQ29tbWVudHMgfHwgW107XG4gICAgICAgICAgICAgICAgICAgICAgICBjb25zdCBhbHJlYWR5SGFzSlNEb2N1bWVudCA9IGV4aXN0aW5nTGVhZC5zb21lKFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIChjKSA9PlxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjLnR5cGUgPT09IFwiQ29tbWVudEJsb2NrXCIgJiZcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgKGMudmFsdWUuaW5jbHVkZXMoXCJAcmV0dXJuc1wiKSB8fFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgYy52YWx1ZS5zdGFydHNXaXRoKFwiIVwiKSksXG4gICAgICAgICAgICAgICAgICAgICAgICApO1xuICAgICAgICAgICAgICAgICAgICAgICAgaWYgKCFhbHJlYWR5SGFzSlNEb2N1bWVudCkge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHBhdGguYWRkQ29tbWVudChcImxlYWRpbmdcIiwgZG9jdW1lbnRfLCBmYWxzZSk7IC8vIGZhbHNlID0+IGJsb2NrIGNvbW1lbnQgPT4gLyohIC4uLiAqL1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRpZENoYW5nZSA9IHRydWU7XG4gICAgICAgICAgICAgICAgICAgICAgICB9XG5cbiAgICAgICAgICAgICAgICAgICAgICAgIC8vIE9wdGlvbmFsOiBJbmplY3QgcGFyYW0gY29lcmNpb25zIGF0IHRvcCBvZiBmdW5jdGlvbiBib2R5IGlmIGVuYWJsZWRcbiAgICAgICAgICAgICAgICAgICAgICAgIGlmIChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBlbmFibGVDb2VyY2lvbnMgJiZcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBwYXJhbWV0ZXJIb2lzdENvZXJjaW9ucyAmJlxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHBhdGgubm9kZS5ib2R5ICYmXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgQXJyYXkuaXNBcnJheShwYXRoLm5vZGUucGFyYW1zKVxuICAgICAgICAgICAgICAgICAgICAgICAgKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgY29uc3QgY29lcmNpb25TdGF0ZW1lbnRzID0gW107XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbGV0IGluZGV4ID0gMDtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBmb3IgKGNvbnN0IHAgb2YgcGF0aC5ub2RlLnBhcmFtcykge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBpZiAoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBwYXJhbWV0ZXJUeXBlc1tpbmRleF0gPT09IFwibnVtYmVyXCIgJiZcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHQuaXNJZGVudGlmaWVyKHApXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICkge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgY29lcmNpb25TdGF0ZW1lbnRzLnB1c2goXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdGVtcGxhdGUuc3RhdGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBgJHtwLm5hbWV9ID0gKCR7cC5uYW1lfSkgfCAwO2AsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgKSgpLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgKTtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBpbmRleCArPSAxO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBpZiAoY29lcmNpb25TdGF0ZW1lbnRzLmxlbmd0aCA+IDApIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcGF0aC5ub2RlLmJvZHkuYm9keS51bnNoaWZ0KFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgLi4uY29lcmNpb25TdGF0ZW1lbnRzLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICApO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkaWRDaGFuZ2UgPSB0cnVlO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgICAgICAgICAgICAgLy8gQ29lcmNlIHBhcmFtcy9yZXR1cm5zIGlmIG51bWJlclxuICAgICAgICAgICAgICAgICAgICAgICAgaWYgKGVuYWJsZUNvZXJjaW9ucykge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHBhdGgudHJhdmVyc2Uoe1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBCaW5hcnlFeHByZXNzaW9uKHN1YlBhdGgpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbnN0IHBhcmFtZXRlck5vZGUgPSBwYXRoLm5vZGUucGFyYW1zLmZpbmQoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgKHApID0+XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHQuaXNJZGVudGlmaWVyKHApICYmXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHQuaXNJZGVudGlmaWVyKHN1YlBhdGgubm9kZS5sZWZ0KSAmJlxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBwLm5hbWUgPT09IHN1YlBhdGgubm9kZS5sZWZ0Lm5hbWUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICApO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgaWYgKFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHBhcmFtZXRlck5vZGUgJiZcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBwYXJhbWV0ZXJUeXBlc1tcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcGF0aC5ub2RlLnBhcmFtcy5pbmRleE9mKFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcGFyYW1ldGVyTm9kZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIF0gPT09IFwibnVtYmVyXCIgJiZcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBhZGRUeXBlQ29lcmNpb24oc3ViUGF0aCwgXCJudW1iZXJcIilcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkaWRDaGFuZ2UgPSB0cnVlO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBSZXR1cm5TdGF0ZW1lbnQoc3ViUGF0aCkge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgaWYgKFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHN1YlBhdGgubm9kZS5hcmd1bWVudCAmJlxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJldHVyblR5cGUgPT09IFwibnVtYmVyXCIgJiZcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBhZGRUeXBlQ29lcmNpb24oc3ViUGF0aCwgXCJudW1iZXJcIilcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkaWRDaGFuZ2UgPSB0cnVlO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIH0pO1xuICAgICAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgICB9LFxuICAgICAgICAgICAgICAgICAgICBWYXJpYWJsZURlY2xhcmF0b3IocGF0aCkge1xuICAgICAgICAgICAgICAgICAgICAgICAgY29uc3QgdHNOb2RlID0gZmluZFRTTm9kZUF0UG9zaXRpb24oXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgc291cmNlRmlsZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBwYXRoLm5vZGUuaWQuc3RhcnQsXG4gICAgICAgICAgICAgICAgICAgICAgICApO1xuICAgICAgICAgICAgICAgICAgICAgICAgaWYgKCF0c05vZGUgfHwgIXBhdGgubm9kZS5pbml0KSByZXR1cm47XG4gICAgICAgICAgICAgICAgICAgICAgICBsZXQgdmFyaWFibGVUeXBlO1xuICAgICAgICAgICAgICAgICAgICAgICAgdHJ5IHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YXJpYWJsZVR5cGUgPSBjaGVja2VyLmdldFR5cGVBdExvY2F0aW9uKHRzTm9kZSk7XG4gICAgICAgICAgICAgICAgICAgICAgICB9IGNhdGNoIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZXR1cm47XG4gICAgICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgICAgICAgICBjb25zdCB0eXBlU3RyaW5nID0gdHNUeXBlVG9KU0RvY3VtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNoZWNrZXIsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFyaWFibGVUeXBlLFxuICAgICAgICAgICAgICAgICAgICAgICAgKTtcbiAgICAgICAgICAgICAgICAgICAgICAgIGlmICh0LmlzSWRlbnRpZmllcihwYXRoLm5vZGUuaWQpKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgaW5mZXJyZWRWYXJpYWJsZVR5cGVzLnNldChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcGF0aC5ub2RlLmlkLm5hbWUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHR5cGVTdHJpbmcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgKTtcbiAgICAgICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICAgICAgICAgIC8vIEFkZCB2YXJpYWJsZSBsZXZlbCBKU0RvYyBpZiBlbmFibGVkICYgbWVhbmluZ2Z1bFxuICAgICAgICAgICAgICAgICAgICAgICAgaWYgKFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhcmlhYmxlRG9jdW1lbnRhdGlvbiAmJlxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHQuaXNJZGVudGlmaWVyKHBhdGgubm9kZS5pZClcbiAgICAgICAgICAgICAgICAgICAgICAgICkge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGxldCBkb2N1bWVudFR5cGUgPSB0eXBlU3RyaW5nO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIC8vIFJlZmluZSBmb3Igb2JqZWN0IGxpdGVyYWwgd2hlbiBnZW5lcmljICdvYmplY3QnXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgaWYgKFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkb2N1bWVudFR5cGUgPT09IFwib2JqZWN0XCIgJiZcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgb2JqZWN0U2hhcGVEb2N1bWVudGF0aW9uICYmXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHQuaXNPYmplY3RFeHByZXNzaW9uKHBhdGgubm9kZS5pbml0KVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICkge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb25zdCBzaGFwZSA9IGluZmVyT2JqZWN0U2hhcGUocGF0aC5ub2RlLmluaXQpO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBpZiAoc2hhcGUpIGRvY3VtZW50VHlwZSA9IHNoYXBlO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAvLyBSZWZpbmUgZm9yIGFycmF5cyBvZiBzaW1wbGUgcHJpbWl0aXZlcyBmcm9tIGxpdGVyYWxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBpZiAodC5pc0FycmF5RXhwcmVzc2lvbihwYXRoLm5vZGUuaW5pdCkpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgaWYgKHBhdGgubm9kZS5pbml0LmVsZW1lbnRzLmxlbmd0aCA9PT0gMClcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRvY3VtZW50VHlwZSA9IFwiYW55W11cIjtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZWxzZSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb25zdCBmaXJzdCA9IHBhdGgubm9kZS5pbml0LmVsZW1lbnRzWzBdO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgaWYgKHQuaXNOdW1lcmljTGl0ZXJhbChmaXJzdCkpXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZG9jdW1lbnRUeXBlID0gXCJudW1iZXJbXVwiO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZWxzZSBpZiAodC5pc1N0cmluZ0xpdGVyYWwoZmlyc3QpKVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRvY3VtZW50VHlwZSA9IFwic3RyaW5nW11cIjtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGVsc2UgaWYgKHQuaXNCb29sZWFuTGl0ZXJhbChmaXJzdCkpXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZG9jdW1lbnRUeXBlID0gXCJib29sZWFuW11cIjtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGVsc2UgZG9jdW1lbnRUeXBlID0gXCJhbnlbXVwiO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGlmIChkb2N1bWVudFR5cGUgJiYgZG9jdW1lbnRUeXBlICE9PSBcImFueVwiKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGFkZEJsb2NrRG9jdW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBwYXRoLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgYEB0eXBlIHske2RvY3VtZW50VHlwZX19YCxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgKTtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZGlkQ2hhbmdlID0gdHJ1ZTtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgICAgICAgICBpZiAoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZW5hYmxlQ29lcmNpb25zICYmXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdHlwZVN0cmluZyA9PT0gXCJudW1iZXJcIiAmJlxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGFkZFR5cGVDb2VyY2lvbihwYXRoLCBcIm51bWJlclwiKVxuICAgICAgICAgICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRpZENoYW5nZSA9IHRydWU7XG4gICAgICAgICAgICAgICAgICAgIH0sXG4gICAgICAgICAgICAgICAgICAgIEZvck9mU3RhdGVtZW50KHBhdGgpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIGxldCBsZWZ0SWQ7XG4gICAgICAgICAgICAgICAgICAgICAgICBpZiAodC5pc1ZhcmlhYmxlRGVjbGFyYXRpb24ocGF0aC5ub2RlLmxlZnQpKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgY29uc3QgZmlyc3QgPSBwYXRoLm5vZGUubGVmdC5kZWNsYXJhdGlvbnM/LlswXTtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBpZiAoZmlyc3QgJiYgdC5pc0lkZW50aWZpZXIoZmlyc3QuaWQpKVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBsZWZ0SWQgPSBmaXJzdC5pZDtcbiAgICAgICAgICAgICAgICAgICAgICAgIH0gZWxzZSBpZiAodC5pc0lkZW50aWZpZXIocGF0aC5ub2RlLmxlZnQpKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbGVmdElkID0gcGF0aC5ub2RlLmxlZnQ7XG4gICAgICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgICAgICAgICBpZiAoIWxlZnRJZCkgcmV0dXJuO1xuICAgICAgICAgICAgICAgICAgICAgICAgY29uc3QgcmlnaHRUU05vZGUgPSBmaW5kVFNOb2RlQXRQb3NpdGlvbihcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzb3VyY2VGaWxlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHBhdGgubm9kZS5yaWdodC5zdGFydCxcbiAgICAgICAgICAgICAgICAgICAgICAgICk7XG4gICAgICAgICAgICAgICAgICAgICAgICBpZiAoIXJpZ2h0VFNOb2RlKSByZXR1cm47XG4gICAgICAgICAgICAgICAgICAgICAgICBsZXQgYXJyYXlUeXBlO1xuICAgICAgICAgICAgICAgICAgICAgICAgdHJ5IHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBhcnJheVR5cGUgPSBjaGVja2VyLmdldFR5cGVBdExvY2F0aW9uKHJpZ2h0VFNOb2RlKTtcbiAgICAgICAgICAgICAgICAgICAgICAgIH0gY2F0Y2gge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybjtcbiAgICAgICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICAgICAgICAgIGxldCBlbGVtZW50VHlwZTtcbiAgICAgICAgICAgICAgICAgICAgICAgIHRyeSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZWxlbWVudFR5cGUgPVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAoY2hlY2tlci5nZXRBcnJheUVsZW1lbnRUeXBlICYmXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjaGVja2VyLmdldEFycmF5RWxlbWVudFR5cGUoYXJyYXlUeXBlKSkgfHxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgKGNoZWNrZXIuZ2V0RWxlbWVudFR5cGVPZkFycmF5VHlwZSAmJlxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgY2hlY2tlci5nZXRFbGVtZW50VHlwZU9mQXJyYXlUeXBlKFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGFycmF5VHlwZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICkpIHx8XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHVuZGVmaW5lZDtcbiAgICAgICAgICAgICAgICAgICAgICAgIH0gY2F0Y2gge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIC8qIGlnbm9yZSAqL1xuICAgICAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgICAgICAgY29uc3QgZWxlbWVudFN0cmluZyA9IHRzVHlwZVRvSlNEb2N1bWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBjaGVja2VyLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGVsZW1lbnRUeXBlLFxuICAgICAgICAgICAgICAgICAgICAgICAgKTtcbiAgICAgICAgICAgICAgICAgICAgICAgIGlmIChlbmFibGVDb2VyY2lvbnMgJiYgZWxlbWVudFN0cmluZyA9PT0gXCJudW1iZXJcIikge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHBhdGgudHJhdmVyc2Uoe1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBCaW5hcnlFeHByZXNzaW9uKHN1YlBhdGgpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGlmIChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB0LmlzSWRlbnRpZmllcihzdWJQYXRoLm5vZGUubGVmdCkgJiZcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB0LmlzSWRlbnRpZmllcihsZWZ0SWQpICYmXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgc3ViUGF0aC5ub2RlLmxlZnQubmFtZSA9PT1cbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbGVmdElkLm5hbWUgJiZcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBhZGRUeXBlQ29lcmNpb24oc3ViUGF0aCwgXCJudW1iZXJcIilcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkaWRDaGFuZ2UgPSB0cnVlO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIH0pO1xuICAgICAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgICB9LFxuICAgICAgICAgICAgICAgICAgICAvLyBEZW9wdCB3YXJuaW5nOiBEeW5hbWljIHByb3BzXG4gICAgICAgICAgICAgICAgICAgIEFzc2lnbm1lbnRFeHByZXNzaW9uKHBhdGgpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIGlmIChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBwYXRoLm5vZGUubGVmdD8uY29tcHV0ZWQgJiZcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBwYXRoLm5vZGUubGVmdC5wcm9wZXJ0eT8udHlwZSAhPT0gXCJJZGVudGlmaWVyXCJcbiAgICAgICAgICAgICAgICAgICAgICAgICkge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIC8vZXNsaW50LWRpc2FibGUtbmV4dC1saW5lIG5vLXVudXNlZC12YXJzXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgY29uc3QgbGluZSA9XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHBhdGgubm9kZS5sb2MgJiYgcGF0aC5ub2RlLmxvYy5zdGFydFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgPyBwYXRoLm5vZGUubG9jLnN0YXJ0LmxpbmVcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIDogXCI/XCI7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgLypcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb25zb2xlLndhcm4oXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGBQb3RlbnRpYWwgVjggZGVvcHRpbWl6YXRpb246IER5bmFtaWMgcHJvcGVydHkgYXQgbGluZSAke2xpbmV9YCxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICApO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICovXG4gICAgICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgICAgIH0sXG4gICAgICAgICAgICAgICAgfSk7XG5cbiAgICAgICAgICAgICAgICAvLyBIZWxwZXI6IEZpbmQgVFMgbm9kZSBhdCBCYWJlbCBwb3NpdGlvbiAoYXBwcm94aW1hdGUgdmlhIHBvcylcbiAgICAgICAgICAgICAgICBmdW5jdGlvbiBmaW5kVFNOb2RlQXRQb3NpdGlvbihzb3VyY2VGaWxlLCBwb3MpIHtcbiAgICAgICAgICAgICAgICAgICAgbGV0IHJlc3VsdDtcbiAgICAgICAgICAgICAgICAgICAgZnVuY3Rpb24gdmlzaXQobm9kZSkge1xuICAgICAgICAgICAgICAgICAgICAgICAgaWYgKHBvcyA8IG5vZGUucG9zIHx8IHBvcyA+PSBub2RlLmVuZCkgcmV0dXJuO1xuICAgICAgICAgICAgICAgICAgICAgICAgcmVzdWx0ID0gbm9kZTtcbiAgICAgICAgICAgICAgICAgICAgICAgIG5vZGUuZm9yRWFjaENoaWxkKHZpc2l0KTtcbiAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgICB2aXNpdChzb3VyY2VGaWxlKTtcbiAgICAgICAgICAgICAgICAgICAgcmV0dXJuIHJlc3VsdDtcbiAgICAgICAgICAgICAgICB9XG5cbiAgICAgICAgICAgICAgICBpZiAoYmFpbE91dCB8fCAhZGlkQ2hhbmdlKSByZXR1cm47XG4gICAgICAgICAgICAgICAgLy8gU3RlcCA0OiBHZW5lcmF0ZSB0cmFuc2Zvcm1lZCBjb2RlIHdpdGggc291cmNlIG1hcCAob25seSBpZiBjaGFuZ2VkKVxuICAgICAgICAgICAgICAgIGNvbnN0IHsgY29kZTogdHJhbnNmb3JtZWRDb2RlLCBtYXAgfSA9IGdlbmVyYXRlKGJhYmVsQXN0LCB7XG4gICAgICAgICAgICAgICAgICAgIHNvdXJjZU1hcHM6IHRydWUsXG4gICAgICAgICAgICAgICAgICAgIHNvdXJjZUZpbGVOYW1lOiBpZCxcbiAgICAgICAgICAgICAgICB9KTtcblxuICAgICAgICAgICAgICAgIHJldHVybiB7XG4gICAgICAgICAgICAgICAgICAgIGNvZGU6IHRyYW5zZm9ybWVkQ29kZSxcbiAgICAgICAgICAgICAgICAgICAgbWFwLFxuICAgICAgICAgICAgICAgIH07XG4gICAgICAgICAgICB9IGNhdGNoIChlcnJvcikge1xuICAgICAgICAgICAgICAgIGNvbnN0IGVycm9yXyA9XG4gICAgICAgICAgICAgICAgICAgIGVycm9yIGluc3RhbmNlb2YgRXJyb3IgPyBlcnJvciA6IG5ldyBFcnJvcihTdHJpbmcoZXJyb3IpKTtcbiAgICAgICAgICAgICAgICBpZiAoaXNCdWlsZCkge1xuICAgICAgICAgICAgICAgICAgICAvLyBGYWlsIHRoZSBidWlsZCB3aXRoIGNvbXBhY3QgbWVzc2FnZVxuICAgICAgICAgICAgICAgICAgICB0aGlzLmVycm9yKGNvbXBhY3RFcnJvcihlcnJvcl8sIGlkKSk7XG4gICAgICAgICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgICAgICAgICAgLy8gS2VlcCBkZXYgc2VydmVyIHJ1bm5pbmcgd2l0aCBjb21wYWN0IG1lc3NhZ2VcbiAgICAgICAgICAgICAgICAgICAgY29uc29sZS5lcnJvcihjb21wYWN0RXJyb3IoZXJyb3JfLCBpZCkpO1xuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICByZXR1cm47IC8vIEdyYWNlZnVsIGZhbGxiYWNrIGluIGRldlxuICAgICAgICAgICAgfVxuICAgICAgICB9LFxuICAgICAgICAvLyBObyBITVIgYmVoYXZpb3I7IHBsdWdpbiBvbmx5IGFwcGxpZXMgaW4gYnVpbGRcbiAgICB9O1xufVxuIiwgImNvbnN0IF9fdml0ZV9pbmplY3RlZF9vcmlnaW5hbF9kaXJuYW1lID0gXCIvVXNlcnMvZ2VvcmdlL0xpYnJldmVyc2UvcGx1Z2luc1wiO2NvbnN0IF9fdml0ZV9pbmplY3RlZF9vcmlnaW5hbF9maWxlbmFtZSA9IFwiL1VzZXJzL2dlb3JnZS9MaWJyZXZlcnNlL3BsdWdpbnMvcG9zdGNzcy1yZW1vdmUtcHJlZml4LmpzXCI7Y29uc3QgX192aXRlX2luamVjdGVkX29yaWdpbmFsX2ltcG9ydF9tZXRhX3VybCA9IFwiZmlsZTovLy9Vc2Vycy9nZW9yZ2UvTGlicmV2ZXJzZS9wbHVnaW5zL3Bvc3Rjc3MtcmVtb3ZlLXByZWZpeC5qc1wiO2Z1bmN0aW9uIHJlbW92ZVByZWZpeCgpIHtcbiAgICByZXR1cm4ge1xuICAgICAgICBwb3N0Y3NzUGx1Z2luOiBcInJlbW92ZS1wcmVmaXhcIixcbiAgICAgICAgRGVjbGFyYXRpb24oZGVjbCkge1xuICAgICAgICAgICAgZGVjbC5wcm9wID0gZGVjbC5wcm9wLnJlcGxhY2UoL14tXFx3Ky0vLCBcIlwiKTtcbiAgICAgICAgfSxcbiAgICB9O1xufVxucmVtb3ZlUHJlZml4LnBvc3Rjc3MgPSB0cnVlO1xuZXhwb3J0IGRlZmF1bHQgcmVtb3ZlUHJlZml4O1xuIiwgImNvbnN0IF9fdml0ZV9pbmplY3RlZF9vcmlnaW5hbF9kaXJuYW1lID0gXCIvVXNlcnMvZ2VvcmdlL0xpYnJldmVyc2UvY29uZmlnL3ZpdGVcIjtjb25zdCBfX3ZpdGVfaW5qZWN0ZWRfb3JpZ2luYWxfZmlsZW5hbWUgPSBcIi9Vc2Vycy9nZW9yZ2UvTGlicmV2ZXJzZS9jb25maWcvdml0ZS9jb21tb24uanNcIjtjb25zdCBfX3ZpdGVfaW5qZWN0ZWRfb3JpZ2luYWxfaW1wb3J0X21ldGFfdXJsID0gXCJmaWxlOi8vL1VzZXJzL2dlb3JnZS9MaWJyZXZlcnNlL2NvbmZpZy92aXRlL2NvbW1vbi5qc1wiOy8vIFNoYXJlZCBWaXRlIGNvbmZpZyBoZWxwZXJzIHVzZWQgYnkgYm90aCB0aGUgUmFpbHMgVml0ZSBkZXYgc2VydmVyIGFuZCBFbGVjdHJvbiBGb3JnZS5cbi8vIEtlZXAgdGhpcyBmaWxlIGRlcGVuZGVuY3ktZnJlZSAoYmVzaWRlcyBOb2RlIGJ1aWx0aW5zKSBzbyBpdCBjYW4gYmUgaW1wb3J0ZWQgZnJvbSBjb25maWcgZmlsZXMuXG5cbmV4cG9ydCBjb25zdCBhbGxPYmZ1c2NhdG9yQ29uZmlnID0ge1xuICAgIGV4Y2x1ZGVzOiBbXSxcbiAgICBlbmFibGU6IHRydWUsXG4gICAgbG9nOiB0cnVlLFxuICAgIGF1dG9FeGNsdWRlTm9kZU1vZHVsZXM6IHRydWUsXG4gICAgdGhyZWFkUG9vbDogdHJ1ZSxcbiAgICBvcHRpb25zOiB7XG4gICAgICAgIGNvbXBhY3Q6IHRydWUsXG4gICAgICAgIGNvbnRyb2xGbG93RmxhdHRlbmluZzogdHJ1ZSxcbiAgICAgICAgY29udHJvbEZsb3dGbGF0dGVuaW5nVGhyZXNob2xkOiAxLFxuICAgICAgICBkZWFkQ29kZUluamVjdGlvbjogZmFsc2UsXG4gICAgICAgIGRlYnVnUHJvdGVjdGlvbjogZmFsc2UsXG4gICAgICAgIGRlYnVnUHJvdGVjdGlvbkludGVydmFsOiAwLFxuICAgICAgICBkaXNhYmxlQ29uc29sZU91dHB1dDogZmFsc2UsXG4gICAgICAgIGlkZW50aWZpZXJOYW1lc0dlbmVyYXRvcjogXCJoZXhhZGVjaW1hbFwiLFxuICAgICAgICBsb2c6IGZhbHNlLFxuICAgICAgICBudW1iZXJzVG9FeHByZXNzaW9uczogZmFsc2UsXG4gICAgICAgIHJlbmFtZUdsb2JhbHM6IGZhbHNlLFxuICAgICAgICBzZWxmRGVmZW5kaW5nOiB0cnVlLFxuICAgICAgICBzaW1wbGlmeTogdHJ1ZSxcbiAgICAgICAgc3BsaXRTdHJpbmdzOiBmYWxzZSxcbiAgICAgICAgaWdub3JlSW1wb3J0czogdHJ1ZSxcbiAgICAgICAgc3RyaW5nQXJyYXk6IHRydWUsXG4gICAgICAgIHN0cmluZ0FycmF5Q2FsbHNUcmFuc2Zvcm06IHRydWUsXG4gICAgICAgIHN0cmluZ0FycmF5Q2FsbHNUcmFuc2Zvcm1UaHJlc2hvbGQ6IDAuNSxcbiAgICAgICAgc3RyaW5nQXJyYXlFbmNvZGluZzogW10sXG4gICAgICAgIHN0cmluZ0FycmF5SW5kZXhTaGlmdDogdHJ1ZSxcbiAgICAgICAgc3RyaW5nQXJyYXlSb3RhdGU6IHRydWUsXG4gICAgICAgIHN0cmluZ0FycmF5U2h1ZmZsZTogdHJ1ZSxcbiAgICAgICAgc3RyaW5nQXJyYXlXcmFwcGVyc0NvdW50OiAxLFxuICAgICAgICBzdHJpbmdBcnJheVdyYXBwZXJzQ2hhaW5lZENhbGxzOiB0cnVlLFxuICAgICAgICBzdHJpbmdBcnJheVdyYXBwZXJzUGFyYW1ldGVyc01heENvdW50OiAyLFxuICAgICAgICBzdHJpbmdBcnJheVdyYXBwZXJzVHlwZTogXCJ2YXJpYWJsZVwiLFxuICAgICAgICBzdHJpbmdBcnJheVRocmVzaG9sZDogMC43NSxcbiAgICAgICAgdW5pY29kZUVzY2FwZVNlcXVlbmNlOiBmYWxzZSxcbiAgICB9LFxufTtcblxuZXhwb3J0IGZ1bmN0aW9uIHdpdGhJbnN0cnVtZW50YXRpb24ocCkge1xuICAgIGxldCBtb2RpZmllZCA9IDA7XG4gICAgcmV0dXJuIHtcbiAgICAgICAgLi4ucCxcbiAgICAgICAgYXN5bmMgdHJhbnNmb3JtKGNvZGUsIGlkKSB7XG4gICAgICAgICAgICBjb25zdCBvdXQgPSBhd2FpdCBwLnRyYW5zZm9ybS5jYWxsKHRoaXMsIGNvZGUsIGlkKTtcbiAgICAgICAgICAgIGlmIChvdXQgJiYgb3V0LmNvZGUgJiYgb3V0LmNvZGUgIT09IGNvZGUpIG1vZGlmaWVkICs9IDE7XG4gICAgICAgICAgICByZXR1cm4gb3V0O1xuICAgICAgICB9LFxuICAgICAgICBidWlsZEVuZCgpIHtcbiAgICAgICAgICAgIHRoaXMuaW5mbyhgW3R5cGVoaW50c10gRmlsZXMgbW9kaWZpZWQ6ICR7bW9kaWZpZWR9YCk7XG4gICAgICAgICAgICBpZiAocC5idWlsZEVuZCkgcmV0dXJuIHAuYnVpbGRFbmQuY2FsbCh0aGlzKTtcbiAgICAgICAgfSxcbiAgICB9O1xufVxuXG5leHBvcnQgZnVuY3Rpb24gY3JlYXRlVHlwZWhpbnRQbHVnaW4odHlwZWhpbnRzUGx1Z2luRmFjdG9yeSkge1xuICAgIHJldHVybiB3aXRoSW5zdHJ1bWVudGF0aW9uKFxuICAgICAgICB0eXBlaGludHNQbHVnaW5GYWN0b3J5KHtcbiAgICAgICAgICAgIHZhcmlhYmxlRG9jdW1lbnRhdGlvbjogdHJ1ZSxcbiAgICAgICAgICAgIG9iamVjdFNoYXBlRG9jdW1lbnRhdGlvbjogdHJ1ZSxcbiAgICAgICAgICAgIG1heE9iamVjdFByb3BlcnRpZXM6IDYsXG4gICAgICAgICAgICBlbmFibGVDb2VyY2lvbnM6IHRydWUsXG4gICAgICAgICAgICBwYXJhbWV0ZXJIb2lzdENvZXJjaW9uczogZmFsc2UsXG4gICAgICAgIH0pLFxuICAgICk7XG59XG5cbmV4cG9ydCBmdW5jdGlvbiBjcmVhdGVFc2J1aWxkQ29uZmlnKGlzRGV2ZWxvcG1lbnQpIHtcbiAgICByZXR1cm4ge1xuICAgICAgICB0YXJnZXQ6IFwiZXMyMDIwXCIsIC8vIE1vZGVybiB0YXJnZXRcbiAgICAgICAga2VlcE5hbWVzOiBmYWxzZSxcbiAgICAgICAgdHJlZVNoYWtpbmc6IGlzRGV2ZWxvcG1lbnQgPyBmYWxzZSA6IHRydWUsIC8vIERpc2FibGUgdHJlZSBzaGFraW5nIGluIGRldmVsb3BtZW50IGZvciBmYXN0ZXIgYnVpbGRzXG4gICAgICAgIGxlZ2FsQ29tbWVudHM6IGlzRGV2ZWxvcG1lbnQgPyBcIm5vbmVcIiA6IFwiaW5saW5lXCIsIC8vIFNraXAgbGVnYWwgY29tbWVudHMgaW4gZGV2ZWxvcG1lbnRcbiAgICB9O1xufVxuXG4vLyBTaGFyZWQgZGV2ZWxvcG1lbnQgaGVhZGVycyBmb3IgVml0ZSBkZXYgc2VydmVycy5cbi8vXG4vLyBUaGVzZSBoZWxwIHdoZW4gdGhlIHJlbmRlcmVyIHVzZXMgQ09FUC9jcmVkZW50aWFsbGVzcyBhbmQgZW1iZWRzIGNvbnRlbnQgZnJvbVxuLy8gb3RoZXIgbG9jYWwgb3JpZ2lucyAoZGlmZmVyZW50IHBvcnQpLCB3aGljaCBjYW4gb3RoZXJ3aXNlIGNhdXNlIENPUlAvQ09FUFxuLy8gYmxvY2tpbmcgaW4gQ2hyb21pdW0vRWxlY3Ryb24uXG5leHBvcnQgZnVuY3Rpb24gZGV2Vml0ZVNlY3VyaXR5SGVhZGVycygpIHtcbiAgICBjb25zdCBoZWFkZXJzID0ge1xuICAgICAgICBcIkNhY2hlLUNvbnRyb2xcIjogXCJuby1zdG9yZSwgbm8tY2FjaGUsIG11c3QtcmV2YWxpZGF0ZSwgbWF4LWFnZT0wXCIsXG4gICAgICAgIC8vIERldi1vbmx5IGNvbnZlbmllbmNlOyBwcm9kdWN0aW9uIGJ1aWxkcyBzaG91bGQgdXNlIHN0cmljdGVyIHBvbGljaWVzLlxuICAgICAgICAvLyBUaGlzIGFsbG93cyB0aGUgVml0ZSByZW5kZXJlciAoaHR0cHM6Ly9sb2NhbGhvc3Q6NTE3MykgdG8gZW1iZWQgdGhlIFJhaWxzXG4gICAgICAgIC8vIFVJIChodHRwczovL2xvY2FsaG9zdDozMDAwKSB3aXRob3V0IENPUlAvQ09FUCBjb25mdXNpb24uXG4gICAgICAgIFwiQ3Jvc3MtT3JpZ2luLVJlc291cmNlLVBvbGljeVwiOiBcImNyb3NzLW9yaWdpblwiLFxuICAgIH07XG5cbiAgICAvLyBDT0VQIG1ha2VzIHRoZSBkb2N1bWVudCBjcm9zcy1vcmlnaW4gaXNvbGF0ZWQgYW5kIGZvcmNlcyBDT1JQL0NPUlMgcnVsZXNcbiAgICAvLyBvbiBlbWJlZGRlZCByZXNvdXJjZXMgKGluY2x1ZGluZyBpZnJhbWVzKS4gVGhpcyBpcyB1c2VmdWwgZm9yIGZlYXR1cmVzXG4gICAgLy8gbGlrZSBTaGFyZWRBcnJheUJ1ZmZlciwgYnV0IGl0IGNhbiBicmVhayB0aGUgRWxlY3Ryb24gZGV2IHNoZWxsIHdoZW4gdGhlXG4gICAgLy8gUmFpbHMgVUkgaXMgZW1iZWRkZWQgZnJvbSBhbm90aGVyIG9yaWdpbi9wb3J0LlxuICAgIC8vXG4gICAgLy8gRW5hYmxlIGV4cGxpY2l0bHkgd2hlbiBuZWVkZWQ6XG4gICAgLy8gICBWSVRFX0VOQUJMRV9DT0VQPTFcbiAgICBpZiAocHJvY2Vzcy5lbnYuVklURV9FTkFCTEVfQ09FUCA9PT0gXCIxXCIpIHtcbiAgICAgICAgaGVhZGVyc1tcIkNyb3NzLU9yaWdpbi1FbWJlZGRlci1Qb2xpY3lcIl0gPSBcImNyZWRlbnRpYWxsZXNzXCI7XG4gICAgfVxuXG4gICAgcmV0dXJuIGhlYWRlcnM7XG59XG5cbmV4cG9ydCBmdW5jdGlvbiBjcmVhdGVUZXJzZXJPcHRpb25zKGlzRGV2ZWxvcG1lbnQpIHtcbiAgICBpZiAoaXNEZXZlbG9wbWVudCkgcmV0dXJuIHVuZGVmaW5lZDtcblxuICAgIHJldHVybiB7XG4gICAgICAgIHBhcnNlOiB7XG4gICAgICAgICAgICBiYXJlX3JldHVybnM6IGZhbHNlLFxuICAgICAgICAgICAgaHRtbDVfY29tbWVudHM6IGZhbHNlLFxuICAgICAgICAgICAgc2hlYmFuZzogZmFsc2UsXG4gICAgICAgICAgICBlY21hOiAyMDIwLCAvLyBNb2Rlcm4gcGFyc2luZ1xuICAgICAgICB9LFxuICAgICAgICBjb21wcmVzczoge1xuICAgICAgICAgICAgZGVmYXVsdHM6IHRydWUsXG4gICAgICAgICAgICBhcnJvd3M6IHRydWUsIC8vIEtlZXAgYXJyb3cgZnVuY3Rpb25zXG4gICAgICAgICAgICBhcmd1bWVudHM6IHRydWUsXG4gICAgICAgICAgICBib29sZWFuczogdHJ1ZSxcbiAgICAgICAgICAgIGJvb2xlYW5zX2FzX2ludGVnZXJzOiBmYWxzZSxcbiAgICAgICAgICAgIGNvbGxhcHNlX3ZhcnM6IHRydWUsXG4gICAgICAgICAgICBjb21wYXJpc29uczogdHJ1ZSxcbiAgICAgICAgICAgIGNvbXB1dGVkX3Byb3BzOiB0cnVlLFxuICAgICAgICAgICAgY29uZGl0aW9uYWxzOiB0cnVlLFxuICAgICAgICAgICAgZGVhZF9jb2RlOiB0cnVlLFxuICAgICAgICAgICAgZGlyZWN0aXZlczogdHJ1ZSxcbiAgICAgICAgICAgIGRyb3BfY29uc29sZTogdHJ1ZSxcbiAgICAgICAgICAgIGRyb3BfZGVidWdnZXI6IHRydWUsXG4gICAgICAgICAgICBlY21hOiAyMDIwLCAvLyBNb2Rlcm4gY29tcHJlc3Npb25cbiAgICAgICAgICAgIGV2YWx1YXRlOiB0cnVlLFxuICAgICAgICAgICAgZXhwcmVzc2lvbjogZmFsc2UsXG4gICAgICAgICAgICBnbG9iYWxfZGVmczoge30sXG4gICAgICAgICAgICBob2lzdF9mdW5zOiB0cnVlLFxuICAgICAgICAgICAgaG9pc3RfcHJvcHM6IHRydWUsXG4gICAgICAgICAgICBob2lzdF92YXJzOiB0cnVlLFxuICAgICAgICAgICAgaWZfcmV0dXJuOiB0cnVlLFxuICAgICAgICAgICAgaW5saW5lOiB0cnVlLFxuICAgICAgICAgICAgam9pbl92YXJzOiB0cnVlLFxuICAgICAgICAgICAga2VlcF9jbGFzc25hbWVzOiBmYWxzZSxcbiAgICAgICAgICAgIGtlZXBfZmFyZ3M6IHRydWUsXG4gICAgICAgICAgICBrZWVwX2ZuYW1lczogZmFsc2UsXG4gICAgICAgICAgICBrZWVwX2luZmluaXR5OiBmYWxzZSxcbiAgICAgICAgICAgIGxvb3BzOiB0cnVlLFxuICAgICAgICAgICAgbmVnYXRlX2lpZmU6IHRydWUsXG4gICAgICAgICAgICBwYXNzZXM6IDEwLFxuICAgICAgICAgICAgcHJvcGVydGllczogdHJ1ZSxcbiAgICAgICAgICAgIHB1cmVfZ2V0dGVyczogXCJzdHJpY3RcIixcbiAgICAgICAgICAgIHB1cmVfZnVuY3M6IFtcbiAgICAgICAgICAgICAgICBcImNvbnNvbGUubG9nXCIsXG4gICAgICAgICAgICAgICAgXCJjb25zb2xlLmluZm9cIixcbiAgICAgICAgICAgICAgICBcImNvbnNvbGUuZGVidWdcIixcbiAgICAgICAgICAgICAgICBcImNvbnNvbGUud2FyblwiLFxuICAgICAgICAgICAgICAgIFwiY29uc29sZS5lcnJvclwiLFxuICAgICAgICAgICAgICAgIFwiY29uc29sZS50cmFjZVwiLFxuICAgICAgICAgICAgICAgIFwiY29uc29sZS5kaXJcIixcbiAgICAgICAgICAgICAgICBcImNvbnNvbGUuZGlyeG1sXCIsXG4gICAgICAgICAgICAgICAgXCJjb25zb2xlLmdyb3VwXCIsXG4gICAgICAgICAgICAgICAgXCJjb25zb2xlLmdyb3VwQ29sbGFwc2VkXCIsXG4gICAgICAgICAgICAgICAgXCJjb25zb2xlLmdyb3VwRW5kXCIsXG4gICAgICAgICAgICAgICAgXCJjb25zb2xlLnRpbWVcIixcbiAgICAgICAgICAgICAgICBcImNvbnNvbGUudGltZUVuZFwiLFxuICAgICAgICAgICAgICAgIFwiY29uc29sZS50aW1lTG9nXCIsXG4gICAgICAgICAgICAgICAgXCJjb25zb2xlLmFzc2VydFwiLFxuICAgICAgICAgICAgICAgIFwiY29uc29sZS5jb3VudFwiLFxuICAgICAgICAgICAgICAgIFwiY29uc29sZS5jb3VudFJlc2V0XCIsXG4gICAgICAgICAgICAgICAgXCJjb25zb2xlLnByb2ZpbGVcIixcbiAgICAgICAgICAgICAgICBcImNvbnNvbGUucHJvZmlsZUVuZFwiLFxuICAgICAgICAgICAgICAgIFwiY29uc29sZS50YWJsZVwiLFxuICAgICAgICAgICAgICAgIFwiY29uc29sZS5jbGVhclwiLFxuICAgICAgICAgICAgXSxcbiAgICAgICAgICAgIHJlZHVjZV92YXJzOiB0cnVlLFxuICAgICAgICAgICAgcmVkdWNlX2Z1bmNzOiB0cnVlLFxuICAgICAgICAgICAgc2VxdWVuY2VzOiB0cnVlLFxuICAgICAgICAgICAgc2lkZV9lZmZlY3RzOiB0cnVlLFxuICAgICAgICAgICAgc3dpdGNoZXM6IHRydWUsXG4gICAgICAgICAgICB0b3BsZXZlbDogdHJ1ZSxcbiAgICAgICAgICAgIHRvcF9yZXRhaW46IG51bGwsXG4gICAgICAgICAgICB0eXBlb2ZzOiB0cnVlLFxuICAgICAgICAgICAgdW5zYWZlOiB0cnVlLFxuICAgICAgICAgICAgdW5zYWZlX2Fycm93czogdHJ1ZSxcbiAgICAgICAgICAgIHVuc2FmZV9jb21wczogdHJ1ZSxcbiAgICAgICAgICAgIHVuc2FmZV9GdW5jdGlvbjogdHJ1ZSxcbiAgICAgICAgICAgIHVuc2FmZV9tYXRoOiB0cnVlLFxuICAgICAgICAgICAgdW5zYWZlX3N5bWJvbHM6IHRydWUsXG4gICAgICAgICAgICB1bnNhZmVfbWV0aG9kczogdHJ1ZSxcbiAgICAgICAgICAgIHVuc2FmZV9wcm90bzogdHJ1ZSxcbiAgICAgICAgICAgIHVuc2FmZV9yZWdleHA6IHRydWUsXG4gICAgICAgICAgICB1bnNhZmVfdW5kZWZpbmVkOiB0cnVlLFxuICAgICAgICAgICAgdW51c2VkOiB0cnVlLFxuICAgICAgICB9LFxuICAgICAgICBtYW5nbGU6IHtcbiAgICAgICAgICAgIGV2YWw6IGZhbHNlLFxuICAgICAgICAgICAga2VlcF9jbGFzc25hbWVzOiBmYWxzZSxcbiAgICAgICAgICAgIGtlZXBfZm5hbWVzOiBmYWxzZSxcbiAgICAgICAgICAgIHJlc2VydmVkOiBbXSxcbiAgICAgICAgICAgIHRvcGxldmVsOiB0cnVlLFxuICAgICAgICAgICAgc2FmYXJpMTA6IGZhbHNlLFxuICAgICAgICB9LFxuICAgICAgICBmb3JtYXQ6IHtcbiAgICAgICAgICAgIGFzY2lpX29ubHk6IGZhbHNlLFxuICAgICAgICAgICAgYmVhdXRpZnk6IGZhbHNlLFxuICAgICAgICAgICAgYnJhY2VzOiBmYWxzZSxcbiAgICAgICAgICAgIGNvbW1lbnRzOiBcInNvbWVcIixcbiAgICAgICAgICAgIGVjbWE6IDIwMjAsXG4gICAgICAgICAgICBpbmRlbnRfbGV2ZWw6IDAsXG4gICAgICAgICAgICBpbmxpbmVfc2NyaXB0OiB0cnVlLFxuICAgICAgICAgICAga2VlcF9udW1iZXJzOiBmYWxzZSxcbiAgICAgICAgICAgIGtlZXBfcXVvdGVkX3Byb3BzOiBmYWxzZSxcbiAgICAgICAgICAgIG1heF9saW5lX2xlbjogMCxcbiAgICAgICAgICAgIHF1b3RlX2tleXM6IGZhbHNlLFxuICAgICAgICAgICAgcHJlc2VydmVfYW5ub3RhdGlvbnM6IGZhbHNlLFxuICAgICAgICAgICAgc2FmYXJpMTA6IGZhbHNlLFxuICAgICAgICAgICAgc2VtaWNvbG9uczogdHJ1ZSxcbiAgICAgICAgICAgIHNoZWJhbmc6IGZhbHNlLFxuICAgICAgICAgICAgd2Via2l0OiBmYWxzZSxcbiAgICAgICAgICAgIHdyYXBfaWlmZTogZmFsc2UsXG4gICAgICAgICAgICB3cmFwX2Z1bmNfYXJnczogZmFsc2UsXG4gICAgICAgIH0sXG4gICAgfTtcbn1cblxuZXhwb3J0IGZ1bmN0aW9uIGNyZWF0ZVJvbGx1cE91dHB1dENvbmZpZygpIHtcbiAgICByZXR1cm4ge1xuICAgICAgICBtaW5pZnlJbnRlcm5hbEV4cG9ydHM6IHRydWUsXG4gICAgICAgIGlubGluZUR5bmFtaWNJbXBvcnRzOiBmYWxzZSxcbiAgICAgICAgY29tcGFjdDogdHJ1ZSxcbiAgICAgICAgZ2VuZXJhdGVkQ29kZToge1xuICAgICAgICAgICAgcHJlc2V0OiBcImVzMjAxNVwiLFxuICAgICAgICAgICAgYXJyb3dGdW5jdGlvbnM6IHRydWUsXG4gICAgICAgICAgICBjb25zdEJpbmRpbmdzOiB0cnVlLFxuICAgICAgICAgICAgb2JqZWN0U2hvcnRoYW5kOiB0cnVlLFxuICAgICAgICB9LFxuICAgIH07XG59XG5cbmV4cG9ydCBmdW5jdGlvbiBjcmVhdGVDb21tb25CdWlsZCh7IGlzRGV2ZWxvcG1lbnQsIHJvbGx1cElucHV0IH0gPSB7fSkge1xuICAgIGNvbnN0IGJ1aWxkID0ge1xuICAgICAgICBjYWNoZTogaXNEZXZlbG9wbWVudCxcbiAgICAgICAgcm9sbHVwT3B0aW9uczoge1xuICAgICAgICAgICAgb3V0cHV0OiBjcmVhdGVSb2xsdXBPdXRwdXRDb25maWcoKSxcbiAgICAgICAgICAgIGV4dGVybmFsOiBbXSxcbiAgICAgICAgICAgIHRyZWVzaGFrZToge1xuICAgICAgICAgICAgICAgIG1vZHVsZVNpZGVFZmZlY3RzOiB0cnVlLFxuICAgICAgICAgICAgICAgIHByb3BlcnR5UmVhZFNpZGVFZmZlY3RzOiBmYWxzZSxcbiAgICAgICAgICAgICAgICB0cnlDYXRjaERlb3B0aW1pemF0aW9uOiBmYWxzZSxcbiAgICAgICAgICAgICAgICB1bmtub3duR2xvYmFsU2lkZUVmZmVjdHM6IGZhbHNlLFxuICAgICAgICAgICAgfSxcbiAgICAgICAgfSxcbiAgICAgICAgdGFyZ2V0OiBbXCJlczIwMjBcIiwgXCJlZGdlODhcIiwgXCJmaXJlZm94NzhcIiwgXCJjaHJvbWU4N1wiLCBcInNhZmFyaTE0XCJdLFxuICAgICAgICBtb2R1bGVQcmVsb2FkOiB7IHBvbHlmaWxsOiB0cnVlIH0sXG4gICAgICAgIGNzc0NvZGVTcGxpdDogdHJ1ZSxcbiAgICAgICAgYXNzZXRzSW5saW5lTGltaXQ6IDUwMDAwMCxcbiAgICAgICAgY3NzVGFyZ2V0OiBbXCJlc25leHRcIl0sXG4gICAgICAgIHNvdXJjZW1hcDogZmFsc2UsXG4gICAgICAgIGNodW5rU2l6ZVdhcm5pbmdMaW1pdDogMjE0NzQ4MzY0NyxcbiAgICAgICAgcmVwb3J0Q29tcHJlc3NlZFNpemU6IGZhbHNlLFxuICAgICAgICBtaW5pZnk6IGlzRGV2ZWxvcG1lbnQgPyBmYWxzZSA6IFwidGVyc2VyXCIsXG4gICAgICAgIHRlcnNlck9wdGlvbnM6IGNyZWF0ZVRlcnNlck9wdGlvbnMoaXNEZXZlbG9wbWVudCksXG4gICAgfTtcblxuICAgIGlmIChyb2xsdXBJbnB1dCkgYnVpbGQucm9sbHVwT3B0aW9ucy5pbnB1dCA9IHJvbGx1cElucHV0O1xuXG4gICAgcmV0dXJuIGJ1aWxkO1xufVxuXG5leHBvcnQgZnVuY3Rpb24gY3JlYXRlT3B0aW1pemVEZXBzRm9yY2UoaXNEZXZlbG9wbWVudCkge1xuICAgIHJldHVybiB7XG4gICAgICAgIGZvcmNlOiBpc0RldmVsb3BtZW50ICYmIHByb2Nlc3MuZW52LlZJVEVfRk9SQ0VfREVQUyA9PT0gXCJ0cnVlXCIsXG4gICAgfTtcbn1cblxuZXhwb3J0IGNvbnN0IGNvbW1vbkRlZmluZSA9IHtcbiAgICBnbG9iYWw6IFwiZ2xvYmFsVGhpc1wiLFxufTtcblxuZXhwb3J0IGNvbnN0IGNvbW1vbkxlZ2FjeU9wdGlvbnMgPSB7XG4gICAgdGFyZ2V0czogW1wiY2hyb21lIDE0MlwiXSxcbiAgICByZW5kZXJMZWdhY3lDaHVua3M6IGZhbHNlLFxuICAgIG1vZGVyblRhcmdldHM6IFtcImNocm9tZSAxNDJcIl0sXG4gICAgbW9kZXJuUG9seWZpbGxzOiB0cnVlLFxufTtcblxuZXhwb3J0IGZ1bmN0aW9uIGNyZWF0ZUJhYmVsT3B0aW9ucyhwYXRoTW9kdWxlKSB7XG4gICAgcmV0dXJuIHtcbiAgICAgICAgZmlsdGVyOiAoaWQpID0+IHtcbiAgICAgICAgICAgIGNvbnN0IGJhc2UgPSBwYXRoTW9kdWxlLmJhc2VuYW1lKGlkIHx8IFwiXCIpLnRvTG93ZXJDYXNlKCk7XG4gICAgICAgICAgICBpZiAoYmFzZSA9PT0gXCJ0ZXh0Y29tcGxldGUubWluLmpzXCIgfHwgYmFzZSA9PT0gXCJvcnQtd2ViLm1pbi5qc1wiKSB7XG4gICAgICAgICAgICAgICAgcmV0dXJuIGZhbHNlO1xuICAgICAgICAgICAgfVxuICAgICAgICAgICAgcmV0dXJuIChcbiAgICAgICAgICAgICAgICAhaWQuaW5jbHVkZXMoXCJAaG90d2lyZWQvc3RpbXVsdXNcIikgJiZcbiAgICAgICAgICAgICAgICAhaWQuaW5jbHVkZXMoXCJAaHVnZ2luZ2ZhY2UvamluamFcIikgJiZcbiAgICAgICAgICAgICAgICAhaWQuaW5jbHVkZXMoXCJvbm54cnVudGltZS13ZWJcIikgJiZcbiAgICAgICAgICAgICAgICAvXFwuKGpzfGNvZmZlZSkkLy50ZXN0KGlkKVxuICAgICAgICAgICAgKTtcbiAgICAgICAgfSxcbiAgICAgICAgYmFiZWxDb25maWc6IHtcbiAgICAgICAgICAgIGlnbm9yZTogWy9ub2RlX21vZHVsZXNbXFxcXC9dbG9jb21vdGl2ZS1zY3JvbGwvXSwgLy8gRXhjbHVkZSBsb2NvbW90aXZlLXNjcm9sbCBmcm9tIGFsbCBCYWJlbCBwcm9jZXNzaW5nIHRvIHByZXNlcnZlIHNwYXJzZSBhcnJheXNcbiAgICAgICAgICAgIGJhYmVscmM6IGZhbHNlLFxuICAgICAgICAgICAgY29uZmlnRmlsZTogZmFsc2UsXG4gICAgICAgICAgICBwbHVnaW5zOiBbXG4gICAgICAgICAgICAgICAgW1wiY2xvc3VyZS1lbGltaW5hdGlvblwiXSxcbiAgICAgICAgICAgICAgICBbXCJtb2R1bGU6ZmFzdGVyLmpzXCJdLFxuICAgICAgICAgICAgICAgIFtcbiAgICAgICAgICAgICAgICAgICAgXCJvYmplY3QtdG8tanNvbi1wYXJzZVwiLFxuICAgICAgICAgICAgICAgICAgICB7XG4gICAgICAgICAgICAgICAgICAgICAgICBtaW5KU09OU3RyaW5nU2l6ZTogMTAyNCxcbiAgICAgICAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgICAgICBdLFxuICAgICAgICAgICAgXSxcbiAgICAgICAgfSxcbiAgICB9O1xufVxuXG5leHBvcnQgZnVuY3Rpb24gY3JlYXRlQ29tbW9uQ3NzKHJlbW92ZVByZWZpeFBsdWdpbkZhY3RvcnkpIHtcbiAgICByZXR1cm4ge1xuICAgICAgICBwcmVwcm9jZXNzb3JPcHRpb25zOiB7XG4gICAgICAgICAgICBzY3NzOiB7XG4gICAgICAgICAgICAgICAgYXBpOiBcIm1vZGVybi1jb21waWxlclwiLFxuICAgICAgICAgICAgICAgIGluY2x1ZGVQYXRoczogW1wibm9kZV9tb2R1bGVzXCIsIFwiLi9ub2RlX21vZHVsZXNcIl0sXG4gICAgICAgICAgICB9LFxuICAgICAgICB9LFxuICAgICAgICBwb3N0Y3NzOiB7XG4gICAgICAgICAgICBwbHVnaW5zOiBbXG4gICAgICAgICAgICAgICAgcmVtb3ZlUHJlZml4UGx1Z2luRmFjdG9yeSgpLFxuICAgICAgICAgICAgICAgIC8vIFRoZSByZXN0IGFyZSBjb25maWd1cmVkIGJ5IGNhbGxlciBiZWNhdXNlIHRoZXkgaW1wb3J0IGRpZmZlcmVudCBtb2R1bGVzLlxuICAgICAgICAgICAgXSxcbiAgICAgICAgfSxcbiAgICB9O1xufVxuIl0sCiAgIm1hcHBpbmdzIjogIjtBQUE0UCxPQUFPO0FBQ25RLFNBQVMsb0JBQW9CO0FBQzdCLE9BQU8sVUFBVTtBQUNqQixPQUFPQSxTQUFRO0FBQ2YsU0FBUyxnQkFBZ0I7QUFDekIsU0FBUyxzQkFBc0I7QUFDL0IsT0FBTyxnQkFBZ0I7QUFDdkIsT0FBTyxnQkFBZ0I7QUFDdkIsT0FBTyxpQkFBaUI7QUFDeEIsT0FBTyxXQUFXO0FBQ2xCLE9BQU8sc0JBQXNCO0FBQzdCLE9BQU8sYUFBYTtBQUNwQixPQUFPLGdCQUFnQjs7O0FDWjZQLE9BQU8sa0JBQWtCO0FBUTlSLFNBQVIsYUFBOEIsY0FBYyxDQUFDLEdBQUc7QUFDbkQsUUFBTSxjQUFjO0FBQUEsSUFDaEIsTUFBTTtBQUFBLElBQ04sV0FBVztBQUFBLEVBQ2Y7QUFFQSxTQUFPO0FBQUEsSUFDSCxNQUFNO0FBQUEsSUFDTixTQUFTO0FBQUEsSUFDVCxVQUFVLE1BQU0sSUFBSTtBQUNoQixVQUFJLENBQUMsR0FBRyxTQUFTLFNBQVMsRUFBRztBQUU3QixZQUFNLFVBQVUsRUFBRSxHQUFHLGFBQWEsR0FBRyxhQUFhLFVBQVUsR0FBRztBQUUvRCxVQUFJO0FBQ0EsY0FBTSxXQUFXLGFBQWEsUUFBUSxNQUFNLE9BQU87QUFDbkQsWUFBSSxPQUFPLGFBQWEsVUFBVTtBQUM5QixpQkFBTyxFQUFFLE1BQU0sVUFBVSxLQUFLLE9BQVU7QUFBQSxRQUM1QztBQUNBLGNBQU0sTUFDRixTQUFTLGVBQWUsU0FBUyxhQUFhO0FBQ2xELGVBQU8sRUFBRSxNQUFNLFNBQVMsSUFBSSxJQUFJO0FBQUEs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QUFBLFlBQ0osUUFBUTtBQUFBLGNBQ0o7QUFBQSxjQUNBO0FBQUEsZ0JBQ0ksY0FBYztBQUFBLGdCQUNkLGlCQUFpQjtBQUFBLGtCQUNiLHVCQUF1QjtBQUFBLGdCQUMzQjtBQUFBLGdCQUNBLGVBQWU7QUFBQSxnQkFDZixjQUFjO0FBQUEsZ0JBQ2QsY0FBYztBQUFBLGdCQUNkLFFBQVE7QUFBQSxjQUNaO0FBQUEsWUFDSjtBQUFBLFVBQ0osQ0FBQztBQUFBLFVBQ0QsYUFBYTtBQUFBLFFBQ2pCO0FBQUEsTUFDSjtBQUFBLElBQ0o7QUFBQSxJQUNBLFFBQVE7QUFBQSxJQUNSLGNBQWM7QUFBQTtBQUFBLE1BRVYsU0FBUztBQUFBLFFBQ0w7QUFBQSxRQUNBO0FBQUEsUUFDQTtBQUFBLFFBQ0E7QUFBQSxRQUNBO0FBQUEsUUFDQTtBQUFBLFFBQ0E7QUFBQSxRQUNBO0FBQUEsUUFDQTtBQUFBLFFBQ0E7QUFBQSxRQUNBO0FBQUEsUUFDQTtBQUFBLFFBQ0E7QUFBQSxRQUNBO0FBQUEsUUFDQTtBQUFBLFFBQ0E7QUFBQSxRQUNBO0FBQUEsUUFDQTtBQUFBLFFBQ0E7QUFBQSxRQUNBO0FBQUEsUUFDQTtBQUFBLFFBQ0E7QUFBQSxRQUNBO0FBQUEsUUFDQTtBQUFBLE1BQ0o7QUFBQSxNQUNBLFNBQVMsQ0FBQyxpQkFBaUI7QUFBQTtBQUFBLE1BRTNCLEdBQUcsd0JBQXdCLGFBQWE7QUFBQSxJQUM1QztBQUFBLElBQ0EsU0FBUztBQUFBLE1BQ0wsYUFBYTtBQUFBLE1BQ2IsY0FBYztBQUFBLE1BQ2QsZUFBZSxLQUFLO0FBQUEsTUFDcEIsYUFBYTtBQUFBLE1BQ2Isa0JBQWtCLFNBQ1osZUFBZSxFQUFFLFNBQVMsa0JBQWtCLENBQUMsSUFDN0M7QUFBQSxNQUNOLE9BQU8sbUJBQW1CO0FBQUEsTUFDMUIsTUFBTSxtQkFBbUIsSUFBSSxDQUFDO0FBQUEsTUFDOUIsV0FBVztBQUFBLE1BQ1gsWUFBWTtBQUFBLE1BQ1osV0FBVztBQUFBLFFBQ1A7QUFBQSxRQUNBO0FBQUEsUUFDQTtBQUFBLE1BQ0osQ0FBQztBQUFBLE1BQ0QsQ0FBQyxnQkFDSywyQkFBMkIsbUJBQW1CLElBQzlDO0FBQUEsTUFDTixDQUFDLGdCQUFnQixpQkFBaUI7QUFBQSxJQUN0QztBQUFBLEVBQ0o7QUFDSixDQUFDOyIsCiAgIm5hbWVzIjogWyJmcyIsICJwYXRoIiwgImFkZEJsb2NrRG9jdW1lbnQiLCAiaW5mZXJPYmplY3RTaGFwZSIsICJmaW5kVFNOb2RlQXRQb3NpdGlvbiIsICJzb3VyY2VGaWxlIiwgImZzIl0KfQo=
