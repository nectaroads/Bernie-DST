const { getClientChannel, buildEmbed } = require('../../discord');
const { dotenv } = require('../../variables');

module.exports = async (req, res) => {
  const body = req.body;
  const channel = await getClientChannel(dotenv.GUILDID, dotenv.CHATROOM);
  if (!channel) return res.status(200).json({ ok: true });
  console.log(body.event.messagestart);
  channel.send({ embeds: [buildEmbed({ color: 0xEDBD34, description: `*\`🌠\` · ${body.event.messagestart.message}*` })] }).catch(error => {
    print(`[Error] Application error: ${error}`);
  });
  return res.status(200).json({ ok: true });
};
