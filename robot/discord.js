const { GatewayIntentBits, EmbedBuilder, Client, Partials } = require('discord.js');
const path = require('path');
const fs = require('fs');
const { dotenv } = require('./variables');
const { print } = require('./tools');

let discord = { client: null, guilds: {}, channels: {}, roles: {}, members: {} };

function getPath(dir) {
  const result = path.join(__dirname, '.' + dir);
  return result;
}

function setPath(dir) {
  let result = getPath(dir);
  if (!fs.existsSync(result)) {
    fs.mkdirSync(result, { recursive: true });
    result = getPath(dir);
  }
  return result;
}

function getFile(dir) {
  const result = getPath(dir);
  return result;
}

function setFile(dir) {
  let result = getFile(dir);
  const folderRelative = path.dirname(dir);
  setPath(folderRelative);
  if (!fs.existsSync(result)) {
    fs.writeFileSync(result, '');
    result = getFile(dir);
  }
  return result;
}

function requireFresh(absFile) {
  delete require.cache[require.resolve(absFile)];
  return require(absFile);
}

function listFiles(relDir, type = 'js') {
  const base = setPath(relDir);
  const out = [];
  const walk = dir => {
    const items = fs.readdirSync(dir, { withFileTypes: true });
    for (const it of items) {
      const full = path.join(dir, it.name);
      if (it.isDirectory()) walk(full);
      else if (it.isFile() && it.name.endsWith(type)) out.push(full);
    }
  };
  walk(base);
  return out;
}

async function getClientGuild(guildId) {
  let guild = discord.guilds[guildId] ? discord.guilds[guildId] : null;
  if (guild) return guild;
  guild = await discord.client.guilds.fetch(guildId).catch(error => {
    print(`[Error] Discord: Application error: ${error}`);
  });
  return guild || null;
}

async function getClientChannel(guildId, channelId) {
  let guild = await getClientGuild(guildId);
  if (!guild) return null;
  let channel = discord.channels[channelId] ? discord.channels[channelId] : null;
  if (channel) return channel;
  channel = await guild.channels.fetch(channelId).catch(error => {
    print(`[Error] Discord: Application error: ${error}`);
  });
  if (channel) discord.channels[channelId] = channel;
  return channel || null;
}

async function getClientRole(guildId, roleId) {
  let guild = await getClientGuild(guildId);
  if (!guild) return null;
  let role = discord.roles[roleId] ? discord.roles[roleId] : null;
  if (role) return role;
  role = await guild.roles.fetch(roleId).catch(error => {
    print(`[Error] Discord: Application error: ${error}`);
  });
  if (role) discord.roles[roleId] = role;
  return role || null;
}

function startDiscordEvents() {
  const files = listFiles('./robot/discord/events');
  for (const abs of files) {
    const name = path.basename(abs, '.js');
    const handler = requireFresh(abs);
    if (typeof handler !== 'function') continue;
    discord.client.on(name, (...args) => handler(discord.client, ...args));
  }
}

function startDiscordCommands() {
  const files = listFiles('./robot/discord/commands');
  const map = new Map();
  for (const abs of files) {
    const cmd = requireFresh(abs);
    if (!cmd || !cmd.data || typeof cmd.run !== 'function') continue;
    map.set(cmd.data.name, cmd);
  }
  return map;
}

async function syncDiscordCommands(commandsMap, guildId = null) {
  const payload = [...commandsMap.values()].map(c => c.data.toJSON());
  if (guildId) {
    const guild = await getClientGuild(guildId);
    if (!guild) return;
    await guild.commands.set(payload);
    return;
  }
  await discord.client.application.commands.set(payload);
}

async function startDiscordClient() {
  print(`[Setup] Discord: Starting Discord client: Please, wait...`);
  const client = new Client({ intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildMembers, GatewayIntentBits.GuildMessages, GatewayIntentBits.GuildMessageReactions, GatewayIntentBits.DirectMessages, GatewayIntentBits.MessageContent], partials: [Partials.Message, Partials.Channel, Partials.Reaction] });
  discord.client = client;
  startDiscordEvents();
  commands = startDiscordCommands();
  discord.client.commands = commands;
  await discord.client.login(dotenv.DISCORDTOKEN);
  print(`[Success] Discord: Client logged-in: ${discord.client.user.username}`);
  await syncDiscordCommands(commands);
}

function buildEmbed({ author = null, title = null, description = null, thumbnail = null, url = null, image = null, footer = null, timestamp = null, fields = [], color = 0x2b2d31 }) {
  const embed = new EmbedBuilder();
  embed.setColor(color);
  if (title) embed.setTitle(title);
  if (description) embed.setDescription(description);
  if (thumbnail) embed.setThumbnail(thumbnail);
  if (author) embed.setAuthor({ name: author.name, url: author.url, icon: author.icon });
  if (footer) embed.setFooter({ text: footer.text, icon: footer.icon });
  if (url) embed.setURL(url);
  if (image) embed.setImage(image);
  if (timestamp) embed.setTimestamp(timestamp);
  if (Array.isArray(fields) && fields.length > 0)
    fields.forEach(field => {
      if (field.name && field.value) {
        embed.addFields({ name: field.name, value: field.value, inline: field.inline || false });
      }
    });
  return embed;
}

function validateStaff(interaction) {
  const staffrole = dotenv.STAFFID;

  const hasStaffRole = interaction.member?.roles?.cache?.has(staffrole);

  if (!hasStaffRole) {
    interaction.reply({ embeds: [buildEmbed({ color: 0xffb356, description: '`⚠️` · **Atenção, você não tem permissão para isso!**' })], ephemeral: true }).catch(error => {
      console.log(`[Error] Application error: ${error}`);
    });
    return false;
  }

  return true;
}

module.exports = { startDiscordClient, getClientChannel, getClientGuild, getClientRole, buildEmbed, validateStaff };
