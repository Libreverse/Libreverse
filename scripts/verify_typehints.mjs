#!/usr/bin/env bun
/* global process */
/**
 * Verify that the typehints plugin actually injected annotations into the built output.
 * Strategy:
 *  1. Ensure a build has run (or instruct user if no files in public/ match expected patterns).
 *  2. Scan built JS assets for preserved bang-star comments (the ones starting with /*! used to retain during minification) containing @param/@returns/@type.
 *  3. Produce JSON summary + non-zero exit if below thresholds (configurable via env vars):
 *      MIN_FUNCTION_HINTS   (default 1)
 *      MIN_VARIABLE_HINTS   (default 0)
 *  4. Output machine-friendly JSON so CI can parse.
 */

import { readdirSync, readFileSync, statSync } from "node:fs";
import path from "node:path";

const distributionDirectory = process.env.TYPEHINTS_BUILD_DIR || "public";
const minFunctionHints = Number(process.env.MIN_FUNCTION_HINTS || "1");
const minVariableHints = Number(process.env.MIN_VARIABLE_HINTS || "0");
const verbose = process.env.VERBOSE === "1";

function gatherFiles(directory) {
    const out = [];
    for (const entry of readdirSync(directory)) {
        const full = path.join(directory, entry);
        const st = statSync(full);
        if (st.isDirectory()) out.push(...gatherFiles(full));
        else if (
            st.isFile() &&
            [".js", ".mjs", ".cjs"].includes(path.extname(entry))
        )
            out.push(full);
    }
    return out;
}

function analyzeFile(path) {
    const source = readFileSync(path, "utf8");
    // Capture /*! ... */ comments quickly (non-greedy across newlines)
    const blockMatches = source.match(/\/\*!([\s\S]*?)\*\//g) || [];
    let functionHints = 0;
    let variableHints = 0;
    for (const block of blockMatches) {
        const hasReturns = /@returns\s+{/.test(block);
        const hasParameter = /@param\s+{/.test(block);
        const hasType = /@type\s+{/.test(block);
        if (hasReturns || hasParameter) functionHints += 1; // treat each block with fn metadata as one function
        if (hasType && !hasReturns && !hasParameter) variableHints += 1; // pure @type blocks from variable decls
    }
    return { functionHints, variableHints, totalBlocks: blockMatches.length };
}

function main() {
    let files;
    try {
        files = gatherFiles(distributionDirectory);
    } catch {
        console.error(
            JSON.stringify({
                ok: false,
                error: `Output directory '${distributionDirectory}' not found. Run the build first.`,
            }),
        );
        process.exit(2);
    }
    if (files.length === 0) {
        console.error(
            JSON.stringify({
                ok: false,
                error: "No JS assets found to inspect.",
            }),
        );
        process.exit(2);
    }
    let sumFunction = 0;
    let sumVariable = 0;
    const perFile = [];
    for (const f of files) {
        const r = analyzeFile(f);
        if (r.functionHints || r.variableHints) perFile.push({ file: f, ...r });
        sumFunction += r.functionHints;
        sumVariable += r.variableHints;
    }
    const summary = {
        ok: sumFunction >= minFunctionHints && sumVariable >= minVariableHints,
        distDir: distributionDirectory,
        functionHints: sumFunction,
        variableHints: sumVariable,
        minFunctionHints,
        minVariableHints,
        filesWithHints: perFile.length,
        timestamp: new Date().toISOString(),
    };
    if (!summary.ok) {
        summary.error = `Thresholds not met (have fn=${sumFunction}, var=${sumVariable}; expected fn>=${minFunctionHints}, var>=${minVariableHints})`;
        console.error(JSON.stringify(summary, undefined, 2));
        process.exit(1);
    }
    if (verbose) summary.details = perFile;
    console.log(JSON.stringify(summary, undefined, 2));
}

main();
