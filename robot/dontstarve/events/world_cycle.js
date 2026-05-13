const { dotenv } = require('../../variables');
const dictionary = require('../../dictionary.json');
const { getClientChannel } = require('../../discord');

module.exports = async (req, res) => {
  const body = req.body;
  const channel = await getClientChannel(dotenv.GUILDID, dotenv.CHATROOM);
  if (!channel) return res.status(200).json({ ok: true });
  if (!body.states) return res.status(200).json({ ok: true });
  const season = body.states.season;
  function validateMoon(state) {
    if (state.isnewmoon == 'newmoon') return 'Nova';
    else if (state.isfullmoon == 'fullmoon') return 'Cheia';
    else return 'Crescente';
  }
  let moonphase = validateMoon(body.states);
  const day = body.states.cycles + 1;
  channel.send({ content: day == 1 ? '-# **Hey, <@&1274449098535079976>!**' : '', embeds: [{ color: 0x307681, title: `\`🌅\` · Amanhece um novo dia...`, description: `- A Constante perdura por **${day}** dias.\n- O **Alter** está na forma **${moonphase}**.\n- São brisas cortantes de **${dictionary[season] ? dictionary[season] : season}**!`, thumbnail: { url: 'https://media.discordapp.net/attachments/1270552171041263658/1338933111026614302/image.png?ex=67ace221&is=67ab90a1&hm=95d8390c733d5e948d851a6b322ba09dd319871e145d58414f37f93032fe7135&=&format=webp&quality=lossless' } }] }).catch(error => {});
  return res.status(200).json({ ok: true });
};
