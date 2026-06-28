const { getClientChannel, buildEmbed } = require('../../discord');
const { dotenv } = require('../../variables');

let lastMessage = '';

module.exports = async (req, res) => {
  const body = req.body;
  const channel = await getClientChannel(dotenv.GUILDID, dotenv.CHATROOM);
  if (!channel) return res.status(200).json({ ok: true });
  const map = { eat: { color: 0x9266cc, message: `*\`🍇\` · **${body.doer}** \`${body.userid}\` está comendo **${body.victim}**!*` }, player_burn: { color: 0xff6723, message: `\`🔥\` · **${body.doer} \`${body.userid}\` está queimando ${body.victim}!**` }, player_break: { color: 0x989ea2, message: `\`🦏\` · **${body.cause} \`${body.userid}\` está quebrando ${body.victim}!**` } };
  if (lastMessage == map[body.key].message) return res.status(200).json({ ok: true });
  channel.send({ embeds: [buildEmbed({ color: map[body.key].color || 0x4cb963, description: map[body.key].message })] }).catch(error => {
    print(`[Error] Application error: ${error}`);
  });
  lastMessage = map[body.key].message;
  return res.status(200).json({ ok: true });
};
