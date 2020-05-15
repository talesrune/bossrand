//Edited by HowToDoThis v1.6 Revamp (2020)
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <tf2items>
#include <multicolors>
//#include <morecolors>
#include <sdkhooks>
#include <tf2items_giveweapon>
#define PLUGIN_VERSION "1.6"



new bool:g_bIsTF2 = false;
new Handle:cvarEnabled;
new bool:g_bCoolEnd[MAXPLAYERS + 1] = { true, ... };
new Handle:ConVar_CoolTime = INVALID_HANDLE;
new Float:TimerRate;
new bool:g_bTrial[MAXPLAYERS + 1] = { false, ... };
//new String:useridd[MAXPLAYERS + 1] ;
new CheckClass[32];
new bool:g_FullCrit[MAXPLAYERS+1] = {false, ...};
new bool:g_BFallDmg[MAXPLAYERS+1] = {false, ...};
new bool:g_IsModel[MAXPLAYERS+1] = { false, ... };
new bool:g_bIsBoss[MAXPLAYERS + 1] = { false, ... };
new BossIndex[32];

new Handle:gArray = INVALID_HANDLE;
new gIndexCmd;

int backstabShield[MAXPLAYERS + 1] = {0, ... };

public Plugin:myinfo =
{
	name = "[TF2] Boss Randomizer-Revamped",
	author = "HowToDoThis",
	description = "Become a Random Boss!",
	version = PLUGIN_VERSION,
	url = ""
}

public OnClientPutInServer(client)
{
	OnClientDisconnect_Post(client);
}
public OnClientDisconnect_Post(client)
{
	g_IsModel[client] = false;
	g_bIsBoss[client] = false;
	g_FullCrit[client] = false;
	backstabShield[client] = 0;
	g_BFallDmg[client] = false;
	
}

public OnPluginStart()
{
	//Convars and Commands
	CreateConVar("bossrand_version", PLUGIN_VERSION , "Bossrand Version",  FCVAR_NOTIFY|0|FCVAR_SPONLY);
	cvarEnabled = CreateConVar("bossrand_enabled", "1", "What the point of setting it 0 in the first place?", 0, true, 0.0, true, 1.0);
	ConVar_CoolTime = CreateConVar("sm_bossrand_cooltime", "90.0", "Cooldown for BossRandomizer. 0 to disable cooldown.", FCVAR_DONTRECORD|0|FCVAR_NOTIFY, true, 0.0);
        HookConVarChange(ConVar_CoolTime, ConVar_Time_Changed);
//	HookEvent("player_spawn", event_PlayerSpawn);
	HookEvent("post_inventory_application", EventInventoryApplication,  EventHookMode_Post);
	HookEvent("player_death", Event_Death,  EventHookMode_Post);
	RegAdminCmd("sm_bossrand", Command_BossRand, ADMFLAG_GENERIC, "Give that person a Random Boss.");
	RegAdminCmd("sm_bossrand_reload", Command_BossRandR, ADMFLAG_GENERIC, "Reload config for BossRand");
	RegAdminCmd("sm_br", Command_BR, ADMFLAG_GENERIC, "Give that person a RB."); //Revamping
	gArray = CreateArray();
	//SetupBossConfigs("bossrand_boss.cfg");
	AddNormalSoundHook(BossSH);
	
	///////////////////////////////////
	for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
            SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
    }

}

public void OnClientPostAdminCheck(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnConfigsExecuted() {
	TimerRate = GetConVarFloat(ConVar_CoolTime);
	SetupBossConfigs("bossrand_boss.cfg");
	
}

/*public event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:auth[32];
	GetClientAuthString( client, auth, sizeof(auth) );
	PrintToChatAll("LOL %s", auth);	
}*/
public OnMapStart()
{
	for (new i = 1; i <= MaxClients; i++)
		{
		g_bTrial[i] = false;
		}
}


public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon,
        Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
    if (victim > 0 && victim <= MaxClients && damagecustom == TF_CUSTOM_BACKSTAB) 
	{
	
				
		if (backstabShield[victim] > 0) { 
			damage = 1.0;			
			EmitSoundToClient(victim, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, _, _, false);
			EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, _, _, false);
			backstabShield[victim]--;
			CPrintToChat(victim, "{frozen}[BossRandomizer-R] \x01Shielded \x04%N.", victim);
			CPrintToChat(attacker, "{frozen}[BossRandomizer-R] \x01Shielded \x04%N.", victim);
		}
		else if (g_bIsBoss[victim]){
			CPrintToChat(victim, "{frozen}[BossRandomizer-R] \x01Killed \x04%N \x01via BackStab.", victim);
			CPrintToChat(attacker, "{frozen}[BossRandomizer-R] \x01Killed \x04%N \x01via BackStab.", victim);
		}
		return Plugin_Changed; //return Plugin_Continue;
		
		//PrintToChatAll("%d",GetClientUserId(victim));
		//PrintToChatAll("%d",GetClientUserId(attacker));
		//PrintToChatAll("%d",GetClientHealth(attacker));
		//PrintToChatAll("%.2f",minusHealth[victim]);
        //Backstab detected. Return Plugin_Changed if changing a variable.
         
    }
    if ((damagetype & DMG_FALL))	{
		if(g_BFallDmg[victim]) {
			damage = 0.0;
			return Plugin_Changed;
		}
		
	}

    return Plugin_Continue;
} 

public Action:Command_BossRandR(client, args)
{
	SetupBossConfigs("bossrand_boss.cfg");
}
public ConVar_Time_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	TimerRate = StringToFloat(newValue);	
}


public Action:Command_BossRand(client, args)
{
	new Enabled = GetConVarInt(cvarEnabled);
	if(Enabled == 1)
	{
		if (!IsPlayerAlive(client))
		{
			CPrintToChat(client, "{frozen}[BossRandomizer-R] \x01Don't waste your !bossrand when you are dead.");
			
			
		}
		else if(!g_bTrial[client] && !GetAdminFlag(GetUserAdmin(client), Admin_Custom1))
		{
			RandBoss(client);
			CPrintToChatAll("{frozen}[BossRandomizer-R] \x04%N \x01has used the trial",client);
			g_bTrial[client]=true;
			CreateTimer(180.0, Timer_Cooldown2, client, TIMER_FLAG_NO_MAPCHANGE); //3mins
		}
		else if(!GetAdminFlag(GetUserAdmin(client), Admin_Custom1))
		{
			
			//CPrintToChatAll("{frozen}[BossRandomizer-R] \x01Hey \x04%N! \x01Cooldown is still ongoing. Approx Cooldown time is 3 minutes for non-members",client);	
			new Handle:hHudText = CreateHudSynchronizer();
    			SetHudTextParams(-1.0, 0.5, 3.0, 255, 131, 250, 255);
  			ShowSyncHudText(client, hHudText, "3 minutes cooldown");
 	        	CloseHandle(hHudText);	
		}
		else if(g_bCoolEnd[client])
		{
			
			RandBoss(client);
			g_bCoolEnd[client] = false;
			
			CreateTimer(TimerRate, Timer_Cooldown, client);
			
			
                     
		}
		else {
			new Handle:hHudText = CreateHudSynchronizer();
    			SetHudTextParams(-1.0, 0.5, 3.0, 255, 131, 250, 255);
  			ShowSyncHudText(client, hHudText, "1 minute 30 seconds cooldown");
 	        	CloseHandle(hHudText);	
			CPrintToChat(client, "{frozen}[BossRandomizer-R] \x01Cooldown is still ongoing.");
		}
	}
	else
	PrintToChatAll("Boss Randomizer is disabled.");	
	
       
}
public Action:Timer_Cooldown(Handle:timer, any:client)
{
      
      for (new i = 1; i <= MaxClients; i++)
      {
         CoolEnd(i);
      }
      
}
public Action:Timer_Cooldown2(Handle:timer, any:client)
{
      g_bTrial[client] = false;	 
      CPrintToChatAll("{frozen}[BossRandomizer-R] \x01Non-Member Cooldown has ended for %N",client);
}
public Action:CoolEnd(client)
{
	if(!g_bCoolEnd[client])
	{
	g_bCoolEnd[client] = true;
        CPrintToChat(client, "{frozen}[BossRandomizer-R] \x01Cooldown has ended.");
	}
}
public Action:RandBoss(client)
{
	new num = GetRandomInt(1 , GetArraySize(gArray) - 1);
	BossIndex[client] = num;
	CreateBoss(num, client, true);
	
	return Plugin_Continue;
}
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{		
		if(g_FullCrit[client])
		{
			result = true;
			return Plugin_Handled;
		}
		return Plugin_Continue;
}
public Action:Command_BR(client, args) {
	
	//if(!IsClientInGame(client) || !IsPlayerAlive(client)) {
	//	ReplyToCommand(client, "%t", "Error");
	//	return Plugin_Handled;
	//}
		
	
	decl String:arg[15];
	decl String:arg2[32];
	if (args < 2) //sm_br hm @all
	{
		arg2 = "@me";
	}
	else GetCmdArg(2, arg2, sizeof(arg2));
	if (!StrEqual(arg2, "@me") && !CheckCommandAccess(client, "sm_br_others", ADMFLAG_ROOT, true))
	{
		PrintToChat(client, "{frozen}[BossRandomizer-R] \x01You do not have access to this command.");
		return Plugin_Handled;
	}


	GetCmdArg(1, arg, sizeof(arg));
	new i;
	new Handle:iTrie = INVALID_HANDLE;
	decl String:sName[64];
	for(i = 0; i < GetArraySize(gArray); i++) { //Array size
		iTrie = GetArrayCell(gArray, i);
		if(iTrie != INVALID_HANDLE) {
			GetTrieString(iTrie, "Name", sName, sizeof(sName));
			if(StrEqual(sName, arg, false)){
				break;
			}
		}
	}
	if(i == GetArraySize(gArray) && !StrEqual(arg, "any")) { //Reached the end
		ReplyToCommand(client, "[Boss] Error: Boss does not exist.");
		return Plugin_Handled;
	}
	gIndexCmd = i;

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
        if ((target_count = ProcessTargetString(
			arg2,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE|(args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0), /* Only allow alive players. If targetting self, allow self. */
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (new j= 0; j < target_count; j++)
	{
		
		if(!StrEqual(arg, "any")) { //specific boss
			BossIndex[target_list[j]] = i;
			CreateBoss(gIndexCmd, target_list[j], true);
		} 
		else { //any boss 
			new num = GetRandomInt(1 , GetArraySize(gArray)-1); //minus 1 is important!
			BossIndex[target_list[j]] = num;
			CreateBoss(num, target_list[j], true);
		}
		
	}
	
	
	return Plugin_Handled;
}


public Action:CreateBoss(b_index, client, bool:cmd) {
	

	decl String:sName[64], String:sModel[256], String:sClass[32], String:sBase[16], String:sWep[16];
	decl String:sSize[16], String:sFName[64], String:sPDA[16], String:sCrits[16], String:sTP[16] , String:sBFallDmg[16];
	decl String:sSpawn[256], String:sSpawnRumble[256], String:sSpawnVo[256], String:sBoo[256], String:sDeath[256], String:sDeathVo[256];
	decl String:sComm[256];
	new Handle:iTrie = GetArrayCell(gArray, b_index);
	GetTrieString(iTrie, "Name", sName, sizeof(sName));
	GetTrieString(iTrie, "Model", sModel, sizeof(sModel));
	GetTrieString(iTrie, "Class", sClass, sizeof(sClass));
	GetTrieString(iTrie, "HP Base", sBase, sizeof(sBase));
	GetTrieString(iTrie, "Weapon", sWep, sizeof(sWep));
	GetTrieString(iTrie, "Size", sSize, sizeof(sSize));
	GetTrieString(iTrie, "FullName", sFName, sizeof(sFName));
	GetTrieString(iTrie, "PDA", sPDA, sizeof(sPDA));
	GetTrieString(iTrie, "Crits", sCrits, sizeof(sCrits));
	GetTrieString(iTrie, "TP", sTP, sizeof(sTP)); 
	GetTrieString(iTrie, "BlockFallDamage", sBFallDmg, sizeof(sBFallDmg)); 
	GetTrieString(iTrie, "Spawn", sSpawn, sizeof(sSpawn)); 
	GetTrieString(iTrie, "SpawnRumble", sSpawnRumble, sizeof(sSpawnRumble)); 
	GetTrieString(iTrie, "SpawnVo", sSpawnVo, sizeof(sSpawnVo)); 
	GetTrieString(iTrie, "Boo", sBoo, sizeof(sBoo)); 
	GetTrieString(iTrie, "Death", sDeath, sizeof(sDeath)); 
	GetTrieString(iTrie, "DeathVo", sDeathVo, sizeof(sDeathVo)); 
	GetTrieString(iTrie, "Comm", sComm, sizeof(sComm)); 

//Model, Size and Precache///////////////////////////////////////////////
	if(!StrEqual(sModel, NULL_STRING) || !StrEqual(sSize, NULL_STRING)) {
	SetModel(client, sModel, sSize);
	}
	if(!StrEqual(sSpawn, NULL_STRING)) {
			PrecacheSound(sSpawn, true);
	}
	if(!StrEqual(sSpawnRumble, NULL_STRING)) {
			PrecacheSound(sSpawnRumble, true);
	}
	if(!StrEqual(sSpawnVo, NULL_STRING)) {
			PrecacheSound(sSpawnVo, true);
	}
	if(!StrEqual(sBoo, NULL_STRING)) {
			PrecacheSound(sBoo, true);
	}
	if(!StrEqual(sDeath, NULL_STRING)) {
			PrecacheSound(sDeath, true);
	}
	if(!StrEqual(sDeathVo, NULL_STRING)) {
			PrecacheSound(sDeathVo, true);
	}
/////////////////////////////////////////////////////////////////////////
//Class//////////////////////////////////////////////////////////////////	
	if(TF2_GetPlayerClass(client) == TFClass_Scout)
	CheckClass[client]=1;
	else if(TF2_GetPlayerClass(client) == TFClass_Soldier)
	CheckClass[client]=2;
	else if(TF2_GetPlayerClass(client) == TFClass_Pyro)
	CheckClass[client]=3;
	else if(TF2_GetPlayerClass(client) == TFClass_DemoMan)
	CheckClass[client]=4;
	else if(TF2_GetPlayerClass(client) == TFClass_Heavy)
	CheckClass[client]=5;
	else if(TF2_GetPlayerClass(client) == TFClass_Engineer)
	CheckClass[client]=6;
	else if(TF2_GetPlayerClass(client) == TFClass_Medic)
	CheckClass[client]=7;
	else if(TF2_GetPlayerClass(client) == TFClass_Sniper)
	CheckClass[client]=8;
	else if(TF2_GetPlayerClass(client) == TFClass_Spy)
	CheckClass[client]=9;

	if(!StrEqual(sClass, NULL_STRING))
	{	
	if(StrEqual(sClass, "scout"))
	TF2_SetPlayerClass(client, TFClass_Scout);
	else if(StrEqual(sClass, "soldier"))
	TF2_SetPlayerClass(client, TFClass_Soldier);
	else if(StrEqual(sClass, "pyro"))
	TF2_SetPlayerClass(client, TFClass_Pyro);
	else if(StrEqual(sClass, "demoman"))
	TF2_SetPlayerClass(client, TFClass_DemoMan);
	else if(StrEqual(sClass, "heavy"))
	TF2_SetPlayerClass(client, TFClass_Heavy);
	else if(StrEqual(sClass, "engineer"))
	TF2_SetPlayerClass(client, TFClass_Engineer);
	else if(StrEqual(sClass, "medic"))
	TF2_SetPlayerClass(client, TFClass_Medic);
	else if(StrEqual(sClass, "sniper"))
	TF2_SetPlayerClass(client, TFClass_Sniper);
	else if(StrEqual(sClass, "spy"))
	TF2_SetPlayerClass(client, TFClass_Spy);
	}
/////////////////////////////////////////////////////////////////////////
	if(StrEqual(sComm, NULL_STRING)) {	//If "Comm" - Command is null
	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill");
	decl String:weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "tf_weapon", false) == 0) 
	{
		SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iWeaponState", 0);
		TF2_RemoveCondition(client, TFCond_Slowed);
	}
	TF2_RemoveAllWeapons(client);
	TF2_RemoveAllWearables(client);
	}
//PDA////////////////////////////////////////////////////////////////////
	if(!StrEqual(sPDA, NULL_STRING)) {
		backstabShield[client] = StringToInt(sPDA);
		//Old code, doesnt work as great anymore
        /*for (new i = 0 ; i < StringToInt(sPDA) ; i++)
        {
                BuildPDA(client);
        }*/	
	}
/////////////////////////////////////////////////////////////////////////	
//Weapon/////////////////////////////////////////////////////////////////
	if(!StrEqual(sWep, NULL_STRING)) {
	GetWeapons(client, sWep);
	TF2_SwitchtoSlot(client, TFWeaponSlot_Primary);
	}
/////////////////////////////////////////////////////////////////////////
//Third Person///////////////////////////////////////////////////////////
	if(!StrEqual(sTP, NULL_STRING)) 
	{
		if(StringToFloat(sTP) == 1.0)
		{
		SetVariantInt(1);
		AcceptEntityInput(client, "SetForcedTauntCam");
		}
	}
/////////////////////////////////////////////////////////////////////////
//Crits//////////////////////////////////////////////////////////////////
	if(!StrEqual(sCrits, NULL_STRING)) {
        	if(StringToFloat(sCrits) == 1.0)
		g_FullCrit[client] = true;
	}
/////////////////////////////////////////////////////////////////////////
//Block Fall Damage//////////////////////////////////////////////////////////////////
	if(!StrEqual(sBFallDmg, NULL_STRING)) {
        	if(StringToFloat(sBFallDmg) == 1.0)
		g_BFallDmg[client] = true;
	}
/////////////////////////////////////////////////////////////////////////
//BaseHealth/////////////////////////////////////////////////////////////
	if(!StrEqual(sBase, NULL_STRING)) {
	new BaseHP = StringToInt(sBase);
	TF2_SetHealth(client, 350 + BaseHP);	//Must put health here
	}
/////////////////////////////////////////////////////////////////////////
	g_bIsBoss[client] = true;	
//Command////////////////////////////////////////////////////////////////
	if(!StrEqual(sComm, NULL_STRING)) {
	decl String:auth[32];
	GetClientAuthId( client, AuthId_Steam2, auth, sizeof(auth) );	
	ReplaceString(auth, sizeof(auth), ":", "_");
	ServerCommand("%s%s 1",sComm,auth);

	}
/////////////////////////////////////////////////////////////////////////
//Full Name//////////////////////////////////////////////////////////////	
	CPrintToChatAll("{frozen}[BossRandomizer-R] \x04%N \x01has rolled an : \x03%s",client,sFName);
/////////////////////////////////////////////////////////////////////////
//Sounds/////////////////////////////////////////////////////////////////
	if(!StrEqual(sSpawn, NULL_STRING)) {
	EmitSoundToAll(sSpawn);
	}
	if(!StrEqual(sSpawnRumble, NULL_STRING)) {
	EmitSoundToAll(sSpawnRumble);
	}
	if(!StrEqual(sSpawnVo, NULL_STRING)) {
	EmitSoundToAll(sSpawnVo);
	}		
////////////////////////////////////////////////////////////////////////
}
public Action:SetModel(client, const String:model[], const String:sSize[])
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		if(!StrEqual(model, NULL_STRING))
		{
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");
		}
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", StringToFloat(sSize));                
		g_IsModel[client] = true;                           
		g_bIsTF2 = true;
		UpdatePlayerHitbox(client, sSize);
	
    }
}
public Action:RemoveModel(client)
{
	if (IsValidClient(client) && g_IsModel[client])
	{
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		g_IsModel[client] = false;
	}
//	return Plugin_Handled;
}
public EventInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	RemoveModel(client);
	if (g_bIsBoss[client])
	{
		SetVariantInt(0);
		AcceptEntityInput(client, "SetForcedTauntCam");
	}
	g_bIsBoss[client] = false;
	g_FullCrit[client] = false;
	backstabShield[client] = 0;
}
public Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new deathflags = GetEventInt(event, "death_flags");
	if (!(deathflags & TF_DEATHFLAG_DEADRINGER))
	{
		if (IsValidClient(client) && g_bIsBoss[client])
		{
			if(CheckClass[client]==1)
			TF2_SetPlayerClass(client, TFClass_Scout);
			else if(CheckClass[client]==2)
			TF2_SetPlayerClass(client, TFClass_Soldier);
			else if(CheckClass[client]==3)
			TF2_SetPlayerClass(client, TFClass_Pyro);
			else if(CheckClass[client]==4)
			TF2_SetPlayerClass(client, TFClass_DemoMan);
			else if(CheckClass[client]==5)
			TF2_SetPlayerClass(client, TFClass_Heavy);
			else if(CheckClass[client]==6)
			TF2_SetPlayerClass(client, TFClass_Engineer);
			else if(CheckClass[client]==7)
			TF2_SetPlayerClass(client, TFClass_Medic);
			else if(CheckClass[client]==8)
			TF2_SetPlayerClass(client, TFClass_Sniper);
			else if(CheckClass[client]==9)
			TF2_SetPlayerClass(client, TFClass_Spy);

			decl String:sDeath[256], String:sDeathVo[256];
			new Handle:iTrie = GetArrayCell(gArray, BossIndex[client]);
			GetTrieString(iTrie, "Death", sDeath, sizeof(sDeath)); 
			GetTrieString(iTrie, "DeathVo", sDeathVo, sizeof(sDeathVo));
			if(!StrEqual(sDeath, NULL_STRING)) { 			
		        EmitSoundToAll(sDeath);
			}
			if(!StrEqual(sDeathVo, NULL_STRING)) {
			EmitSoundToAll(sDeathVo);
			}
			BossIndex[client] = GetArraySize(gArray);
		}
	}
}
stock TF2_RemoveAllWearables(client) 
{ 
    new i = -1; 
    while ((i = FindEntityByClassname(i, "tf_wearable*")) != -1) 
    { 
        if (client != GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity")) continue; 
        AcceptEntityInput(i, "Kill"); 
    } 
}  
stock UpdatePlayerHitbox(const client, const String:sSize[])
{
	static const Float:vecTF2PlayerMin[3] = { -24.5, -24.5, 0.0 }, Float:vecTF2PlayerMax[3] = { 24.5,  24.5, 83.0 };
	static const Float:vecGenericPlayerMin[3] = { -16.5, -16.5, 0.0 }, Float:vecGenericPlayerMax[3] = { 16.5,  16.5, 73.0 };
	decl Float:vecScaledPlayerMin[3], Float:vecScaledPlayerMax[3];
	if (g_bIsTF2)
	{
		vecScaledPlayerMin = vecTF2PlayerMin;
		vecScaledPlayerMax = vecTF2PlayerMax;
	}
	else
	{
		vecScaledPlayerMin = vecGenericPlayerMin;
		vecScaledPlayerMax = vecGenericPlayerMax;
	}
	ScaleVector(vecScaledPlayerMin, StringToFloat(sSize));
	ScaleVector(vecScaledPlayerMax, StringToFloat(sSize));
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", vecScaledPlayerMin);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecScaledPlayerMax);
}
/*public Action:BuildPDA(client)//Obselete
{
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	if (hWeapon != INVALID_HANDLE)
	{
		TF2Items_SetClassname(hWeapon, "tf_wearable"); //tf_weapon_pda_engineer_destroy
		TF2Items_SetItemIndex(hWeapon, 57);
		TF2Items_SetLevel(hWeapon, 100);
		TF2Items_SetQuality(hWeapon, 5);
                new String:weaponAttribs[256];
		Format(weaponAttribs, sizeof(weaponAttribs), "52 ; 1");
                new String:weaponAttribsArray[32][32];
		new attribCount = ExplodeString(weaponAttribs, " ; ", weaponAttribsArray, 32, 32);
		if (attribCount > 0) {
			TF2Items_SetNumAttributes(hWeapon, attribCount/2);
			new i2 = 0;
			for (new i = 0; i < attribCount; i+=2) {
				TF2Items_SetAttribute(hWeapon, i2, StringToInt(weaponAttribsArray[i]), StringToFloat(weaponAttribsArray[i+1]));
				i2++;
			}
		} else {
			TF2Items_SetNumAttributes(hWeapon, 0);
		}
		
		new weapon = TF2Items_GiveNamedItem(client, hWeapon);
		EquipPlayerWeapon(client, weapon);
		CloseHandle(hWeapon);
		
	}
}*/
stock TF2_SwitchtoSlot(client, slot)
{
	if (slot >= 0 && slot <= 5 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		decl String:classname[64];
		new wep = GetPlayerWeaponSlot(client, slot);
		if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, classname, sizeof(classname)))
		{
			FakeClientCommandEx(client, "use %s", classname);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wep);
		}
	}
}
stock GetWeapons(const client, const String:sWep[])
{
	if (IsValidClient(client))
	{
		new String:GetWep[32][32];
		new attribCount = ExplodeString(sWep, ",", GetWep, 32, 32);		
		for (new i = 0; i < attribCount; i++) {
		TF2Items_GiveWeapon(client, StringToInt(GetWep[i]));

		}
			
        }
}

stock TF2_SetHealth(client, NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
}
public SetupBossConfigs(const String:sFile[]) {
	
	new String:sPath[PLATFORM_MAX_PATH]; 
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/%s", sFile);
	
	if(!FileExists(sPath)) {
		PrintToServer("[BossRandomizer-R] Error: Can not find boss filepath %s", sPath);
		SetFailState("[BossRandomizer-R] Error: Can not find boss filepath %s", sPath);
	}
	new Handle:kv = CreateKeyValues("Boss Randomizer");
	FileToKeyValues(kv, sPath);

	if(!KvGotoFirstSubKey(kv)) PrintToServer("Could not read boss file: %s", sPath);
	
	decl String:sName[64], String:sModel[256], String:sClass[32], String:sBase[16], String:sWep[16];
	decl String:sSize[16], String:sFName[64], String:sPDA[16], String:sCrits[16], String:sTP[16], String:sBFallDmg[16];
	decl String:sSpawn[256], String:sSpawnRumble[256], String:sSpawnVo[256], String:sBoo[256], String:sDeath[256], String:sDeathVo[256];
	decl String:sComm[256]
	do {
		KvGetSectionName(kv, sName, sizeof(sName));
		KvGetString(kv, "Model", sModel, sizeof(sModel), NULL_STRING); 
		KvGetString(kv, "Class", sClass, sizeof(sClass));
		KvGetString(kv, "HP Base", sBase, sizeof(sBase), "10000");
		KvGetString(kv, "Weapon", sWep, sizeof(sWep));		
		KvGetString(kv, "Size", sSize, sizeof(sSize), "1.0");
		KvGetString(kv, "FullName", sFName, sizeof(sFName));
		KvGetString(kv, "PDA", sPDA, sizeof(sPDA), "5");
		KvGetString(kv, "Crits", sCrits, sizeof(sCrits), "2.0");
		KvGetString(kv, "TP", sTP, sizeof(sTP), "2.0");
		KvGetString(kv, "BlockFallDamage", sBFallDmg, sizeof(sBFallDmg), "2.0");
		KvGetString(kv, "Spawn", sSpawn, sizeof(sSpawn), NULL_STRING);
		KvGetString(kv, "SpawnRumble", sSpawnRumble, sizeof(sSpawnRumble), NULL_STRING);
		KvGetString(kv, "SpawnVo", sSpawnVo, sizeof(sSpawnVo), NULL_STRING);
		KvGetString(kv, "Boo", sBoo, sizeof(sBoo), NULL_STRING);
		KvGetString(kv, "Death", sDeath, sizeof(sDeath), NULL_STRING);
		KvGetString(kv, "DeathVo", sDeathVo, sizeof(sDeathVo), NULL_STRING);
		KvGetString(kv, "Comm", sComm, sizeof(sComm), NULL_STRING);
	
		if(!StrEqual(sModel, NULL_STRING)) {
			PrecacheModel(sModel, true);
		}
		
		new Handle:iTrie = CreateTrie();
		SetTrieString(iTrie, "Name", sName, false);
		SetTrieString(iTrie, "Model", sModel, false);
		SetTrieString(iTrie, "Class", sClass, false);
		SetTrieString(iTrie, "HP Base", sBase, false);
		SetTrieString(iTrie, "Weapon", sWep, false);
		SetTrieString(iTrie, "Size", sSize, false);
		SetTrieString(iTrie, "FullName", sFName, false);
		SetTrieString(iTrie, "PDA", sPDA, false);
		SetTrieString(iTrie, "Crits", sCrits, false);
		SetTrieString(iTrie, "TP", sTP, false);
		SetTrieString(iTrie, "BlockFallDamage", sBFallDmg, false);
		SetTrieString(iTrie, "Spawn", sSpawn, false);
		SetTrieString(iTrie, "SpawnRumble", sSpawnRumble, false);
		SetTrieString(iTrie, "SpawnVo", sSpawnVo, false);
		SetTrieString(iTrie, "Boo", sBoo, false);
		SetTrieString(iTrie, "Death", sDeath, false);
		SetTrieString(iTrie, "DeathVo", sDeathVo, false);
		SetTrieString(iTrie, "Comm", sComm, false);
		PushArrayCell(gArray, iTrie);
	} while (KvGotoNextKey(kv));
	CloseHandle(kv);
        
	PrintToServer("Loaded BossRand configs successfully."); 
}
public Action:BossSH(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{

	if (!IsValidClient(entity)) return Plugin_Continue;
	if (!g_bIsBoss[entity]) return Plugin_Continue;
	
	if (StrContains(sample, "_medic0", false) != -1)
	{
		decl String:sBoo[256];
		new Handle:iTrie = GetArrayCell(gArray, BossIndex[entity]);
		GetTrieString(iTrie, "Boo", sBoo, sizeof(sBoo)); 
		if(!StrEqual(sBoo, NULL_STRING)) {		 
		sample = sBoo;
		}
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
stock bool:IsValidClient(client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
//	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}
/*stock TF2_EquipWearable(client, entity)
{
	if (bSDKStarted == false || hSDKEquipWearable == INVALID_HANDLE)
	{
		TF2_SdkStartup();
		LogMessage("Error: Can't call EquipWearable, SDK functions not loaded! If it continues to fail, reload plugin or restart server. Make sure your gamedata is intact!");
	}
	else
	{
		if (TF2_IsEntityWearable(entity)) SDKCall(hSDKEquipWearable, client, entity);
		else LogMessage("Error: Item %i isn't a valid wearable.", entity);
	}
}
stock bool:TF2_IsEntityWearable(entity)
{
	if (entity > MaxClients && IsValidEdict(entity))
	{
		new String:strClassname[32]; GetEdictClassname(entity, strClassname, sizeof(strClassname));
		return (strncmp(strClassname, "tf_wearable", 11, false) == 0 || strncmp(strClassname, "tf_powerup", 10, false) == 0);
	}

	return false;
}
*/

