functor
import
    GUI
    Input
    PlayerManager
    System
define
    PortGUI
    PortsPlayers
    InitPlayers
    TurnByTurn
    PlayersLeft
    Broadcast
in

    
    fun {InitPlayers}

        %Create record with a feature for each remaining player
        fun {InitPlayersLeft ID PLeft}
            if Input.nbPlayer >= ID then
                {InitPlayersLeft ID+1  {Adjoin f(ID:ID) PLeft}}
            else
                PLeft
            end
        end

        %Create a port for each player
        fun {InitPortsPlayers ID}
            if Input.nbPlayer >= ID then
                {PlayerManager.playerGenerator {List.nth Input.players ID} {List.nth Input.colors ID} ID}|{InitPortsPlayers ID+1}
            else
                nil
            end
        end

        %Initialise the game
        proc {Init PortsPlayers}
            case PortsPlayers of H|T then
                ID Position Direction Pos
                
            in
                {Send H initPosition(ID Position)}
                {Wait ID}
                {Wait Position}
                {Send PortGUI initPlayer(ID Position)}
                {Init T}
            [] _ then skip
            end
        end
    in
        PortsPlayers = {InitPortsPlayers 1}
        PlayersLeft = {InitPlayersLeft 1 f()}
        {Init}
    end

    %Broadcast msg to everyone
    proc {Broadcast Type PPorts ID Direction KindItem Position Drone}
        case PPorts of H|T then
            case Type of nil then skip
            [] saySurface then
                {Send H saySurface(ID)}
            [] sayMove then
                {send H sayMove(ID Direction)}
            end
            {Broadcast Type PPorts ID Direction KindItem Position Drone}
        [] then nil
        end
    end

    proc {TurnByTurn Current PLeft}
        {Delay Input.guiDelay}
        if {Record.width PLeft} > 1 then
            ID Position Direction
        in
            if Current =< Input.nbPlayer then
                {Send {List.nth PortsPlayers Current} move(ID Position Direction)}
                {Wait ID}
                {Wait Position}
                {Wait Direction}
                if Direction == surface then
                    {Broadcast saySurface PortsPlayers ID Direction nil Position nil}
                    {Send PortGUI surface(ID)}
                else
                    {Send PortGUI movePlayer(ID Position)}
                end
                {TurnByTurn Current+1 PLeft}
            else
                {TurnByTurn 1 PLeft}
            end
        else
            {System.show {List.nth {Record.toList PLeft} 1}}
        end
    end

    PortGUI = {GUI.portWindow}
    {Send PortGUI buildWindow}
    
    {InitPlayers PortsPlayers}
    {TurnByTurn 1 PlayersLeft}

end
