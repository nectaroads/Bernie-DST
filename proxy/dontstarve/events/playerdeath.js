const dictionary = require('../../dictionary.json');
const { getClientChannel } = require('../../discord');
const { rollDice } = require('../../tools');
const { dotenv } = require("../../variables");

module.exports = async (req, res) => {
    const channel = await getClientChannel(dotenv.GUILDID, dotenv.CHATROOM);
    if (!channel) return res.status(200).json({ ok: true });
    const body = req.body;
    if (!body.userid) return res.status(200).json({ ok: true });
    let target = "Charlie";
    let players = Object.values(body.players) || null;
    let playersLength = players.length || 0;
    if (playersLength > 0) {
        players = players.filter(player => player.userid !== body.userid);
        if (players.length > 1) {
            const dice = rollDice(0, players.length - 1)
            target = players[dice].name || "Charlie";
        }
    } else return res.status(200).json({ ok: true });
    const doerName = dictionary[body.doer] || body.doer || "Desconhecido";
    const desc = `- Queda causada por **${doerName}**\n- Será que **${target}** vai ajudar?\n- Assombrações te **corroem**.`;
    const title = `\`👻\` · ${body.victim.slice(0, 12)} está morto(a)!`;
    channel.send({ embeds: [{ color: 0x8C8C8C, title: title, description: desc, thumbnail: { url: "https://media.discordapp.net/attachments/1270552171041263658/1343494255632580628/image.png?ex=67bd7a07&is=67bc2887&hm=b2d9146a8000778e700214957e225db667886bf11142c1d5b5e4c918b1d512b5&=&format=webp&quality=lossless" } }] }).catch((error) => { print(`[Error] Application error: ${error}`); });
    return res.status(200).json({ ok: true });
}