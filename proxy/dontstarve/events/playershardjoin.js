const { getClientChannel } = require("../../discord");
const { dotenv } = require("../../variables");

module.exports = async (req, res) => {
    const body = req.body;
    const channel = await getClientChannel(dotenv.GUILDID, dotenv.CHATROOM);
    if (!channel) return res.status(200).json({ ok: true });
    if (body.value.iscave) {
        let phase = "Desconhecido";
        if (body.value.state.isnightmarewarn) phase = "Impaciente";
        if (body.value.state.isnightmarecalm) phase = "Adormecida";
        if (body.value.state.isnightmaredawn) phase = "Desequilibrada";
        if (body.value.state.isnightmarewild) phase = "Enfurecida";
        channel.send({ embeds: [{ color: 0x8675A9, title: `\`🦇\` · ${body.value.name.slice(0, 12)} está no abismo!`, description: `- A cripta está **${phase}**!\n- **Alter** não tem influência aqui.\n- Você teme o **Desconhecido**...`, thumbnail: { url: "https://media.discordapp.net/attachments/1270552171041263658/1348917847182802966/image.png?ex=67d13524&is=67cfe3a4&hm=cc4b6ae369b758c216046b03eadf0e15a3e9c4aff0d13a89200ac467a794bbc8&=&format=webp&quality=lossless" } }] }).catch((error) => { print(`[Error] Application error: ${error}`); });
    }
    return res.status(200).json({ ok: true });
}