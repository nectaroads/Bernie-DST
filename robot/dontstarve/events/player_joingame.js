const { getClientChannel } = require('../../discord');
const { rollDice } = require('../../tools');
const { dotenv } = require('../../variables');

module.exports = async (req, res) => {
  const body = req.body;
  const channel = await getClientChannel(dotenv.GUILDID, dotenv.CHATROOM);
  if (!channel) return res.status(200).json({ ok: true });
  const players = Object.values(body.players);
  if (!players) return res.status(200).json({ ok: true });
  const firstLine = players.length > 1 ? `**0${players.length - 1}** sobrevivente(s) comemoram!` : `Porém **ninguém escutou**...`;
  channel.send({ embeds: [{ color: 0x43724f, title: `\`🏡\` · Boas-vindas à ${body.name.slice(0, 12)}!`, description: `- ${firstLine}\n- **Charlie** pensa em queimar tudo.\n- Há espaço para **0${body.emptyspace}** pessoa(s).`, thumbnail: { url: 'https://cdn.discordapp.com/attachments/1270552171041263658/1338945608823738489/image.png?ex=67acedc5&is=67ab9c45&hm=490420dd396c22667f09dc10e483ee3f8dbc0e30b8bc82d123e41697b8edd46d&' } }] }).catch(error => {
    print(`[Error] Application error: ${error}`);
  });
  channel.setTopic(`O servidor tem ${players.length}/${body.maxplayers} players online - Sobreviva para contar histórias aos que lutarem depois de você!`).catch(error => {
    print(`[Error] Application error: ${error}`);
  });
  return res.status(200).json({ ok: true });
};
