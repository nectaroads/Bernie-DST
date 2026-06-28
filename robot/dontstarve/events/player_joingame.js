const { getClientChannel } = require('../../discord');
const { rollDice } = require('../../tools');
const { dotenv, dontstarveserver } = require('../../variables');

module.exports = async (req, res) => {
  const body = req.body;
  const channel = await getClientChannel(dotenv.GUILDID, dotenv.CHATROOM);
  if (!channel) return res.status(200).json({ ok: true });
  const players = Object.values(body.players);
  if (!players) return res.status(200).json({ ok: true });
  const firstLine = players.length > 1 ? `**0${players.length - 1}** sobrevivente(s) comemoram!` : `Porém **ninguém escutou**...`;
  channel.send({ embeds: [{ color: 0x43724f, description: `*\`🏡\` · Boas-vindas à **${body.name.slice(0, 12)}**! Há espaço para **${body.emptyspace}** pessoa(s).*` }] }).catch(error => {
    print(`[Error] Application error: ${error}`);
  });
  channel.setTopic(`O servidor tem ${body.onlineplayers}/${body.maxplayers} players online - Sobreviva para contar histórias aos que lutarem depois de você!`).catch(error => {
    print(`[Error] Application error: ${error}`);
  });
  dontstarveserver.playersonline = players.length;
  dontstarveserver.maxplayers = body.maxplayers;
  return res.status(200).json({ ok: true });
};
