<!DOCTYPE html>
<html lang="nl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>3F Woordenschat Battle</title>
    <script src="https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js"></script>
    <script src="https://www.gstatic.com/firebasejs/9.22.0/firebase-database-compat.js"></script>
    <style>
        body { font-family: 'Segoe UI', sans-serif; padding: 20px; background: #eef2f7; color: #333; }
        .container { max-width: 800px; margin: auto; background: white; padding: 30px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
        .hidden { display: none; }
        h2 { color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
        input, select, button, textarea { width: 100%; padding: 12px; margin: 10px 0; border: 1px solid #ccc; border-radius: 6px; font-size: 16px; }
        button { background: #3498db; color: white; border: none; cursor: pointer; font-weight: bold; }
        button:hover { background: #2980b9; }
        .admin-btn { background: #95a5a6; }
        .reset-btn { background: #e74c3c; }
        .score-list { background: #f8f9fa; padding: 15px; border-left: 5px solid #3498db; margin-top: 20px; }
        #target-word { font-size: 50px; color: #e74c3c; margin: 10px 0; text-transform: uppercase; font-weight: 800; }
        .meaning-box { background: #fff3cd; padding: 15px; border-radius: 6px; font-style: italic; border: 1px solid #ffeeba; margin-top: 10px; }
    </style>
</head>
<body>

<div class="container">
    <div id="login-screen">
        <h2>Inloggen Student</h2>
        <input type="text" id="username" placeholder="Je voornaam...">
        <select id="userclass">
            <option value="Delta">Delta</option>
            <option value="Echo">Echo</option>
            <option value="Foxtrot">Foxtrot</option>
            <option value="Lima">Lima</option>
            <option value="Mike">Mike</option>
        </select>
        <button onclick="login()">Start Spel</button>
        <button class="admin-btn" onclick="showAdmin()">Docent Dashboard (Bulk)</button>
    </div>

    <div id="admin-screen" class="hidden">
        <h2>Bulk Invoer</h2>
        <p>Plak hier je lijst. Formaat: <strong>woord[SPATIE]betekenis</strong></p>
        <textarea id="bulk-input" rows="10" placeholder="democratie staatsvorm waarbij het volk regeert"></textarea>
        <button onclick="saveWords()">Lijst Opslaan & Start</button>
        <button class="reset-btn" onclick="resetDatabase()">DATABASE RESETTEN</button>
        <button onclick="location.reload()">Terug</button>
    </div>

    <div id="game-screen" class="hidden">
        <h3 id="welcome-msg"></h3>
        <div id="role-status" style="font-weight: bold; padding: 10px; border-radius: 4px;">Wachten op ronde...</div>
        <hr>
        
        <div id="describer-view" class="hidden">
            <p>Jij moet dit woord omschrijven aan de klas:</p>
            <div id="target-word">---</div>
            <div class="meaning-box">
                <strong>Betekenis:</strong> <span id="target-meaning"></span>
            </div>
        </div>

        <div id="guesser-view" class="hidden">
            <p>Raad het woord (spelling telt!):</p>
            <input type="text" id="guess-input" placeholder="Type je antwoord hier...">
            <button onclick="checkGuess()">Verstuur</button>
        </div>

        <hr>
        <h4>Tussenstand:</h4>
        <div id="score-display" class="score-list"></div>
    </div>
</div>

<script>
    // Firebase Configuratie
    const firebaseConfig = {
        apiKey: "AIzaSyCJ5of6K5MRFXMOiEqEyZxZbs1xoJtXuN8",
        authDomain: "pvaangifteinleveren.firebaseapp.com",
        databaseURL: "https://pvaangifteinleveren-default-rtdb.europe-west1.firebasedatabase.app",
        projectId: "pvaangifteinleveren",
        storageBucket: "pvaangifteinleveren.firebasestorage.app",
        messagingSenderId: "989190242332",
        appId: "1:989190242332:web:867ea95845325cf9835fd9"
    };

    firebase.initializeApp(firebaseConfig);
    const db = firebase.database();

    let myName = "";
    let myClass = "";

    function showAdmin() {
        document.getElementById('login-screen').classList.add('hidden');
        document.getElementById('admin-screen').classList.remove('hidden');
    }

    function login() {
        myName = document.getElementById('username').value.trim();
        myClass = document.getElementById('userclass').value;
        if(!myName) return alert("Vul je naam in!");

        document.getElementById('login-screen').classList.add('hidden');
        document.getElementById('game-screen').classList.remove('hidden');
        document.getElementById('welcome-msg').innerText = `Speler: ${myName} (${myClass})`;

        db.ref('players/' + myName).set({ name: myName, class: myClass, score: 0 });
        listenToGame();
    }

    function saveWords() {
        const text = document.getElementById('bulk-input').value;
        const lines = text.split('\n');
        let words = [];

        lines.forEach(line => {
            const trimLine = line.trim();
            const firstSpace = trimLine.indexOf(' ');
            if (firstSpace !== -1) {
                const w = trimLine.substring(0, firstSpace).trim();
                const m = trimLine.substring(firstSpace).trim();
                words.push({ w: w, m: m });
            }
        });

        if(words.length > 0) {
            db.ref('wordlist').set(words);
            db.ref('usedIndices').set([]);
            alert(words.length + " woorden geladen!");
            pickNewRound();
        }
    }

    function pickNewRound() {
        db.ref('wordlist').once('value', snapshot => {
            const allWords = snapshot.val();
            db.ref('players').once('value', pSnap => {
                const players = Object.keys(pSnap.val() || {});
                if(players.length === 0) return alert("Nog geen spelers!");

                const randomWordIdx = Math.floor(Math.random() * allWords.length);
                const randomPlayer = players[Math.floor(Math.random() * players.length)];
                const selected = allWords[randomWordIdx];

                db.ref('currentRound').set({
                    word: selected.w,
                    meaning: selected.m,
                    describer: randomPlayer,
                    startTime: Date.now()
                });
            });
        });
    }

    function listenToGame() {
        // Update scores
        db.ref('players').on('value', snap => {
            const data = snap.val();
            let html = "";
            for(let p in data) {
                html += `<div>${data[p].name} (${data[p].class}): <strong>${data[p].score}</strong></div>`;
            }
            document.getElementById('score-display').innerHTML = html;
        });

        // Update ronde
        db.ref('currentRound').on('value', snap => {
            const round = snap.val();
            if(!round) return;

            const isDescriber = (round.describer === myName);
            const statusBox = document.getElementById('role-status');
            
            if(isDescriber) {
                statusBox.innerText = "JIJ BENT DE OMSCHRIJVER";
                statusBox.style.background = "#e74c3c";
                statusBox.style.color = "white";
                document.getElementById('describer-view').classList.remove('hidden');
                document.getElementById('guesser-view').classList.add('hidden');
                document.getElementById('target-word').innerText = round.word;
                document.getElementById('target-meaning').innerText = round.meaning;
            } else {
                statusBox.innerText = `${round.describer} is aan het omschrijven...`;
                statusBox.style.background = "#27ae60";
                statusBox.style.color = "white";
                document.getElementById('describer-view').classList.add('hidden');
                document.getElementById('guesser-view').classList.remove('hidden');
                document.getElementById('guess-input').value = "";
                document.getElementById('guess-input').focus();
            }
        });
    }

    function checkGuess() {
        const guess = document.getElementById('guess-input').value.trim().toLowerCase();
        db.ref('currentRound/word').once('value', snap => {
            if(guess === snap.val().toLowerCase()) {
                alert("GOED! +3 punten");
                db.ref('players/' + myName + '/score').transaction(s => (s || 0) + 3);
                pickNewRound();
            } else {
                alert("Helaas, probeer het nog eens.");
            }
        });
    }

    function resetDatabase() {
        if(confirm("Database volledig leegmaken voor een nieuwe les?")) {
            db.ref('/').remove();
            location.reload();
        }
    }
</script>

</body>
</html>
