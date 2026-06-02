const { databaseGetUserByUserId, databaseCreateUser, databaseSetUserById } = require('../../database/users');
const { getClientChannel, buildEmbed } = require('../../discord');
const { dotenv, messagebuffer } = require('../../variables');

let epiccooldowns = {};

module.exports = async (req, res) => {
  const body = req.body;
  const channel = await getClientChannel(dotenv.GUILDID, dotenv.CHATROOM);
  if (!channel) return res.status(200).json({ ok: true });
  channel.send({ embeds: [{ color: 0xc84937, title: `\`🏟️\` · ${body.victim} caiu!`, description: `- Que perigo! Isso foi **intenso**!\n- Foi **${body.cause || 'Charlie'}** quem o derrubou.\n- Outro(s) **00** estão presentes.`, thumbnail: { url: 'https://media.discordapp.net/attachments/1270552171041263658/1343495140702027776/image.png?ex=67bd7ada&is=67bc295a&hm=5ce03cab9ab65c4b76ebf9126377720f73b5dfebdbd1a5da5f42ea9bce05a456&=&format=webp&quality=lossless' } }] }).catch(error => {});
  if (!epiccooldowns[body.prefab]) epiccooldowns[body.prefab] = 0;

  const users = body.users ? Object.values(body.users) : [];
  const now = Date.now();

  const cooldownKey = body.prefab || body.victim || 'unknown';
  const lastKill = epiccooldowns[cooldownKey] || 0;
  const eightMinutes = 8 * 60 * 1000;

  if (now - lastKill < eightMinutes) return res.status(200).json({ ok: true, cooldown: true });

  channel.send({ embeds: [buildEmbed({ color: 0xe69745, description: `\`🪙\` · **Todos** receberam **3 Oinks**!` })] }).catch(error => {
    print(`[Error] Application error: ${error}`);
  });

  epiccooldowns[cooldownKey] = now;

  const colour = { r: 0.95, g: 0.78, b: 0.25, a: 1 };

  for (const player of users) {
    if (!player.userid) continue;

    let dbUser = await databaseGetUserByUserId(player.userid);

    if (!dbUser) {
      dbUser = await databaseCreateUser(player.name, player.userid);
    } else if (dbUser.name !== player.name) {
      dbUser = await databaseSetUserById(player.userid, { name: player.name });
    }

    await databaseSetUserById(player.userid, { points: Number(dbUser.points || 0) + 3, oinks: Number(dbUser.oinks || 0) + 3 });
    messagebuffer.buffer.push({ key: 'bernie_rpc_client_message', rpc: 'bernie_rpc_client_message', userid: player.userid, type: 'server', message: 'Você encontrou 3 Oinks ~★', sound: 'dontstarve/HUD/get_gold', colour });
  }

  return res.status(200).json({ ok: true });
};
