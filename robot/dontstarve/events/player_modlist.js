const { getClientChannel } = require('../../discord');
const { dotenv } = require('../../variables');
const whitelist = require('../../whitelist.json');

const MAX_LENGTH = 1900;

module.exports = async (req, res) => {
  const body = req.body;
  const channel = await getClientChannel(dotenv.GUILDID, dotenv.MODROOM);

  if (!channel) return res.status(200).json({ ok: true });

  const victim = body.victim || 'Unknown';
  const mods = Array.isArray(body.modlist) ? body.modlist : [];

  const lines = mods
    .map(mod => String(mod).replace('workshop-', ''))
    .filter(id => !whitelist.anticheat[id])
    .map(id => `> Sharedfile: [steamcommunity](https://steamcommunity.com/sharedfiles/filedetails/?id=${id})`);

  if (lines.length <= 0) return res.status(200).json({ ok: true });

  let current = '';
  let part = 1;
  const messages = [];

  for (const line of lines) {
    if ((current + line + '\n').length > MAX_LENGTH) {
      messages.push(current);
      current = '';
    }
    current += line + '\n';
  }

  if (current.length > 0) messages.push(current);

  for (let i = 0; i < messages.length; i++) {
    await channel.send(`***Modlist Context ${i + 1}: ${victim}***\n${messages[i]}`);
  }

  return res.status(200).json({ ok: true });
};
