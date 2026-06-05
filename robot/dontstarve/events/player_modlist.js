const { getClientChannel } = require('../../discord');
const { dotenv } = require('../../variables');
const whitelist = require('../../whitelist.json');

const MAX_LENGTH = 1900;

async function getWorkshopName(id) {
  const url = `https://steamcommunity.com/sharedfiles/filedetails/?id=${id}`;

  try {
    const res = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0' } });
    const html = await res.text();
    const og = html.match(/<meta property="og:title" content="([^"]+)"/i);
    if (og?.[1]) return decodeHtml(og[1]);
    const title = html.match(/<title>(.*?)<\/title>/i);
    if (title?.[1])
      return decodeHtml(title[1])
        .replace(/^Steam Workshop::/i, '')
        .trim();
    return `Workshop ${id}`;
  } catch {
    return `Workshop ${id}`;
  }
}

function decodeHtml(text) {
  return String(text)
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .trim();
}

module.exports = async (req, res) => {
  const body = req.body;
  const channel = await getClientChannel(dotenv.GUILDID, dotenv.MODROOM);

  if (!channel) return res.status(200).json({ ok: true });

  const victim = body.victim || 'Unknown';

  const ids = Array.isArray(body.modlist)
    ? body.modlist
        .map(mod => String(mod).replace('workshop-', '').trim())
        .filter(Boolean)
        .filter(id => !whitelist.anticheat[id])
    : [];

  if (ids.length <= 0) return res.status(200).json({ ok: true });

  const items = await Promise.all(
    ids.map(async id => {
      const name = await getWorkshopName(id);
      const url = `https://steamcommunity.com/sharedfiles/filedetails/?id=${id}`;
      return `[${name}](${url})`;
    })
  );

  const messages = [];
  let current = `***Modlist Context: ${victim}***\n> Sharedfiles: `;

  for (let i = 0; i < items.length; i++) {
    const part = i === 0 ? items[i] : `, ${items[i]}`;

    if ((current + part).length > MAX_LENGTH) {
      messages.push(current);
      current = `***Modlist Context: ${victim}***\n> Sharedfiles: ${items[i]}`;
    } else {
      current += part;
    }
  }

  if (current.length > 0) messages.push(current);

  for (const message of messages) {
    await channel.send(message);
  }

  return res.status(200).json({ ok: true });
};
