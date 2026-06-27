const { getClientChannel, buildEmbed } = require('../../discord');
const dictionary = require('../../dictionary.json');
const { dotenv, messagesbuffer } = require('../../variables');
const { print } = require('../../tools');
const { chathistory } = require('../../grok');

let lastmessage = 0;

module.exports = async (req, res) => {
  const body = req.body;

  if (!body?.message || !body?.username) return res.status(200).json({ ok: true });
  const channel = await getClientChannel(dotenv.GUILDID, dotenv.CHATROOM);
  if (!channel) return res.status(200).json({ ok: true });
  if (body.whisper === true) return res.status(200).json({ ok: true });
  if (body.cave === true) return res.status(200).json({ ok: true });
  const MAX_DISCORD_MESSAGE_LENGTH = 300;
  const msg = body.message.length > MAX_DISCORD_MESSAGE_LENGTH ? body.message.substring(0, MAX_DISCORD_MESSAGE_LENGTH - 5) + '(...)' : body.message;
  channel.send({ embeds: [buildEmbed({ description: `-# \`✉️\` **· ${body.username} \`${body.prefab === '' ? 'Seleção' : dictionary[body.prefab] || body.prefab}\`** *▸* ${msg}`, color: 0x37373e })] }).catch(error => {
    print(`[Error] Application error: ${error}`);
  });

  chathistory.push({ username: body.username, message: body.message });
  while (chathistory.length > 5) {
    chathistory.shift();
  }

  const lowerMessage = body.message.toLowerCase();

  return res.status(200).json({ ok: true });
};
