const { getClientChannel, buildEmbed } = require("../../discord");
const dictionary = require('../../dictionary.json');
const { dotenv } = require("../../variables");

module.exports = async (req, res) => {
    const body = req.body;
    const channel = await getClientChannel(dotenv.GUILDID, dotenv.CHATROOM);
    if (!channel) return res.status(200).json({ ok: true });
    if (body.whisper === true) return res.status(200).json({ ok: true });
    if (body.cave === true) return res.status(200).json({ ok: true });
    const MAX_DISCORD_MESSAGE_LENGTH = 300;
    const msg = body.message.length > MAX_DISCORD_MESSAGE_LENGTH ? body.message.substring(0, MAX_DISCORD_MESSAGE_LENGTH - 3) + "(...)" : body.message;
    channel.send({ embeds: [buildEmbed({ description: `\`✉️\` **· ${body.username} \`${body.prefab == '' ? "Seleção" : dictionary[body.prefab] || body.prefab}\`** *▸* ${msg}`, color: 0x37373E })] }).catch((error) => { print(`[Error] Application error: ${error}`); });
    return res.status(200).json({ ok: true });
}