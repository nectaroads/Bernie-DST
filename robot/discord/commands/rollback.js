const { SlashCommandBuilder } = require('discord.js');
const { buildEmbed, validateStaff } = require('../../discord');
const { print } = require('../../tools');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('rollback')
    .setDescription('Send a rollback command to the server.')
    .addNumberOption(option => option.setName('days').setDescription('How many days?').setRequired(true)),
  run: async ({ interaction }) => {
    if (!validateStaff(interaction)) return;
    const days = interaction.options.getString('days');
    const actionData = { key: 'rollback', quantity: days };
    messagebuffer.buffer.push(actionData);
    interaction.reply({ embeds: [buildEmbed({ color: 0xfc7753, description: `\`⏲️\` **· Voltando ${days} dias no tempo...**` })] }).catch(error => {
      print(`[Error] Application error: ${error}`);
    });
    r;
  }
};
