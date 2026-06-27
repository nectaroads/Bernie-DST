return {
    quotes = {
        wilson = {
            "Something feels... different. I should keep an eye on this.",
            "I have a hypothesis, but I'd rather test it before celebrating.",
            "Well... that's either very good or very, very bad."
        },

        willow = {
            "Heh... I kinda like where this is going.",
            "That smell... wait, that's not smoke, is it?",
            "Ooh, something's about to happen. I can feel it."
        },

        wolfgang = {
            "Hmm... Wolfgang is ready. Probably.",
            "Strong muscles cannot punch uncertainty.",
            "Something approaches. Let it try."
        },

        wendy = {
            "The world holds its breath once again.",
            "Another twist in an endless story.",
            "Even Abigail seems... uncertain."
        },

        wx78 = {
            "UNEXPECTED VARIABLE DETECTED.",
            "CALCULATING OUTCOME... ERROR.",
            "THIS DEVELOPMENT IS SUBOPTIMAL."
        },

        wickerbottom = {
            "Curious... I don't recall reading about this.",
            "Experience suggests caution.",
            "Some chapters are better left unread."
        },

        woodie = {
            "Easy there... this doesn't feel normal.",
            "I've got a bad feeling about this, eh.",
            "Let's hope Lucy doesn't start complaining."
        },

        wes = {
            "...",
            "*shrugs nervously*",
            "*awkward mime noises*"
        },

        maxwell = {
            "Interesting. I wasn't expecting that.",
            "Fortune always demands payment.",
            "Let's see who this favors."
        },

        wigfrid = {
            "Fate calls once more!",
            "May this tale honor the worthy.",
            "Even heroes fear the unknown."
        },

        webber = {
            "Uh... do we hide?",
            "The spiders don't know what this means either.",
            "Everybody stay together!"
        },

        winona = {
            "Well, that's gonna need fixing.",
            "Hope I packed enough tools.",
            "I've seen worse... I think."
        },

        warly = {
            "Let's hope this doesn't spoil the recipe.",
            "Every surprise needs the right seasoning.",
            "Hmm... difficult to predict."
        },

        wortox = {
            "Heehee... what a delightful mystery!",
            "Chaos keeps life entertaining.",
            "Or maybe everything is exactly as planned."
        },

        wormwood = {
            "Roots... worried.",
            "Something changes.",
            "Plant waits."
        },

        wurt = {
            "Fishy feeling, florp.",
            "Hope this is good... florp.",
            "Don't like weird water, florp."
        },
    },
    willow = {
        rain = {
            messagestart = { value = true, key = "message", type = "willow", message = "Pegue um guarda-chuva ou você vai se molhar!", event = "blink" },
            messageend = { value = false, key = "message", type = "willow", message = "É difícil queimar as coisas com tanta umidade.", event = "blink" },
            type = "rain",
            loop = 0,
            currentloop = 0
        },
        coldsnap = {
            messagestart = { value = true, key = "message", type = "willow", message = "Eu não sou fã, mas vou fazer nevar.", event = "blink" },
            messageend = { value = false, key = "message", type = "willow", message = "Já consigo escutar geleiras descongelando... *-*", event = "blink" },
            type = "coldsnap",
            loop = 60,
            currentloop = 0,

        },
        heatwave = {
            messagestart = { value = true, key = "message", type = "willow", message = "HAHA! Queimem, hoje vai fazer calor.", event = "blink" },
            messageend = { value = false, key = "message", type = "willow", message = "Hm... acho que já deu de sol quente.", event = "blink" },
            type = "heatwave",
            loop = 60,
            currentloop = 0,
        },
        houndattack = {
            messagestart = { value = true, key = "message", type = "willow", message = "Bernie escutou latidos se aproximando...", event = "blink" },
            messageend = { value = false, key = "message", type = "willow", message = "Eles chegaram, eles estão aqui!" },
            type = "attack",
            loop = 0,
            currentloop = 0,
            prefab = "hound",
            alt = "terrorbeak",
            maxcreatures = 3
        },
        apeattack = {
            messagestart = { value = true, key = "message", type = "willow", message = "Ouvi falar que tem ladrões na região...", event = "blink" },
            messageend = { value = false, key = "message", type = "willow", message = "E parece que encontraram uma vítima!" },
            type = "attack",
            loop = 0,
            currentloop = 0,
            prefab = "powder_monkey",
            alt = "monkey",
            maxcreatures = 3,
        },
        witchcraft = {
            messagestart = { value = true, key = "message", type = "willow", message = "Eeew... que cheiro podre. Algo vai acontecer.", event = "blink" },
            messageend = { value = false, key = "message", type = "willow", message = "Essa bruxaria estragou meu almoço picante..." },
            name = "witchcraft",
            type = "witchcraft",
            loop = 0,
            currentloop = 0
        },
        blackout = {
            messagestart = { value = true, key = "message", type = "willow", message = "Busque uma fonta de luz, Charlie está agitada hoje!", event = "blink" },
            messageend = { value = false, key = "message", type = "willow", message = "Incendiar a base é uma ótima forma de sobreviver..." },
            type = "blackout",
            loop = 0,
            currentloop = 0
        },
        bloodfeast = {
            messagestart = { value = true, key = "message", type = "willow", message = "Mate... MATE! O ritual de sangue começa!", event = "blink", overlay = "miasmaover" },
            messageend = { value = false, key = "message", type = "willow", message = "De volta a pacata vida tranquila...", overlay = "miasmaover", event = "blink" },
            type = "bloodfeast",
            loop = 0,
            currentloop = 0
        },
        randomflare = {
            messagestart = { value = true, key = "message", type = "willow", message = "Vou acender um sinalizador, eu encontrei alguma coisa...", event = "blink" },
            messageend = { value = false, key = "message", type = "willow", message = "Verifique a região, quem sabe acha isqueiros novos?" },
            type = "randomflare",
            loop = 0,
            currentloop = 0
        },
    }
}
