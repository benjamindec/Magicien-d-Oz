functor
import
    GUI
    Input
    OS
    PlayerManager
    System
define
    PortGUI
    PortsPlayers
    InitPlayers
    LaunchGame
    PlayersLeft
    SurfaceStatus
    RecordWeapons
    RecordMines
    Remaining
    BroadcastProc
    BroadcastFun
    HowMuchAlive

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
                {Send PortGUI initPlayer(ID Position)}
                {Init T}
            [] _ then skip
            end
        end
    in
        PortsPlayers = {InitPortsPlayers 1}
        PlayersLeft = {InitRecord 1 Input.maxDamage f()}
        SurfaceStatus = {InitRecord 1 ~1 f()}
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
            Message Answer
        in
            {Send H isDead(Answer)}
            case Type of nil then skip
            [] sayMissileExplode andthen {Not Answer} then
                {Send H sayMissileExplode(ID Position Message)}
            [] sayMineExplode andthen {Not Answer} then
                {Send H sayMineExplode(ID Position Message)}
            [] _ then
                Message = null
            end
            {BroadcastFun Type T ID Direction KindItem Position Message|Status}
        [] nil then Status
        end
    end

    fun {HowMuchAlive PPorts Nb}
        Answer
    in
        case PPorts of H|T then
            
            {Send H isDead(Answer)}
            case Answer of false then
                {HowMuchAlive T Nb + 1}
            [] true then
                {HowMuchAlive T Nb}
            [] _ then 
                {HowMuchAlive PPorts Nb}
            end
        [] nil then 
            Nb
        end
    end

    proc {Remaining Messages PPorts}
        case Messages of H|T then
            case H of null then 
                {Remaining T PPorts}
            [] sayDamageTaken(ID Damage LifeLeft) then
                TmpID = ID.id Temp
            in
                {Send PortGUI lifeUpdate(ID LifeLeft)}
                {BroadcastProc sayDamageTaken PPorts ID nil nil nil nil nil Damage LifeLeft}
                %Temp = {Adjoin Players f( TmpID : LifeLeft )}
                {Remaining T PPorts}
                
            [] sayDeath(ID) then
                {BroadcastProc sayDeath PPorts ID nil nil nil nil nil nil nil}
                {Send PortGUI removePlayer(ID)}
                {Remaining T PPorts}
            end
        [] nil then
            skip
        end
    end

    proc {LaunchGame Current SStatus FirstTurn Count}
        Answer Victory Suicide 
    in
        if Current =< Input.nbPlayer then
            
            {Send {List.nth PortsPlayers Current} isDead(Answer)}
            Victory = {HowMuchAlive PortsPlayers 0}
            if Victory > 1 then
                ID Position Direction KindAim KindFire Next Mine PLeftMissiles PLeftMines 
            in 
                
                if Input.isTurnByTurn then
                    Next = Current + 1
                    {Delay Input.guiDelay}
                else
                    Next = Current
                    {Delay (({OS.rand} mod (Input.thinkMax - Input.thinkMin)) + Input.thinkMin)}
                end
                %Check surface countdown
                
                if (SStatus.Current =< 0 orelse {Not Input.isTurnByTurn}) then
                    
                    %Dive if surface
                    if FirstTurn orelse SStatus.Current == 0 then
                        {Send {List.nth PortsPlayers Current} dive()}
                    end
                    %Move
                    if (Input.isTurnByTurn andthen {Not Answer}) orelse {Not Answer} then
                        {Send {List.nth PortsPlayers Current} move(ID Position Direction)}
                    
                        if Direction == surface then
                            {Send PortGUI surface(ID)}
                            {BroadcastProc saySurface PortsPlayers ID Direction nil Position nil nil nil nil}
                            
                            if {Not Input.isTurnByTurn} then
                                {Delay Input.turnSurface * 1000}
                            end
                            {LaunchGame Next {Adjoin SStatus f(Current:Input.turnSurface-1)} FirstTurn Count+1}
                        else
                            {Send PortGUI movePlayer(ID Position)}
                        
                        
                            {BroadcastProc sayMove PortsPlayers ID Direction nil Position nil nil nil nil}
                        
                            %Charge item
                            {Send {List.nth PortsPlayers Current} chargeItem(ID KindAim)}
                            case KindAim of null then skip
                            [] missile then
                                {BroadcastProc sayCharge PortsPlayers ID nil KindAim nil nil nil nil nil}
                            [] drone then
                                {BroadcastProc sayCharge PortsPlayers ID nil KindAim nil nil nil nil nil}
                            [] sonar then
                                {BroadcastProc sayCharge PortsPlayers ID nil KindAim nil nil nil nil nil}
                            [] mine then
                                {BroadcastProc sayCharge PortsPlayers ID nil KindAim nil nil nil nil nil}
                            end

                            %Fire item
                            {Send {List.nth PortsPlayers Current} fireItem(ID KindFire)}
                            case KindFire of null then skip
                            [] missile(pt(x:X y:Y)) then
                                MessagesMissiles
                            in
                                MessagesMissiles = {BroadcastFun sayMissileExplode PortsPlayers ID nil nil pt(x:X y:Y) nil}
                                %Handle death by missile
                                {Remaining MessagesMissiles PortsPlayers}
                            [] mine(pt(x:X y:Y)) then
                                {Send PortGUI putMine(ID pt(x:X y:Y))}
                                {BroadcastProc sayMinePlaced PortsPlayers ID nil nil nil nil nil nil nil}
                            [] drone(row X) then
                                {BroadcastProc sayPassingDrone PortsPlayers ID nil nil nil drone(row X) {List.nth PortsPlayers Current} nil nil}
                            [] drone(column Y) then
                                {BroadcastProc sayPassingDrone PortsPlayers ID nil nil nil drone(column Y) {List.nth PortsPlayers Current} nil nil}
                            [] sonar then
                                {BroadcastProc sayPassingSonar PortsPlayers ID nil nil nil nil {List.nth PortsPlayers Current} nil nil}
                            end
                            {Send {List.nth PortsPlayers Current} isDead(Suicide)}

                            if {Not Suicide} then

                                %Fire mine
                                {Send {List.nth PortsPlayers Current} fireMine(ID Mine)}
                                case Mine of pt(x:X y:Y) then
                                    MessagesMines
                                in
                                    {Send PortGUI removeMine(ID Mine)}
                                    MessagesMines = {BroadcastFun sayMineExplode PortsPlayers ID nil nil pt(x:X y:Y) nil}
                                    %Handle death by mine
                                    {Remaining MessagesMines PortsPlayers}
                                [] _ then
                                    skip
                                end
                            end
                            {LaunchGame Next {Adjoin SStatus f(Current:~1)} FirstTurn Count+1}
                        end
                    else
                        {LaunchGame Next {Adjoin SStatus f(Current:SStatus.Current - 1)} FirstTurn Count+1}
                    end
                else
                    {LaunchGame Next {Adjoin SStatus f(Current:SStatus.Current - 1)} FirstTurn Count+1}
                end
            else
                Answ
            in
                {Send {List.nth PortsPlayers Current} isDead(Answ)}
                if {Not Answ} andthen Victory == 1 andthen {Not Input.isTurnByTurn}  then
                    {System.show [victoire Current Count]}
                else
                    if Victory == 0 andthen {Not Input.isTurnByTurn} then 
                        {System.show draw}
                    end
                end

                if Input.isTurnByTurn then
                    if Current == 1 then
                        {System.show [victoire Input.nbPlayer]}
                    else
                        {System.show [victoire Current-1]}
                    end
                end
            end
        else
            {LaunchGame 1 SStatus false Count+1}
        end
    end

    PortGUI = {GUI.portWindow}
    {Send PortGUI buildWindow}
    
    {InitPlayers PortsPlayers}
    if Input.isTurnByTurn then
        {LaunchGame 1 SurfaceStatus true 0}
    else 
        proc {LaunchSimultaneous PlayerID SurfaceS}
            if PlayerID =< Input.nbPlayer then
                thread
                    {LaunchGame PlayerID SurfaceS true 0}
                end
                {LaunchSimultaneous PlayerID+1 SurfaceS}
            else
                skip
            end
        end
    in
        {LaunchSimultaneous 1 SurfaceStatus}
    end

end
