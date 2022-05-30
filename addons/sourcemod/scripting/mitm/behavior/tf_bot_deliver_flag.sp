/*
 * Copyright (C) 2022  Mikusch
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

static bool g_bInCaptureZone;

static CountdownTimer m_upgradeTimer[MAXPLAYERS + 1];
static CountdownTimer m_buffPulseTimer[MAXPLAYERS + 1];
static int m_upgradeLevel[MAXPLAYERS + 1];
static bool m_bIsDeploying[MAXPLAYERS + 1];

void CTFBotDeliverFlag_OnStart(int me)
{
	if (!tf_mvm_bot_allow_flag_carrier_to_fight.BoolValue)
	{
		Player(me).SetAttribute(SUPPRESS_FIRE);
	}
	
	// mini-bosses don't upgrade - they are already tough
	if (GetEntProp(me, Prop_Send, "m_bIsMiniBoss"))
	{
		// Set threat level to max
		m_upgradeLevel[me] = DONT_UPGRADE;
		SetEntProp(TFObjectiveResource(), Prop_Send, "m_nFlagCarrierUpgradeLevel", 4);
		SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMBaseBombUpgradeTime", -1.0);
		SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMNextBombUpgradeTime", -1.0);
	}
	else
	{
		m_upgradeLevel[me] = 0;
		m_upgradeTimer[me].Start(tf_mvm_bot_flag_carrier_interval_to_1st_upgrade.FloatValue);
		SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMBaseBombUpgradeTime", GetGameTime());
		SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMNextBombUpgradeTime", GetGameTime() + m_upgradeTimer[me].GetRemainingTime());
	}
}

void CTFBotDeliverFlag_Update(int me)
{
	// like a crappy version of CTFBotDeliverFlag::OnContact, but good enough
	if (m_bIsDeploying[me])
	{
		if (CTFBotMvMDeployBomb_Update(me))
		{
			// currently deploying
			return;
		}
		
		// end deploying
		m_bIsDeploying[me] = false;
		CTFBotMvMDeployBomb_OnEnd(me);
	}
	else
	{
		g_bInCaptureZone = false;
		
		// check if the player is in a capture zone
		float origin[3];
		GetClientAbsOrigin(me, origin);
		TR_EnumerateEntities(origin, origin, PARTITION_TRIGGER_EDICTS, RayType_EndPoint, EnumerateEntities);
		
		if (g_bInCaptureZone)
		{
			// begin deploying
			m_bIsDeploying[me] = true;
			CTFBotMvMDeployBomb_OnStart(me);
			return;
		}
	}
	
	if (SDKCall_HasTheFlag(me) && UpgradeOverTime(me))
	{
		// Taunting for our new upgrade
		FakeClientCommand(me, "taunt");
	}
}

void CTFBotDeliverFlag_OnEnd(int me)
{
	Player(me).ClearAttribute(SUPPRESS_FIRE);
	
	if (GameRules_IsMannVsMachineMode())
	{
		SDKCall_ResetRageBuffs(GetPlayerShared(me));
	}
}

static bool UpgradeOverTime(int me)
{
	if (m_upgradeLevel[me] != DONT_UPGRADE)
	{
		CTFNavArea myArea = view_as<CTFNavArea>(CBaseCombatCharacter(me).GetLastKnownArea());
		TFNavAttributeType spawnRoomFlag = TF2_GetClientTeam(me) == TFTeam_Red ? RED_SPAWN_ROOM : BLUE_SPAWN_ROOM;
		
		if (myArea && myArea.HasAttributeTF(spawnRoomFlag))
		{
			// don't start counting down until we leave the spawn
			m_upgradeTimer[me].Start(tf_mvm_bot_flag_carrier_interval_to_1st_upgrade.FloatValue);
			SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMBaseBombUpgradeTime", GetGameTime());
			SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMNextBombUpgradeTime", GetGameTime() + m_upgradeTimer[me].GetRemainingTime());
		}
		
		// do defensive buff effect ourselves (since we're not a soldier)
		if (m_upgradeLevel[me] > 0 && m_buffPulseTimer[me].IsElapsed())
		{
			m_buffPulseTimer[me].Start(1.0);
			
			const float buffRadius = 450.0;
			
			for (int client = 1; client <= MaxClients; client++)
			{
				if (!IsClientInGame(client))
					continue;
				
				if (TF2_GetClientTeam(client) != TF2_GetClientTeam(me))
					continue;
				
				if (!IsPlayerAlive(client))
					continue;
				
				if (IsRangeLessThan(me, client, buffRadius))
				{
					TF2_AddCondition(client, TFCond_DefenseBuffNoCritBlock, 1.2);
				}
			}
		}
		
		// the flag carrier gets stronger the longer he holds the flag
		if (m_upgradeTimer[me].IsElapsed())
		{
			const int maxLevel = 3;
			
			if (m_upgradeLevel[me] < maxLevel)
			{
				++m_upgradeLevel[me];
				
				EmitGameSoundToAll("MVM.Warning");
				
				switch (m_upgradeLevel[me])
				{
					//---------------------------------------
					case 1:
					{
						m_upgradeTimer[me].Start(tf_mvm_bot_flag_carrier_interval_to_2nd_upgrade.FloatValue);
						
						// permanent buff banner effect (handled above)
						
						// update the objective resource so clients have the information
						SetEntProp(TFObjectiveResource(), Prop_Send, "m_nFlagCarrierUpgradeLevel", 1);
						SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMBaseBombUpgradeTime", GetGameTime());
						SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMNextBombUpgradeTime", GetGameTime() + m_upgradeTimer[me].GetRemainingTime());
						HaveAllPlayersSpeakConceptIfAllowed("TLK_MVM_BOMB_CARRIER_UPGRADE1", TFTeam_Defenders);
						DispatchParticleEffect("mvm_levelup1", PATTACH_POINT_FOLLOW, me, "head");
						return true;
					}
					
					//---------------------------------------
					case 2:
					{
						m_upgradeTimer[me].Start(tf_mvm_bot_flag_carrier_interval_to_3rd_upgrade.FloatValue);
						
						TF2Attrib_SetByName(me, "health regen", tf_mvm_bot_flag_carrier_health_regen.FloatValue);
						
						// update the objective resource so clients have the information
						SetEntProp(TFObjectiveResource(), Prop_Send, "m_nFlagCarrierUpgradeLevel", 2);
						SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMBaseBombUpgradeTime", GetGameTime());
						SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMNextBombUpgradeTime", GetGameTime() + m_upgradeTimer[me].GetRemainingTime());
						HaveAllPlayersSpeakConceptIfAllowed("TLK_MVM_BOMB_CARRIER_UPGRADE2", TFTeam_Defenders);
						DispatchParticleEffect("mvm_levelup2", PATTACH_POINT_FOLLOW, me, "head");
						return true;
					}
					
					//---------------------------------------
					case 3:
					{
						// add critz
						TF2_AddCondition(me, TFCond_CritCanteen);
						
						// update the objective resource so clients have the information
						SetEntProp(TFObjectiveResource(), Prop_Send, "m_nFlagCarrierUpgradeLevel", 3);
						SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMBaseBombUpgradeTime", -1.0);
						SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMNextBombUpgradeTime", -1.0);
						HaveAllPlayersSpeakConceptIfAllowed("TLK_MVM_BOMB_CARRIER_UPGRADE3", TFTeam_Defenders);
						DispatchParticleEffect("mvm_levelup3", PATTACH_POINT_FOLLOW, me, "head");
						return true;
					}
				}
			}
		}
	}
	
	return false;
}

static bool EnumerateEntities(int entity)
{
	char classname[64];
	if (GetEntityClassname(entity, classname, sizeof(classname)) && StrEqual(classname, "func_capturezone"))
	{
		Handle trace = TR_ClipCurrentRayToEntityEx(MASK_ALL, entity);
		bool didHit = TR_DidHit(trace);
		delete trace;
		
		g_bInCaptureZone = didHit;
		return !didHit;
	}
	
	return true;
}
