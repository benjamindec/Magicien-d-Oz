functor
import
	Player1
	Player2
	Player078EatMyFishStick
	Player078RandomCaptainIglo
	AIAssistant
export
	playerGenerator:PlayerGenerator
define
	PlayerGenerator
in
	fun{PlayerGenerator Kind Color ID}
		case Kind
		of player2 then {Player2.portPlayer Color ID}
		[] player1 then {Player1.portPlayer Color ID}
		[] player3 then {AIAssistant.portPlayer Color ID}
		[] fish then {Player078EatMyFishStick.portPlayer Color ID}
		[] iglo then {Player078RandomCaptainIglo.portPlayer Color ID}
		end
	end
end
