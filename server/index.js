const express = require('express');
const app = express();
const cors = require('cors');
var http = require('http');
const port = process.env.PORT || 3000;
var server = http.createServer(app);
const mongoose = require('mongoose');
const Room = require('./models/room_model');
const getWord = require('./api/getWord');
require('dotenv').config();

var io = require('socket.io')(server);

app.use(express.json());

const DB = process.env.DB_URL;

app.use(cors({
    origin: function (origin, callback) {
        // Allow requests with no origin (like mobile apps or curl requests)
        if (!origin) return callback(null, true);

        // Allow localhost with any port
        if (/^http:\/\/localhost(:[0-9]+)?$/.test(origin)) {
            return callback(null, true);
        }

        // Add more allowed origins as needed
        const allowedOrigins = ['http://your-production-url.com', 'http://another-allowed-origin.com'];
        if (allowedOrigins.includes(origin)) {
            return callback(null, true);
        }

        // Reject the request if the origin is not allowed
        callback(new Error('Not allowed by CORS'));
    }
}));

mongoose.connect(DB).then(() => {
    console.log('Connection Successful');
}).catch((e) => {
    console.error('Database connection error:', e);
});

app.get('/check-room', async (req, res) => {
    const { name } = req.query;
    try {
        const room = await Room.findOne({ name });
        if (room) {
            res.json({ exists: true, full: !room.canJoin });
        } else {
            res.json({ exists: false, full: false });
        }
    } catch (e) {
        res.status(500).json({ error: 'Server error' });
    }
});


io.on('connection', (socket) => {
    console.log('Connected');

    // For Creating Game
    socket.on('create-game', async ({ nickname, name, occupancy, maxRounds }) => {
        try {
            const existingRoom = await Room.findOne({ name: name });
            if (existingRoom) {
                  if (existingRoom.currentRound == existingRoom.maxRounds) {
                      // Game has completed; allow recreation
                      await Room.deleteOne({ name: name });
                      console.log(`Deleted completed room: ${name}`);// Delete the completed room
                  } else {
                      // Room is still active; notify the user
                      socket.emit('notCorrectGame', 'Room already exists');
                      return;
                  }
            }
            let room = new Room();
            let word = getWord();
            room.name = name;
            room.word = word;
            room.occupancy = occupancy;
            room.maxRounds = maxRounds;
            room.currentRound = 1;
            room.players = [{
                nickname: nickname,
                socketID: socket.id,
                isPartyLeader: true
            }];
            room.canJoin = true;
            room = await room.save();
            socket.join(name);
            io.to(name).emit('updateRoom', room);
        } catch (e) {
            console.error('Error creating game:', e);
        }
    });

    // For Joining Game
    socket.on('join-game', async ({ nickname, name }) => {
        try {
            let room = await Room.findOne({ name: name });
            if (!room) {
                socket.emit('notCorrectGame', 'Room does not exist');
                return;
            }

            if (room.currentRound > room.maxRounds) {
                socket.emit('notCorrectGame', 'Room does not exist');
                return;
            }

            if (room.canJoin) {
                room.players.push({
                    nickname: nickname,
                    socketID: socket.id,
                });
                socket.join(name);
                if (room.occupancy === room.players.length) {
                    room.canJoin = false;
                }
                room.turnIndex = room.turnIndex || 0; // Default value
                room.turn = room.players[room.turnIndex] || null; // Default to null if no players
                room = await room.save();
                io.to(name).emit('updateRoom', room);
            } else {
                socket.emit('notCorrectGame', 'The game is going on! Wait for the next round');
            }
        } catch (e) {
            console.error('Error joining game:', e);
        }
    });

    // Doodling Sockets
    socket.on('paint', ({ details, roomName, tool }) => {
        io.to(roomName).emit('points', { details: details, tool: tool });
    });



    // Color Sockets
    socket.on('color-change', ({ color, roomName }) => {
        io.to(roomName).emit('color-change', color);
    });

    // Stroke Sockets
    socket.on('stroke-width', ({ value, roomName }) => {
        io.to(roomName).emit('stroke-width', value);
    });

    // Clear Sockets
    socket.on('clean-screen', (roomName) => {
        io.to(roomName).emit('clear-screen', '');
    });

    // Message Sockets
    socket.on('msg', async (data) => {
        console.log(data.toString());
        try {
            let room = await Room.findOne({ name: data.roomName });
            if (!room) {
                console.log('Room not found');
                return;
            }

            let userPlayer = room.players.find(
                (player) => player.nickname === data.username
            );

            if (userPlayer) {
                if (data.msg === data.word) {
                    if (data.timeTaken !== 0) {
                        userPlayer.points += Math.round((200 / data.timeTaken) * 10);
                    }
                    await room.save();
                    io.to(data.roomName).emit('msg', {
                        username: data.username.toString(),
                        msg: 'Guessed it right!',
                        guessedUserCount: data.guessedUserCount + 1,
                    });
                    socket.emit('closeInput', "");
                } else {
                    io.to(data.roomName).emit('msg', {
                        username: data.username.toString(),
                        msg: data.msg.toString(),
                        guessedUserCount: data.guessedUserCount,
                    });
                }
            } else {
                console.log('User player not found');
            }
        } catch (e) {
            console.error('Error handling message:', e);
        }
    });

    // Next Round
    socket.on('next-round', async (name) => {
        try {
            let room = await Room.findOne({ name: name });
            if (!room) {
                console.log('Room not found');
                return;
            }

            let index = room.turnIndex || 0; // Default value
            if (index + 1 === room.players.length) {
                room.currentRound += 1;
            }
            if (room.currentRound <= room.maxRounds) {
                const word = getWord();
                room.word = word;
                room.turnIndex = (index + 1) % room.players.length;
                room.turn = room.players[room.turnIndex] || null; // Default to null if no players
                room = await room.save();
                io.to(name).emit('next-round', room);
            } else {
                io.to(name).emit("show-leaderboard", room.players);
            }
        } catch (e) {
            console.error('Error handling next round:', e);
        }
    });

    // Update Scoreboard
    socket.on('updateScore', async (name) => {
        try {
            const room = await Room.findOne({ name });
            if (!room) {
                console.log('Room not found');
                return;
            }
            io.to(name).emit('updateScore', room);
        } catch (err) {
            console.error('Error updating scoreboard:', err);
        }
    });

    // User Disconnects
    socket.on('disconnect', async () => {
            try {
                let room = await Room.findOne({ "players.socketID": socket.id });
                if (room) {
                    // Remove player and emit updates
                    room.players = room.players.filter(player => player.socketID !== socket.id);
                    await room.save();

                    if (room.players.length === 0) {
                        // Clean up if no players left
                        await Room.deleteOne({ name: room.name });
                        console.log(`Room ${room.name} deleted as no players are left`);
                    } else {
                        io.to(room.name).emit('user-disconnected', room);
                    }
                } else {
                    console.log('Room not found, possibly because it is over');
                }
            } catch (err) {
                console.error('Error handling disconnection:', err);
            }
        });
});

server.listen(port, '0.0.0.0', () => {
    console.log('Server started and running on port ' + port);
});
