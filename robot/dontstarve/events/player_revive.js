const { getClientChannel } = require('../../discord');
const { rollDice } = require('../../tools');
const { dotenv } = require('../../variables');

module.exports = async (req, res) => {
  const body = req.body;
  const channel = await getClientChannel(dotenv.GUILDID, dotenv.CHATROOM);
  if (!channel) return res.status(200).json({ ok: true });
  channel.send({ embeds: [{ color: 0x7a5dba, description: `-# \`🔮\` · **${body.victim.slice(0, 12)}** renasceu! **${body.cause}** o trouxe de volta.` }] }).catch(error => {
    print(`[Error] Application error: ${error}`);
  });
  return res.status(200).json({ ok: true });
};
