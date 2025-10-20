const { env } = require("shakapacker");
const { existsSync } = require("node:fs");
const path = require("node:path");

const environmentSpecificConfig = () => {
    const extension = ".cjs";
    const configPath = path.resolve(__dirname, `${env.nodeEnv}${extension}`);
    if (!existsSync(configPath)) {
        throw new Error(
            `Could not find file to load ${configPath}, based on NODE_ENV`,
        );
    }
    console.log(
        `Loading ENV specific webpack configuration file ${configPath}`,
    );
    return require(configPath);
};

module.exports = environmentSpecificConfig();
