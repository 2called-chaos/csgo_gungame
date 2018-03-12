# GunGame (CS:GO) - Chaos edit

This is a fork of https://github.com/altexdim/sourcemod-plugin-gungame

Modifications mostly don't have options and are targeted at deathmatch environments. This is my attempt
to recreate some of the behaviour of the original AMXX mod.

This modified version is running on our [GunGame DM on steroids](https://funcs.de/gungame) server.

Note that I don't play CS:S and can't test my changes for CS:S but they should work in theory.


Changes include:

  * give grenades (HE/Molotov) after timeout and after any kill with (any) other weapon (glock/knife) (no cvars, maybe should be?)
  * don't steal levels of victims if attacker is on knife level (how it was in AMXX, no cvar, maybe should be?)
  * MOTD panel fixed and additional parameters "winnerID", "loserID", "clientID" (all STEAM_*) and "nextMap"
  * Show more info in chat message (how far you are in the lead / how many are tied on lead)
  * Includes [`gungame_mvp` plugin](https://forums.alliedmods.net/showpost.php?p=1627823&postcount=3105) by default (thanks to Peace-Maker)
  * Includes new [`gungame_one_shot_awp` plugin](https://github.com/2called-chaos/csgo_gungame/blob/master/addons/sourcemod/scripting/gungame_one_shot_awp.sp)
  * New commands
    * gg_setlevel // <target> <level> - sets target's level. use + or - for relative, otherwise it's absolute.
    * gg_win // [target] - if target, forces target to win. if no target, forces highest level player to win.


Todo:

  * With the recent introduction of snd_stream (and the future removal of the audio cache) add wav-sounds for other events like in AMXX (tied, lost lead, etc.)
  * LostLead Fwd
