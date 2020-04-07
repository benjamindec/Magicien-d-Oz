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
    MovePos
    MoveAllowed
    Visited
in

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
            pt(x:Pt.x + 1 y:Pt.y)
        [] north then
            pt(x:Pt.x y:Pt.y - 1)
        [] south then
            pt(x:Pt.x y:Pt.y + 1)
        [] west then
            pt(x:Pt.x - 1 y:Pt.y)
        [] surface then
            {System.show Dir}
            Pt
        end
    end 

    
    proc{TreatStream Stream ID Position Weapon Surface Direction} % as as many parameters as you want

        if Surface == 0 then
            case Stream of nil then skip
            [] initPosition(?ID2 ?Pos)|T then
                Pos = {RandomPos}
                ID2 = ID
                {TreatStream T ID2 Pos|Position Weapon Surface Direction}
            [] move(?ID2 ?Pos ?Dir)|T then
                Dir = {RandomDir [north east south west] Position}
                Pos = {MovePos Position.1 Dir}
                ID2 = ID
                case Dir of surface then
                    {TreatStream T ID2 Pos|nil Weapon Surface Dir|Direction}
                [] _ then
                    {TreatStream T ID2 Pos|Position Weapon Surface Dir|Direction}
                end
            [] dive()|T then
                skip
            [] chargeItem(?ID ?KindItem)|T then
                skip
            [] fireItem(?ID ?KindFire)|T then
                skip
            [] fireMine(?ID ?Mine)|T then
                skip
            [] isDead(?Answer)|T then
                skip
            [] sayMove(?ID ?Direction)|T then
                skip
            [] saySurface(?ID)|T then
                skip
            [] sayCharge(?ID ?KindItem)|T then
                skip
            [] sayMinePlaced(?ID)|T then
                skip
            [] sayMissileExplode(ID Position ?Message)|T then
                skip
            [] sayMineExplode(ID POSITION ?Messsage)|T then
                skip
            [] sayPassingDrone(Drone ?ID ?Answer)|T then
                skip
            [] sayAnswerDrone(Drone ID Answer)|T then
                skip
            [] sayPassingSonar(?ID ?Answer)|T then
                skip
            [] sayAnswerSonar(ID Answer)|T then
                skip
            [] sayDeath(ID)|T then
                skip
            [] sayDamageTaken(ID Damage LifeLeft)|T then
                skip
            end
        else
            {TreatStream Stream ID Position Weapon Surface-1 Direction}
        end
    end

    
    fun{StartPlayer Color ID}
        Stream
        Port
    in
        {NewPort Stream Port}
        thread
            {TreatStream Stream id(id:ID color:Color name:ID) nil Weapon 1 Direction}
        end
        Port
    end
end
