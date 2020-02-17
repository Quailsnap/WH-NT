//====================================================================================
//
//	fn_onEachFrame.sqf - Updates values for WHA nametags (heavily based on F3 and ST)
//							Intended to be run each frame.
//
//	> 	WHA_NAMETAGS_EVENTHANDLER = addMissionEventHandler 
//		["Draw3D", { call wha_nametags_fnc_onEachFrame }];	<
//
//	@ /u/Whalen207 | Whale #5963
//
//====================================================================================

//------------------------------------------------------------------------------------
//	Initializing variables.
//------------------------------------------------------------------------------------
// TODO: all of this only if there's something to draw
//	Store the player and the player's group.
private _player = WHA_NAMETAGS_PLAYER;
private _playerGroup = group _player;

//	Find player camera's position.
private _cameraPositionAGL = positionCameraToWorld[0,0,0];
private _cameraPositionASL = AGLtoASL _cameraPositionAGL;

//	Get zoom, which will be used to adjust size and spacing of text.
private _zoom = call wha_nametags_fnc_getZoom;

//	Initialize other variables to be used.
private _time = time;

//	Make a copy of the global cache containing nearby entities and their data.
private _toDraw =+ WHA_NAMETAGS_CACHE;

//if (_time > WHA_NAMETAG_CACHE_TIME + 0.5) then
//{}

//------------------------------------------------------------------------------------
//	Check if player is unconscious.
//------------------------------------------------------------------------------------

if (WHA_NAMETAGS_MOD_ACE && _player getVariable ["ACE_isUnconscious", false]) 
exitWith {};


//------------------------------------------------------------------------------------
//	Collect player cursor target for drawing tags.
//------------------------------------------------------------------------------------

// TODO: cursorTarget does not work with freelook (unless walking?? )
//	Only collect the cursor target if it's within range and on the player's side.
private _cursorObject = 
if ( (_player distance cursorTarget) <= (((WHA_NAMETAGS_DRAWDISTANCE_CURSOR) * WHA_NAMETAGS_VAR_NIGHT) * _zoom) &&
	{(side group cursorTarget isEqualTo side _playerGroup)} ) 
then { cursorTarget }
else { objNull };


//------------------------------------------------------------------------------------
//	If the cursor target fits above criteria, get the data for it.
//------------------------------------------------------------------------------------

//	Only worry about the cursorObject at all if it's not null.
if !( isNull _cursorObject ) then
{
	//	Clean out any previous data.
	private _newData = [[],[]];
	private _cursorInCache = false;
	{
		//	If the cursor target is already in the global cache (ie: cursor target
		//	is nearby)...
		if ( _x in (_toDraw select 0) ) then
		{
			//	...then just take that data...
			_index = (_toDraw select 0) find _x;
			_unitData =+ ((_toDraw select 1) select _index);
			
			//	...adjust it so it knows it's the cursor target...
			_unitData set [7,true];
			
			//	...take it out of the copy of the global cache...
			(_toDraw select 0) deleteAt _index;
			(_toDraw select 1) deleteAt _index;
			
			//	...and save it for later.
			(_newData select 0) pushBack _x;
			(_newData select 1) pushBack _unitData;
			
			//	Also, let us know we don't need to process cursor any further.
			_cursorInCache = true;
		}
		else 
		{ _cursorInCache = false };
	} count (crew _cursorObject);
	
	//	If the cursor target is not already in our global cache...
	if !_cursorInCache then
	{
		//	Check the cursor cache, which is used in case we're staring continuously
		//	at something far away.
		if ( _cursorObject isEqualTo WHA_NAMETAGS_CACHE_CURSOR ) then
		//	If it's in there, just take that data.
		{ _newData =+ WHA_NAMETAGS_CACHE_CURSOR_DATA }
		else
		{
			//	If all else fails and the data is not in the cursor cache nor the global
			//	cache, then find the data anew.
			_newData = 
			[_player,_playerGroup,_cameraPositionAGL,_cameraPositionASL,[_cursorObject],true]
			call wha_nametags_fnc_getData;
		};
	};
	
	//	Whatever data we did save for later, add it to the cursor cache...
	WHA_NAMETAGS_CACHE_CURSOR_DATA =+ _newData;
	
	//	...and add it to the temporary copy of the global cache, too.
	(_toDraw select 0) append (_newData select 0);
	(_toDraw select 1) append (_newData select 1);
};


//------------------------------------------------------------------------------------
//	Draw everything currently in the temporary copy of the global cache.
//	This usually means drawing all nearby entities and the cursor.
//------------------------------------------------------------------------------------

{
	_unitData =+ ( (_toDraw select 1) select _forEachIndex );
	
	//	Pass in the player's camera and zoom level.
	_unitData append [_cameraPositionAGL,_zoom,_time,nil];
	
	//	Call the draw function with the above parameters.
	_unitData call wha_nametags_fnc_drawUnit;
} forEach (_toDraw select 0);


//------------------------------------------------------------------------------------
//	Also, draw everything currently being faded out (ie: moused over it, moused away.)
//------------------------------------------------------------------------------------

//	For every name in the cache of data for fading names...
{
	//	Get the time we started rendering this tag.
	private _startTime = ( (WHA_NAMETAGS_CACHE_FADE select 2) select _forEachIndex );
	
	//	If it hasn't been long enough that it should be invisible, draw it.
	if ( _time < _startTime + WHA_NAMETAGS_FADETIME) then
	{
		_unitData =+ ( (WHA_NAMETAGS_CACHE_FADE select 1) select _forEachIndex );
		_unitData append [_cameraPositionAGL,_zoom,_time,_startTime];
		_unitData call wha_nametags_fnc_drawUnit;
	}
	//	If it has been that long, delete it.
	else
	{
		(WHA_NAMETAGS_CACHE_FADE select 0) deleteAt _forEachIndex;
		(WHA_NAMETAGS_CACHE_FADE select 1) deleteAt _forEachIndex;
		(WHA_NAMETAGS_CACHE_FADE select 2) deleteAt _forEachIndex;
	};
} forEach (WHA_NAMETAGS_CACHE_FADE select 0);


//------------------------------------------------------------------------------------
//	If the cursor changed last frame, add the previous cursor to the cache of things
//	to fade out.
//------------------------------------------------------------------------------------

// TODO: move all fade shit to it's own function

//	If the last cursor is something we can draw a tag on...
//	...and if the last cursor is not the current cursor...
//	...and this thing isn't already being faded out...
//	...and we're not already fading too much stuff...
if (
	!(isNull WHA_NAMETAGS_CACHE_CURSOR)
	&& {!(_cursorObject isEqualTo WHA_NAMETAGS_CACHE_CURSOR)}
	) then
{
	//	Prevent the fade system from fading more than four tags
	//	at a time. Give priority to new fades.
	if ( count (WHA_NAMETAGS_CACHE_FADE select 0) > 4) then
	{
		_index = (count (WHA_NAMETAGS_CACHE_FADE select 0)) - 4;
		
		for "_i" from 0 to _index do
		{
			(WHA_NAMETAGS_CACHE_FADE select 0) deleteAt 0;
			(WHA_NAMETAGS_CACHE_FADE select 1) deleteAt 0;
			(WHA_NAMETAGS_CACHE_FADE select 2) deleteAt 0;
		};
	};
	
	//	Prevent the fade system from fading the same tag twice.
	if (((WHA_NAMETAGS_CACHE_CURSOR_DATA select 0) select 0) in (WHA_NAMETAGS_CACHE_FADE select 0)) then
	{
		{
			_index = 
			(WHA_NAMETAGS_CACHE_FADE select 0) find ((WHA_NAMETAGS_CACHE_CURSOR_DATA select 0) select _forEachIndex);
			
			(WHA_NAMETAGS_CACHE_FADE select 0) deleteAt _index;
			(WHA_NAMETAGS_CACHE_FADE select 1) deleteAt _index;
			(WHA_NAMETAGS_CACHE_FADE select 2) deleteAt _index;
		} forEach (WHA_NAMETAGS_CACHE_CURSOR_DATA select 0);
	};
	
	//	Then chuck all that data from the thing into the array of things to fade.
	(WHA_NAMETAGS_CACHE_FADE select 0) append (WHA_NAMETAGS_CACHE_CURSOR_DATA select 0);
	(WHA_NAMETAGS_CACHE_FADE select 1) append (WHA_NAMETAGS_CACHE_CURSOR_DATA select 1);
	{ (WHA_NAMETAGS_CACHE_FADE select 2) pushBack time } forEach (WHA_NAMETAGS_CACHE_CURSOR_DATA select 0);
};

//	For the next frame, set the cache of the cursor to the current cursor.
WHA_NAMETAGS_CACHE_CURSOR = _cursorObject;
