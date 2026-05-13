const { getClientChannel } = require('../../discord');
const { dotenv } = require('../../variables');

module.exports = async (req, res) => {
  const body = req.body;
  const channel = await getClientChannel(dotenv.GUILDID, dotenv.CHATROOM);
  if (!channel) return res.status(200).json({ ok: true });
  channel.send({ embeds: [{ color: 0xc84937, title: `\`🏟️\` · ${body.victim} caiu!`, description: `- Que perigo! Isso foi **intenso**!\n- Foi **${body.cause || 'Charlie'}** quem o derrubou.\n- Outro(s) **00** estão presentes.`, thumbnail: { url: 'https://media.discordapp.net/attachments/1270552171041263658/1343495140702027776/image.png?ex=67bd7ada&is=67bc295a&hm=5ce03cab9ab65c4b76ebf9126377720f73b5dfebdbd1a5da5f42ea9bce05a456&=&format=webp&quality=lossless' } }] }).catch(error => {});
  return res.status(200).json({ ok: true });
};
