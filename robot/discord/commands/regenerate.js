const { SlashCommandBuilder } = require('discord.js');
const { buildEmbed, validateStaff } = require('../../discord');
const { messagebuffer } = require('../../variables');
const { print } = require('../../tools');

module.exports = {
  data: new SlashCommandBuilder().setName('regenerate').setDescription("Regenerate the server's world."),
  run: async ({ interaction }) => {
    if (!validateStaff(interaction)) return;
    const actionData = { key: 'regenerate' };
    messagebuffer.buffer.push(actionData);
    interaction.reply({ embeds: [buildEmbed({ color: 0xfc7753, description: `\`🪐\` **· Regenerando o mundo...**` })] }).catch(error => {
      print(`[Error] Application error: ${error}`);
    });
  }
};
