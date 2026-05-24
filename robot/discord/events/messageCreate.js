const { chathistory } = require('../../grok');
const { dotenv, messagebuffer } = require('../../variables');

const MAX_DST_MESSAGE_LENGTH = 140;

module.exports = async (client, message) => {
  if (message.author.id === client.user.id || !message.content || message.channel.id !== dotenv.CHATROOM) return;

  let truncatedMessage = message.content.length > MAX_DST_MESSAGE_LENGTH ? message.content.substring(0, MAX_DST_MESSAGE_LENGTH - 5) + '(...)' : message.content;

  const mentionRegex = /<@!?(\d+)>/g;
  const matches = [...truncatedMessage.matchAll(mentionRegex)];

  for (const match of matches) {
    const userId = match[1];
    let member = null;
    try {
      member = await message.guild?.members.fetch(userId);
    } catch {}
    if (member) {
      const name = member.displayName || member.user?.username || 'usuário';
      truncatedMessage = truncatedMessage.replaceAll(match[0], `@${name}`);
    }
  }

  // place emojis here
  truncatedMessage = truncatedMessage
    .replace(/\r/g, ' ')
    .replace(/\n/g, ' ')
    .replace(/\t/g, ' ')
    .replace(/\0/g, ' ')
    .replace(/\\/g, '∖')
    .replace(/"/g, '＂')
    .replace(/'/g, '＇')
    .replace(/`/g, '｀')
    .replace(/\{/g, '｛')
    .replace(/\}/g, '｝')
    .replace(/\[/g, '［')
    .replace(/\]/g, '］')
    .replace(/[\u0000-\u001F]/g, '⚠️')
    .replace(/[\u007F-\u009F]/g, '⚠️')
    .replace(/\u2028/g, '⏎')
    .replace(/\u2029/g, '⏎')
    .trim();

  const dominantRole = message.member?.roles?.color;
  const hexColor = dominantRole?.hexColor || '#FFFFFF';

  const colour = {
    r: parseInt(hexColor.slice(1, 3), 16) / 255,
    g: parseInt(hexColor.slice(3, 5), 16) / 255,
    b: parseInt(hexColor.slice(5, 7), 16) / 255,
    a: 1
  };

  const messageData = { key: 'bernie_rpc_client_message', rpc: 'bernie_rpc_client_message', type: 'discord', message: truncatedMessage, name: message.member?.displayName || message.author.username, colour: colour };
  messagebuffer.buffer.push(messageData);
  chathistory.push(messageData);

  while (chathistory.length > 5) {
    chathistory.shift();
  }
};
