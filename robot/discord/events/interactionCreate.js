module.exports = async (client, interaction) => {
  if (!interaction.isChatInputCommand()) return;
  const command = client.commands.get(interaction.commandName);
  if (!command) return;
  try {
    await command.run({ interaction, client });
  } catch (error) {
    console.log(`[Error] Command error: ${error}`);
    const payload = { content: 'Erro ao executar o comando.', ephemeral: true };
    if (interaction.replied || interaction.deferred) await interaction.followUp(payload).catch(() => {});
    else await interaction.reply(payload).catch(() => {});
  }
};
