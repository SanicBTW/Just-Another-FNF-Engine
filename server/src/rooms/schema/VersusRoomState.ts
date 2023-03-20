import { Schema, Context, type } from '@colyseus/schema';

// jugador jugando como bf
// jugador jugando como dad
export class VersusRoomState extends Schema
{
    // Song Metadata
    @type("string") songName:string;

    // Players
    @type("string") opponentName:String;
    @type("string") playerName:String;
}