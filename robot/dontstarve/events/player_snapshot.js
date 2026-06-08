const { getClientChannel } = require('../../discord');
const { dotenv, messagebuffer } = require('../../variables');

let players = {};

module.exports = async (req, res) => {
  const body = req.body;
  const channel = await getClientChannel(dotenv.GUILDID, dotenv.MODROOM);

  if (!channel) return res.status(200).json({ ok: true });

  const worldmap = body.caves ? 'Caves' : 'Overworld';
  const victim = body.victim || 'Unknown';
  const userid = body.userid || victim;
  const snapshot = String(body.snapshot || 'unknown');

  if (!players[userid]) players[userid] = {};

  players[userid][worldmap] = snapshot;

  const snapshotCounts = {};

  for (const playerid in players) {
    const playerSnapshot = players[playerid][worldmap];
    if (playerSnapshot) snapshotCounts[playerSnapshot] = (snapshotCounts[playerSnapshot] || 0) + 1;
  }

  const entries = Object.entries(snapshotCounts).sort((a, b) => b[1] - a[1]);
  const [mostrecurrentsnapshot, mostrecurrentcount] = entries[0] || [null, 0];
  const secondcount = entries[1]?.[1] || 0;
  const hasDominantSnapshot = mostrecurrentcount > secondcount;
  const knownSnapshots = entries.map(([snap, count]) => `> ${snap}: ${count}`).join('\n');
  
  await channel.send(`***${worldmap}-Snapshot: ${victim} | ${snapshot}***\n> ***Known Snapshots:***\n${knownSnapshots}`);

  return res.status(200).json({ ok: true });
};
