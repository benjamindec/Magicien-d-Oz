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
    RecordMines
    Remaining
    BroadcastProc
    BroadcastFun

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
        PlayersLeft = {InitRecord 1 Input.maxDamage f()}
        SurfaceStatus = {InitRecord 1 ~1 f()}
        RecordWeapons = {InitRecord 1 weapons(mine:0 missile:0 drone:0 sonar:0) players()}
        RecordMines = {InitRecord 1 {List.make 0} mines()}
        {Init}
    end

    %Broadcast msg to everyone
    proc {BroadcastProc Type PPorts ID Direction KindItem Position Drone PortSD Damage LifeLeft}
        Answer ID2
    in
        case PPorts of H|T then
            case Type of nil then skip
            [] saySurface then
                {Send H saySurface(ID)}
            [] sayMove then
                {Send H sayMove(ID Direction)}
            [] sayCharge then
                {Send H sayCharge(ID KindItem)}
            [] sayMinePlaced then
                {Send H sayMinePlaced(ID)}
            [] sayPassingDrone then
                {Send H sayPassingDrone(Drone ?ID2 ?Answer)}
                {Send PortSD sayAnswerDrone(Drone ID2 Answer)}
            [] sayPassingSonar then
                {Send H sayPassingSonar(?ID2 ?Answer)}
                {Send PortSD sayAnswerSonar(ID2 Answer)}
            [] sayDamageTaken then
                {Send H sayDamageTaken(ID Damage LifeLeft)}
            [] sayDeath then
                {Send H sayDeath(ID)}
            end
            {BroadcastProc Type T ID Direction KindItem Position Drone PortSD Damage LifeLeft}
        [] nil then skip
        end
    end

    fun {BroadcastFun Type PPorts ID Direction KindItem Position Status}
        case PPorts of H|T then
            Message
        in
            case Type of nil then skip
            [] sayMissileExplode then
                {Send H sayMissileExplode(ID Position Message)}
            [] sayMineExplode then
                {Send H sayMineExplode(ID Position Message)}
            end
            {Wait Message}
            {BroadcastFun Type T ID Direction KindItem Position Message|Status}
        [] nil then Status
        end
    end

    fun {Remaining Messages Players PPorts}
        case Messages of H|T then
            case H of nil then 
                {Remaining T Players PPorts}
            [] sayDamageTaken(ID Damage LifeLeft) then
                TmpID = ID.id Temp
            in
                {BroadcastProc sayDamageTaken PPorts ID nil nil nil nil nil Damage LifeLeft}
                Temp = {Adjoin Players f( TmpID : LifeLeft )}
                {Remaining T  Temp PPorts}
                
            [] sayDeath(ID) then
                {BroadcastProc sayDeath PPorts ID nil nil nil nil nil nil nil}
                {System.show {Record.subtract Players ID.id}}
                {Remaining T {Record.subtract Players ID.id} PPorts}
            end
        [] nil then
            Players
        end
    end

    proc {TurnByTurn Current PLeft SStatus FirstTurn TrackWeapons TrackMines}
        {Delay Input.guiDelay}
        if {Record.width PLeft} > 1 then
            ID Position Direction KindAim KindFire TrackChargedWeapons TrackFiredWeapons TrackPlacedMine TrackExplodedMine Mine PLeftMissiles PLeftMines
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
                        {Send PortGUI surface(ID)}
                        {BroadcastProc saySurface PortsPlayers ID Direction nil Position nil nil nil nil}
                        {TurnByTurn Current+1 PLeft {Adjoin SStatus f(Current:Input.turnSurface-1)} FirstTurn TrackWeapons TrackMines}
                    else
                        {Send PortGUI movePlayer(ID Position)}
                        {BroadcastProc sayMove PortsPlayers ID Direction nil Position nil nil nil nil}

                        %Charge item
                        {Send {List.nth PortsPlayers Current} chargeItem(ID KindAim)}
                        case KindAim of nil then skip
                        [] missile then
                            %{System.show missilecharged}
                            {BroadcastProc sayCharge PortsPlayers ID nil KindAim nil nil nil nil nil}
                        [] drone then
                            %{System.show dronecharged}
                            {BroadcastProc sayCharge PortsPlayers ID nil KindAim nil nil nil nil nil}
                        [] sonar then
                            {System.show sonarcharged}
                            {BroadcastProc sayCharge PortsPlayers ID nil KindAim nil nil nil nil nil}
                        [] mine then
                            %{System.show minecharged}
                            {BroadcastProc sayCharge PortsPlayers ID nil KindAim nil nil nil nil nil}
                        end

                        case KindAim of nil then
                            TrackChargedWeapons = TrackWeapons
                        [] _ then
                            TrackChargedWeapons = {Adjoin TrackWeapons players(Current:{Adjoin TrackWeapons.Current weapons(KindAim:TrackWeapons.Current.KindAim + 1)})}
                        end


                        %Fire item
                        {Send {List.nth PortsPlayers Current} fireItem(ID KindFire)}
                        case KindFire of nil then skip
                        [] missile(pt(x:X y:Y)) then
                            MessagesMissiles
                        in
                            %{System.show [missilefired X Y]}
                            MessagesMissiles = {BroadcastFun sayMissileExplode PortsPlayers ID nil nil pt(x:X y:Y) nil}
                            %Handle death by missile
                            PLeftMissiles = {Remaining MessagesMissiles PLeft  PortsPlayers}
                        [] mine(pt(x:X y:Y)) then
                            %{System.show [minelanded X Y]}
                            TrackPlacedMine = {Adjoin TrackMines mines(Current:{List.append TrackMines.Current [pt(x:X y:Y)]})}
                            {Send PortGUI putMine(ID pt(x:X y:Y))}
                            {BroadcastProc sayMinePlaced PortsPlayers ID nil nil nil nil nil nil nil}
                        [] drone(row X) then
                            {System.show [dronefired row X]}
                            {BroadcastProc sayPassingDrone PortsPlayers ID nil nil nil drone(row X) {List.nth PortsPlayers Current} nil nil}
                        [] drone(column Y) then
                            {System.show [dronefired column Y]}
                            {BroadcastProc sayPassingDrone PortsPlayers ID nil nil nil drone(column Y) {List.nth PortsPlayers Current} nil nil}
                        [] sonar then
                            {System.show sonar}
                            {BroadcastProc sayPassingSonar PortsPlayers ID nil nil nil nil {List.nth PortsPlayers Current} nil nil}
                        end


                        case KindFire of _ andthen {Record.label KindFire} \= missile then
                            PLeftMissiles = PLeft
                        [] _ then skip
                        end

                        case KindFire of nil then
                            TrackPlacedMine = TrackMines
                            TrackFiredWeapons = TrackChargedWeapons
                        [] _ then
                            Label
                        in
                            Label = {Record.label KindFire}
                            TrackFiredWeapons = {Adjoin TrackChargedWeapons players(Current:{Adjoin TrackChargedWeapons.Current weapons(Label:TrackChargedWeapons.Current.Label - 1)})}
                            if Label \= mine then
                                TrackPlacedMine = TrackMines
                            end
                        end

                        %Fire mine
                        {Send {List.nth PortsPlayers Current} fireMine(ID Mine)}
                        case Mine of pt(x:X y:Y) then
                            MessagesMines
                        in
                            TrackExplodedMine = {Adjoin TrackPlacedMine mine(Current:{List.subtract TrackPlacedMine.Current Mine})}
                            {Send PortGUI removeMine(ID Mine)}
                            MessagesMines = {BroadcastFun sayMineExplode PortsPlayers ID nil nil pt(x:X y:Y) nil}
                            %Handle death by mine
                            PLeftMines = {Remaining MessagesMines PLeftMissiles  PortsPlayers}
                        [] _ then
                            PLeftMines = PLeftMissiles
                            TrackExplodedMine = TrackPlacedMine
                        end

                        


                        {TurnByTurn Current+1 PLeftMines {Adjoin SStatus f(Current:~1)} FirstTurn TrackFiredWeapons TrackExplodedMine}

                    end
                else
                    {TurnByTurn Current+1 PLeft {Adjoin SStatus f(Current:SStatus.Current - 1)} FirstTurn TrackWeapons TrackMines}
                end
            else
                {TurnByTurn 1 PLeft SStatus false TrackWeapons TrackMines}
            end
        else
            {System.show victoire}
            {System.show PLeft}
        end
    end

    PortGUI = {GUI.portWindow}
    {Send PortGUI buildWindow}
    
    {InitPlayers PortsPlayers}
    {TurnByTurn 1 PlayersLeft SurfaceStatus true RecordWeapons RecordMines}

end
