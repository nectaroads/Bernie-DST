const { getClientChannel } = require("../../discord");
const { rollDice } = require("../../tools");
const { dotenv } = require("../../variables");

module.exports = async (req, res) => {
    const body = req.body;
    const channel = await getClientChannel(dotenv.GUILDID, dotenv.CHATROOM);
    if (!channel) return res.status(200).json({ ok: true });
    const players = Object.values(body.players);
    if (!players) return res.status(200).json({ ok: true });
    const player = body.name;
    const onlinePlayers = players.length - 1;
    let target = "Charlie";
    if (onlinePlayers > 0) {
        const dice = rollDice(0, onlinePlayers)
        target = players[dice].name || "Charlie";
    }
    const firstLine = onlinePlayers > 1 ? `**0${onlinePlayers - 1}** sobrevivente(s) comemoram!` : `Porém **ninguém escutou**...`;
    channel.send({ embeds: [{ color: 0x43724F, title: `\`🏡\` · Boas-vindas à ${player.slice(0, 12)}!`, description: `- ${firstLine}\n- **${target}** pensa em queimar tudo.\n- Há espaço para **0${body.maxplayers - (players?.length || 1)}** pessoa(s).`, thumbnail: { url: "https://cdn.discordapp.com/attachments/1270552171041263658/1338945608823738489/image.png?ex=67acedc5&is=67ab9c45&hm=490420dd396c22667f09dc10e483ee3f8dbc0e30b8bc82d123e41697b8edd46d&" } }] }).catch((error) => { print(`[Error] Application error: ${error}`); });
    channel.setTopic(`O servidor tem ${onlinePlayers}/${body.maxplayers} players online - Sobreviva para contar histórias aos que lutarem depois de você!`).catch((error) => { print(`[Error] Application error: ${error}`); });
    return res.status(200).json({ ok: true });
}