const { SlashCommandBuilder } = require('discord.js');
const { buildEmbed, validateStaff } = require('../../discord');
const { print } = require('../../tools');
const { messagebuffer } = require('../../variables');

module.exports = {
  data: new SlashCommandBuilder
  ()
    .setName('ban')
    .setDescription('Ban an player from the server.')
    .addStringOption(option => option.setName('id').setDescription('User ID.').setRequired(true))
    .addNumberOption(option => option.setName('days').setDescription('How many days the ban should exist.').setRequired(false)),
  run: async ({ interaction }) => {
    if (!validateStaff(interaction)) return;
    const id = interaction.options.getString('id');
    let duration = interaction.options.getNumber('days');
    if (!duration) duration = 1;
    const actionData = { key: 'ban', target: id, duration: duration };
    messagebuffer.buffer.push(actionData);
    interaction.reply({ embeds: [buildEmbed({ color: 0x62417f, description: `-# \`🫂\` · Banindo \`${userId}\` por \`${duration}\` dias...` })] }).catch(error => {
      print(`[Error] Application error: ${error}`);
    });
  }
};
