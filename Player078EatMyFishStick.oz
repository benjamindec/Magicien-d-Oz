functor
import
    Input
    System
    OS
export
    portPlayer:StartPlayer
define
    StartPlayer
    TreatStream
    Position
    Direction
    Weapon
    Surface
    RandomPos
    RandomDir
    RandomWeapon
    TrackPlayer
    FireRandom
    MovePos
    MoveAllowed
    Visited
    FollowPrey
    OnRange
    MineOnRange
    InitTrack
    ChangePrey
    Recalibrate
    AllLocalized
in

    fun {InitTrack Players ID MyID}
        if ID =< Input.nbPlayer andthen ID \= MyID then
            {InitTrack {Adjoin Players players(ID:pt(x:0 y:0))} ID+1 MyID}
        else
            Players
        end
    end
    
    fun {RandomWeapon}
        Weapons = [mine missile]
    in
        {List.nth Weapons ({OS.rand} mod {List.length Weapons}) + 1}
    end
    
    fun {FireRandom WeaponList Weapons Position}
        RandomW Pos Coord
        fun {FirePosition InitialPos Position DistLeft}
            Coord Sign TmpPos
        in
            if DistLeft > 0 then
                Coord = ({OS.rand} mod 2)
                Sign = ({OS.rand} mod 2)
                case Coord of 0 then %Modify X
                    case Sign of 0 then %Positive
                        TmpPos = pt(x:Position.x + 1 y:Position.y)
                    [] 1 then %Negative
                        TmpPos = pt(x:Position.x - 1 y:Position.y)
                    end
                [] 1 then %Modify Y
                    case Sign of 0 then %Positive
                        TmpPos = pt(x:Position.x y:Position.y + 1)
                    [] 1 then %Negative
                        TmpPos = pt(x:Position.x y:Position.y - 1)
                    end
                end

                if TmpPos == InitialPos orelse {Not {MoveAllowed TmpPos}}then
                    {FirePosition InitialPos Position DistLeft}
                else
                    {FirePosition InitialPos TmpPos DistLeft-1}
                end
            else
                Position
            end
        end
    in
        RandomW = {List.nth WeaponList ({OS.rand} mod {List.length WeaponList}) + 1}
        if Weapons.RandomW >= Input.RandomW then
            case RandomW of mine then
                Pos = {FirePosition Position Position (({OS.rand} mod Input.maxDistanceMine) + 1)}
                mine(Pos)
            [] missile then
                Pos = {FirePosition Position Position (({OS.rand} mod Input.maxDistanceMissile) + 1)}
                missile(Pos)
            [] sonar then
                sonar
            [] drone then
                Pos = {RandomPos}
                Coord = ({OS.rand} mod 2)
                case Coord of 0 then %Row
                    drone(row Pos.x)
                [] 1 then %Column
                    drone(column Pos.y)
                end
            end
        else
            if {List.length WeaponList} > 1 then
                {FireRandom {List.subtract WeaponList RandomW} Weapons Position}
            else
                null
            end
        end
    end

    fun {RandomPos}
        X Y Xfound Yfound
    in
        X = ({OS.rand} mod Input.nRow) + 1
        Y = ({OS.rand} mod Input.nColumn) + 1
        {List.nth Input.map X ?Xfound}
        {List.nth  Xfound Y ?Yfound}
        if Yfound == 1 then
            {RandomPos}
        else
            pt(x:X y:Y)
        end
    end

    fun {RandomDir Directions Pos}
        TmpPos Ind Dir
    in
        if {List.length Directions} == 0 then
                surface
        else
            Ind = ({OS.rand} mod {List.length Directions}) + 1
            {List.nth Directions Ind ?Dir}
            TmpPos = {MovePos Pos.1 Dir}

            if {MoveAllowed TmpPos} andthen {Not {Visited TmpPos Pos}} then
                Dir
            else
                {RandomDir {List.subtract Directions Dir} Pos}
            end
        end
    end

    fun {MoveAllowed Pt}
        Xfound Yfound
    in
        if Pt.x =< Input.nRow andthen Pt.x >= 1 andthen Pt.y =< Input.nColumn andthen Pt.y >= 1 then
            {List.nth Input.map Pt.x ?Xfound}
            {List.nth  Xfound Pt.y ?Yfound}
            {Not Yfound == 1}
        else
            false
        end
    end

    fun {Visited Pt Pos}
        case Pos of H|T then
            if H == Pt then
                true
            else
                {Visited Pt T}
            end
        [] nil then
            false
        end
    end

    fun {MovePos Pt Dir}
        case Dir of nil then nil
        [] east then
            pt(x:Pt.x y:Pt.y + 1)
        [] north then
            pt(x:Pt.x - 1 y:Pt.y)
        [] south then
            pt(x:Pt.x + 1 y:Pt.y)
        [] west then
            pt(x:Pt.x y:Pt.y - 1)
        [] surface then
            Pt
        end
    end

    fun {TrackPlayer Players ID Dir Remaining}
        if {Value.hasFeature Players ID} andthen {Record.width Players} == Remaining-1  andthen Players.ID.x \= 0 then
            case Dir of surface then Players
            [] south andthen (Players.ID.x + 1) =< Input.nRow then {Adjoin Players players(ID:pt(x:Players.ID.x + 1 y:Players.ID.y))}
            [] north andthen (Players.ID.x - 1) >= 1 then {Adjoin Players players(ID:pt(x:Players.ID.x - 1 y:Players.ID.y))}
            [] east andthen (Players.ID.y + 1) =< Input.nColumn then {Adjoin Players players(ID:pt(x:Players.ID.x y:Players.ID.y + 1))}
            [] west andthen (Players.ID.y - 1) >= 1 then {Adjoin Players players(ID:pt(x:Players.ID.x y:Players.ID.y - 1))}
            [] _ then Players
            end
        else
            {Adjoin Players player(ID:pt(x:0 y:0))}
        end
    end

    fun {FollowPrey Prey Players MyPos Directions Count Believe MyID}
        TmpPos Ind Dir DirTmp ManDist = {Abs (MyPos.1.x - Players.Prey.x)} + {Abs (MyPos.1.y - Players.Prey.y)}
    in
        
        if {Value.hasFeature Players Prey} andthen Count =< 5 then
            if {List.length Directions} == 0 then
                surface
            else
                %NEW
                
                if Believe.Prey.x == 0 orelse Believe.Prey.x == 1 then
                    PosX DirX X
                in
                    X = MyPos.1.x - Players.Prey.x
                    if X >= 2 andthen ManDist >=2 then
                        if X < 0 then
                            DirX = south
                        else
                            DirX = north
                        end
                        PosX = {MovePos MyPos.1 DirX}
                        if {MoveAllowed PosX} andthen {Not {Visited PosX MyPos}} then
                            Dir = DirX
                        end
                    end
                end

                if (Believe.Prey.y == 0 orelse Believe.Prey.y == 1) andthen {Not {Value.isDet Dir}} then
                    PosY DirY Y
                in
                    Y = MyPos.1.y - Players.Prey.y
                    if Y >= 2 andthen ManDist >= 2 then
                        if Y < 0 then
                            DirY = east
                        else
                            DirY = west
                        end
                        PosY = {MovePos MyPos.1 DirY}
                        if {Not {Value.isDet Dir}} andthen {MoveAllowed PosY} andthen {Not {Visited PosY MyPos}} then
                            Dir = DirY
                        end
                    end
                end
                if {Not {Value.isDet Dir}} then
                    Dir = random
                end
                case Dir of north then
                    Dir
                [] south then
                    Dir
                [] east then
                    Dir
                [] west then
                    Dir
                [] random then
                    DirF
                in
                    Ind = ({OS.rand} mod {List.length Directions}) + 1
                    {List.nth Directions Ind ?DirF}
                    TmpPos = {MovePos MyPos.1 DirF}

                    if {MoveAllowed TmpPos} andthen {Not {Visited TmpPos MyPos}} then
                        DirF
                    else
                        {FollowPrey Prey Players MyPos {List.subtract Directions DirF} Count+1 Believe MyID}
                    end  
                end

                   
            end
        else
            {RandomDir Directions MyPos}
        end
    end

    fun {OnRange Players ID MyPos MyID Believe}
        Dist
    in
        if MyID \= ID andthen {Record.width Players} > 0  andthen ID =< Input.nbPlayer andthen {Value.hasFeature Players ID} andthen Players.ID.x \= 0 andthen ( (Believe.ID.x == 0  andthen Believe.ID.y == 0) orelse (Believe.ID.x == 1  andthen Believe.ID.y == 0) orelse (Believe.ID.x == 0  andthen Believe.ID.y == 1) )then

            Dist = {Abs (MyPos.x - Players.ID.x)} + {Abs (MyPos.y - Players.ID.y)}
            if Dist =< Input.maxDistanceMissile andthen Dist > 1 then
                missile(Players.ID)
            else
                {OnRange Players ID+1 MyPos MyID Believe}
            end    
        else
            if ID > Input.nbPlayer then
                nil
            else
                {OnRange Players ID+1 MyPos MyID Believe}
            end
        end
    end

    fun {MineOnRange Players Nb Mines MyID MyPos Believe}
        fun {NearPlayer Players ID Mine MyID MyPos Believe}
            Dist MyDist
        in
            if ID \= MyID andthen {Record.width Players} > 0  andthen ID =< Input.nbPlayer andthen {Value.hasFeature Players ID} andthen Players.ID.x \= 0 andthen ( (Believe.ID.x == 0  andthen Believe.ID.y == 0) orelse (Believe.ID.x == 1  andthen Believe.ID.y == 0) orelse (Believe.ID.x == 0  andthen Believe.ID.y == 1) )  then
                Dist = {Abs (Mine.x - Players.ID.x)} + {Abs (Mine.y - Players.ID.y)}
                MyDist = {Abs (Mine.x - MyPos.x)} + {Abs (Mine.y - MyPos.y)}
                if Dist =< 1 andthen MyDist > 1 then
                    true
                else
                    {NearPlayer Players ID+1 Mine MyID MyPos Believe}
                end
            
            else
                MyDist = {Abs (Mine.x - MyPos.x)} + {Abs (Mine.y - MyPos.y)}
                if {List.length Mines} > 4 andthen MyDist > 1 then
                    true
                else
                    false
                end
            end
        end
    in
        if {List.length Mines} > 0 andthen Nb =< {List.length Mines} then
            case {NearPlayer Players 1 {List.nth Mines Nb} MyID MyPos Believe} of true then
                {List.nth Mines Nb}
            [] false then {MineOnRange Players Nb+1 Mines MyID MyPos Believe}
            end
        else
            null
        end
    end

    fun {ChangePrey Prey Believe Id MyId Players Mort}

        if Id =< Input.nbPlayer then
            X Y
        in  
            
            if MyId \= Id andthen {Value.hasFeature Players Id} then
                if Believe.Prey.x > Believe.Id.x then
                    X = 1
                else
                    X = 0
                end

                if Believe.Prey.y > Believe.Id.y then
                    Y = 1
                else
                    Y = 0
                end

                if (Y+X) == 2 then
                    Id
                else
                    if (Id \= Mort) then
                        Id
                    else
                        {ChangePrey Prey Believe Id+1 MyId Players Mort}
                    end
                end
            else
                
                {ChangePrey Prey Believe Id+1 MyId Players Mort}
                  
            end
        else
            Prey
        end
    end

    fun {Recalibrate ID Answer Players Believe}
        XB YB XP YP
    in
        if {Value.hasFeature Players ID} then
            if Players.ID.x \= Answer.x andthen Believe.ID.x > 0 then
                if Believe.ID.x < 2 then
                    XB = Believe.ID.x + 1
                else
                    XB = 2
                end
                
            else
                XB = 0
            end
            if Believe.ID.x == 0 then
                XP = Players.ID.x
            else
                XP = Answer.x
            end
            

            if Players.ID.y \= Answer.y andthen Believe.ID.y > 0 then
                if Believe.ID.y < 2 then
                    YB = Believe.ID.x + 1
                else
                    YB = 2
                end
                
            else
                YB = 0
            end
            if Believe.ID.y == 0 then
                YP = Players.ID.y
            else
                YP = Answer.y
            end

            return(1: {Adjoin Players players(ID:pt(x:XP y:YP))} 2: {Adjoin Believe info(ID:pt(x:XB y:YB))})
        else
            return(1: Players 2:Believe)
        end

    end

    fun {AllLocalized Believe Count MyId}
        if Count =< Input.nbPlayer then
            if MyId \= Count then
                if Believe.Count.x \= 0 orelse Believe.Count.y \= 0 then
                    false
                else
                    {AllLocalized Believe Count+1 MyId}
                end
            else
                {AllLocalized Believe Count+1 MyId}
            end
        else
            true
        end

    end

    
    proc{TreatStream Stream ID Position Weapons Surface Direction Mines Life Players Prey Item Believe Step SDTime Remaining LastExplosion} % as as many parameters as you want
        
        case Stream of nil then skip
        [] initPosition(?ID2 ?Pos)|T andthen {Not Surface} then
            Pos = {RandomPos}
            ID2 = ID
            {TreatStream T ID2 Pos|Position Weapons Surface Direction Mines Life Players Prey Item Believe Step SDTime Remaining LastExplosion}
        [] move(?ID2 ?Pos ?Dir)|T andthen {Not Surface}  then
            
            if Prey == nil then
                Dir = {RandomDir [north east south west] Position}
            else
                Dir = {FollowPrey Prey Players Position [north east south west] 0 Believe ID.id}
            end
            Pos = {MovePos Position.1 Dir}
            ID2 = ID
            
            if Dir == surface then
                {TreatStream T ID2 Pos|nil Weapons true Dir|Direction Mines Life Players Prey Item Believe Step SDTime Remaining LastExplosion}
            else
                {TreatStream T ID2 Pos|Position Weapons Surface Dir|Direction Mines Life Players Prey Item Believe Step SDTime Remaining LastExplosion} 
            end
        [] dive()|T then
            {TreatStream T ID Position Weapons false Direction Mines Life Players Prey Item Believe Step SDTime Remaining LastExplosion}
        [] chargeItem(?ID2 ?KindItem)|T andthen {Not Surface}  then
            Charge TmpW NextStep CurrentStep NewSDTime
        in
            ID2 = ID
            if SDTime >= (Input.drone + Input.sonar)*3 andthen {Not {AllLocalized Believe 1 ID.id}} then
                NewSDTime = 0
                CurrentStep = 1
            else
                CurrentStep = Step
                NewSDTime = SDTime + 1
            end
            
            case CurrentStep of 1 then
                TmpW = sonar
            [] 2 then
                TmpW = drone
            [] 3 then
                if Item == nil orelse (Weapons.Item mod Input.Item) == 0 then
                    if Weapons.missile >= (Input.missile) then
                        TmpW = mine
                    else
                        TmpW = missile
                    end
                else
                    TmpW = Item
                end
            end
            
            Charge = {Adjoin Weapons weapons(TmpW:Weapons.TmpW + 1)}
            if Charge.TmpW > 0 andthen (Charge.TmpW mod Input.TmpW) == 0 then
                KindItem = TmpW
            else
                KindItem = null
            end
            {TreatStream T ID2 Position Charge Surface Direction Mines Life Players Prey TmpW Believe CurrentStep NewSDTime Remaining LastExplosion}
        [] fireItem(?ID2 ?KindFire)|T andthen {Not Surface}  then
            Charge Label NewMines NextStep 
        in
            ID2 = ID
            
            case Step of 1 then
                if Weapons.sonar >= Input.sonar then
                    KindFire = sonar
                    NextStep = Step + 1
                else
                    KindFire = null
                    NextStep = Step
                end
                NewMines = Mines
            [] 2 then
                if Weapons.drone >= Input.drone then
                    if Believe.Prey.x == 1 then
                        KindFire = drone(column Players.Prey.x)
                    else
                        KindFire = drone(row Players.Prey.y)
                    end
                    NextStep = Step + 1
                else
                    KindFire = null
                    NextStep = Step
                end
                NewMines = Mines
            [] 3 then
                if Weapons.missile >= Input.missile andthen {OnRange Players 1 Position.1 ID.id Believe} \= nil then
                    KindFire = {OnRange Players 1 Position.1 ID.id Believe} 
                    NewMines = Mines
                else
                    if Weapons.mine >= Input.mine then
                        
                        KindFire = {FireRandom [mine] Weapons Position.1}
                        
                        NewMines = {List.append Mines [pt(x:KindFire.1.x y:KindFire.1.y)]}
                    else
                        NewMines = Mines
                        KindFire = null
                    end
                end
                NextStep = Step
            end
            

            if {Record.label KindFire} == null then
                {TreatStream T ID2 Position Weapons Surface Direction Mines Life Players Prey Item Believe NextStep SDTime Remaining LastExplosion}
            else
                Label = {Record.label KindFire}
                Charge = {Adjoin Weapons weapons(Label:Weapons.Label - Input.Label)}
                {TreatStream T ID2 Position Charge Surface Direction NewMines Life Players Prey Item Believe NextStep SDTime Remaining LastExplosion}
            end
        [] fireMine(?ID2 ?Mine)|T andthen {Not Surface}  then
            NewMines
        in
            ID2 = ID
            case {MineOnRange Players 1 Mines ID.id Position.1 Believe} of pt(x:X y:Y) then
                Mine = pt(x:X y:Y)
                NewMines = {List.subtract Mines Mine}
            [] null then
                NewMines = Mines
                Mine = null
            end
            {TreatStream T ID2 Position Weapons Surface Direction NewMines Life Players Prey Item Believe Step SDTime Remaining LastExplosion}
        [] isDead(?Answer)|T then
            if Life =< 0 then
                Answer = true
            else
                Answer = false
            end
            {TreatStream T ID Position Weapons Surface Direction Mines Life Players Prey Item Believe Step SDTime Remaining LastExplosion}
        [] sayMove(ID2 Dir)|T then
            if ID2.color \= ID.color then
                NewPlayers
            in
                if {Record.width Players} \= Remaining-1 then
                    Tmp = {InitTrack Players 1 ID.id}
                in
                    NewPlayers = {TrackPlayer Tmp ID2.id Dir Remaining}
                else
                    NewPlayers = {TrackPlayer Players ID2.id Dir Remaining}
                end
                {TreatStream T ID Position Weapons Surface Direction Mines Life NewPlayers Prey Item Believe Step SDTime Remaining LastExplosion}
            else
                {TreatStream T ID Position Weapons Surface Direction Mines Life Players Prey Item Believe Step SDTime Remaining LastExplosion}
            end
        [] saySurface(ID2)|T then
            {TreatStream T ID Position Weapons Surface Direction Mines Life Players Prey Item Believe Step SDTime Remaining LastExplosion}
        [] sayCharge(ID2 KindItem)|T then
            {TreatStream T ID Position Weapons Surface Direction Mines Life Players Prey Item Believe Step SDTime Remaining LastExplosion}
        [] sayMinePlaced(ID2)|T then
            {TreatStream T ID Position Weapons Surface Direction Mines Life Players Prey Item Believe Step SDTime Remaining LastExplosion}
        [] sayMissileExplode(ID2 Pos ?Message)|T then
            Dist HP 
        in
            Dist = {Abs (Pos.x - Position.1.x)} + {Abs (Pos.y - Position.1.y)}
            case Dist of 0 then
                HP = Life - 2
                if HP > 0 then
                    Message = sayDamageTaken(ID 1 HP)
                else
                    Message = sayDeath(ID)
                end
            [] 1 then
                HP = Life - 1
                if HP > 0 then
                    Message = sayDamageTaken(ID 1 HP)
                else
                    Message = sayDeath(ID)
                end
            [] _ then
                HP = Life
                Message = null
            end
            {TreatStream T ID Position Weapons Surface Direction Mines HP Players Prey Item Believe Step SDTime Remaining Pos|LastExplosion}
            
            %Message = null
            %{TreatStream T ID Position Weapons Surface Direction Mines Life Players Prey Item}
        [] sayMineExplode(ID2 Pos ?Message)|T then
            Dist HP
        in
            
            Dist = {Abs (Pos.x - Position.1.x)} + {Abs (Pos.y - Position.1.y)}
            case Dist of 0 then
                HP = Life - 2
                if HP > 0 then
                    Message = sayDamageTaken(ID 1 HP)
                else
                    Message = sayDeath(ID)
                end
            [] 1 then
                HP = Life - 1
                if HP > 0 then
                    Message = sayDamageTaken(ID 1 HP)
                else
                    Message = sayDeath(ID)
                end
            [] _ then
                HP = Life
                Message = null
            end
            {TreatStream T ID Position Weapons Surface Direction Mines HP Players Prey Item Believe Step SDTime Remaining Pos|LastExplosion}
            
            %Message = null
            %{TreatStream T ID Position Weapons Surface Direction Mines Life Players Prey Item}
        [] sayPassingDrone(Drone ?ID2 ?Answer)|T then

            
            if Life > 0 then
                case Drone of drone(row X) then
                    if X == Position.1.x then
                        Answer = true
                    else
                        Answer = false
                    end
                [] drone(column Y) then
                    if Y == Position.1.y then
                        Answer = true
                    else
                        Answer = false
                    end
                [] _ then 
                    Answer = false
                end
                ID2 = ID
            else
                ID2 = null
                Answer = null
            end
           
            {TreatStream T ID Position Weapons Surface Direction Mines Life Players Prey Item Believe Step SDTime Remaining LastExplosion}     
        [] sayAnswerDrone(Drone ID2 Answer)|T then
            NewPlayers Id = ID2.id NewBelieve NewPrey
        in
            if ID2.color \= ID.color then
                case Drone of drone(row X) then
                    if Answer andthen Believe.Id.x == 0 then
                        NewPlayers = {Adjoin Players players(Id:pt(x:X y:Players.Id.y))}
                        NewBelieve = Believe
                    else
                        if Answer andthen (Believe.Id.x == 2 orelse Believe.Id.x == 1) then
                            NewPlayers = {Adjoin Players players(Id:pt(x:X y:Players.Id.y))}
                            NewBelieve = {Adjoin Believe info(Id:pt(x:0 y:Believe.Id.y))}
                        else

                            if {Not Answer}  then
                                NewBelieve = {Adjoin Believe info(Id:pt(x:2 y:0))}
                            else
                                NewBelieve = Believe
                            end
                            NewPlayers = Players
                        end
                    end

                [] drone(column Y) then
                    if Answer andthen Believe.Id.y == 0 then
                        NewPlayers = {Adjoin Players players(Id:pt(x:Players.Id.x y:Y))}
                        NewBelieve = Believe
                    else
                        if Answer andthen (Believe.Id.y == 2 orelse Believe.Id.y == 1) then
                            NewPlayers = {Adjoin Players players(Id:pt(x:Players.Id.x y:Y))}
                            NewBelieve = {Adjoin Believe info(Id:pt(x:Believe.Id.x y:0))}
                        else
                            if {Not Answer} then
                                NewBelieve = {Adjoin Believe info(Id:pt(x:0 y:2))}
                            else
                                NewBelieve = Believe
                            end
                            NewPlayers = Players
                        end
                    end
                [] _ then
                    NewBelieve = Believe
                    NewPlayers = Players
                end
                NewPrey = {ChangePrey Prey NewBelieve 1 ID.id NewPlayers 0}
                {TreatStream T ID Position Weapons Surface Direction Mines Life NewPlayers NewPrey Item NewBelieve Step SDTime Remaining LastExplosion}
            end
            {TreatStream T ID Position Weapons Surface Direction Mines Life Players Prey Item Believe Step SDTime Remaining LastExplosion}
        [] sayPassingSonar(?ID2 ?Answer)|T then

            if Life > 0 then
                if Input.nRow >= Input.nColumn then
                    Answer = pt(x:({OS.rand} mod Input.nRow) + 1 y:Position.1.y )
                else
                    Answer = pt(x: Position.1.x y: ({OS.rand} mod Input.nRow) + 1 )
                end
                ID2 = ID
            else
                ID2 = null
                Answer = null
            end
            {TreatStream T ID Position Weapons Surface Direction Mines Life Players Prey Item Believe Step SDTime Remaining LastExplosion}
        [] sayAnswerSonar(ID2 Answer)|T then
            if ID2.color \= ID.color then
                Id = ID2.id Trust
            in
                
                if {Not {Value.hasFeature Believe ID2.id}} then
                    if Input.nRow >= Input.nColumn then
                        Trust = {Adjoin Believe info(Id:pt(x:2 y:0))}
                    else
                        Trust = {Adjoin Believe info(Id:pt(x:0 y:2))}
                    end
                else
                    %RECALIBRATE
                    Trust = {Recalibrate ID2.id Answer Players Believe}
                    {TreatStream T ID Position Weapons Surface Direction Mines Life Trust.1 Prey Item Trust.2 Step SDTime Remaining LastExplosion}
                    %Trust = Believe
                end
                if Prey == nil then
                    {TreatStream T ID Position Weapons Surface Direction Mines Life {Adjoin Players players(Id:Answer)} ID2.id Item Trust Step SDTime Remaining LastExplosion}
                else
                    {TreatStream T ID Position Weapons Surface Direction Mines Life {Adjoin Players players(Id:Answer)} Prey Item Trust Step SDTime Remaining LastExplosion}
                end
            end
            {TreatStream T ID Position Weapons Surface Direction Mines Life Players Prey Item Believe Step SDTime Remaining LastExplosion}     
        [] sayDeath(ID2)|T then
            Id = ID2.id NewPlayers NewPrey
        in
            NewPlayers = {Record.subtract Players Id}
            %(({OS.rand} mod {Record.width Players})+1)
            NewPrey = {ChangePrey Prey Believe 1 ID.id NewPlayers Id}
            if Id == Prey then
                {TreatStream T ID Position Weapons Surface Direction Mines Life NewPlayers NewPrey   Item Believe Step SDTime Remaining-1 LastExplosion}
            end
            {TreatStream T ID Position Weapons Surface Direction Mines Life NewPlayers Prey Item Believe Step SDTime Remaining-1 LastExplosion}   
        [] sayDamageTaken(ID2 Damage LifeLeft)|T then
            NewPlayers NewBelieve Id = ID2.id
        in
            if ID2.color \= ID.color then
                TrustX TrustY PosX PosY
            in
                %Changement de la Trust List
                if Believe.Id.x > 0 then
                    if Damage == 1 then
                        TrustX = 1
                    else
                        TrustX = 0
                    end
                    PosX = LastExplosion.1.x
                else
                    TrustX = Believe.Id.x
                    PosX = Players.Id.x
                end

                if Believe.Id.y > 0 then
                    if Damage == 1 then
                        TrustY = 1
                    else
                        TrustY = 0
                    end
                    PosY = LastExplosion.1.y
                else
                    TrustY = Believe.Id.y
                    PosY = Players.Id.y
                end

                NewBelieve = {Adjoin Believe info(Id:pt(x:TrustX y:TrustY))}
                NewPlayers = {Adjoin Players players(Id:pt(x:PosX y:PosY))}
            else
                NewBelieve = Believe
                NewPlayers = Players
            end
            {TreatStream T ID Position Weapons Surface Direction Mines Life NewPlayers Prey Item NewBelieve Step SDTime Remaining LastExplosion}
        [] _ then 
            skip     
        end
    end

    
    fun{StartPlayer Color ID}
        Stream
        Port
    in
        {NewPort Stream Port}
        thread
            {TreatStream Stream id(id:ID color:Color name:ID) nil weapons(mine:0 missile:0 drone:0 sonar:0) false Direction {List.make 0} Input.maxDamage {InitTrack players() 1 ID} nil nil info(ID:pt(x:2 y:2)) 1 0 Input.nbPlayer nil}
        end
        Port
    end
end
