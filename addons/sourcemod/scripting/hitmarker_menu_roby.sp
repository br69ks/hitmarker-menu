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
#define TAG_HS 						"\x01 \x0B[Hitsound]\x01"
#define HITMARKER_SHOW_TIME			0.45
#define SPECMODE_NONE 				0
#define SPECMODE_FIRSTPERSON 		4
#define SPECMODE_3RDPERSON 			5
#define SPECMODE_FREELOOK	 		6

char hitmarker_path[20][PLATFORM_MAX_PATH];
char hitmarker_name[20][32];
char hitsound_path[20][PLATFORM_MAX_PATH];
char hitsound_name[20][32];

Handle g_cookie_hitmarker 	= INVALID_HANDLE;
Handle g_cookie_hit 		= INVALID_HANDLE;
Handle g_cookie_hitsound 	= INVALID_HANDLE;

int hitmarkers;
int hitsounds;
int g_client_hitmarker[MAXPLAYERS + 1] 	= {1, ...}; // default hitmarker: wingsmarkerv2_era (1)
int g_client_hit[MAXPLAYERS + 1] 		= {0, ...};	// default hit: none (0)
int g_client_hitsound[MAXPLAYERS + 1] 	= {1, ...};

public OnPluginStart() {
	RegConsoleCmd("sm_hitmarker", cmd_hitmarker);
	RegConsoleCmd("sm_hitmarkers", cmd_hitmarker);
	RegConsoleCmd("sm_hitmark", cmd_hitmarker);
	RegConsoleCmd("sm_hm", cmd_hitmarker);
	RegConsoleCmd("sm_hit", cmd_hit);
	RegConsoleCmd("sm_hitsounds", cmd_hitsound);
	RegConsoleCmd("sm_hitsound", cmd_hitsound);
	RegConsoleCmd("sm_hs", cmd_hitsound);
	
	HookEvent("player_hurt", event_player_hurt, EventHookMode_Post);
	HookEvent("player_death", event_player_death);
	
	g_cookie_hitmarker 	= RegClientCookie("roby_hitmarker_kill", "Kill hitmarker", CookieAccess_Protected);
	g_cookie_hit		= RegClientCookie("roby_hitmarker_hit", "Hit hitmarker", CookieAccess_Protected);
	g_cookie_hitsound	= RegClientCookie("roby_hitsound", "Hitsound", CookieAccess_Protected);
	
	ParseHM();
	ParseHS();
	
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


/***********************/
/* menus and callbacks */

void init_hitmarker_menu(int client) {
	char info[8], item[64];
	Menu menu = new Menu(hitmarker_menu_cb);
	menu.SetTitle("Choose your hitmarker (on kill):");
	for (int i = 0; i < hitmarkers; i++) {
		Format(item, sizeof(item), "%s %s", hitmarker_name[i], i == g_client_hitmarker[client] ? "[X]" : " ");
		IntToString(i, info, sizeof(info));
		menu.AddItem(info, item);
	}
	menu.Display(client, MENU_TIME_FOREVER);
}

void init_hit_menu(int client) {
	char info[8], item[64];
	Menu menu = new Menu(hit_menu_cb);
	menu.SetTitle("Choose your hitmarker (on hit):");
	for (int i = 0; i < hitmarkers; i++) {
		Format(item, sizeof(item), "%s %s", hitmarker_name[i], i == g_client_hit[client] ? "[X]" : " ");
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
			else			PrintToChat(client, "%s \x0FYou chose \x07\"%s\" \x0Fhitmarker (on kill)", TAG_HM, hitmarker_name[option]);

			cl_show_overlay(client, hitmarker_path[option]);
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
			else			PrintToChat(client, "%s \x0FYou chose \x07\"%s\" \x0Fhitmarker (on hit)", TAG_HM, hitmarker_name[option]);
			
			cl_show_overlay(client, hitmarker_path[option]);
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


/**********/
/* events */

public Action event_player_hurt(Event event, const char[] name, bool dontBroadcast) {
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	if (is_valid_client(attacker) && g_client_hit[attacker]) {
		cl_show_overlay(attacker, hitmarker_path[g_client_hit[attacker]]);
		cl_play_sound(attacker, hitsound_path[g_client_hitsound[attacker]]);
		CreateTimer(HITMARKER_SHOW_TIME, cl_hide_overlay, attacker);
	}
	
	show_to_spec(attacker, false);
	return Plugin_Handled;
}

public Action event_player_death(Event event, const char[] name, bool dontBroadcast) {
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    
	if (is_valid_client(attacker) && g_client_hitmarker[attacker]) {
		cl_show_overlay(attacker, hitmarker_path[g_client_hitmarker[attacker]]);
		cl_play_sound(attacker, hitsound_path[g_client_hitsound[attacker]]);
		CreateTimer(HITMARKER_SHOW_TIME, cl_hide_overlay, attacker);
	}

	show_to_spec(attacker, true);
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

void show_to_spec(int attacker, bool kill) {
	// s/o kamay
	for (int spec = 1; spec <= MaxClients; spec++) {
		if (!is_valid_client(spec) || !IsClientObserver(spec))
			continue;
	
		int iSpecMode = GetEntProp(spec, Prop_Send, "m_iObserverMode");

		if (iSpecMode == SPECMODE_FIRSTPERSON || iSpecMode == SPECMODE_3RDPERSON) {
			int iTarget = GetEntPropEnt(spec, Prop_Send, "m_hObserverTarget");
			
			if (kill) {
				if (iTarget == attacker && g_client_hitmarker[spec])
					cl_show_overlay(spec, hitmarker_path[g_client_hitmarker[spec]]);
			}
			else {
				if (iTarget == attacker && g_client_hit[spec])
					cl_show_overlay(spec, hitmarker_path[g_client_hit[spec]]);
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
	char hm[4], hit[4], hs[4];
	GetClientCookie(client, g_cookie_hitmarker, hm, sizeof(hm));
	GetClientCookie(client, g_cookie_hit, hit, sizeof(hit));
	GetClientCookie(client, g_cookie_hitsound, hs, sizeof(hs));
	
	if (hm[0] == '\0') {
		SetClientCookie(client, g_cookie_hitmarker, "1");
		g_client_hitmarker[client] = 1;
	}
	else {
		g_client_hitmarker[client] = StringToInt(hm);
	}
	
	if (hit[0] == '\0') {
		SetClientCookie(client, g_cookie_hit, "0");
		g_client_hit[client] = 0;
	}
	else {
		g_client_hit[client] = StringToInt(hit);
	}
	
	if (hs[0] == '\0') {
		SetClientCookie(client, g_cookie_hitsound, "0");
		g_client_hitsound[client] = 0;
	}
	else {
		g_client_hitsound[client] = StringToInt(hs);
	}

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
	KeyValues kv = new KeyValues("roby_hitmarker");
	
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/roby_hit/hitmarkers.cfg");
	
	
	if (!kv.ImportFromFile(path))
		LogError("[Hitmarker] Could not import hitmarkers from %s", path);
		
	kv.Rewind();
	
	hitmarkers = 0;
	char buffer[64];
	
	if (kv.JumpToKey("Hitmarkers") && kv.GotoFirstSubKey()) {
		do {
			kv.GetSectionName(hitmarker_name[hitmarkers], 32);
			kv.GetString("path", hitmarker_path[hitmarkers], PLATFORM_MAX_PATH);
			
			FormatEx(buffer, sizeof(buffer), "materials/%s.vmt", hitmarker_path);
			if(FileExists(buffer, false)) AddFileToDownloadsTable(buffer);
				
			FormatEx(buffer, sizeof(buffer), "materials/%s.vtf", hitmarker_path);
			if(FileExists(buffer, false)) AddFileToDownloadsTable(buffer);
			
			hitmarkers++;
		} while (kv.GotoNextKey());
	} kv.Close();
}

void ParseHS() {
	KeyValues kv = new KeyValues("roby_hitsound");
	
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/roby_hit/hitsounds.cfg");
	
	
	if (!kv.ImportFromFile(path))
		LogError("[Hitsound] Could not import hitsounds from %s", path);
		
	kv.Rewind();
	
	hitsounds = 0;
	char buffer[64];
	
	if (kv.JumpToKey("Hitsounds") && kv.GotoFirstSubKey()) {
		do {
			kv.GetSectionName(hitsound_name[hitsounds], 32);
			kv.GetString("path", hitsound_path[hitsounds], PLATFORM_MAX_PATH);
			
			FormatEx(buffer, sizeof(buffer), "sound/%s", hitmarker_path);
			if (FileExists(buffer, false)) {
				AddFileToDownloadsTable(buffer);
				PrecacheSound(buffer);
			}
			
			hitsounds++;
		} while (kv.GotoNextKey());
	} kv.Close();
}
