require('dotenv').config();
const dotenv = process.env;

let dontstarveserver = {
  playersonline: 0,
  maxplayers: 0,
  ping: 0,
  tps: 0
};

let messagebuffer = {
  lastcall: 0,
  buffer: []
};

module.exports = { dotenv, messagebuffer, dontstarveserver };
