require('dotenv').config();
const dotenv = process.env;

const messagebuffer = {
  lastcall: 0,
  buffer: []
};

module.exports = { dotenv, messagebuffer };
