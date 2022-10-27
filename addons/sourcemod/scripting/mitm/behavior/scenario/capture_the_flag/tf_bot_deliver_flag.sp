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

methodmap CTFBotDeliverFlag < NextBotAction
{
	public static void Init()
	{
		ActionFactory = new NextBotActionFactory("DeliverFlag");
		ActionFactory.BeginDataMapDesc()
			.DefineIntField("m_upgradeTimer")
			.DefineIntField("m_buffPulseTimer")
			.DefineIntField("m_upgradeLevel")
		.EndDataMapDesc();
		ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
		ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
		ActionFactory.SetCallback(NextBotActionCallbackType_OnEnd, OnEnd);
		ActionFactory.SetEventCallback(EventResponderType_OnContact, OnContact);
	}
	
	public CTFBotDeliverFlag()
	{
		CTFBotDeliverFlag action = view_as<CTFBotDeliverFlag>(ActionFactory.Create());
		action.m_upgradeTimer = new CountdownTimer();
		action.m_buffPulseTimer = new CountdownTimer();
		return action;
	}
	
	property CountdownTimer m_upgradeTimer
	{
		public get()
		{
			return this.GetData("m_upgradeTimer");
		}
		public set(CountdownTimer upgradeTimer)
		{
			this.SetData("m_upgradeTimer", upgradeTimer);
		}
	}
	
	property CountdownTimer m_buffPulseTimer
	{
		public get()
		{
			return this.GetData("m_buffPulseTimer");
		}
		public set(CountdownTimer buffPulseTimer)
		{
			this.SetData("m_buffPulseTimer", buffPulseTimer);
		}
	}
	
	property int m_upgradeLevel
	{
		public get()
		{
			return this.GetData("m_upgradeLevel");
		}
		public set(int upgradeLevel)
		{
			this.SetData("m_upgradeLevel", upgradeLevel);
		}
	}
}

static int OnStart(CTFBotDeliverFlag action, int actor, NextBotAction priorAction)
{
	if (!tf_mvm_bot_allow_flag_carrier_to_fight.BoolValue)
	{
		Player(actor).SetAttribute(SUPPRESS_FIRE);
	}
	
	if (!IsFakeClient(actor))
	{
		tf_avoidteammates_pushaway.ReplicateToClient(actor, "0");
	}
	
	// mini-bosses don't upgrade - they are already tough
	if (GetEntProp(actor, Prop_Send, "m_bIsMiniBoss"))
	{
		// Set threat level to max
		action.m_upgradeLevel = DONT_UPGRADE;
		if (g_pObjectiveResource.IsValid())
		{
			g_pObjectiveResource.SetFlagCarrierUpgradeLevel(4);
			g_pObjectiveResource.SetBaseMvMBombUpgradeTime(-1.0);
			g_pObjectiveResource.SetNextMvMBombUpgradeTime(-1.0);
		}
	}
	else
	{
		action.m_upgradeLevel = 0;
		action.m_upgradeTimer.Start(tf_mvm_bot_flag_carrier_interval_to_1st_upgrade.FloatValue);
		if (g_pObjectiveResource.IsValid())
		{
			g_pObjectiveResource.SetBaseMvMBombUpgradeTime(GetGameTime());
			g_pObjectiveResource.SetNextMvMBombUpgradeTime(GetGameTime() + action.m_upgradeTimer.GetRemainingTime());
		}
	}
	
	return action.Continue();
}

static int Update(CTFBotDeliverFlag action, int actor, float interval)
{
	int flag = Player(actor).GetFlagToFetch();
	
	if (!IsValidEntity(flag))
	{
		return action.Done("No flag");
	}
	
	int carrier = GetEntPropEnt(flag, Prop_Send, "m_hOwnerEntity");
	if (carrier == -1 || actor != carrier)
	{
		return action.Done("I'm no longer carrying the flag");
	}
	
	if (UpgradeOverTime(action, actor))
	{
		return action.SuspendFor(CTFBotTaunt(), "Taunting for our new upgrade");
	}
	
	return action.Continue();
}

static void OnEnd(CTFBotDeliverFlag action, int actor, NextBotAction nextAction)
{
	Player(actor).ClearAttribute(SUPPRESS_FIRE);
	
	if (!IsFakeClient(actor))
	{
		tf_avoidteammates_pushaway.ReplicateToClient(actor, "1");
	}
	
	if (IsMannVsMachineMode())
	{
		SDKCall_ResetRageBuffs(GetPlayerShared(actor));
		TF2Attrib_RemoveByName(actor, "health regen");
		TF2_RemoveCondition(actor, TFCond_CritCanteen);
	}
	
	delete action.m_upgradeTimer;
	delete action.m_buffPulseTimer;
}

static bool UpgradeOverTime(CTFBotDeliverFlag action, int actor)
{
	if (IsMannVsMachineMode() && action.m_upgradeLevel != DONT_UPGRADE)
	{
		CTFNavArea myArea = view_as<CTFNavArea>(CBaseCombatCharacter(actor).GetLastKnownArea());
		TFNavAttributeType spawnRoomFlag = TF2_GetClientTeam(actor) == TFTeam_Red ? RED_SPAWN_ROOM : BLUE_SPAWN_ROOM;
		
		if (myArea && myArea.HasAttributeTF(spawnRoomFlag))
		{
			// don't start counting down until we leave the spawn
			action.m_upgradeTimer.Start(tf_mvm_bot_flag_carrier_interval_to_1st_upgrade.FloatValue);
			g_pObjectiveResource.SetBaseMvMBombUpgradeTime(GetGameTime());
			g_pObjectiveResource.SetNextMvMBombUpgradeTime(GetGameTime() + action.m_upgradeTimer.GetRemainingTime());
		}
		
		// do defensive buff effect ourselves (since we're not a soldier)
		if (action.m_upgradeLevel > 0 && action.m_buffPulseTimer.IsElapsed())
		{
			action.m_buffPulseTimer.Start(1.0);
			
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
		if (action.m_upgradeTimer.IsElapsed())
		{
			const int maxLevel = 3;
			
			if (action.m_upgradeLevel < maxLevel)
			{
				++action.m_upgradeLevel;
				
				BroadcastSound(255, "MVM.Warning");
				
				switch (action.m_upgradeLevel)
				{
					//---------------------------------------
					case 1:
					{
						action.m_upgradeTimer.Start(tf_mvm_bot_flag_carrier_interval_to_2nd_upgrade.FloatValue);
						
						// permanent buff banner effect (handled above)
						
						// update the objective resource so clients have the information
						if (g_pObjectiveResource.IsValid())
						{
							g_pObjectiveResource.SetFlagCarrierUpgradeLevel(1);
							g_pObjectiveResource.SetBaseMvMBombUpgradeTime(GetGameTime());
							g_pObjectiveResource.SetNextMvMBombUpgradeTime(GetGameTime() + action.m_upgradeTimer.GetRemainingTime());
							HaveAllPlayersSpeakConceptIfAllowed("TLK_MVM_BOMB_CARRIER_UPGRADE1", TFTeam_Defenders);
							TE_TFParticleEffect("mvm_levelup1", .attachType = PATTACH_POINT_FOLLOW, .entity = actor, .attachPoint = LookupEntityAttachment(actor, "head"));
						}
						return true;
					}
					
					//---------------------------------------
					case 2:
					{
						action.m_upgradeTimer.Start(tf_mvm_bot_flag_carrier_interval_to_3rd_upgrade.FloatValue);
						
						TF2Attrib_SetByName(actor, "health regen", tf_mvm_bot_flag_carrier_health_regen.FloatValue);
						
						// update the objective resource so clients have the information
						if (g_pObjectiveResource.IsValid())
						{
							g_pObjectiveResource.SetFlagCarrierUpgradeLevel(2);
							g_pObjectiveResource.SetBaseMvMBombUpgradeTime(GetGameTime());
							g_pObjectiveResource.SetNextMvMBombUpgradeTime(GetGameTime() + action.m_upgradeTimer.GetRemainingTime());
							HaveAllPlayersSpeakConceptIfAllowed("TLK_MVM_BOMB_CARRIER_UPGRADE2", TFTeam_Defenders);
							TE_TFParticleEffect("mvm_levelup2", .attachType = PATTACH_POINT_FOLLOW, .entity = actor, .attachPoint = LookupEntityAttachment(actor, "head"));
						}
						return true;
					}
					
					//---------------------------------------
					case 3:
					{
						// add critz
						TF2_AddCondition(actor, TFCond_CritCanteen);
						
						// update the objective resource so clients have the information
						if (g_pObjectiveResource.IsValid())
						{
							g_pObjectiveResource.SetFlagCarrierUpgradeLevel(3);
							g_pObjectiveResource.SetBaseMvMBombUpgradeTime(-1.0);
							g_pObjectiveResource.SetNextMvMBombUpgradeTime(-1.0);
							HaveAllPlayersSpeakConceptIfAllowed("TLK_MVM_BOMB_CARRIER_UPGRADE3", TFTeam_Defenders);
							TE_TFParticleEffect("mvm_levelup3", .attachType = PATTACH_POINT_FOLLOW, .entity = actor, .attachPoint = LookupEntityAttachment(actor, "head"));
						}
						return true;
					}
				}
			}
		}
	}
	
	return false;
}

static int OnContact(CTFBotDeliverFlag action, int actor, int other, Address result)
{
	if (IsMannVsMachineMode() && IsValidEntity(other) && FClassnameIs(other, "func_capturezone"))
	{
		return action.TrySuspendFor(CTFBotMvMDeployBomb(), RESULT_CRITICAL, "Delivering the bomb!");
	}
	
	return action.TryContinue();
}
