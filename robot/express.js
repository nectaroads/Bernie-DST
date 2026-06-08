const express = require('express');
const bodyParser = require('body-parser');
const path = require('path');
const fs = require('fs');
const { formatValue, print } = require('./tools');

const app = express();
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

const dontstarveHandlers = {};
const dontstarveHandlersDir = path.join(__dirname, './dontstarve/events');

fs.readdirSync(dontstarveHandlersDir).forEach(file => {
  if (file.endsWith('.js')) {
    const key = path.basename(file, '.js');
    dontstarveHandlers[key] = require(path.join(dontstarveHandlersDir, file));
  }
});

app.post('/bernie', (req, res) => {
  if (!req.body) return res.status(200).json({ ok: true });
  const bodyStr = Object.entries(req.body)
    .map(([k, v]) => `${k}: ${formatValue(v)}`)
    .join(', ');
  if (req.body.key != 'update' && req.body.key != 'server_tps') print(`[Request] Express: Web request`);
  if (req.body.key != 'update' && req.body.key != 'server_tps') print(`[Log] Body: ${req.body.key}: ${bodyStr}`);
  if (dontstarveHandlers[req.body.key]) return dontstarveHandlers[req.body.key](req, res);
  return res.status(200).json({ ok: true });
});

async function startExpress(PORT) {
  return new Promise((resolve, reject) => {
    app.listen(PORT, '0.0.0.0', error => {
      if (error) return reject(new Error(error));
      print(`[Setup] Express: Listening to: ${PORT}`);
      resolve();
    });
  }).catch(error => {
    print(`[Error] Express: Failed to start:${error}`);
  });
}

module.exports = { startExpress };
