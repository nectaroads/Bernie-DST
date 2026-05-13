function rollDice(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
}

function print(value, result = false) {
    const tags = { '[Request]': '\x1b[34m', '[Log]': '\x1b[90m', '[Success]': '\x1b[32m', '[Error]': '\x1b[31m', '[Warn]': '\x1b[33m', '[Database]': '\x1b[36m', '[Setup]': '\x1b[35m' };
    const blocks = { '[Request]': '\x1b[44m', '[Log]': '\x1b[100m', '[Success]': '\x1b[42m', '[Error]': '\x1b[41m', '[Warn]': '\x1b[43m', '[Database]': '\x1b[46m', '[Setup]': '\x1b[45m' };
    const specials = { value: '\x1b[2m', reset: '\x1b[0m', gray: '\x1b[90m' };
    let formattedString = '';
    let formatIndex = 0;
    for (const word of value.split(' ')) {
        if (tags[`${word}`]) formattedString += `${blocks[word]}  ${specials.reset} ${tags[word]}${word}${specials.reset} `;
        else if (word.endsWith(':')) {
            formattedString += `${word} ${formatIndex == 0 ? specials.value : '\x1b[94m'}`;
            formatIndex += 1;
        } else formattedString += `${word} `;
    }
    console.log(formattedString + specials.reset);
    return result;
}

function formatValue(v) {
    if (v === null) return 'null';
    if (v === undefined) return 'undefined';
    if (typeof v === 'object') {
        try {
            return JSON.stringify(v);
        } catch {
            return '[Circular]';
        }
    }
    return String(v);
}

module.exports = { rollDice, print, formatValue }