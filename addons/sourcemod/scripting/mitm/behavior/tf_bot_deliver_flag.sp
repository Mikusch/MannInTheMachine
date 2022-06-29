/**
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

#pragma semicolon 1
#pragma newdecls required

#define DONT_UPGRADE	-1

static NextBotActionFactory ActionFactory;

static CountdownTimer m_upgradeTimer[MAXPLAYERS + 1];
static CountdownTimer m_buffPulseTimer[MAXPLAYERS + 1];
static int m_upgradeLevel[MAXPLAYERS + 1];

void CTFBotDeliverFlag_Init()
{
	ActionFactory = new NextBotActionFactory("DeliverFlag");
	ActionFactory.BeginDataMapDesc()
	// TODO
	.EndDataMapDesc();
	ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, CTFBotDeliverFlag_OnStart);
	ActionFactory.SetCallback(NextBotActionCallbackType_Update, CTFBotDeliverFlag_Update);
	ActionFactory.SetCallback(NextBotActionCallbackType_OnEnd, CTFBotDeliverFlag_OnEnd);
	ActionFactory.SetEventCallback(EventResponderType_OnContact, CTFBotDeliverFlag_OnContact);
}

NextBotAction CTFBotDeliverFlag_Create()
{
	return ActionFactory.Create();
}

static int CTFBotDeliverFlag_OnStart(NextBotAction action, int actor, NextBotAction priorAction)
{
	if (!tf_mvm_bot_allow_flag_carrier_to_fight.BoolValue)
	{
		Player(actor).SetAttribute(SUPPRESS_FIRE);
	}
	
	// mini-bosses don't upgrade - they are already tough
	if (GetEntProp(actor, Prop_Send, "m_bIsMiniBoss"))
	{
		// Set threat level to max
		m_upgradeLevel[actor] = DONT_UPGRADE;
		SetEntProp(TFObjectiveResource(), Prop_Send, "m_nFlagCarrierUpgradeLevel", 4);
		SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMBaseBombUpgradeTime", -1.0);
		SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMNextBombUpgradeTime", -1.0);
	}
	else
	{
		m_upgradeLevel[actor] = 0;
		m_upgradeTimer[actor].Start(tf_mvm_bot_flag_carrier_interval_to_1st_upgrade.FloatValue);
		SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMBaseBombUpgradeTime", GetGameTime());
		SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMNextBombUpgradeTime", GetGameTime() + m_upgradeTimer[actor].GetRemainingTime());
	}
	
	return action.Continue();
}

static int CTFBotDeliverFlag_Update(NextBotAction action, int actor, float interval)
{
	int flag = Player(actor).GetFlagToFetch();
	
	if (!IsValidEntity(flag))
	{
		return action.Done("No flag");
	}
	
	int carrier = GetEntPropEnt(flag, Prop_Send, "m_hOwnerEntity");
	if (!IsValidEntity(carrier) || actor != carrier)
	{
		return action.Done("I'm no longer carrying the flag");
	}
	
	if (UpgradeOverTime(actor))
	{
		return action.SuspendFor(CTFBotTaunt_Create(), "Taunting for our new upgrade");
	}
	
	return action.Continue();
}

static void CTFBotDeliverFlag_OnEnd(NextBotAction action, int actor, NextBotAction nextAction)
{
	Player(actor).ClearAttribute(SUPPRESS_FIRE);
	
	if (GameRules_IsMannVsMachineMode())
	{
		SDKCall_ResetRageBuffs(GetPlayerShared(actor));
	}
}

static bool UpgradeOverTime(int actor)
{
	if (m_upgradeLevel[actor] != DONT_UPGRADE)
	{
		CTFNavArea myArea = view_as<CTFNavArea>(CBaseCombatCharacter(actor).GetLastKnownArea());
		TFNavAttributeType spawnRoomFlag = TF2_GetClientTeam(actor) == TFTeam_Red ? RED_SPAWN_ROOM : BLUE_SPAWN_ROOM;
		
		if (myArea && myArea.HasAttributeTF(spawnRoomFlag))
		{
			// don't start counting down until we leave the spawn
			m_upgradeTimer[actor].Start(tf_mvm_bot_flag_carrier_interval_to_1st_upgrade.FloatValue);
			SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMBaseBombUpgradeTime", GetGameTime());
			SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMNextBombUpgradeTime", GetGameTime() + m_upgradeTimer[actor].GetRemainingTime());
		}
		
		// do defensive buff effect ourselves (since we're not a soldier)
		if (m_upgradeLevel[actor] > 0 && m_buffPulseTimer[actor].IsElapsed())
		{
			m_buffPulseTimer[actor].Start(1.0);
			
			const float buffRadius = 450.0;
			
			for (int client = 1; client <= MaxClients; client++)
			{
				if (!IsClientInGame(client))
					continue;
				
				if (TF2_GetClientTeam(client) != TF2_GetClientTeam(actor))
					continue;
				
				if (!IsPlayerAlive(client))
					continue;
				
				if (IsRangeLessThan(actor, client, buffRadius))
				{
					TF2_AddCondition(client, TFCond_DefenseBuffNoCritBlock, 1.2);
				}
			}
		}
		
		// the flag carrier gets stronger the longer he holds the flag
		if (m_upgradeTimer[actor].IsElapsed())
		{
			const int maxLevel = 3;
			
			if (m_upgradeLevel[actor] < maxLevel)
			{
				++m_upgradeLevel[actor];
				
				TFGameRules_BroadcastSound(255, "MVM.Warning");
				
				switch (m_upgradeLevel[actor])
				{
					//---------------------------------------
					case 1:
					{
						m_upgradeTimer[actor].Start(tf_mvm_bot_flag_carrier_interval_to_2nd_upgrade.FloatValue);
						
						// permanent buff banner effect (handled above)
						
						// update the objective resource so clients have the information
						SetEntProp(TFObjectiveResource(), Prop_Send, "m_nFlagCarrierUpgradeLevel", 1);
						SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMBaseBombUpgradeTime", GetGameTime());
						SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMNextBombUpgradeTime", GetGameTime() + m_upgradeTimer[actor].GetRemainingTime());
						HaveAllPlayersSpeakConceptIfAllowed("TLK_MVM_BOMB_CARRIER_UPGRADE1", TFTeam_Defenders);
						TE_TFParticleEffect("mvm_levelup1", .attachType = PATTACH_POINT_FOLLOW, .entity = actor, .attachPoint = LookupEntityAttachment(actor, "head"));
						return true;
					}
					
					//---------------------------------------
					case 2:
					{
						m_upgradeTimer[actor].Start(tf_mvm_bot_flag_carrier_interval_to_3rd_upgrade.FloatValue);
						
						TF2Attrib_SetByName(actor, "health regen", tf_mvm_bot_flag_carrier_health_regen.FloatValue);
						
						// update the objective resource so clients have the information
						SetEntProp(TFObjectiveResource(), Prop_Send, "m_nFlagCarrierUpgradeLevel", 2);
						SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMBaseBombUpgradeTime", GetGameTime());
						SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMNextBombUpgradeTime", GetGameTime() + m_upgradeTimer[actor].GetRemainingTime());
						HaveAllPlayersSpeakConceptIfAllowed("TLK_MVM_BOMB_CARRIER_UPGRADE2", TFTeam_Defenders);
						TE_TFParticleEffect("mvm_levelup2", .attachType = PATTACH_POINT_FOLLOW, .entity = actor, .attachPoint = LookupEntityAttachment(actor, "head"));
						return true;
					}
					
					//---------------------------------------
					case 3:
					{
						// add critz
						TF2_AddCondition(actor, TFCond_CritCanteen);
						
						// update the objective resource so clients have the information
						SetEntProp(TFObjectiveResource(), Prop_Send, "m_nFlagCarrierUpgradeLevel", 3);
						SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMBaseBombUpgradeTime", -1.0);
						SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMNextBombUpgradeTime", -1.0);
						HaveAllPlayersSpeakConceptIfAllowed("TLK_MVM_BOMB_CARRIER_UPGRADE3", TFTeam_Defenders);
						TE_TFParticleEffect("mvm_levelup3", .attachType = PATTACH_POINT_FOLLOW, .entity = actor, .attachPoint = LookupEntityAttachment(actor, "head"));
						return true;
					}
				}
			}
		}
	}
	
	return false;
}

static int CTFBotDeliverFlag_OnContact(NextBotAction action, int actor, int other, Address result)
{
	if (GameRules_IsMannVsMachineMode() && IsValidEntity(other) && FClassnameIs(other, "func_capturezone"))
	{
		return action.TrySuspendFor(CTFBotMvMDeployBomb_Create(), RESULT_CRITICAL, "Delivering the bomb!");
	}
	
	return action.TryContinue();
}
