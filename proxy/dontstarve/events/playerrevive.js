const { getClientChannel } = require("../../discord");
const { rollDice } = require("../../tools");
const { dotenv } = require("../../variables");

module.exports = async (req, res) => {
    const body = req.body;
    const channel = await getClientChannel(dotenv.GUILDID, dotenv.CHATROOM);
    if (!channel) return res.status(200).json({ ok: true });
    let target = "Charlie";
    let players = Object.values(body.players) || null;
    let playersLength = players.length || 0;
    if (playersLength > 0) {
        players = players.filter(player => player.userid !== body.userid);
        if (players.length > 1) {
            const dice = rollDice(0, players.length - 1)
            target = players[dice]?.name || "Charlie";
        }
    }
    channel.send({ embeds: [{ color: 0x7A5DBA, title: `\`🔮\` · ${body.name.slice(0, 12)} renasceu!`, description: `- **Algo** o trouxe de volta.\n- Será que **${target}** ajudou?\n- Nossa sanidade **restaura**!`, thumbnail: { url: "https://media.discordapp.net/attachments/1270552171041263658/1343494940440793139/image.png?ex=67bd7aaa&is=67bc292a&hm=e60319eae6482423211b85ccaf6dc05a5ed4c96d28c636cb6afb33cd798d2dd7&=&format=webp&quality=lossless" } }] }).catch((error) => { print(`[Error] Application error: ${error}`); });
    return res.status(200).json({ ok: true });
}