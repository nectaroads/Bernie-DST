const { getClientChannel, buildEmbed } = require('../../discord');
const { dotenv, messagebuffer } = require('../../variables');

module.exports = async (req, res) => {
  const body = req.body;
  const channel = await getClientChannel(dotenv.GUILDID, dotenv.CHATROOM);
  if (!channel) return res.status(200).json({ ok: true });

  const roleId = '1265501710256705607';
  channel.send({ embeds: [buildEmbed({ color: 0xfd528c, description: `*\`🚨\` · Modificação detectada! **${body.victim}** \`${body.userid}\`*` })] }).catch(error => {
    print(`[Error] Application error: ${error}`);
  });

  //const messageData = { key: 'message', type: 'willow', message: `${body.victim} será expulso em breve. O usuário recebeu flag "Client Modificado" e está sujeito a banimento. Se acredita que essa notificação é um erro, por favor, compartilhe no Discord.` };
  //messagebuffer.buffer.push(messageData);
  //setTimeout(() => {
  //  const actionData = { key: 'kick', target: body.userid };
  //  messagebuffer.buffer.push(actionData);
  //}, 30000);

  return res.status(200).json({ ok: true });
};
