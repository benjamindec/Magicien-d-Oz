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
    FireRandom
    MovePos
    MoveAllowed
    Visited
in
    fun {RandomWeapon}
        %Weapons = [mine missile sonar drone]
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
                nil
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


    
    proc{TreatStream Stream ID Position Weapons Surface Direction Mines Life} % as as many parameters as you want
        

        case Stream of nil then skip
        [] initPosition(?ID2 ?Pos)|T andthen {Not Surface} then
            Pos = {RandomPos}
            ID2 = ID
            {TreatStream T ID2 Pos|Position Weapons Surface Direction Mines Life}
        [] move(?ID2 ?Pos ?Dir)|T andthen {Not Surface}  then
            Dir = {RandomDir [north east south west] Position}
            
            Pos = {MovePos Position.1 Dir}
            ID2 = ID
            if Dir == surface then
                {TreatStream T ID2 Pos|nil Weapons true Dir|Direction Mines Life}
            else
                {TreatStream T ID2 Pos|Position Weapons Surface Dir|Direction Mines Life}
            end
        [] dive()|T then
            {TreatStream T ID Position Weapons false Direction Mines Life}
        [] chargeItem(?ID2 ?KindItem)|T andthen {Not Surface}  then
            Charge TmpW
        in
            ID2 = ID
            TmpW = {RandomWeapon}
            Charge = {Adjoin Weapons weapons(TmpW:Weapons.TmpW + 1)}
            if Charge.TmpW > 0 andthen (Charge.TmpW mod Input.TmpW) == 0 then
                KindItem = TmpW
            else
                KindItem = nil
            end
            {TreatStream T ID2 Position Charge Surface Direction Mines Life}
        [] fireItem(?ID2 ?KindFire)|T andthen {Not Surface}  then
            Charge Label NewMines
        in
            ID2 = ID
            KindFire = {FireRandom [missile drone sonar mine ] Weapons Position.1}
            if {Record.label KindFire} == nil then
                {TreatStream T ID2 Position Weapons Surface Direction Mines Life}
            else
                Label = {Record.label KindFire}
                case KindFire of mine(pt(x:X y:Y)) then
                    NewMines = {List.append Mines [pt(x:X y:Y)]}
                [] _ then
                    NewMines = Mines
                end
                Charge = {Adjoin Weapons weapons(Label:Weapons.Label - Input.Label)}
                {TreatStream T ID2 Position Charge Surface Direction NewMines Life}
            end
        [] fireMine(?ID2 ?Mine)|T andthen {Not Surface}  then
            NewMines
        in
            ID2 = ID
            if {List.length Mines} > 0 then
                Mine = {List.nth Mines (({OS.rand} mod {List.length Mines}) + 1)}
                NewMines = {List.subtract Mines Mine}
            else
                NewMines = Mines
                Mine = nil
            end
            {TreatStream T ID2 Position Weapons Surface Direction NewMines Life}
        [] isDead(?Answer)|T then
            if Life == 0 then
                Answer = true
            else
                Answer = false
            end
            {TreatStream T ID Position Weapons Surface Direction Mines Life}
        [] sayMove(ID2 Dir)|T then
            if ID2.color \= ID.color then
                %{System.show [le joueur ID2.color est parti vers Dir]}
                skip
            end
            {TreatStream T ID Position Weapons Surface Direction Mines Life}
        [] saySurface(ID2)|T then
            if ID2.color \= ID.color then
                {System.show [le joueur ID2.color est parti vers la surface]}
            end
            {TreatStream T ID Position Weapons Surface Direction Mines Life}
        [] sayCharge(ID2 KindItem)|T then
            if ID2.color \= ID.color then
                skip
                %{System.show [le joueur ID2.color a charger KindItem]}
            end
            {TreatStream T ID Position Weapons Surface Direction Mines Life}
        [] sayMinePlaced(ID2)|T then
            if ID2.color \= ID.color then
                {System.show [le joueur ID2.color a placer une mine]}
            end
            {TreatStream T ID Position Weapons Surface Direction Mines Life}
        [] sayMissileExplode(ID2 Pos ?Message)|T then
            Dist HP 
        in
            if ID2.color \= ID.color then
                %{System.show [le joueur ID2.color exploser missile en Pos.x Pos.y]}
                Dist = {Abs (Pos.x - Position.1.x)} + {Abs (Pos.y - Position.1.y)}
                %{System.show Position}
                %{System.show Dist}
                case Dist of 0 then
                    HP = Life - 2
                    Message = sayDamageTaken(ID 2 HP)
                    if HP > 0 then
                        Message = sayDamageTaken(ID 1 HP)
                    else
                        Message = sayDeath(ID)
                    end
                [] 1 then
                    HP = Life - 2
                    if HP > 0 then
                        Message = sayDamageTaken(ID 1 HP)
                    else
                        Message = sayDeath(ID)
                    end
                [] _ then
                    HP = Life
                    Message = nil
                end
                {TreatStream T ID Position Weapons Surface Direction Mines HP}
            end
            Message = nil
            {TreatStream T ID Position Weapons Surface Direction Mines Life}
        [] sayMineExplode(ID2 Pos ?Message)|T then
            Dist HP
        in
            if ID2.color \= ID.color then
                %{System.show [le joueur ID2.color exploser  mine Pos.x Pos.y]}
                Dist = {Abs (Pos.x - Position.1.x)} + {Abs (Pos.y - Position.1.y)}
                %{System.show Position}
                %{System.show Dist}
                case Dist of 0 then
                    HP = Life - 2
                    if HP > 0 then
                        Message = sayDamageTaken(ID 1 HP)
                    else
                        Message = sayDeath(ID)
                    end
                [] 1 then
                    HP = Life - 2
                    if HP > 0 then
                        Message = sayDamageTaken(ID 1 HP)
                    else
                        Message = sayDeath(ID)
                    end
                [] _ then
                    HP = Life
                    Message = nil
                end
                {TreatStream T ID Position Weapons Surface Direction Mines HP}
            end
            Message = nil
            {TreatStream T ID Position Weapons Surface Direction Mines Life}
        [] sayPassingDrone(Drone ?ID2 ?Answer)|T then
            {System.show [un drone passe en Drone]}
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
            {System.show Answer}
            ID2 = ID
            {TreatStream T ID Position Weapons Surface Direction Mines Life}     
        [] sayAnswerDrone(Drone ID2 Answer)|T then
            {TreatStream T ID Position Weapons Surface Direction Mines Life}     
        [] sayPassingSonar(?ID2 ?Answer)|T then
            XorY
        in
            {System.show [un sonar passe]}
            XorY = ({OS.rand} mod 2)
            case XorY of 0 then
                Answer = pt(x:({OS.rand} mod Input.nRow) + 1 y:Position.1.y )
            [] 1 then
                Answer = pt(x: Position.1.x y: ({OS.rand} mod Input.nColumn) + 1 )
            end
            {System.show Answer}
            ID2 = ID
            {TreatStream T ID Position Weapons Surface Direction Mines Life}
        [] sayAnswerSonar(ID2 Answer)|T then
            {TreatStream T ID Position Weapons Surface Direction Mines Life}     
        [] sayDeath(ID2)|T then
            {TreatStream T ID Position Weapons Surface Direction Mines Life}     
        [] sayDamageTaken(ID2 Damage LifeLeft)|T then
            {TreatStream T ID Position Weapons Surface Direction Mines Life}
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
            {TreatStream Stream id(id:ID color:Color name:ID) nil weapons(mine:0 missile:0 drone:0 sonar:0) false Direction {List.make 0} Input.maxDamage}
        end
        Port
    end
end
