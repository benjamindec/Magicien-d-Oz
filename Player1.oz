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
in

    fun {InitTrack Players ID MyID}
        if ID =< Input.nbPlayer andthen ID \= MyID then
            {InitTrack {Adjoin Players players(ID:pt(x:0 y:0))} ID+1 MyID}
        else
            Players
        end
    end
    
    fun {RandomWeapon}
        Weapons = [mine missile sonar drone]
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
        if Pt.x =< Input.nColumn andthen Pt.x >= 1 andthen Pt.y =< Input.nRow andthen Pt.y >= 1 then
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
            pt(x:Pt.x  y:Pt.y-1)
        [] surface then
            Pt
        end
    end

    fun {TrackPlayer Players ID Dir}
        {System.show prinnnnntplayeeeeer}
        {System.show [Players ID]}
        {Delay 10}
        if {Record.width Players} == Input.nbPlayer-1  andthen Players.ID.x \= 0 then
            case Dir of surface then Players
            [] east then {Adjoin Players players(ID:pt(x:Players.ID.x y:Players.ID.y + 1))}
            [] west then {Adjoin Players players(ID:pt(x:Players.ID.x y:Players.ID.y - 1))}
            [] south then {Adjoin Players players(ID:pt(x:Players.ID.x + 1 y:Players.ID.y))}
            [] north then {Adjoin Players players(ID:pt(x:Players.ID.x - 1 y:Players.ID.y))}
            [] _ then Players
            end
        else
            {Adjoin Players player(ID:pt(x:0 y:0))}
        end
    end

    fun {FollowPrey Prey Players MyPos Directions Count}
        TmpPos Ind Dir X Y Coord
    in
        if Count >= 5 then
            {System.show avantFollowprey}
            if {List.length Directions} == 0 then
                    surface
            else

                Coord = ({OS.rand} mod 2)
                X = MyPos.1.x - Players.Prey.x
                Y = MyPos.1.y - Players.Prey.y
                case Coord of 0 then %X
                    if X \= 0 then
                        if X < 0 then
                            Dir = south
                        else
                            Dir = north
                        end
                    else
                        if Y \= 0 then
                            if Y < 0 then
                                Dir = east
                            else
                                Dir = west
                            end
                        end
                    end
                [] 1 then %Y
                    if Y \= 0 then
                        if Y < 0 then
                            Dir = east
                        else
                            Dir = west
                        end
                    else
                        if X \= 0 then
                            if X < 0 then
                                Dir = south
                            else
                                Dir = north
                            end
                        end
                    end
                [] _ then
                    Ind = ({OS.rand} mod {List.length Directions}) + 1
                    {List.nth Directions Ind ?Dir}
                end
                {System.show followpreymovepos}
                TmpPos = {MovePos MyPos.1 Dir}

                if {MoveAllowed TmpPos} andthen {Not {Visited TmpPos MyPos}} then
                    {System.show followpreyretour}
                    Dir
                else
                    {FollowPrey Prey Players MyPos {List.subtract Directions Dir} Count+1}
                end
            end
        else
            {RandomDir Directions MyPos}
        end
    end

    fun {OnRange Players ID MyPos MyID}
        Dist
    in
        {System.show onrangedebut}
        if MyID \= ID andthen {Record.width Players} > 0  andthen ID =< Input.nbPlayer andthen {Value.hasFeature Players ID} andthen Players.ID.x \= 0 then

            {System.show onrangemilieu}
            Dist = {Abs (MyPos.x - Players.ID.x)} + {Abs (MyPos.y - Players.ID.y)}
            if Dist =< Input.maxDistanceMissile then
                {System.show retour}
                missile(Players.ID)
            else
                {OnRange Players ID+1 MyPos MyID}
            end    
        else
            nil
        end
    end

    fun {MineOnRange Players Nb Mines MyID}
        fun {NearPlayer Players ID Mine MyID}
            Dist
        in
            if ID \= MyID andthen {Record.width Players} > 0  andthen ID =< Input.nbPlayer andthen {Value.hasFeature Players ID} andthen Players.ID.x \= 0  then
                {System.show  [idplayerfiremine Players.ID.x]}
                Dist = {Abs (Mine.x - Players.ID.x)} + {Abs (Mine.y - Players.ID.y)}
                if Dist =< 1 then
                    true
                else
                    {NearPlayer Players ID+1 Mine MyID}
                end
            
            else
                false
            end
        end
    in
        {System.show [Players Nb Mines]}
        if {List.length Mines} > 0 andthen Nb =< {List.length Mines} then
            case {NearPlayer Players 1 {List.nth Mines Nb} MyID} of true then
                {System.show retourfiremine}
                {List.nth Mines Nb}
            [] false then {MineOnRange Players Nb+1 Mines MyID}
            end
        else
            null
        end
    end

    
    proc{TreatStream Stream ID Position Weapons Surface Direction Mines Life Players Prey Item} % as as many parameters as you want
        case Stream of nil then skip
        [] initPosition(?ID2 ?Pos)|T andthen {Not Surface} then
            Pos = {RandomPos}
            ID2 = ID
            {TreatStream T ID2 Pos|Position Weapons Surface Direction Mines Life Players Prey Item}
        [] move(?ID2 ?Pos ?Dir)|T andthen {Not Surface}  then
            {System.show avantmove}
            {System.show Prey}
            if Prey == nil then
                Dir = {RandomDir [north east south west] Position}
            else
                Dir = {FollowPrey Prey Players Position [north east south west] 0}
            end
            {System.show pendantmove}
            Pos = {MovePos Position.1 Dir}
            ID2 = ID
            {System.show apresmove}
            if Dir == surface then
                {TreatStream T ID2 Pos|nil Weapons true Dir|Direction Mines Life Players Prey Item}
            else
                {TreatStream T ID2 Pos|Position Weapons Surface Dir|Direction Mines Life Players Prey Item} 
            end
        [] dive()|T then
            {TreatStream T ID Position Weapons false Direction Mines Life Players Prey Item}
        [] chargeItem(?ID2 ?KindItem)|T andthen {Not Surface}  then
            Charge TmpW
        in
            ID2 = ID
            if Item == nil orelse (Weapons.Item mod Input.Item) == 0 then
                TmpW = {RandomWeapon}
            else
                TmpW = Item
            end
            {System.show Weapons}
            Charge = {Adjoin Weapons weapons(TmpW:Weapons.TmpW + 1)}
            if Charge.TmpW > 0 andthen (Charge.TmpW mod Input.TmpW) == 0 then
                KindItem = TmpW
            else
                KindItem = null
            end
            {TreatStream T ID2 Position Charge Surface Direction Mines Life Players Prey TmpW}
        [] fireItem(?ID2 ?KindFire)|T andthen {Not Surface}  then
            Charge Label NewMines
        in
            ID2 = ID
            {System.show avant}
            if (Weapons.missile mod Input.missile == 0) andthen {OnRange Players 1 Position.1 ID.id} \= nil then
                KindFire = {OnRange Players 1 Position.1 ID.id}
                Charge = {Adjoin Weapons weapons(missile:Weapons.missile - Input.missile)}
                {TreatStream T ID2 Position Charge Surface Direction Mines Life Players Prey Item}
            end

            KindFire = {FireRandom [missile drone sonar mine ] Weapons Position.1}
            {System.show pendant}
            if {Record.label KindFire} == null then
                {TreatStream T ID2 Position Weapons Surface Direction Mines Life Players Prey Item}
            else
                {System.show apres}
                Label = {Record.label KindFire}
                case KindFire of mine(pt(x:X y:Y)) then
                    NewMines = {List.append Mines [pt(x:X y:Y)]}
                [] _ then
                    NewMines = Mines
                end
                Charge = {Adjoin Weapons weapons(Label:Weapons.Label - Input.Label)}
                {TreatStream T ID2 Position Charge Surface Direction NewMines Life Players Prey Item}
            end
        [] fireMine(?ID2 ?Mine)|T andthen {Not Surface}  then
            NewMines
        in
            
            ID2 = ID
            {System.show avantfiremine}
            case {MineOnRange Players 1 Mines ID.id} of pt(x:X y:Y) then
                {System.show inrangeeeeeeeee}
                Mine = pt(x:X y:Y)
                NewMines = {List.subtract Mines Mine}
            [] null then 
                NewMines = Mines
                Mine = null
            end
            {System.show apresfiremine}
            {TreatStream T ID2 Position Weapons Surface Direction NewMines Life Players Prey Item}
        [] isDead(?Answer)|T then
            {System.show isdeaaaaad}
            if Life =< 0 then
                Answer = true
            else
                Answer = false
            end
            {TreatStream T ID Position Weapons Surface Direction Mines Life Players Prey Item}
        [] sayMove(ID2 Dir)|T then
            if ID2.color \= ID.color then
                NewPlayers
            in
                if {Record.width Players} \= Input.nbPlayer-1 then
                    Tmp = {InitTrack Players 1 ID.id}
                in
                    NewPlayers = {TrackPlayer Tmp ID2.id Dir}
                else
                    NewPlayers = {TrackPlayer Players ID2.id Dir}
                end
                
                
                
                {TreatStream T ID Position Weapons Surface Direction Mines Life NewPlayers Prey Item}
            else
                {TreatStream T ID Position Weapons Surface Direction Mines Life Players Prey Item}
            end
        [] saySurface(ID2)|T then
            {TreatStream T ID Position Weapons Surface Direction Mines Life Players Prey Item}
        [] sayCharge(ID2 KindItem)|T then
            {TreatStream T ID Position Weapons Surface Direction Mines Life Players Prey Item}
        [] sayMinePlaced(ID2)|T then
            {TreatStream T ID Position Weapons Surface Direction Mines Life Players Prey Item}
        [] sayMissileExplode(ID2 Pos ?Message)|T then
            Dist HP 
        in
            if ID2.color \= ID.color then
                Dist = {Abs (Pos.x - Position.1.x)} + {Abs (Pos.y - Position.1.y)}
                case Dist of 0 then
                    {System.show [ID.color Dist toucher par ID2.color missile Pos]}
                    HP = Life - 2
                    if HP > 0 then
                        Message = sayDamageTaken(ID 1 HP)
                    else
                        Message = sayDeath(ID)
                    end
                [] 1 then
                    {System.show [ID.color Dist toucher par ID2.color missile Pos]}
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
                {TreatStream T ID Position Weapons Surface Direction Mines HP Players Prey Item}
            end
            Message = null
            {TreatStream T ID Position Weapons Surface Direction Mines Life Players Prey Item}
        [] sayMineExplode(ID2 Pos ?Message)|T then
            Dist HP
        in
            if ID2.color \= ID.color then
                Dist = {Abs (Pos.x - Position.1.x)} + {Abs (Pos.y - Position.1.y)}
                case Dist of 0 then
                    {System.show [ID.color Dist toucher par ID2.color mine Pos]}
                    HP = Life - 2
                    if HP > 0 then
                        Message = sayDamageTaken(ID 1 HP)
                    else
                        Message = sayDeath(ID)
                    end
                [] 1 then
                    {System.show [ID.color Dist toucher par ID2.color mine Pos]}
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
                {TreatStream T ID Position Weapons Surface Direction Mines HP Players Prey Item}
            end
            Message = null
            {TreatStream T ID Position Weapons Surface Direction Mines Life Players Prey Item}
        [] sayPassingDrone(Drone ?ID2 ?Answer)|T then
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
            {TreatStream T ID Position Weapons Surface Direction Mines Life Players Prey Item}     
        [] sayAnswerDrone(Drone ID2 Answer)|T then
            {TreatStream T ID Position Weapons Surface Direction Mines Life Players Prey Item}     
        [] sayPassingSonar(?ID2 ?Answer)|T then
            XorY
        in
            XorY = ({OS.rand} mod 2)
            case XorY of 0 then
                Answer = pt(x:({OS.rand} mod Input.nRow) + 1 y:Position.1.y )
            [] 1 then
                Answer = pt(x: Position.1.x y: ({OS.rand} mod Input.nColumn) + 1 )
            end
            ID2 = ID
            {TreatStream T ID Position Weapons Surface Direction Mines Life Players Prey Item}
        [] sayAnswerSonar(ID2 Answer)|T then
            if ID2.color \= ID.color then
                Id
            in
                Id = ID2.id
                if Prey == nil then
                    {TreatStream T ID Position Weapons Surface Direction Mines Life {Adjoin Players players(Id:Answer)} ID2.id Item}
                else
                    {TreatStream T ID Position Weapons Surface Direction Mines Life {Adjoin Players players(Id:Answer)} Prey Item}
                end
            end
            {TreatStream T ID Position Weapons Surface Direction Mines Life Players Prey Item}     
        [] sayDeath(ID2)|T then
            Id = ID2.id NewPlayers = {Record.subtract Players Id}
        in
            if Id == Prey then
                {TreatStream T ID Position Weapons Surface Direction Mines Life NewPlayers (({OS.rand} mod {Record.width Players})+1) Item}
            end
            {TreatStream T ID Position Weapons Surface Direction Mines Life {Record.subtract Players Id} Prey Item}   
        [] sayDamageTaken(ID2 Damage LifeLeft)|T then
            {TreatStream T ID Position Weapons Surface Direction Mines Life Players Prey Item}
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
            {TreatStream Stream id(id:ID color:Color name:ID) nil weapons(mine:0 missile:0 drone:0 sonar:0) false Direction {List.make 0} Input.maxDamage {InitTrack players() 1 ID} nil nil}
        end
        Port
    end
end
