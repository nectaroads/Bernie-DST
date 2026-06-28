const { getClientChannel } = require('../../discord');
const { rollDice } = require('../../tools');
const { dotenv, dontstarveserver } = require('../../variables');

module.exports = async (req, res) => {
  const body = req.body;
  const channel = await getClientChannel(dotenv.GUILDID, dotenv.CHATROOM);
  if (!channel) return res.status(200).json({ ok: true });
  const players = Object.values(body.players);
  if (!players) return;
  const firstLine = body.emptyspace > 1 ? `Há **0${body.emptyspace}** sobrevivente(s) em luto.` : `**Não restam** sobreviventes...`;
  channel.send({ embeds: [{ color: 0x875555, description: `-# \`🏚️\` · **${body.name.slice(0, 12)}** foi embora. Há espaço para **${body.maxplayers - 1 == body.emptyspace ? body.maxplayers : body.emptyspace}** pessoa(s).` }] }).catch(error => {
    print(`[Error] Application error: ${error}`);
  });
  channel.setTopic(`O servidor tem ${body.onlineplayers - 1}/${body.maxplayers} players online - Sobreviva para contar histórias aos que lutarem depois de você!`).catch(error => {
    print(`[Error] Application error: ${error}`);
  });
  dontstarveserver.playersonline = players.length - 1;
  dontstarveserver.maxplayers = body.maxplayers;
  return res.status(200).json({ ok: true });
};
