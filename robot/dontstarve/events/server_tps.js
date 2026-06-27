const { getClientChannel, buildEmbed } = require('../../discord');
const { dotenv, dontstarveserver } = require('../../variables');

module.exports = async (req, res) => {
  const body = req.body;
  const channel = await getClientChannel(dotenv.GUILDID, dotenv.CHATROOM);
  if (!channel) return res.status(200).json({ ok: true });
  dontstarveserver.tps = body.tps;
  dontstarveserver.playersonline = body.onlineplayers;
  dontstarveserver.maxplayers = body.maxplayers;
  if (body.tps < 25) {
    const roleId = '1265501710256705607';
    channel.send({ embeds: [buildEmbed({ color: 0xffb256, description: `**\`⚠️\` · O servidor está com má performance! \`TPS\`**` })], allowedMentions: { roles: [roleId] } }).catch(error => {
      print(`[Error] Application error: ${error}`);
    });
  }
  return res.status(200).json({ ok: true });
};
