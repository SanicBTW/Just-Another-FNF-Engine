import { Room, Client, generateId } from "colyseus";
import { VersusRoomState } from "./schema/VersusRoomState";

// I think is better to have if its playing as the opponent
// Instead of doing strumLine:0|1
interface PlayerData
{
    name:string;
    ready:boolean;
    isOpponent:boolean;
    status:string;

    accuracy:number;
    score:number;
    misses:number;
}

interface PocketbaseObject
{
    id:string;
    song:string;
    chart:string;
    inst:string;
    voices:string;
}

// I'm trying to base off BattleRoom, once I understand I will rewrite the code and shit
export class VersusRoom extends Room<VersusRoomState>
{
    started:boolean = false;
    songObject:PocketbaseObject = {id: "", song: "", chart: "", inst: "", voices: ""};

    player1:PlayerData = { name: 'guest', ready: false, status: '', isOpponent: false, accuracy: 0.0, score: 0, misses: 0 };
    player2:PlayerData = { name: 'guest', ready: false, status: '', isOpponent: false, accuracy: 0.0, score: 0, misses: 0 };

    maxClients: 2;

    onCreate(options: any): void | Promise<any> 
    {
        this.setState(new VersusRoomState());
        this.autoDispose = true;
        this.roomId = this.generateID();
        console.log(`Generated an ID for the room ${this.roomId}`);

        this.onMessage('set_ready', (client:Client, message:{ready:boolean}) =>
        {
            try
            {
                if (client.sessionId == this.clients[0].sessionId) this.player1.ready = message.ready;
                else this.player2.ready = message.ready;

                if (this.player1.ready && this.player2.ready)
                {
                    this.started = true;
                    this.broadcast('game_start');

                    this.player1.status = "Transitioning";
                    this.player2.status = "Transitioning";
                    this.broadcast('status_report', { p1status: this.player1.status, p2status: this.player2.status });
                }
                this.broadcast('ready_state', {p1: this.player1.ready, p2: this.player2.ready});
            }
            catch (er)
            {
                console.log(er);
            }
        });

        this.onMessage('set_song', (client:Client, message:{songObj:PocketbaseObject}) =>
        {
            this.songObject = message.songObj;
        });

        this.onMessage('report_status', (client:Client, status:string) =>
        {
            if (client.sessionId == this.clients[0].sessionId) this.player1.status = status;
            else this.player2.status = status;

            var curPlayer:string = `Player ${client.sessionId == this.clients[0].sessionId ? 1 : 2}`;
            console.log(`${curPlayer} reported a status change to ${status}`);
            
            try
            {
                this.broadcast('status_report', { p1status: this.player1.status, p2status: this.player2.status });

                // Fix song time on each client

                // Wait 2,5 sec to broadcast the beginning of the song????
                if (status == "Playing" && this.player1.status == this.player2.status)
                {
                    setTimeout(() => 
                    {
                        this.broadcast('song_start', "");
                    }, 2500);
                }
            }
            catch (er)
            {
                console.log(er);
            }
        });

        this.onMessage('set_name', (client:Client, message:{name:string}) =>
        {
            if (client.sessionId == this.clients[0].sessionId) this.player1.name = message.name;
            else
            {
                this.player2.name = message.name;
                this.broadcast('join', message.name);
            }
        });

        this.onMessage('set_stats', (client:Client, message:{accuracy:number, score:number, misses:number}) => 
        {
            if (!this.started)
                return;

            if (client.sessionId == this.clients[0].sessionId)
            {
                Object.entries(message).forEach(([prop, val]) =>
                {
                    if (prop == "accuracy")
                        val = parseFloat(val.toFixed(2));
                    Reflect.set(this.player1, prop, val);
                });
            }
            else
            {

                Object.entries(message).forEach(([prop, val]) =>
                {
                    if (prop == "accuracy")
                        val = parseFloat(val.toFixed(2));
                    Reflect.set(this.player2, prop, val);
                });
            }

            try
            {
                this.broadcast('ret_stats', {p1: this.player1, p2: this.player2});
            }
            catch (er)
            {
                console.log(er);
            }
        });
    }

    onJoin(client: Client, options?: any, auth?: any): void | Promise<any> 
    {
        console.log(`${client.sessionId} joined Versus Room`);
        
        // what the fuck is this
        if (this.clients.length != 2)
        {
            try
            {
                client.send('message', {id: this.roomId});
            }
            catch (er)
            {
                console.log(er);
            }
        }

        if (this.clients.length >= 2)
        {
            try
            {
                setTimeout(() => 
                {
                    this.clients[1].send('message', { song: this.songObject, player1: this.player1 });
                }, 2000);
            }
            catch (er)
            {
                console.log(er);
            }
        }
    }

    onLeave(client: Client, consented?: boolean): void | Promise<any> 
    {
        if (this.clients.length > 0)
        {
            if (client.sessionId == this.clients[0].sessionId && !this.started)
            {
                for (let i = 0; i < this.clients.length; i++)
                {
                    this.clients[i].leave();
                }
            }
            else
            {
                this.player2.name = "";
                this.player2.ready = false;
                this.broadcast('left', "player2");
                this.lock();
            }
        }
    }

    onDispose(): void | Promise<any> 
    {
        console.log(`Disposed room ${this.roomId}`);
    }

    // Straight up copied from FNFNet BattleRoom
    generateID()
    {
        var chars:string = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJLKMNOPQRSTUVWXYZ123456789#';
        var newID:string = '';
        for (var i = 0; i < 5; i++)
        {
            newID += chars[Math.floor(Math.random() * (chars.length - 1 + 1) + 0)];
        }
        return newID;
    }
}