const mongoose = require('mongoose');

const playerSchema = new mongoose.Schema({
    nickname: {
        trim: true,
        type: String
    },
    socketID: {
            type: String,
    },
    isPartyLeader: {
            default: false,
            type: Boolean,
    },
    points: {
        type: Number,
        default: 0
    }
});

const playerModel = mongoose.model('Player', playerSchema);
module.exports = {playerModel, playerSchema};
