const { databaseGetUsers, databaseGetUserByUserId, databaseCreateUser, databaseSetUserById } = require('../../database/users');
const { r, messagebuffer } = require('../../variables');

module.exports = async (req, res) => {
  const body = req.body;
  const now = Date.now();
  let data = [];
  let users = [];

  if (body.users) {
    const incomingUsers = Object.values(body.users);

    for (const player of incomingUsers) {
      let dbUser = await databaseGetUserByUserId(player.userid);
      if (!dbUser) dbUser = await databaseCreateUser(player.name, player.userid);
      else if (dbUser.name !== player.name) dbUser = await databaseSetUserById(player.userid, { name: player.name });

      const users = await databaseGetUsers();
      const pointsRanking = [...users].sort((a, b) => b.points - a.points);
      const oinksRanking = [...users].sort((a, b) => b.oinks - a.oinks);

      const messageData = { key: 'rank', pointsleaderboard: pointsRanking.slice(0, 20), oinksleaderboard: oinksRanking.slice(0, 20) };

      for (const player of incomingUsers) {
        const dbUser = users.find(u => u.userid === player.userid);
        if (!dbUser) continue;

        const pointrank = pointsRanking.findIndex(u => u.userid === player.userid) + 1;
        const oinkrank = oinksRanking.findIndex(u => u.userid === player.userid) + 1;

        const privateMessageData = { ...messageData, userid: dbUser.userid, player: { name: dbUser.name, userid: dbUser.userid, points: dbUser.points, oinks: dbUser.oinks, pointrank, oinkrank } };

        messagebuffer.buffer.push(privateMessageData);
      }
    }
  }

  if (now - messagebuffer.lastcall > 3000) messagebuffer.buffer.length = 0;
  if (messagebuffer.buffer.length > 0) {
    data = [...messagebuffer.buffer].reverse();
    messagebuffer.buffer.splice(0, data.length);
  }
  messagebuffer.lastcall = now;
  return res.json(data);
};
