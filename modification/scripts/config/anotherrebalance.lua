return {
    gnomequotes = {
        "This place smells like gnome hospitals...",
        "I made some whimsical farts.",
        "The dirt whispers forbidden gardening secrets.",
        "I once fought a bee. The bee won.",
        "Tiny feet, enormous destiny.",
        "A true gnome fears neither death nor mushrooms.",
        "I can hear colors today.",
        "The moon owes me money.",
        "Never trust a tall gnome.",
        "I buried my taxes in the forest.",
        "The goblins rejected my cooking again.",
        "Every rock deserves a little kiss.",
        "I licked the lightning once.",
        "The worms know too much.",
        "I traded my sanity for this hat.",
        "There are bees inside my thoughts.",
        "Do not feed the invisible frogs.",
        "My bones itch with ancient whimsy.",
        "This grass tastes emotionally complicated.",
        "I dream of screaming carrots.",
        "The fairies stole my left sock again.",
        "I was banned from seven underground kingdoms.",
        "The trees are laughing at you.",
        "My beard contains forbidden knowledge.",
        "Gnomes invented dancing by accident.",
        "I swallowed a coin for luck.",
        "The fog smells delicious tonight.",
        "Never challenge a raccoon to gambling.",
        "I can outrun destiny barefoot.",
        "The mushrooms are plotting democracy.",
        "Tiny goblin inside me demands soup.",
        "I miss the old screaming woods.",
        "The floor feels judgmental today.",
        "A pebble insulted my ancestors.",
        "I know where the moon sleeps.",
        "You look highly throwable today.",
        "I possess several illegal garden techniques.",
        "The crows appointed me mayor.",
        "There is definitely soup in my pockets.",
        "My soul was handcrafted by forest goblins."

    },

    gnomeevents = {

        gold = {
            message = "Shiny rocks for the little goblin?",
            sanity = 2,
            spawnnearby = "goldnugget"
        },

        hound = {
            message = "They smelling your unwashed gnome FEET!",
            sanity = -1,
            spawnenemy = "hound"
        },

        slip = {
            message = "WHOOOOPS! The floor betrayed ya!",
            sanity = -2,
            state = "slip"
        },

        mushroom = {
            message = "True gnomes survives on magic mushrooms.",
            sanity = 1,
            give = "blue_cap"
        },

        drop = {
            message = "Oopsie daisy! BUTTER FINGERS!",
            sanity = -1,
            drop = true
        },

        sing = {
            message = "*gnomish humming intensifies* ♫",
            sanity = 5
        },

        teleport = {
            message = "Reality is merely optional for a gnome.",
            sanity = -5,
            teleport = true
        },

        poop = {
            message = "Fresh from the royal gnome mines.",
            sanity = 1,
            give = "poop"
        },

        lightning = {
            message = "THE SKY GNOMES HAVE SPOKEN!",
            sanity = -3,
            lightning = true
        },

        confusion = {
            message = "dance... GROOVE!",
            sanity = -10,
            confusion = true
        },

        piss = {
            message = "Take warm gnome piss, you GNOLL!",
            sanity = -3,
            wetness = 30
        },

        heal = {
            message = "A little gnome blessing...",
            sanity = 10,
            health = 20
        },

        freeze = {
            message = "Brrr... the ancient frost gnomes are near.",
            sanity = -3,
            temperature = -90
        },

        overheat = {
            message = "The fire gnomes demand SWEAT!",
            sanity = -3,
            temperature = 90
        }
    }
}
