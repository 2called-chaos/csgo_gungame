#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <gungame>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_AUTHOR      "2called-chaos"
#define PLUGIN_NAME        "Gungame: OneShot AWP"
#define PLUGIN_VERSION     "1.0.1"
#define PLUGIN_DESCRIPTION "Sets and monitors the AWP clip size to 1 (hit = refill, miss = reload)"
#define PLUGIN_URL         "https://github.com/2called-chaos/csgo_gungame"

public Plugin myinfo = { name = PLUGIN_NAME, author = PLUGIN_AUTHOR, description = PLUGIN_DESCRIPTION, version = PLUGIN_VERSION, url = PLUGIN_URL };

bool g_bLateLoad = false;
bool g_bEnabled = false;
bool g_bTakeReserveAmmo = false;
int g_iReserveAmmo = -1;
int g_iReloadingWeapons[MAXPLAYERS+1] = {-1,...};

// cvars
ConVar g_Cvar_PluginVersion;
ConVar g_Cvar_PluginEnabled;
ConVar g_Cvar_ReserveAmmo;
ConVar g_Cvar_TakeReserveAmmo;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
  g_bLateLoad = late;
}

public void OnPluginStart()
{
    // cvars
    g_Cvar_PluginVersion = CreateConVar("sm_ggosa_version", PLUGIN_VERSION, "plugin version", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
    g_Cvar_PluginEnabled = CreateConVar("sm_ggosa_enabled", "1", "Whether to apply OneShot AWP clip size modifications", FCVAR_NONE, true, 0.0, true, 1.0);
    g_Cvar_PluginEnabled.AddChangeHook(OnEnableChange);

    g_Cvar_ReserveAmmo = CreateConVar("sm_ggosa_reserve_ammo", "1", "Change AWP reserve ammo, set to 0 to disable", FCVAR_NONE, true, 0.0, true, 511.0);
    g_Cvar_ReserveAmmo.AddChangeHook(OnConVarChanged);

    g_Cvar_TakeReserveAmmo = CreateConVar("sm_ggosa_take_reserve_ammo", "0", "If set to 0 reserve ammo won't deplete on reload", FCVAR_NONE, true, 0.0, true, 1.0);
    g_Cvar_TakeReserveAmmo.AddChangeHook(OnConVarChanged);

    AutoExecConfig();
    OnConVarChanged(g_Cvar_PluginVersion, "", "");

    if (g_bLateLoad && g_bEnabled)
        for (int i = 1; i <= MaxClients; i++)
            if (IsClientInGame(i)) OnClientPutInServer(i);
}

public void OnEnableChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
    bool disabled = g_bEnabled && !convar.BoolValue;
    bool enabled = !g_bEnabled && convar.BoolValue;
    g_bEnabled = convar.BoolValue;

    if(disabled)
    {
        for (int i = 1; i <= MaxClients; i++)
            if (IsClientInGame(i)) OnClientDisconnect(i);
    }
    else if (enabled)
    {
        for (int i = 1; i <= MaxClients; i++)
            if (IsClientInGame(i)) OnClientPutInServer(i);
    }
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_bEnabled = convar.BoolValue;
    g_iReserveAmmo = g_Cvar_ReserveAmmo.IntValue;
    g_bTakeReserveAmmo = g_Cvar_TakeReserveAmmo.BoolValue;
}

public void OnMapStart()
{
}

public void OnClientPutInServer(int client)
{
    g_iReloadingWeapons[client] = -1;
    SDKHook(client, SDKHook_WeaponSwitch, CompleteWeaponReload);
}

public void OnClientDisconnect(int client)
{
    g_iReloadingWeapons[client] = -1;
    SDKUnhook(client, SDKHook_WeaponSwitch, CompleteWeaponReload);
}

// GG forward: fix clip/ammo right after weapon equip
public Action GG_OnWeaponEquipped(int weapon)
{
    if (g_bEnabled && IsWeaponAwp(weapon))
    {
        SetEntProp(weapon, Prop_Send, "m_iClip1", 1);
        if (g_iReserveAmmo > 0)
            SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", g_iReserveAmmo);
        SDKHook(weapon, SDKHook_Reload, OnWeaponReload);
    }
    return Plugin_Continue;
}

// GG forward: fix clip right after GG reloaded weapon due to kill
public Action GG_OnWeaponInstantReloaded(int weapon)
{
    if (g_bEnabled && IsWeaponAwp(weapon))
        SetEntProp(weapon, Prop_Send, "m_iClip1", 2);
    return Plugin_Continue;
}

// Track weapon reloading (check for weapon switch and wait for reload to finish)
public Action OnWeaponReload(int weapon)
{
    if (g_bEnabled && IsWeaponAwp(weapon))
    {
        int clip = GetEntProp(weapon, Prop_Send, "m_iClip1");

        if (clip == 0)
        {
            // start timer to check when the weapon is reloaded
            Handle data = INVALID_HANDLE;
            int client = GetEntPropEnt(weapon, Prop_Send, "m_hOwner");
            CreateDataTimer(0.1, Timer_FixAwpAmmunition, data, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
            WritePackCell(data, EntIndexToEntRef(weapon));
            WritePackCell(data, GetClientUserId(client));
        }
        else
        {
            // For some reason the clip is larger than it should, adjust it (should never happen)
            if (clip > 1) SetEntProp(weapon, Prop_Send, "m_iClip1", 1);

            // AWP is "full", block reload
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

// Fix clip/ammo after reload animation or weapon switch
public Action CompleteWeaponReload(int client, int weapon)
{
    if (g_iReloadingWeapons[client] == weapon)
    {
        int clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
        SetEntProp(weapon, Prop_Send, "m_iClip1", 1);

        int ammo = GetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount");
        if (g_bTakeReserveAmmo) ammo--;
        SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", ammo + clip);
        g_iReloadingWeapons[client] = -1;
    }
    return Plugin_Continue;
}

// Timer to wait for reload to finish
public Action Timer_FixAwpAmmunition(Handle event, DataPack data)
{
    if (data == INVALID_HANDLE)
    {
        LogError("Invalid data timer!");
        return Plugin_Stop;
    }

    // Retrieve all the data from timer
    ResetPack(data);
    int weapon  = EntRefToEntIndex(ReadPackCell(data));
    int client  = GetClientOfUserId(ReadPackCell(data));

    // If weapon reference or client is invalid, stop timer immediately
    if (weapon == INVALID_ENT_REFERENCE || !client)
        return Plugin_Stop;

    if (GetEntProp(weapon, Prop_Data, "m_bInReload", true))
    {
        // remember which weapon is reloading
        g_iReloadingWeapons[client] = weapon;
    }
    else
    {
        CompleteWeaponReload(client, GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"));
        return Plugin_Stop;
    }
    return Plugin_Continue;
}

bool IsWeaponAwp(int weapon)
{
    if (weapon <= MaxClients) return false;
    char classname[64];
    GetEdictClassname(weapon, classname, sizeof(classname));
    return StrEqual(classname, "weapon_awp");
}
