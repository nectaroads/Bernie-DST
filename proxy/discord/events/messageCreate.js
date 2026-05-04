const { dotenv, messagesbuffer } = require("../../variables");

const MAX_DST_MESSAGE_LENGTH = 140;

module.exports = async (client, message) => {
    if (message.author?.bot || !message.content || message.channel.id !== dotenv.CHATROOM) return;

    let truncatedMessage = message.content.length > MAX_DST_MESSAGE_LENGTH ? message.content.substring(0, MAX_DST_MESSAGE_LENGTH - 5) + "(...)" : message.content;

    const mentionRegex = /<@!?(\d+)>/g;
    const matches = [...truncatedMessage.matchAll(mentionRegex)];

    for (const match of matches) {
        const userId = match[1];
        let member = null;
        try { member = await message.guild?.members.fetch(userId); } catch { }
        if (member) {
            const name = member.displayName || member.user?.username || "usuário";
            truncatedMessage = truncatedMessage.replaceAll(match[0], `@${name}`);
        }
    }

    const messageData = { message: truncatedMessage, name: message.member?.displayName || message.author.username, type: "discord" };
    messagesbuffer.push({ key: "message", value: messageData });
};