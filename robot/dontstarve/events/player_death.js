const { databaseGetUserByUserId, databaseCreateUser, databaseSetUserById } = require('../../database/users');
const dictionary = require('../../dictionary.json');
const { getClientChannel, buildEmbed } = require('../../discord');
const { rollDice } = require('../../tools');
const { dotenv, messagebuffer } = require('../../variables');

module.exports = async (req, res) => {
  const channel = await getClientChannel(dotenv.GUILDID, dotenv.CHATROOM);
  if (!channel) return res.status(200).json({ ok: true });
  const body = req.body;
  const desc = `\`👻\`** · ${body.victim.slice(0, 12)} faleceu! Foi *${body.cause}* quem matou.**`;
  channel.send({ embeds: [{ color: 0x8c8c8c, description: desc }] }).catch(error => {
    print(`[Error] Application error: ${error}`);
  });

  if (body.userid) {
    let dbUser = await databaseGetUserByUserId(body.userid);
    if (!dbUser) dbUser = await databaseCreateUser(body.name, body.userid);
    const currentPoints = Number(dbUser.points || 0);
    if (currentPoints > 0) {
      const quantity = Math.min(currentPoints, Math.ceil(6 + currentPoints * 0.07));
      await databaseSetUserById(body.userid, { points: currentPoints - quantity });
      const colour = { r: 0.95, g: 0.35, b: 0.35, a: 1 };
      if (quantity > 0) {
        messagebuffer.buffer.push({ key: 'message', type: 'server', message: `${body.victim} perdeu ${quantity} Pontos...`, colour });
        channel.send({ embeds: [buildEmbed({ color: 0xf92088, description: `\`👅\` · **${body.victim}** perdeu **${quantity} Pontos**!` })] }).catch(error => {
          print(`[Error] Application error: ${error}`);
        });
      }
    }
  }

  if (body.causeuserid) {
    let dbUser = await databaseGetUserByUserId(body.causeuserid);
    if (!dbUser) dbUser = await databaseCreateUser(body.name, body.causeuserid);
    const currentPoints = Number(dbUser.points || 0);
    if (currentPoints > 0) {
      const quantity = 12;
      await databaseSetUserById(body.causeuserid, { points: currentPoints + quantity });
      const colour = { r: 0.95, g: 0.35, b: 0.35, a: 1 };
      messagebuffer.buffer.push({ key: 'message', type: 'server', message: `${body.cause} recebeu ${quantity} Pontos...`, colour });
      channel.send({ embeds: [buildEmbed({ color: 0xe69745, description: `\`🪙\` · **${body.cause}** recebeu **${quantity} Oinks**!` })] }).catch(error => {
        print(`[Error] Application error: ${error}`);
      });
    }
  }

  return res.status(200).json({ ok: true });
};
