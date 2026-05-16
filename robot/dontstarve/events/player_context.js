const { getClientChannel } = require('../../discord');
const { dotenv } = require('../../variables');

module.exports = async (req, res) => {
  const body = req.body;
  const channel = await getClientChannel(dotenv.GUILDID, dotenv.MODROOM);
  if (!channel) return res.status(200).json({ ok: true });
  const victim = body.victim || 'Unknown';
  const mods = Array.isArray(body.context) ? body.context : [];
  const links = mods
    .map((mod, index) => {
      const id = String(mod).replace('workshop-', '');
      return `> Link: [workshop-mod](https://steamcommunity.com/sharedfiles/filedetails/?id=${id})`;
    })
    .join('\n');
  if (links.length > 0) {
    await channel.send(`***Mod Context: ${victim}***\n${links}`);
  }
  return res.status(200).json({ ok: true });
};
