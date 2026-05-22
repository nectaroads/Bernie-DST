const { SlashCommandBuilder } = require('discord.js');
const { buildEmbed, validateStaff } = require('../../discord');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('kick')
    .setDescription('Kick an player from the server.')
    .addStringOption(option => option.setName('id').setDescription('User ID.').setRequired(true)),
  run: async ({ interaction }) => {
    if (!validateStaff(interaction)) return;
    const id = interaction.options.getString('id');
    const actionData = { key: 'kick', target: id };
    messagebuffer.buffer.push(actionData);
    interaction.reply({ embeds: [buildEmbed({ color: 0xffc83d, description: `\`👋\` · **Expulsando \`${id}\`...**` })] }).catch(error => {
      print(`[Error] Application error: ${error}`);
    });
  }
};
