export default {
    testEnvironment: "jsdom",
    moduleDirectories: ["node_modules", "<rootDir>"],
    modulePathIgnorePatterns: ["<rootDir>/.codeql/"],
    transform: {
        "^.+\\.js$": "babel-jest",
    },
    moduleNameMapper: {
        "^@hotwired/(.*)$": "<rootDir>/node_modules/@hotwired/$1",
        "^~/(.*)$": "<rootDir>/app/javascript/$1",
        "^../utils/xmlrpc$":
            "<rootDir>/test/javascript/utils/__mocks__/xmlrpc.js",
    },
    setupFilesAfterEnv: ["<rootDir>/test/javascript/setup.js"],
    testMatch: ["<rootDir>/test/javascript/**/*.test.js"],
    moduleFileExtensions: ["js", "json"],
    collectCoverage: true,
    collectCoverageFrom: [
        "app/javascript/**/*.js",
        "!app/javascript/**/*.spec.js",
        "!app/javascript/channels/**/*.js",
        "!node_modules/**",
        "!.codeql/**",
    ],
    coverageReporters: ["text", "html"],
    coverageDirectory: "coverage",
    testEnvironmentOptions: {
        customExportConditions: ["node", "node-addons"],
    },
};
