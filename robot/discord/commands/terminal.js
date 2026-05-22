const { SlashCommandBuilder } = require('discord.js');
const { buildEmbed, validateStaff } = require('../../discord');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('terminal')
    .setDescription('Send an terminal command to the server.')
    .addStringOption(option => option.setName('command').setDescription('The command itself!').setRequired(true)),
  run: async ({ interaction }) => {
    if (!validateStaff(interaction)) return;
    const command = interaction.options.getString('command');
    const actionData = { key: 'terminal', command: command };
    messagebuffer.buffer.push(actionData);
    interaction.reply({ embeds: [buildEmbed({ color: 0xfc7753, description: `\`💻\` · **Executando comando...**` })] }).catch(error => {
      print(`[Error] Application error: ${error}`);
    });r
  }
};
