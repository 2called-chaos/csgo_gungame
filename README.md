# GunGame (CS:GO) - Chaos edit

This is a fork of https://github.com/altexdim/sourcemod-plugin-gungame

Modifications mostly don't have options and are targeted at deathmatch environments. This is my attempt
to recreate some of the behaviour of the original AMXX mod.

This modified version is running on our [GunGame DM on steroids](https://funcs.de/gungame) server.

Note that I don't play CS:S and can't test my changes for CS:S but they should work in theory (CS:S configs are not maintained).


Changes include:

  * FFA support
  * give grenades (HE/Molotov) after timeout and after any kill with (any) other weapon (glock/knife) (no cvars, maybe should be?)
  * don't steal levels of victims if attacker is on knife level (how it was in AMXX, no cvar, maybe should be?)
  * ~~MOTD panel fixed and additional parameters "winnerID", "loserID", "clientID" (all STEAM_*) and "nextMap"~~ irrelevant since Volvo gave MOTD support a 360° noscope, thanks btw
  * Show more info in chat message (how far you are in the lead / how many are tied on lead)
  * Includes [`gungame_mvp` plugin](https://forums.alliedmods.net/showpost.php?p=1627823&postcount=3105) by default (thanks to Peace-Maker)
  * Includes new [`gungame_one_shot_awp` plugin](https://github.com/2called-chaos/csgo_gungame/blob/master/addons/sourcemod/scripting/gungame_one_shot_awp.sp)
  * Allow for sounds to be in wave (.wav) format which allows concurrent playback (default sound pack switched to wav except endgame music)
  * Add new cvar `sm_gg_bot_turbo` which - when set to 1 - will make bots level up with every kill
  * Add cvar-less setting `BotNadeSkip` to let bots skip nade and taser level
  * Added missing sounds (from AMXX perspective) "lead taken", "lead tied" and "lead lost"
  * New commands
    * gg_setlevel // <target> <level> - sets target's level. use + or - for relative, otherwise it's absolute.
    * gg_win // [target] - if target, forces target to win. if no target, forces highest level player to win.
    * gg_ffa // [1/0] [> 0=restart game] - enable/disable FFA, second argument > 0 = restart game in that many seconds


### Todo

  * sometimes a bomb exists and can be planted and defused in deathmatch (shouldn't?)
