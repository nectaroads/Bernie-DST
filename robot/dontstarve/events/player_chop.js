const { getClientChannel, buildEmbed } = require('../../discord');
const { dotenv } = require('../../variables');

module.exports = async (req, res) => {
  const body = req.body;
  const channel = await getClientChannel(dotenv.GUILDID, dotenv.CHATROOM);
  if (!channel) return res.status(200).json({ ok: true });
  channel.send({ embeds: [buildEmbed({ color: 0x895B56, description: `*\`🪵\` · **${body.cause}** \`${body.userid}\` está derrubando **${body.victim}**!*` })] }).catch(error => {
    print(`[Error] Application error: ${error}`);
  });
  return res.status(200).json({ ok: true });
};
