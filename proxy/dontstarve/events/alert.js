const { getClientChannel, buildEmbed } = require("../../discord");
const { dotenv } = require("../../variables");

let lastMessage = '';

module.exports = async (req, res) => {
    const body = req.body;
    const channel = await getClientChannel(dotenv.GUILDID, dotenv.CHATROOM);
    if (!channel) return res.status(200).json({ ok: true });
    const map = { eat: { color: 0x9266CC, message: `\`🍇\` **· ${body.value.doer} \`${body.value.userid}\` está comendo ${body.value.victim}!**` }, burn: { color: 0xFF6723, message: `\`🔥\` · **${body.value.doer} \`${body.value.userid}\` está queimando ${body.value.victim}!**` }, break: { color: 0x989EA2, message: `\`🦏\` · **${body.value.doer} \`${body.value.userid}\` está quebrando ${body.value.victim}!**` } };
    if (lastMessage == map[body.value.key].message) return res.status(200).json({ ok: true });
    channel.send({ embeds: [buildEmbed({ color: map[body.value.key].color || 0x4CB963, description: map[body.value.key].message })] }).catch((error) => { print(`[Error] Application error: ${error}`); });
    lastMessage = map[body.value.key].message;
    return res.status(200).json({ ok: true });
}