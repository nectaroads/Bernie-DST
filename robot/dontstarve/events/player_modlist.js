const { getClientChannel } = require('../../discord');
const { dotenv } = require('../../variables');
const whitelist = require('../../whitelist.json');

module.exports = async (req, res) => {
  const body = req.body;
  const channel = await getClientChannel(dotenv.GUILDID, dotenv.MODROOM);
  if (!channel) return res.status(200).json({ ok: true });
  const victim = body.victim || 'Unknown';
  const mods = Array.isArray(body.modlist) ? body.modlist : [];
  let added = 0;
  const links = mods
    .map(mod => String(mod).replace('workshop-', ''))
    .filter(id => !whitelist.anticheat[id])
    .map(id => `> Sharedfile: [steamcommunity](https://steamcommunity.com/sharedfiles/filedetails/?id=${id})`)
    .join('\n');
  if (links.length > 0) {
    await channel.send(`***Modlist Context: ${victim}***\n${links}`);
  }
  return res.status(200).json({ ok: true });
};
