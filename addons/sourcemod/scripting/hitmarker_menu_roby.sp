#include <sourcemod>
#include <sdktools>
#include <clientprefs>

/* im ready for csurf people remove credits and put their community here ;) */
public Plugin myinfo = {
    name = "Hitmarker Menu",
    author = "roby", /* s/o zauni and era surf community */
    description = "Choose your custom kill/hit hitmarker!",
    version = "2.0",
    url = "https://steamcommunity.com/id/sleepiest/ OR roby#0577"
};

// code is very old sorry if it looks like ****

/***********/
/* globals */

#define TAG_HM 						"\x01 \x0B[Hitmarker]\x01"
#define TAG_DM 						"\x01 \x0B[Deathmarker]\x01"
#define TAG_HS 						"\x01 \x0B[Hitsound]\x01"
#define TAG_DS 						"\x01 \x0B[Deathsound]\x01"
#define HITMARKER_SHOW_TIME			0.45
#define SPECMODE_NONE 				0
#define SPECMODE_FIRSTPERSON 		4
#define SPECMODE_3RDPERSON 			5
#define SPECMODE_FREELOOK	 		6

char hitmarker_kill_path[20][PLATFORM_MAX_PATH];
char hitmarker_kill_name[20][32];

char hitmarker_hit_path[20][PLATFORM_MAX_PATH];
char hitmarker_hit_name[20][32];

char hitsound_path[20][PLATFORM_MAX_PATH];
char hitsound_name[20][32];

char deathmarker_path[20][PLATFORM_MAX_PATH];
char deathmarker_name[20][32];

char deathsound_path[20][PLATFORM_MAX_PATH];
char deathsound_name[20][32];

Cookie g_cookie_hitmarker;
Cookie g_cookie_hit;
Cookie g_cookie_hitsound;
Cookie g_cookie_deathmarker;
Cookie g_cookie_deathsound;

int hitmarkers_kill;
int hitmarkers_hit;
int hitsounds;
int deathmarkers;
int deathsounds;
int g_client_hitmarker[MAXPLAYERS + 1] 		= {1, ...}; // default hitmarker: wingsmarkerv2_era (1)
int g_client_hit[MAXPLAYERS + 1] 			= {0, ...};	// default hit: none (0)
int g_client_hitsound[MAXPLAYERS + 1] 		= {1, ...};
int g_client_deathmarker[MAXPLAYERS + 1]	= {1, ...};
int g_client_deathsound[MAXPLAYERS + 1] 	= {1, ...};

public OnPluginStart() {
	RegConsoleCmd("sm_hitmarker", cmd_hitmarker);
	RegConsoleCmd("sm_hitmarkers", cmd_hitmarker);
	RegConsoleCmd("sm_hitmark", cmd_hitmarker);
	RegConsoleCmd("sm_hm", cmd_hitmarker);
	
	RegConsoleCmd("sm_hit", cmd_hit);
	
	RegConsoleCmd("sm_hitsounds", cmd_hitsound);
	RegConsoleCmd("sm_hitsound", cmd_hitsound);
	RegConsoleCmd("sm_hs", cmd_hitsound);
	
	RegConsoleCmd("sm_deathmarker", cmd_deathmarker);
	RegConsoleCmd("sm_deathmarkers", cmd_deathmarker);
	RegConsoleCmd("sm_deathmark", cmd_deathmarker);
	RegConsoleCmd("sm_dm", cmd_deathmarker);
	
	RegConsoleCmd("sm_deathsound", cmd_deathsound);
	RegConsoleCmd("sm_deathsounds", cmd_deathsound);
	RegConsoleCmd("sm_ds", cmd_deathsound);
	
	HookEvent("player_hurt", event_player_hurt, EventHookMode_Post);
	HookEvent("player_death", event_player_death);
	
	g_cookie_hitmarker 		= new Cookie("roby_hitmarker_kill", "Kill hitmarker", CookieAccess_Private);
	g_cookie_hit			= new Cookie("roby_hitmarker_hit", "Hit hitmarker", CookieAccess_Private);
	g_cookie_hitsound		= new Cookie("roby_hitsound", "Hitsound", CookieAccess_Private);
	g_cookie_deathmarker 	= new Cookie("roby_deathmarker", "Deathmarker", CookieAccess_Private);
	g_cookie_deathsound 	= new Cookie("roby_deathsound", "Deathsound", CookieAccess_Private);
	
	ParseHM();
	ParseHit();
	ParseHS();
	ParseDM();
	ParseDS();
	
	for (int i = MaxClients; i > 0; --i)
        if(AreClientCookiesCached(i))
			OnClientCookiesCached(i);
}

/************/
/* commands */

public Action cmd_hitmarker(int client, int args) {
	if (is_valid_client(client)) {
		init_hitmarker_menu(client);
	}
	return Plugin_Handled;
}

public Action cmd_hit(int client, int args) {
	if (is_valid_client(client)) {
		init_hit_menu(client);
	}
	return Plugin_Handled;
}

public Action cmd_hitsound(int client, int args) {
	if (is_valid_client(client)) {
		init_hitsound_menu(client);
	}
	return Plugin_Handled;
}

public Action cmd_deathmarker(int client, int args) {
	if (is_valid_client(client)) {
		init_deathmarker_menu(client);
	}
	return Plugin_Handled;
}

public Action cmd_deathsound(int client, int args) {
	if (is_valid_client(client)) {
		init_deathsound_menu(client);
	}
	return Plugin_Handled;
}


/***********************/
/* menus and callbacks */

void init_hitmarker_menu(int client) {
	char info[8], item[64];
	Menu menu = new Menu(hitmarker_menu_cb);
	menu.SetTitle("Choose your hitmarker (on kill):");
	for (int i = 0; i < hitmarkers_kill; i++) {
		Format(item, sizeof(item), "%s %s", hitmarker_kill_name[i], i == g_client_hitmarker[client] ? "[X]" : " ");
		IntToString(i, info, sizeof(info));
		menu.AddItem(info, item);
	}
	menu.Display(client, MENU_TIME_FOREVER);
}

void init_hit_menu(int client) {
	char info[8], item[64];
	Menu menu = new Menu(hit_menu_cb);
	menu.SetTitle("Choose your hitmarker (on hit):");
	for (int i = 0; i < hitmarkers_hit; i++) {
		Format(item, sizeof(item), "%s %s", hitmarker_hit_name[i], i == g_client_hit[client] ? "[X]" : " ");
		IntToString(i, info, sizeof(info));
		menu.AddItem(info, item);
	}
	menu.Display(client, MENU_TIME_FOREVER);
}

void init_hitsound_menu(int client) {
	char info[8], item[64];
	Menu menu = new Menu(hitsound_menu_cb);
	menu.SetTitle("Choose your hitsound:");
	for (int i = 0; i < hitsounds; i++) {
		Format(item, sizeof(item), "%s %s", hitsound_name[i], i == g_client_hitsound[client] ? "[X]" : " ");
		IntToString(i, info, sizeof(info));
		menu.AddItem(info, item);
	}
	menu.Display(client, MENU_TIME_FOREVER);
}

void init_deathmarker_menu(int client) {
	char info[8], item[64];
	Menu menu = new Menu(deathmarker_menu_cb);
	menu.SetTitle("Choose your deathmarker:");
	for (int i = 0; i < deathmarkers; i++) {
		Format(item, sizeof(item), "%s %s", deathmarker_name[i], i == g_client_deathmarker[client] ? "[X]" : " ");
		IntToString(i, info, sizeof(info));
		menu.AddItem(info, item);
	}
	menu.Display(client, MENU_TIME_FOREVER);
}

void init_deathsound_menu(int client) {
	char info[8], item[64];
	Menu menu = new Menu(deathsound_menu_cb);
	menu.SetTitle("Choose your deathsound:");
	for (int i = 0; i < deathsounds; i++) {
		Format(item, sizeof(item), "%s %s", deathsound_name[i], i == g_client_deathsound[client] ? "[X]" : " ");
		IntToString(i, info, sizeof(info));
		menu.AddItem(info, item);
	}
	menu.Display(client, MENU_TIME_FOREVER);
}

public int hitmarker_menu_cb(Menu menu, MenuAction action, int client, int param) {
	switch (action) {
		case MenuAction_End: { 
			menu.Close();
		}

		case MenuAction_Select: {
			char item[32];
			menu.GetItem(param, item, sizeof(item));
			
			int option = StringToInt(item);
			SetClientCookie(client, g_cookie_hitmarker, item); // pls work
			g_client_hitmarker[client] = option;

			if (!option)	PrintToChat(client, "%s \x0FYou disabled \x07hitmarkers on kill", TAG_HM);
			else			PrintToChat(client, "%s \x0FYou chose \x07\"%s\" \x0Fhitmarker (on kill)", TAG_HM, hitmarker_kill_name[option]);

			cl_show_overlay(client, hitmarker_kill_path[option]);
			CreateTimer(HITMARKER_SHOW_TIME, cl_hide_overlay, client);
        }
    }
}

public int hit_menu_cb(Menu menu, MenuAction action, int client, int param) {
	switch (action) {
		case MenuAction_End: { 
			menu.Close(); 
		}

		case MenuAction_Select: {
			char item[32];
			menu.GetItem(param, item, sizeof(item));
			
			int option = StringToInt(item);
			SetClientCookie(client, g_cookie_hit, item); // pls work
			g_client_hit[client] = option;

			if (!option)	PrintToChat(client, "%s \x0FYou disabled \x07hitmarkers on hit.", TAG_HM);
			else			PrintToChat(client, "%s \x0FYou chose \x07\"%s\" \x0Fhitmarker (on hit)", TAG_HM, hitmarker_hit_name[option]);
			
			cl_show_overlay(client, hitmarker_hit_path[option]);
			CreateTimer(HITMARKER_SHOW_TIME, cl_hide_overlay, client);
		}
	}
}

public int hitsound_menu_cb(Menu menu, MenuAction action, int client, int param) {
	switch (action) {
		case MenuAction_End: { 
			menu.Close(); 
		}

		case MenuAction_Select: {
			char item[32];
			menu.GetItem(param, item, sizeof(item));
			
			int option = StringToInt(item);
			SetClientCookie(client, g_cookie_hitsound, item); // pls work
			g_client_hitsound[client] = option;

			if (!option)	PrintToChat(client, "%s \x0FYou disabled \x07hitsounds", TAG_HS);
			else			PrintToChat(client, "%s \x0FYou chose \x07\"%s\" \x0Fhitsound", TAG_HS, hitsound_name[option]);
			
			cl_play_sound(client, hitsound_path[option]);
		}
	}
}

public int deathmarker_menu_cb(Menu menu, MenuAction action, int client, int param) {
	switch (action) {
		case MenuAction_End: { 
			menu.Close(); 
		}

		case MenuAction_Select: {
			char item[32];
			menu.GetItem(param, item, sizeof(item));
			
			int option = StringToInt(item);
			SetClientCookie(client, g_cookie_deathmarker, item); // pls work
			g_client_deathmarker[client] = option;

			if (!option)	PrintToChat(client, "%s \x0FYou disabled \x07deathmarkers", TAG_DM);
			else			PrintToChat(client, "%s \x0FYou chose \x07\"%s\" \x0Fdeathmarker", TAG_DM, deathmarker_name[option]);
			
			cl_show_overlay(client, deathmarker_path[option]);
			CreateTimer(HITMARKER_SHOW_TIME, cl_hide_overlay, client);
		}
	}
}

public int deathsound_menu_cb(Menu menu, MenuAction action, int client, int param) {
	switch (action) {
		case MenuAction_End: { 
			menu.Close(); 
		}

		case MenuAction_Select: {
			char item[32];
			menu.GetItem(param, item, sizeof(item));
			
			int option = StringToInt(item);
			SetClientCookie(client, g_cookie_deathsound, item); // pls work
			g_client_deathsound[client] = option;

			if (!option)	PrintToChat(client, "%s \x0FYou disabled \x07deathsounds", TAG_DS);
			else			PrintToChat(client, "%s \x0FYou chose \x07\"%s\" \x0Fdeathsound", TAG_DS, deathsound_name[option]);
			
			cl_play_sound(client, deathsound_path[option]);
		}
	}
}


/**********/
/* events */

public Action event_player_hurt(Event event, const char[] name, bool dontBroadcast) {
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	if (is_valid_client(attacker) && g_client_hit[attacker]) {
		cl_show_overlay(attacker, hitmarker_hit_path[g_client_hit[attacker]]);
		cl_play_sound(attacker, hitsound_path[g_client_hitsound[attacker]]);
		CreateTimer(HITMARKER_SHOW_TIME, cl_hide_overlay, attacker);
	}
	
	show_to_spec(attacker, 0, false);
	return Plugin_Handled;
}

public Action event_player_death(Event event, const char[] name, bool dontBroadcast) {
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victim 	 = GetClientOfUserId(event.GetInt("userid"));
    
	if (is_valid_client(attacker) && g_client_hitmarker[attacker]) {
		cl_show_overlay(attacker, hitmarker_kill_path[g_client_hitmarker[attacker]]);
		cl_play_sound(attacker, hitsound_path[g_client_hitsound[attacker]]);
		CreateTimer(HITMARKER_SHOW_TIME, cl_hide_overlay, attacker);
	}
	
	if (is_valid_client(victim) && g_client_deathmarker[victim]) {
		cl_show_overlay(victim, deathmarker_path[g_client_deathmarker[victim]]);
		cl_play_sound(victim, deathsound_path[g_client_deathsound[victim]]);
		CreateTimer(HITMARKER_SHOW_TIME, cl_hide_overlay, victim);
	}

	show_to_spec(attacker, victim, true);
	return Plugin_Handled;
}


/*************/
/* functions */

void cl_show_overlay(int client, const char[] overlaypath) {
	if(is_valid_client(client)) ClientCommand(client, "r_screenoverlay \"%s\"", overlaypath);
}

void cl_play_sound(int client, const char[] soundpath) {
	if(is_valid_client(client)) ClientCommand(client, "playgamesound \"%s\"", soundpath);
}

public Action cl_hide_overlay(Handle timer, any client) {
	if(is_valid_client(client)) cl_show_overlay(client, "");
} 

stock bool is_valid_client(int client) {
    return (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsClientSourceTV(client));
}

void show_to_spec(int attacker, int victim, bool kill) {
	// s/o kamay
	for (int spec = 1; spec <= MaxClients; spec++) {
	

		if (!is_valid_client(spec) || !IsClientObserver(spec))
			return;
			
		int iVictim = GetEntPropEnt(spec, Prop_Send, "m_hObserverTarget");
		if (kill && iVictim == victim)
		{
			cl_show_overlay(victim, deathmarker_path[g_client_deathmarker[victim]]);
			cl_play_sound(victim, deathsound_path[g_client_deathsound[victim]]);
			CreateTimer(HITMARKER_SHOW_TIME, cl_hide_overlay, victim);
			return;
		}
		
		int iSpecMode = GetEntProp(spec, Prop_Send, "m_iObserverMode");
		
		if (iSpecMode == SPECMODE_FIRSTPERSON || iSpecMode == SPECMODE_3RDPERSON) {
			int iTarget = GetEntPropEnt(spec, Prop_Send, "m_hObserverTarget");
			
			if (kill) {
				if (iTarget == attacker && g_client_hitmarker[spec])
					cl_show_overlay(spec, hitmarker_kill_path[g_client_hitmarker[spec]]);
			}
			else {
				if (iTarget == attacker && g_client_hit[spec])
					cl_show_overlay(spec, hitmarker_hit_path[g_client_hit[spec]]);
			}
			
			if (iTarget == attacker && g_client_hitsound[spec])
				cl_play_sound(attacker, hitsound_path[g_client_hitsound[attacker]]);
			
			CreateTimer(HITMARKER_SHOW_TIME, cl_hide_overlay, spec);
		}
	}
}


/***********/
/* cookies */ 
// i have no idea if this works properly xd 

public OnClientCookiesCached(int client) {
	char hm[4], hit[4], hs[4], dm[4], ds[4];
	g_cookie_hitmarker.Get(client, hm, sizeof(hm));
	g_cookie_hit.Get(client, hit, sizeof(hit));
	g_cookie_hitsound.Get(client, hs, sizeof(hs));
	g_cookie_deathmarker.Get(client, dm, sizeof(dm));
	g_cookie_deathsound.Get(client, ds, sizeof(ds));
	
	if (hm[0] == '\0') {
		SetClientCookie(client, g_cookie_hitmarker, "1");
		g_client_hitmarker[client] = 1;
	}
	else
		g_client_hitmarker[client] = StringToInt(hm);
	
	if (hit[0] == '\0') {
		SetClientCookie(client, g_cookie_hit, "0");
		g_client_hit[client] = 0;
	}
	else
		g_client_hit[client] = StringToInt(hit);
	
	if (hs[0] == '\0') {
		SetClientCookie(client, g_cookie_hitsound, "0");
		g_client_hitsound[client] = 0;
	}
	else
		g_client_hitsound[client] = StringToInt(hs);
	
	if (dm[0] == '\0') {
		SetClientCookie(client, g_cookie_deathmarker, "0");
		g_client_deathmarker[client] = 0;
	}
	else
		g_client_deathmarker[client] = StringToInt(dm);
	
	if (ds[0] == '\0') {
		SetClientCookie(client, g_cookie_deathsound, "0");
		g_client_deathsound[client] = 0;
	}
	else
		g_client_deathsound[client] = StringToInt(ds);

}

public void OnClientDisconnect(int client) {
	char hm_option[4], hit_option[4], hs_option[4];
	IntToString(g_client_hitmarker[client], hm_option, sizeof(hm_option));
	IntToString(g_client_hit[client], hit_option, sizeof(hit_option));
	IntToString(g_client_hitsound[client], hs_option, sizeof(hs_option));
	SetClientCookie(client, g_cookie_hitmarker, hm_option);
	SetClientCookie(client, g_cookie_hit, hit_option);
	SetClientCookie(client, g_cookie_hitsound, hs_option);
}


/******************/
/* download stuff */

void ParseHM() {
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/roby_hit/hitmarkers_kill.cfg");
	
	KeyValues kv = new KeyValues("hitmarkers_kill");	
	
	if (!kv.ImportFromFile(path))
	{
		LogError("[Hitmarker] Could not import hitmarkers from %s", path);
		return;
	}
		
	kv.Rewind();
	
	if (!kv.JumpToKey("Hitmarkers") && !kv.GotoFirstSubKey()) {
		LogError("[Hitmarker] Could not import Hitmarkers from %s", path);
		return;
	}
	
	hitmarkers_kill = 0;
	char buffer[64];
	do {
		kv.GetSectionName(hitmarker_kill_name[hitmarkers_kill], 32);
		kv.GetString("path", hitmarker_kill_path[hitmarkers_kill], PLATFORM_MAX_PATH);
			
		FormatEx(buffer, sizeof(buffer), "materials/%s.vmt", hitmarker_kill_path);
		if (FileExists(buffer, false)) AddFileToDownloadsTable(buffer);
				
		FormatEx(buffer, sizeof(buffer), "materials/%s.vtf", hitmarker_kill_path);
		if (FileExists(buffer, false)) AddFileToDownloadsTable(buffer);
			
		hitmarkers_kill++;
	} while (kv.GotoNextKey());
	kv.Close();
}

void ParseHit() {
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/roby_hit/hitmarkers_hit.cfg");
	
	KeyValues kv = new KeyValues("hitmarkers_hit");
	
	if (!kv.ImportFromFile(path))
	{
		LogError("[Hitmarker] Could not import hitmarkers from %s", path);
		return;
	}
		
	kv.Rewind();
	
	if (!kv.JumpToKey("Hitmarkers") && !kv.GotoFirstSubKey()) {
		LogError("[Hitmarker] Could not import hitmarkers from %s", path);
		return;
	}
	
	hitmarkers_hit = 0;
	char buffer[64];
	do {
		kv.GetSectionName(hitmarker_hit_name[hitmarkers_hit], 32);
		kv.GetString("path", hitmarker_hit_path[hitmarkers_hit], PLATFORM_MAX_PATH);
			
		FormatEx(buffer, sizeof(buffer), "materials/%s.vmt", hitmarker_hit_path);
		if (FileExists(buffer, false)) AddFileToDownloadsTable(buffer);
				
		FormatEx(buffer, sizeof(buffer), "materials/%s.vtf", hitmarker_hit_path);
		if (FileExists(buffer, false)) AddFileToDownloadsTable(buffer);
			
		hitmarkers_hit++;
	} while (kv.GotoNextKey());
	kv.Close();
}

void ParseHS() {
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/roby_hit/hitsounds.cfg");
	
	KeyValues kv = new KeyValues("hitsounds");
	
	if (!kv.ImportFromFile(path))
	{
		LogError("[Hitsound] Could not import hitmarkers from %s", path);
		return;
	}
		
	kv.Rewind();
	
	if (!kv.JumpToKey("Hitsounds") && !kv.GotoFirstSubKey()) {
		LogError("[Hitsound] Could not import hitsounds from %s", path);
		return;
	}
	
	hitsounds = 0;
	char buffer[64];
	do {
		kv.GetSectionName(hitsound_name[hitsounds], 32);
		kv.GetString("path", hitsound_path[hitsounds], PLATFORM_MAX_PATH);
			
		FormatEx(buffer, sizeof(buffer), "sound/%s", hitsound_path);
		if (FileExists(buffer, false)) 
		{
			AddFileToDownloadsTable(buffer);
			PrecacheSound(hitsound_path[hitsounds]);
		}
			
		hitsounds++;
	} while (kv.GotoNextKey());
	kv.Close();
}

void ParseDS() {
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/roby_hit/deathsounds.cfg");
	
	KeyValues kv = new KeyValues("deathsounds");
	
	if (!kv.ImportFromFile(path))
	{
		LogError("[Deathsound] Could not import deathsounds from %s", path);
		return;
	}
		
	kv.Rewind();
	
	if (!kv.JumpToKey("Deathsounds") && !kv.GotoFirstSubKey()) {
		LogError("[Deathmarker] Could not import Deathmarkers from %s", path);
		return;
	}
	
	deathsounds = 0;
	char buffer[64];
	do {
		kv.GetSectionName(deathsound_name[deathsounds], 32);
		kv.GetString("path", deathsound_path[deathsounds], PLATFORM_MAX_PATH);
			
		FormatEx(buffer, sizeof(buffer), "sound/%s", deathsound_path);
		if (FileExists(buffer, false)) 
		{
			AddFileToDownloadsTable(buffer);
			PrecacheSound(deathsound_path[deathsounds]);
		}
			
		deathsounds++;
	} while (kv.GotoNextKey());
	kv.Close();
}

void ParseDM() {
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/roby_hit/deathmarkers.cfg");
	
	KeyValues kv = new KeyValues("deathmarkers");
	
	if (!kv.ImportFromFile(path))
	{
		LogError("[Deathmarker] Could not import deathmarkers from %s", path);
		return;
	}
		
	kv.Rewind();
	
	if (!kv.JumpToKey("Deathmarkers") && !kv.GotoFirstSubKey()) {
		LogError("[Deathmarker] Could not import Deathmarkers from %s", path);
		return;
	}
	
	deathmarkers = 0;
	char buffer[64];
		
	do {
		kv.GetSectionName(deathmarker_name[deathmarkers], 32);
		kv.GetString("path", deathmarker_path[deathmarkers], PLATFORM_MAX_PATH);
			
		FormatEx(buffer, sizeof(buffer), "materials/%s.vmt", deathmarker_path);
		if (FileExists(buffer, false)) AddFileToDownloadsTable(buffer);
				
		FormatEx(buffer, sizeof(buffer), "materials/%s.vtf", deathmarker_path);
		if (FileExists(buffer, false)) AddFileToDownloadsTable(buffer);
			
		deathmarkers++;
	} while (kv.GotoNextKey());
	kv.Close();
}
