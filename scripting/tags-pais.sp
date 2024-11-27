#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <geoip>
#include <multicolors>

#define PLUGIN_VERSION "1.0.1"
#define PLUGIN_TAG "{purple}[CountryTag]{default}"
#define CVAR_FLAGS FCVAR_NOTIFY

char g_sOriginalName[MAXPLAYERS + 1][MAX_NAME_LENGTH];
char g_sCustomTag[MAXPLAYERS + 1][5];

// ConVars
ConVar g_cvPlayerJoinMessage;
ConVar g_cvPlayerJoinMessageLayout;
ConVar g_cvNameLayout;
ConVar g_cvShowCountryList;
ConVar g_cvPluginVersion;

public Plugin myinfo = 
{
    name = "NMRiH Country Tag",
    author = "IIBladeII",
    description = "Adds country tag to player names",
    version = PLUGIN_VERSION,
    url = "https://github.com/IIBladeII"
};

public void OnPluginStart()
{
    // Load translations
    LoadTranslations("common.phrases");
    
    // Create ConVars
    g_cvPlayerJoinMessage = CreateConVar("nmrih_ct_join_message", "1", "Show message when player joins (1 = Yes, 0 = No)", CVAR_FLAGS);
    g_cvPlayerJoinMessageLayout = CreateConVar("nmrih_ct_join_layout", "{purple}{NAME} from {LOC} has joined the server.", "Welcome message format. {NAME} = player name, {LOC} = country", CVAR_FLAGS);
    g_cvNameLayout = CreateConVar("nmrih_ct_name_layout", "{NAME} [{TAG}]", "Player name layout with tag", CVAR_FLAGS);
    g_cvShowCountryList = CreateConVar("nmrih_ct_show_list", "1", "Allow !countries command to list players (1 = Yes, 0 = No)", CVAR_FLAGS);
    g_cvPluginVersion = CreateConVar("nmrih_ct_version", PLUGIN_VERSION, "Country Tag Plugin Version", CVAR_FLAGS|FCVAR_DONTRECORD);
    
    // Register commands
    RegConsoleCmd("sm_countries", Command_ListPlayers, "List all players and their countries");
    RegAdminCmd("sm_settag", Command_SetTag, ADMFLAG_GENERIC, "Set a player's custom tag");
    RegAdminCmd("sm_resettag", Command_ResetTag, ADMFLAG_GENERIC, "Remove a player's custom tag");
    
    // Generate config file
    AutoExecConfig(true, "nmrih_country_tag");
    
    // Hook events
    HookEvent("player_changename", Event_PlayerChangeName, EventHookMode_Pre);
}

public void OnClientConnected(int client)
{
    if (client > 0)
    {
        g_sCustomTag[client][0] = '\0'; // Clear custom tag
    }
}

public void OnClientPostAdminCheck(int client)
{
    if (client > 0 && !IsFakeClient(client))
    {
        char IP[16];
        char Country[100];
        
        GetClientIP(client, IP, sizeof(IP));
        GetClientName(client, g_sOriginalName[client], sizeof(g_sOriginalName[]));
        
        if (g_cvPlayerJoinMessage.BoolValue)
        {
            if (GeoipCountry(IP, Country, sizeof(Country)))
            {
                // Add "The" prefix for certain countries
                if (StrContains(Country, "United", false) != -1 || 
                    StrContains(Country, "Republic", false) != -1)
                {
                    Format(Country, sizeof(Country), "The %s", Country);
                }
                
                char szMessage[256];
                char szName[MAX_NAME_LENGTH];
                GetClientName(client, szName, sizeof(szName));
                
                g_cvPlayerJoinMessageLayout.GetString(szMessage, sizeof(szMessage));
                ReplaceString(szMessage, sizeof(szMessage), "{NAME}", szName);
                ReplaceString(szMessage, sizeof(szMessage), "{LOC}", Country);
                
                CPrintToChatAll(szMessage);
            }
        }
        
        // Update name with tag
        UpdatePlayerNameTag(client);
    }
}

public Action Command_SetTag(int client, int args)
{
    if (args < 2)
    {
        CPrintToChat(client, "%s Usage: !settag <player> <tag>", PLUGIN_TAG);
        return Plugin_Handled;
    }
    
    char target[32];
    char tag[5];
    GetCmdArg(1, target, sizeof(target));
    GetCmdArg(2, tag, sizeof(tag));
    
    int targetClient = FindTarget(client, target, true, false);
    if (targetClient == -1)
    {
        return Plugin_Handled;
    }
    
    strcopy(g_sCustomTag[targetClient], sizeof(g_sCustomTag[]), tag);
    UpdatePlayerNameTag(targetClient);
    
    CPrintToChat(client, "%s Successfully set tag for %N to [%s]", PLUGIN_TAG, targetClient, tag);
    return Plugin_Handled;
}

public Action Command_ResetTag(int client, int args)
{
    if (args < 1)
    {
        CPrintToChat(client, "%s Usage: !resettag <player>", PLUGIN_TAG);
        return Plugin_Handled;
    }
    
    char target[32];
    GetCmdArg(1, target, sizeof(target));
    
    int targetClient = FindTarget(client, target, true, false);
    if (targetClient == -1)
    {
        return Plugin_Handled;
    }
    
    g_sCustomTag[targetClient][0] = '\0';
    UpdatePlayerNameTag(targetClient);
    
    CPrintToChat(client, "%s Successfully reset tag for %N", PLUGIN_TAG, targetClient);
    return Plugin_Handled;
}

public Action Command_ListPlayers(int client, int args)
{
    if (!g_cvShowCountryList.BoolValue)
    {
        CPrintToChat(client, "%s This command is disabled.", PLUGIN_TAG);
        return Plugin_Handled;
    }
    
    CPrintToChat(client, "%s List of players and their countries:", PLUGIN_TAG);
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            char IP[16];
            char Country[100];
            GetClientIP(i, IP, sizeof(IP));
            
            if (GeoipCountry(IP, Country, sizeof(Country)))
            {
                CPrintToChat(client, "%s %N - %s", PLUGIN_TAG, i, Country);
            }
        }
    }
    
    return Plugin_Handled;
}

public Action Event_PlayerChangeName(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && IsClientInGame(client))
    {
        char newName[MAX_NAME_LENGTH];
        event.GetString("newname", newName, sizeof(newName));
        strcopy(g_sOriginalName[client], sizeof(g_sOriginalName[]), newName);
        
        UpdatePlayerNameTag(client);
    }
    return Plugin_Handled;
}

void UpdatePlayerNameTag(int client)
{
    if (!IsClientInGame(client) || IsFakeClient(client))
        return;
        
    char IP[16];
    char Country[3];
    GetClientIP(client, IP, sizeof(IP));
    
    char nameFormat[128];
    g_cvNameLayout.GetString(nameFormat, sizeof(nameFormat));
    
    char finalName[MAX_NAME_LENGTH];
    char tag[5];
    
    if (g_sCustomTag[client][0] != '\0')
    {
        strcopy(tag, sizeof(tag), g_sCustomTag[client]);
    }
    else if (GeoipCode2(IP, Country))
    {
        strcopy(tag, sizeof(tag), Country);
    }
    else
    {
        strcopy(tag, sizeof(tag), "??");
    }
    
    ReplaceString(nameFormat, sizeof(nameFormat), "{NAME}", g_sOriginalName[client]);
    ReplaceString(nameFormat, sizeof(nameFormat), "{TAG}", tag);
    strcopy(finalName, sizeof(finalName), nameFormat);
    
    SetClientName(client, finalName);
}