const fs = require('fs');
const path = require('path');

const commandHandlers = {};
const commandHandlersDir = path.join(__dirname, '../commands');

fs.readdirSync(commandHandlersDir).forEach(file => {
    if (file.endsWith('.js')) {
        const key = path.basename(file, '.js');
        commandHandlers[key] = require(path.join(commandHandlersDir, file));
    }
});

module.exports = async (req, res) => {
    const body = req.body;
    const handler = commandHandlers[body.value.command];
    if (handler) handler(body, res, server);
    return res.status(200).json({ ok: true });
};