const { messagesbuffer } = require('../../variables');

module.exports = async (req, res) => {
  let data = [];
  if (messagesbuffer.length > 0) {
    data = [...messagesbuffer].reverse();
    messagesbuffer.splice(0, data.length);
  }
  return res.json(data);
};
