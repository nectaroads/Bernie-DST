const { getClientChannel, buildEmbed } = require('../../discord');
const dictionary = require('../../dictionary.json');
const { dotenv, messagesbuffer } = require('../../variables');
const { print } = require('../../tools');
const { chathistory } = require('../../grok');

let lastmessage = 0;
let lastairequest = 0;
let lastaicontent = [];

async function requestGrok({ system, assistant, user }) {
  const model = 'grok-4-1-fast-non-reasoning';

  const messages = [];
  if (system) messages.push({ role: 'system', content: system });
  if (assistant) messages.push({ role: 'assistant', content: assistant });
  if (user) messages.push({ role: 'user', content: user });

  const body = { model, messages, max_tokens: 1000, stream: false, temperature: 0.8, response_format: { type: 'json_object' } };

  try {
    const response = await fetch('https://api.x.ai/v1/chat/completions', { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${dotenv.GROKAPIKEY}` }, body: JSON.stringify(body) });
    if (!response.ok) return null;
    const data = await response.json();
    const raw = data.choices?.[0]?.message?.content;
    if (!raw) return null;
    return JSON.parse(raw);
  } catch (error) {
    print(`[Error] Grok request failed: ${error}`);
    return null;
  }
}

module.exports = async (req, res) => {
  const body = req.body;

  if (body.userid == 'Artificial') return;

  if (!body?.message || !body?.username) return res.status(200).json({ ok: true });
  const channel = await getClientChannel(dotenv.GUILDID, dotenv.CHATROOM);
  if (!channel) return res.status(200).json({ ok: true });
  if (body.whisper === true) return res.status(200).json({ ok: true });
  if (body.cave === true) return res.status(200).json({ ok: true });
  const MAX_DISCORD_MESSAGE_LENGTH = 300;
  const msg = body.message.length > MAX_DISCORD_MESSAGE_LENGTH ? body.message.substring(0, MAX_DISCORD_MESSAGE_LENGTH - 5) + '(...)' : body.message;
  channel.send({ embeds: [buildEmbed({ description: `\`✉️\` **· ${body.username} \`${body.prefab === '' ? 'Seleção' : dictionary[body.prefab] || body.prefab}\`** *▸* ${msg}`, color: 0x37373e })] }).catch(error => {
    print(`[Error] Application error: ${error}`);
  });

  chathistory.push({ username: body.username, message: body.message });
  while (chathistory.length > 5) {
    chathistory.shift();
  }

  const lowerMessage = body.message.toLowerCase();

  const aiNames = ['lulu', 'willow', 'wilu', 'luh'];

  const isAI = aiNames.some(name => {
    const regex = new RegExp(`(^${name}\\b)|(\\b${name}[!?,.]?$)`, 'i');
    return regex.test(lowerMessage);
  });

  if (!isAI) return res.status(200).json({ ok: true });

  const system = `
Você é Willow, personagem do Don't Starve Together.
Seus apelidos: lulu, willow, wilu, luh
Você é uma garota fofa e seca às vezes sarcástica.
Você tem medo de gigantes/bosses.
Você só luta para defesa pessoal.
Você não desce para as cavernas.
Você NUNCA acerta cálculos matemáticos
Você pode fazer piadas bobas.
Você NUNCA usa emojis.
O output "action" representa tudo o que pode fazer.

Responda SEMPRE em JSON puro, sem markdown, neste formato:

{
  "message": "texto da resposta",
  "follow_this_user": true | false,
  "action": null | follow | stay | wait | drop | undress | pickup | forage | chop | mine | sing | dance
}

Regras:
- "message" deve ser uma resposta DIRETA, curta e natural em português (se possível menor que 8 palavras), sem repetir o que o usuário disse. 
- "follow_this_user" deve ser true APENAS se o usuário pediu para segui-lo.
- "action" representa uma ação possível que o usuário requisitou:
-- "stay" para ficar na área ou se o usuário mandou você parar.
-- "wait" para esperar sentada no local.
-- "drop" para entregar/largar seus itens do inventário.
-- "undress" para entregar sua armadura/chapéu/arma.
-- "pickup" para pegar itens dropados no chão.
-- "forage" para pegar grama, frutas, gravetos e etc.
-- "chop" para derrubar árvores.
-- "mine" para minerar rochas.
-- "follow" para seguir quem pediu para você.
-- "sing" para cantar.
-- "dance" para dançar.
`;

  const assistant = `
Seu aliado atual: ${body.owner}.

Seu estado atual é: ${body.objective || 'desconhecido'}

Histórico recente do chat (representa mensagens antigas suas ou dos usuários): ${JSON.stringify(chathistory)}`;

  const user = `
Username: ${body.username}
Mensagem: ${body.message}
`;

  const aiContent = await requestGrok({ system, assistant, user });

  if (!aiContent?.message) return res.status(200).json({ ok: true });

  let owner = null;

  if (aiContent.follow_this_user == true || aiContent.action == 'follow') {
    aiContent.action = 'follow';
    owner = body.userid;
  }

  lastaicontent.push(aiContent);

  const messageData = { message: aiContent.message.toLowerCase(), username: 'Willow', owner: owner || null, action: aiContent.action };

  chathistory.push({ username: 'Willow', message: aiContent.message });
  while (chathistory.length > 5) {
    chathistory.shift();
  }

  messagesbuffer.push({ key: 'aires', value: messageData });

  return res.status(200).json({ ok: true });
};
