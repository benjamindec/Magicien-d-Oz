functor
import
	Player1
	Player2
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
		end
	end
end
