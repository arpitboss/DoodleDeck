const mongoose = require('mongoose');
const {playerSchema} = require('../models/player_model');

const roomSchema = new mongoose.Schema({
    word: {
        required: true,
        type: String
    },
    name: {
            required: true,
            type: String,
            unique: true,
            trim: true
    },
    occupancy: {
            required: true,
            type: Number,
            default: 4
    },
    maxRounds: {
            required: true,
            type: Number
    },
    currentRound: {
            required: true,
            type: Number,
            default: 1
    },
    players: [playerSchema],
    canJoin: {
             type: Boolean,
             default: true
    },
    turn: playerSchema,
    turnIndex: {
             type: Number,
             default: 0
    }
});

const roomModel = mongoose.model('Room', roomSchema);
module.exports = roomModel;