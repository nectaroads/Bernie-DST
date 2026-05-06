const { startDiscordClient } = require("./discord");
const { startExpress } = require("./express");
const { print } = require("./tools");

async function main() {
    console.clear();
    print(`[Setup] Main module: Starting core systems: Please, wait...`);
    await startDiscordClient();
    await startExpress("24574");
}

main();