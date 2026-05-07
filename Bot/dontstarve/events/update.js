const { messagesbuffer } = require("../../variables");

module.exports = async (req, res) => {
    const body = req.body;
    let data = [];
    if(messagesbuffer.length > 0) {
        data = [...messagesbuffer].reverse();
        messagesbuffer.length = 0;
    }
    return res.json(data);
}