OnCreateCommand()
{
    // ConsoleCmd
    RegConsoleCmd("level", _CmdLevel);
    RegConsoleCmd("rules", _CmdRules);
    RegConsoleCmd("score", _CmdScore);
    RegConsoleCmd("weapons", _CmdWeapons);
    RegConsoleCmd("commands", _CmdCommand);
    RegConsoleCmd("leader", _CmdLeader);

    RegConsoleCmd("gg_version", _CmdVersion);
    RegConsoleCmd("gg_status", _CmdStatus);
    RegAdminCmd("gg_restart", CmdReset, GUNGAME_ADMINFLAG, "Restarts the whole game from the beginning.");
    RegAdminCmd("gg_enable", _CmdEnable, GUNGAME_ADMINFLAG, "Turn off gungame and restart the game.");
    RegAdminCmd("gg_disable", _CmdDisable, GUNGAME_ADMINFLAG, "Turn on gungame and restart the game.");
    RegAdminCmd("gg_setlevel", _CmdAdminSetlevel, GUNGAME_ADMINFLAG, "sets target's level (use +/- for relative)");
    RegAdminCmd("gg_win", _CmdAdminWin, GUNGAME_ADMINFLAG, "forces target or highest player to win");
    RegAdminCmd("gg_ffa", _CmdAdminFfa, GUNGAME_ADMINFLAG, "set FFA at runtime");

    /**
     * Add any ES GunGame command if there is any.
     */
}

public Action:_CmdEnable(client, args)
{
    if(!IsActive)
    {
        ReplyToCommand(client, "[GunGame] Turning on GunGame:SM");
        CPrintToChatAll("%t", "GunGame has been enabled");

        SetConVarInt(gungame_enabled, 1);

        Call_StartForward(FwdStart);
        Call_PushCell(true);
        Call_Finish();

        SetConVarInt(mp_restartgame, 1);
    } else {
        ReplyToCommand(client, "[GunGame] is already enabled");
    }
    return Plugin_Handled;
}

public Action:_CmdDisable(client, args)
{
    if(IsActive)
    {
        ReplyToCommand(client, "[GunGame] Turning off GunGame:SM");
        CPrintToChatAll("%t", "GunGame has been disabled");

        SetConVarInt(gungame_enabled, 0);

        Call_StartForward(FwdShutdown);
        Call_PushCell(true);
        Call_Finish();

        SetConVarInt(mp_restartgame, 1);
    } else {
        ReplyToCommand(client, "[GunGame] is already disabled");
    }
    return Plugin_Handled;
}

public Action:_CmdLevel(client, args)
{
    if ( IsActive )
    {
        CreateLevelPanel(client);
    }
    return Plugin_Handled;
}

public Action:_CmdLeader(client, args)
{
    if ( IsActive )
    {
        ShowLeaderMenu(client);
    }
    return Plugin_Handled;
}

public Action:_CmdRules(client, args)
{
    if(IsActive)
    {
        ShowRulesMenu(client);
    }
    return Plugin_Handled;
}

public Action:_CmdScore(client, args)
{
    if(IsActive)
    {
        ShowPlayerLevelMenu(client);
    }
    return Plugin_Handled;
}

public Action:_CmdWeapons(client, args)
{
    if(IsActive)
    {
        ShowWeaponLevelPanel(client);
    }
    return Plugin_Handled;
}

public Action:_CmdCommand(client, args)
{
    if(IsActive)
    {
        ShowCommandPanel(client);
    }
    return Plugin_Handled;
}

public Action:_CmdVersion(client, args)
{
    if(GetCmdReplySource() == SM_REPLY_TO_CHAT)
    {
        CPrintToChat(client, "%t", "Please view your console for more information");
    }

    PrintToConsole(client, "Gun Game Information:\n   Version: %s\n   Author: %s", GUNGAME_VERSION, GUNGAME_AUTHOR);
    PrintToConsole(client, "   Website: http://www.sourcemod.net\n   Compiled Time: %s %s", DATE, TIME);
    PrintToConsole(client, "\n   Idea and concepts of Gun Game was\n   originally made by cagemonkey\n   @ http://www.cagemonkey.org");

    return Plugin_Handled;
}

public Action:CmdReset(client, args)
{
    if(IsActive)
    {
        /* Reset the game and start over */
        for(new i = 1; i <= MaxClients; i++)
        {
            PlayerLevel[i] = 0;
            UTIL_UpdatePlayerScoreLevel(i);
        }

        SetConVarInt(mp_restartgame, 1);
    }

    return Plugin_Handled;
}

public Action:_CmdStatus(client, args)
{
    /**
     * Add a command called gg_status this will tell the state of the current game.
     * If the game is still in warmup round, warmup round has start/not started, If game is started
     * or not and if started it will state the leader level and gun.
     */

    if(IsActive)
    {
        ReplyToCommand(client, "[GunGame] Currently not implmented");
    }

    return Plugin_Handled;
}

public Action:_CmdAdminSetlevel(client, args)
{
    if(!IsActive)
    {
        ReplyToCommand(client, "[GunGame] is not enabled!");
        return Plugin_Handled;
    }

    // usage
    if (args != 2)
    {
        ReplyToCommand(client, "Usage: gg_setlevel <target> <level>");
        return Plugin_Handled;
    }

    // find target
    new String: target_string[65];
    GetCmdArg(1, target_string, sizeof(target_string));
    int target = FindTarget(client, target_string, false, false);
    if (!IsClientConnected(target) || !IsClientInGame(target))
    {
        ReplyToCommand(client, "Invalid target!");
        return Plugin_Handled;
    }

    // level
    int oldLevel = PlayerLevel[target], setLevel;
    char level_string[16];
    GetCmdArg(2, level_string, sizeof(level_string));
    if (level_string[0] == '-' || level_string[0] == '+')
    {
        setLevel = StringToInt(level_string);
    }
    else
    {
        setLevel = StringToInt(level_string) - oldLevel - 1;
    }
    int newLevel = UTIL_ChangeLevel(target, setLevel);
    UTIL_GiveNextWeapon(target, newLevel);

    decl String:name[MAX_NAME_SIZE];
    GetClientName(target, name, sizeof(name));
    PrintLeaderToChat(target, oldLevel, newLevel, name);
    return Plugin_Handled;
}

public Action:_CmdAdminWin(client, args)
{
    if(!IsActive)
    {
        ReplyToCommand(client, "[GunGame] is not enabled!");
        return Plugin_Handled;
    }

    // find target
    if (args == 0)
    {
        if(CurrentLeader == 0)
        {
            ReplyToCommand(client, "[GunGame] There is no leader!");
            return Plugin_Handled;
        }
        char targetName[MAX_NAME_LENGTH];
        GetClientName(CurrentLeader, targetName, sizeof(targetName));
        ReplyToCommand(client, "[GunGame] Forcing best player (%s) to win...", targetName);
        UTIL_ChangeLevel(CurrentLeader, WeaponOrderCount);
    }
    else if (args == 1)
    {
        new String: target_string[65];
        GetCmdArg(1, target_string, sizeof(target_string));
        int target = FindTarget(client, target_string, false, false);

        if (target && IsClientConnected(target) && IsClientInGame(target))
        {
            char targetName[MAX_NAME_LENGTH];
            GetClientName(target, targetName, sizeof(targetName));
            ReplyToCommand(client, "[GunGame] Forcing player (%s) to win (cheater)...", targetName);
            UTIL_ChangeLevel(target, WeaponOrderCount);
        } else {
            ReplyToCommand(client, "Invalid target!");
        }
    }
    else
    {
        ReplyToCommand(client, "Usage: gg_win [target]");
    }

    return Plugin_Handled;
}

public Action:_CmdAdminFfa(client, args)
{
    if(!IsActive)
    {
        ReplyToCommand(client, "[GunGame] is not enabled!");
    }
    else if (args == 0)
    {
        ReplyToCommand(client, "[GunGame] FFA is currently %s", FFA ? "enabled" : "disabled");
    }
    else if (args > 2)
    {
        ReplyToCommand(client, "Usage: gg_ffa [enable=0/1] [restart round=0/1]");
    }
    else
    {
        char ConfigGameDirName[PLATFORM_MAX_PATH];
        GG_ConfigGetDir(ConfigGameDirName, sizeof(ConfigGameDirName));

        char arg1[16], arg2[16];
        GetCmdArg(1, arg1, sizeof(arg1));
        GetCmdArg(2, arg2, sizeof(arg2));
        int restartDelay = StringToInt(arg2);

        if(StrEqual(arg1, "1"))
        {
            if (FFA)
            {
                ReplyToCommand(client, "[GunGame] FFA is already enabled!");
            }
            else
            {
                FFA = true;
                InsertServerCommand("exec \\%s\\gungame.ffa_on.cfg", ConfigGameDirName);
                CPrintToChatAll("%t", "FFA has been enabled");
                CPrintToChatAll("%t", "FFA has been enabled");
                CPrintToChatAll("%t", "FFA has been enabled");
            }
        }
        else if(StrEqual(arg1, "0"))
        {
            if (!FFA)
            {
                ReplyToCommand(client, "[GunGame] FFA is already disabled!");
            }
            else
            {
                FFA = false;
                CPrintToChatAll("%t", "FFA has been disabled");
                CPrintToChatAll("%t", "FFA has been disabled");
                CPrintToChatAll("%t", "FFA has been disabled");
                InsertServerCommand("exec \\%s\\gungame.ffa_off.cfg", ConfigGameDirName);
            }
        }

        if(restartDelay > 0)
        {
            CPrintToChatAll("%t", "GAME WILL RESTART");
            if(IsActive)
            {
                /* Reset the game and start over */
                for(new i = 1; i <= MaxClients; i++)
                {
                    PlayerLevel[i] = 0;
                    UTIL_UpdatePlayerScoreLevel(i);
                }

                SetConVarInt(mp_restartgame, restartDelay);
            }
        }
    }

    return Plugin_Handled;
}
