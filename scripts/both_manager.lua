local GLOBAL = GLOBAL or _G

print('[Bernie] Starting Both-Manager Module...')

Assets = { Asset("IMAGE", "images/profileflair_ashley.tex"), Asset("ATLAS", "images/profileflair_ashley.xml"), Asset("IMAGE", "images/profileflair_bernie.tex"), Asset("ATLAS", "images/profileflair_bernie.xml"), Asset("IMAGE", "images/profileflair_willow.tex"), Asset("ATLAS", "images/profileflair_willow.xml"), Asset("IMAGE", "images/profileflair_global.tex"), Asset("ATLAS", "images/profileflair_global.xml"), Asset("IMAGE", "images/profileflair_private.tex"), Asset("ATLAS", "images/profileflair_private.xml"), Asset("IMAGE", "images/profileflair_discord.tex"), Asset("ATLAS", "images/profileflair_discord.xml"), Asset("IMAGE", "images/profileflair_staffdiscord.tex"), Asset("ATLAS", "images/profileflair_staffdiscord.xml"), Asset("IMAGE", "images/profileflair_server.tex"), Asset("ATLAS", "images/profileflair_server.xml") }

local STRINGS = GLOBAL.STRINGS

STRINGS.CHARACTERS.WEBBER = STRINGS.CHARACTERS.WEBBER or {}

STRINGS.CHARACTERS.WEBBER.ANNOUNCE_READ_BOOK = {
    BOOK_SLEEP = "*yawn*... Zzz...",
    BOOK_BIRDS = "Feathery friends! Let's be buddies!",
    BOOK_TENTACLES = "I don’t think I wanna meet them up close.",
    BOOK_BRIMSTONE = "It smells like trouble...",
    BOOK_GARDENING = "Maybe I can grow some spider plants!",
    BOOK_SILVICULTURE = "So many trees! So much climbing!",
    BOOK_HORTICULTURE = "This garden stuff is fun!",
    BOOK_FISH = "Fishy tales... mhmm...",
    BOOK_FIRE = "This seems a bit too hot to handle.",
    BOOK_WEB = "Spider webs! Just like home!",
    BOOK_TEMPERATURE = "Hot and cold... I prefer cozy.",
    BOOK_LIGHT = "Let there be... uh, more nightlights?",
    BOOK_RAIN = "Drizzles are nice when you're not too fuzzy.",
    BOOK_MOON = "Moon stuff makes me tingly.",
    BOOK_BEES = "Buzz buzz! Hope they like me.",
    BOOK_HORTICULTURE_UPGRADED = "Advanced plant magic!",
    BOOK_RESEARCH_STATION = "Time to study!",
    BOOK_LIGHT_UPGRADED = "Whoa, that’s bright!"
}

STRINGS.CHARACTERS.WEBBER.ANNOUNCE_BOOK_UNDERSTAND = "I think I get it... maybe."

print('[Bernie] Finished loading!')