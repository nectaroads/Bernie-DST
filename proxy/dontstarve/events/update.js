const { messagesbuffer } = require("../../variables");
const { dotenv } = require("../../variables");

module.exports = async (req, res) => {
    const body = req.body;
    const data = [...messagesbuffer].reverse();
    messagesbuffer.length = 0;
    return res.json(data);
}