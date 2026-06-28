const { SlashCommandBuilder } = require('discord.js');
const { buildEmbed, validateStaff } = require('../../discord');
const { print } = require('../../tools');
const { messagebuffer } = require('../../variables');

module.exports = {
  data: new SlashCommandBuilder().setName('shutdown').setDescription('Shutdown the server.'),
  run: async ({ interaction }) => {
    if (!validateStaff(interaction)) return;
    const actionData = { key: 'shutdown' };
    messagebuffer.buffer.push(actionData);
    interaction.reply({ embeds: [buildEmbed({ color: 0x9e74ca, description: `-# \`🌑\` · Salvando e desligando o servidor...` })] }).catch(error => {
      print(`[Error] Application error: ${error}`);
    });
  }
};
