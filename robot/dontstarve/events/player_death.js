const dictionary = require('../../dictionary.json');
const { getClientChannel } = require('../../discord');
const { rollDice } = require('../../tools');
const { dotenv } = require('../../variables');

module.exports = async (req, res) => {
  const channel = await getClientChannel(dotenv.GUILDID, dotenv.CHATROOM);
  if (!channel) return res.status(200).json({ ok: true });
  const body = req.body;
  const desc = `- Queda causada por **${body.cause}**\n- Será que **Charlie** vai ajudar?\n- Assombrações te **corroem**.`;
  const title = `\`👻\` · ${body.victim.slice(0, 12)} faleceu!`;
  channel.send({ embeds: [{ color: 0x8c8c8c, title: title, description: desc, thumbnail: { url: 'https://media.discordapp.net/attachments/1270552171041263658/1343494255632580628/image.png?ex=67bd7a07&is=67bc2887&hm=b2d9146a8000778e700214957e225db667886bf11142c1d5b5e4c918b1d512b5&=&format=webp&quality=lossless' } }] }).catch(error => {
    print(`[Error] Application error: ${error}`);
  });
  return res.status(200).json({ ok: true });
};
