const { getClientChannel } = require('../../discord');
const { rollDice } = require('../../tools');
const { dotenv } = require('../../variables');

module.exports = async (req, res) => {
  const body = req.body;
  const channel = await getClientChannel(dotenv.GUILDID, dotenv.CHATROOM);
  if (!channel) return res.status(200).json({ ok: true });
  channel.send({ embeds: [{ color: 0x7a5dba, title: `\`🔮\` · ${body.victim.slice(0, 12)} renasceu!`, description: `- **${body.cause}** o trouxe de volta.\n- Será que **Charlie** ajudou?\n- Nossa sanidade **restaura**!`, thumbnail: { url: 'https://media.discordapp.net/attachments/1270552171041263658/1343494940440793139/image.png?ex=67bd7aaa&is=67bc292a&hm=e60319eae6482423211b85ccaf6dc05a5ed4c96d28c636cb6afb33cd798d2dd7&=&format=webp&quality=lossless' } }] }).catch(error => {
    print(`[Error] Application error: ${error}`);
  });
  return res.status(200).json({ ok: true });
};
