const { getClientChannel } = require('../../discord');
const { dotenv } = require('../../variables');

module.exports = async (req, res) => {
  const body = req.body;
  const channel = await getClientChannel(dotenv.GUILDID, dotenv.MODROOM);
  if (!channel) return res.status(200).json({ ok: true });
  await channel.send(`***Test player cheating: ${body.victim} ${body.userid}*** @everyone`);
  return res.status(200).json({ ok: true });
};
