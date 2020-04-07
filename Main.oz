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
    SurfaceStatus
    RecordWeapons
    Broadcast

in

    
    fun {InitPlayers}

        %Create record with a feature for each remaining player
        fun {InitRecord ID Value Rec}
            if Input.nbPlayer >= ID then
                {InitRecord ID+1  Value {Adjoin f(ID:Value) Rec}}
            else
                Rec
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
        PlayersLeft = {InitRecord 1 1 f()}
        SurfaceStatus = {InitRecord 1 ~1 f()}
        RecordWeapons = {InitRecord 1 weapons(mine:0 missile:0 drone:0 sonar:0) players()}
        {Init}
    end

    %Broadcast msg to everyone
    proc {Broadcast Type PPorts ID Direction KindItem Position Drone}
        case PPorts of H|T then
            case Type of nil then skip
            [] saySurface then
                {Send H saySurface(ID)}
            [] sayMove then
                {Send H sayMove(ID Direction)}
            end
            {Broadcast Type T ID Direction KindItem Position Drone}
        [] nil then skip
        end
    end

    proc {TurnByTurn Current PLeft SStatus FirstTurn TrackWeapons}
        {Delay Input.guiDelay}
        
        if {Record.width PLeft} > 1 then
            ID Position Direction KindFire 
        in
            %Check if correct player ID
            if Current =< Input.nbPlayer then
                %Check surface countdown
                if SStatus.Current =< 0 then

                    %Dive if surface
                    if FirstTurn orelse SStatus.Current == 0 then
                        {Send {List.nth PortsPlayers Current} dive()}
                    end
                    
                    %Move
                    {Send {List.nth PortsPlayers Current} move(ID Position Direction)}
                    if Direction == surface then
                        %{Broadcast saySurface PortsPlayers ID Direction nil Position nil}
                        {Send PortGUI surface(ID)}
                        {TurnByTurn Current+1 PLeft {Adjoin SStatus f(Current:Input.turnSurface-1)} FirstTurn TrackWeapons}
                    else
                        {Send PortGUI movePlayer(ID Position)}

                        %Charge items
                        {System.show chargeputain}
                        {Send {List.nth PortsPlayers Current} chargeItem(ID KindFire)}
                        case KindFire of nil then skip
                        [] missile then
                            {System.show missilecharged}
                        [] drone then
                            {System.show dronecharged}
                        [] sonar then
                            {System.show sonarcharged}
                        [] mine then
                            {System.show minecharged}
                        end

                        case KindFire of nil then
                            {TurnByTurn Current+1 PLeft {Adjoin SStatus f(Current:~1)} FirstTurn TrackWeapons}
                        [] _ then
                            {TurnByTurn Current+1 PLeft {Adjoin SStatus f(Current:~1)} FirstTurn {Adjoin TrackWeapons players(Current:{Adjoin TrackWeapons.Current weapons(KindFire:TrackWeapons.Current.KindFire + 1)})}}
                        end
                    end
                else
                    {TurnByTurn Current+1 PLeft {Adjoin SStatus f(Current:SStatus.Current - 1)} FirstTurn TrackWeapons}
                end
            else
                {System.show TrackWeapons}
                {TurnByTurn 1 PLeft SStatus false TrackWeapons}
            end
        else
            {System.show {List.nth {Record.toList PLeft} 1}}
        end
    end

    PortGUI = {GUI.portWindow}
    {Send PortGUI buildWindow}
    
    {InitPlayers PortsPlayers}
    {TurnByTurn 1 PlayersLeft SurfaceStatus true RecordWeapons}

end
