#pragma semicolon 1

#include <sourcemod>
#include <csgo_motdfix>
#include <gungame_const>
#include <gungame>
#include <gungame_stats>
#include <gungame_config>
#include <url>

new bool:g_showWinnerOnRankUpdate = false;
new g_winner;
new g_lastVictim[MAXPLAYERS+1];

new State:ConfigState;
new g_Cfg_DisplayWinnerMotd = 0;
new String:g_Cfg_DisplayWinnerUrl[256];
new g_Cfg_ShowPlayerRankOnWin = 1;

public Plugin:myinfo =
{
    name = "GunGame:SM Display Winner",
    description = "Shows a MOTD window with the winner's information when the game is won.",
    author = "bl4nk, Otstrel.ru Team",
    version = GUNGAME_VERSION,
    url = "http://forums.alliedmods.net, http://otstrel.ru"
};

public OnPluginStart()
{
    HookEvent("player_death", Event_PlayerDeath);

    ResetLastVictims();
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    if ( !g_Cfg_DisplayWinnerMotd )
    {
        return;
    }
    new victim = GetClientOfUserId(GetEventInt(event, "userid"));
    new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    g_lastVictim[attacker] = victim;
}

public GG_OnWinner(client, const String:weapon[], victim)
{
    if ( ( !g_Cfg_DisplayWinnerMotd && !g_Cfg_ShowPlayerRankOnWin ) || IsFakeClient(client) )
    {
        return;
    }
    g_showWinnerOnRankUpdate = true;
    g_winner = client;
}

public GG_OnLoadRank()
{
    if ( ( !g_Cfg_DisplayWinnerMotd && !g_Cfg_ShowPlayerRankOnWin ) || !g_showWinnerOnRankUpdate )
    {
        return;
    }
    g_showWinnerOnRankUpdate = false;

    if ( !IsClientInGame(g_winner) )
    {
        return;
    }

    if ( g_Cfg_ShowPlayerRankOnWin )
    {
        GG_ShowRank(g_winner);                  /* HINT: gungame_stats */
    }
    if ( g_Cfg_DisplayWinnerMotd )
    {
        ShowWinnerMotdAll();
    }
}

public GG_ConfigNewSection(const String:name[])
{
    if ( strcmp("Config", name, false) == 0 )
    {
        ConfigState = CONFIG_STATE_CONFIG;
    }
}

public GG_ConfigKeyValue(const String:key[], const String:value[])
{
    if ( ConfigState == CONFIG_STATE_CONFIG )
    {
        if ( strcmp("DisplayWinnerMotd", key, false) == 0 ) {
            g_Cfg_DisplayWinnerMotd = StringToInt(value);
        } else if ( strcmp("DisplayWinnerUrl", key, false) == 0 ) {
            strcopy(g_Cfg_DisplayWinnerUrl, sizeof(g_Cfg_DisplayWinnerUrl), value);
        } else if ( strcmp("ShowPlayerRankOnWin", key, false) == 0 ) {
            g_Cfg_ShowPlayerRankOnWin = StringToInt(value);
        }
    }
}

public GG_ConfigParseEnd()
{
    ConfigState = CONFIG_STATE_NONE;
    ResetLastVictims();
}

public OnMapEnd()
{
    g_showWinnerOnRankUpdate = false;
    ResetLastVictims();
}

void ResetLastVictims()
{
    for ( new i = 1; i <= MaxClients; i++ )
    {
        g_lastVictim[i] = -1;
    }
}

void ShowWinnerMotdAll()
{
    // get winner name/auth
    decl String:winnerName[MAX_NAME_LENGTH];
    decl String:winnerID[64];
    GetClientName(g_winner, winnerName, sizeof(winnerName));
    GetClientAuthId(g_winner, AuthId_Steam2, winnerID, sizeof(winnerID));

    // get loser name/auth
    new loserClient = g_lastVictim[g_winner];
    decl String:loserName[MAX_NAME_LENGTH];
    decl String:loserID[64];
    if(IsClientInGame(loserClient))
    {
        GetClientName(loserClient, loserName, sizeof(loserName));
        GetClientAuthId(loserClient, AuthId_Steam2, loserID, sizeof(loserID));
    }

    // get next map
    decl String:nextMap[PLATFORM_MAX_PATH];
    GetNextMap(nextMap, sizeof(nextMap));
    GetMapDisplayName(nextMap, nextMap, sizeof(nextMap));

    // urlencode variables
    decl String:winnerNameUrlEncoded[sizeof(winnerName)*3+1];
    decl String:winnerIDUrlEncoded[sizeof(winnerID)*3+1];
    decl String:loserNameUrlEncoded[sizeof(loserName)*3+1];
    decl String:loserIDUrlEncoded[sizeof(loserID)*3+1];
    decl String:nextMapUrlEncoded[sizeof(nextMap)*3+1];
    url_encode(winnerName, sizeof(winnerName), winnerNameUrlEncoded, sizeof(winnerNameUrlEncoded));
    url_encode(winnerID, sizeof(winnerID), winnerIDUrlEncoded, sizeof(winnerIDUrlEncoded));
    url_encode(loserName, sizeof(loserName), loserNameUrlEncoded, sizeof(loserNameUrlEncoded));
    url_encode(loserID, sizeof(loserID), loserIDUrlEncoded, sizeof(loserIDUrlEncoded));
    url_encode(nextMap, sizeof(nextMap), nextMapUrlEncoded, sizeof(nextMapUrlEncoded));

    // build URL
    decl String:url[128+sizeof(g_Cfg_DisplayWinnerUrl)];
    new bool:urlHasParams = (StrContains(g_Cfg_DisplayWinnerUrl, "?", true) != -1);
    Format(url, sizeof(url), "%s%swinnerName=%s&winnerID=%s&loserName=%s&loserID=%s&wins=%i&place=%i&totalPlaces=%i&nextMap=%s",
        g_Cfg_DisplayWinnerUrl,
        urlHasParams? "&": "?",
        winnerNameUrlEncoded,
        winnerIDUrlEncoded,
        loserNameUrlEncoded,
        loserIDUrlEncoded,
        GG_GetClientWins(g_winner),         /* HINT: gungame_stats */
        GG_GetPlayerPlaceInStat(g_winner),  /* HINT: gungame_stats */
        GG_CountPlayersInStat(),            /* HINT: gungame_stats */
        nextMapUrlEncoded
    );

    // open winner page for all clients
    for ( new i = 1; i <= MaxClients; i++ )
    {
        if ( IsClientInGame(i) )
        {
            // get each client's auth and pass it too
            decl String:clientID[64];
            decl String:clientIDUrlEncoded[sizeof(clientID)*3+1];
            GetClientAuthId(i, AuthId_Steam2, clientID, sizeof(clientID));
            url_encode(clientID, sizeof(clientID), clientIDUrlEncoded, sizeof(clientIDUrlEncoded));

            decl String:urlCopy[sizeof(url)];
            Format(urlCopy, sizeof(urlCopy), "%s&clientID=%s", url, clientIDUrlEncoded);
            MOTDFixOpenURL(i, "", urlCopy);
        }
    }
}
