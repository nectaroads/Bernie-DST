const { getClientChannel } = require('../../discord');
const { rollDice } = require('../../tools');
const { dotenv } = require('../../variables');

module.exports = async (req, res) => {
  const body = req.body;
  const channel = await getClientChannel(dotenv.GUILDID, dotenv.CHATROOM);
  if (!channel) return res.status(200).json({ ok: true });
  const players = Object.values(body.players);
  if (!players) return;
  const firstLine = body.emptyspace > 1 ? `Há **0${body.emptyspace}** sobrevivente(s) em luto.` : `**Não restam** sobreviventes...`;
  channel.send({ embeds: [{ color: 0x875555, title: `\`🏚️\` · ${body.name.slice(0, 12)} foi embora.`, description: `- ${firstLine}\n- **Charlie** soa levemente confusa.\n- Há espaço para **0${body.maxplayers - 1 == body.emptyspace ? body.maxplayers : body.emptyspace}** pessoa(s).`, thumbnail: { url: 'https://media.discordapp.net/attachments/1270552171041263658/1343496222417096784/image.png?ex=67bd7bdc&is=67bc2a5c&hm=47b44c87be7424bf2b1138e3b1eb113659fc4b256cbaa27b172e16eb645c8f21&=&format=webp&quality=lossless' } }] }).catch(error => {
    print(`[Error] Application error: ${error}`);
  });
  channel.setTopic(`O servidor tem ${body.emptyspace - 1}/${body.maxplayers} players online - Sobreviva para contar histórias aos que lutarem depois de você!`).catch(error => {
    print(`[Error] Application error: ${error}`);
  });
  return res.status(200).json({ ok: true });
};
