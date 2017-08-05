//====================================================================================
//
//	wh_nametagInit.sqf - Initializes values for WH nametags.
//
//	> [] execVM "wh\nametags\wh_nametagInit.sqf"; <
//	@ /u/Whalen207 | Whale #5963
//
//====================================================================================

//------------------------------------------------------------------------------------
//	Initial setup.
//------------------------------------------------------------------------------------

//	Make sure this isn't a dedicated server or headless client.
if (!hasInterface) exitWith {};

//	Global variable that will be flipped on and off using the disableKey and CBA.
WH_NT_NAMETAGS_ON = true; 


//------------------------------------------------------------------------------------
//	Configuration import.
//------------------------------------------------------------------------------------

//	Allows for missionmaker configuration of important settings.
#include "wh_nametagCONFIG.sqf"


//------------------------------------------------------------------------------------
//	Setting up CBA settings box.
//------------------------------------------------------------------------------------

//	Allows for player (client) configuration of other settings.
#include "wh_nametagSettings.sqf"


//------------------------------------------------------------------------------------
//	More preparation.
//------------------------------------------------------------------------------------

//	Let the player initialize properly.
waitUntil{!isNull player};
waitUntil{player == player};
sleep 0.2;

//	Reveal all players (on same side) so cursorTarget won't act up.
{ 
	if ( (side _x getFriend playerSide) > 0.6 )
	then { player reveal [_x,4]; }
} forEach allPlayers;

//	Reset font spacing and size to (possibly) new conditions.
call wh_nt_fnc_nametagResetFont;

//	Setting up cursor fading cache.
WH_NT_FADE_TARGET = objNull;
WH_NT_FADE_NAMES = [];
//WH_NT_FADE_IDS = [];
WH_NT_FADE_DATA  = [];

//	Wait for player to get ingame.
waitUntil {!isNull (findDisplay 46)};

//	Setting up our disableKey (Default '+')
#include "wh_nametagDisableKey.sqf"


//------------------------------------------------------------------------------------
//	Set player to keep an updated cache of all tags to draw.
//------------------------------------------------------------------------------------

#include "wh_nametagCache.sqf"


//------------------------------------------------------------------------------------
//	Set player to render nametags from the cache every frame.
//------------------------------------------------------------------------------------

WH_NT_EVENTHANDLER = addMissionEventHandler 
["Draw3D", 
{
	if WH_NT_NAMETAGS_ON then
	{	call wh_nt_fnc_nametagUpdate	};
}];