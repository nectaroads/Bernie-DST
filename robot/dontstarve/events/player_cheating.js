const { getClientChannel } = require('../../discord');
const { dotenv, messagebuffer } = require('../../variables');

module.exports = async (req, res) => {
  const body = req.body;
  const channel = await getClientChannel(dotenv.GUILDID, dotenv.MODROOM);
  if (!channel) return res.status(200).json({ ok: true });
  await channel.send(`***Test player cheating: ${body.victim} ${body.userid}*** @everyone`);

  const messageData = { key: 'bernie_rpc_client_message', rpc: 'bernie_rpc_client_message', type: 'willow', message: `${victim} será expulso em breve. O usuário recebeu flag "Client Modificado" e está sujeito a banimento. Se acredita que essa notificação é um erro, por favor, compartilhe no Discord.` };
  messagebuffer.buffer.push(messageData);
  setTimeout(10000, () => {
    const actionData = { key: 'kick', target: body.userid };
    messagebuffer.buffer.push(actionData);
  });

  return res.status(200).json({ ok: true });
};
