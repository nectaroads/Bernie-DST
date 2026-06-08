return {
    willow = {
        rain = {
            messagestart = { key = "message", type = "willow", message = "Pegue um guarda-chuva ou você vai se molhar!", event = "blink" },
            messageend = { key = "message", type = "willow", message = "É difícil queimar as coisas com tanta umidade.", event = "blink" },
            type = "rain",
            loop = 0,
            currentloop = 0
        },
        coldsnap = {
            messagestart = { key = "message", type = "willow", message = "Eu não sou fã, mas vou fazer nevar.", event = "blink" },
            messageend = { key = "message", type = "willow", message = "Já consigo escutar geleiras descongelando... *-*" },
            type = "coldsnap",
            loop = 60,
            currentloop = 0,

        },
        heatwave = {
            messagestart = { key = "message", type = "willow", message = "HAHA! Queimem, hoje vai fazer calor.", event = "blink" },
            messageend = { key = "message", type = "willow", message = "Hm... acho que já deu de sol quente." },
            type = "heatwave",
            loop = 60,
            currentloop = 0,
        },
        houndattack = {
            messagestart = { key = "message", type = "willow", message = "Bernie escutou latidos se aproximando...", event = "blink" },
            messageend = { key = "message", type = "willow", message = "Eles chegaram, eles estão aqui!" },
            type = "attack",
            loop = 0,
            currentloop = 0,
            prefab = "hound",
            alt = "terrorbeak",
            maxcreatures = 3
        },
        apeattack = {
            messagestart = { key = "message", type = "willow", message = "Ouvi falar que tem ladrões na região...", event = "blink" },
            messageend = { key = "message", type = "willow", message = "E parece que encontraram uma vítima!" },
            type = "attack",
            loop = 0,
            currentloop = 0,
            prefab = "powder_monkey",
            alt = "monkey",
            maxcreatures = 3,
        },
        witchcraft = {
            messagestart = { key = "message", type = "willow", message = "Eeew... que cheiro podre. Algo vai acontecer.", event = "blink" },
            messageend = { key = "message", type = "willow", message = "Essa bruxaria estragou meu almoço picante..." },
            name = "witchcraft",
            type = "witchcraft",
            loop = 0,
            currentloop = 0
        },
        blackout = {
            messagestart = { key = "message", type = "willow", message = "Busque uma fonta de luz, Charlie está agitada hoje!", event = "blink" },
            messageend = { key = "message", type = "willow", message = "haHaHA! Fogo é fonte de luz!" },
            type = "blackout",
            loop = 0,
            currentloop = 0
        },
        --bloodfeast = {
        --    messagestart = { key = "message", type = "willow", message = "Mate seus amigos, o ritual de sangue começa!", event = "blink" },
        --    messageend = { key = "message", type = "willow", message = "Ah... eu nem gostava tanto disso aí..." },
        --    type = "bloodfeast",
        --    loop = 0,
        --    currentloop = 0
        --},
        randomflare = {
            messagestart = { key = "message", type = "willow", message = "Vou acender um sinalizador, eu encontrei alguma coisa...", event = "blink" },
            messageend = { key = "message", type = "willow", message = "Verifique a região, quem sabe acha isqueiros novos?" },
            type = "randomflare",
            loop = 0,
            currentloop = 0
        },
    }
}
