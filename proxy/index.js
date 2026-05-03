const express = require('express');
const bodyParser = require('body-parser');

const app = express();
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

app.use(cors({ origin: '*', methods: ['GET', 'POST', 'OPTIONS'], allowedHeaders: ['Content-Type', 'Authorization'], credentials: false, maxAge: 86400 }));

app.post('/bernie', (req, res) => {
    console.log(`[Request] Express: Web request`);
    if (!req.body) return res.status(200).json({ ok: true });
    console.log(req.body);
    return res.status(200).json({ ok: true });
});

async function startExpress(PORT) {
    return new Promise((resolve, reject) => {
        app.listen(PORT, '0.0.0.0', error => {
            if (error) return reject(new Error(error));
            console.log(`[Setup] Express: Listening to: ${PORT}`);
            resolve();
        });
    }).catch(error => {
        console.log(`[Error] Express: Failed to start:${error}`);
    });
}

startExpress();