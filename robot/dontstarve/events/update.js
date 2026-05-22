const { r, messagebuffer } = require('../../variables');

module.exports = async (req, res) => {
  let data = [];
  const now = Date.now();
  if (now - messagebuffer.lastcall > 3000) messagebuffer.buffer.length = 0;
  if (messagebuffer.buffer.length > 0) {
    data = [...messagebuffer.buffer].reverse();
    messagebuffer.buffer.splice(0, data.length);
  }
  messagebuffer.lastcall = now;
  return res.json(data);
};
