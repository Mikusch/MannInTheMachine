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

static NextBotActionFactory ActionFactory;

methodmap CTFBotMainAction < NextBotAction
{
	public static void Init()
	{
		ActionFactory = new NextBotActionFactory("MainAction");
		ActionFactory.BeginDataMapDesc()
			.DefineIntField("m_undergroundTimer")
		.EndDataMapDesc();
		ActionFactory.SetCallback(NextBotActionCallbackType_InitialContainedAction, InitialContainedAction);
		ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
		ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
		ActionFactory.SetCallback(NextBotActionCallbackType_OnEnd, OnEnd);
		ActionFactory.SetCallback(NextBotActionCallbackType_CreateInitialAction, CreateInitialAction);
		ActionFactory.SetEventCallback(EventResponderType_OnKilled, OnKilled);
		ActionFactory.SetEventCallback(EventResponderType_OnContact, OnContact);
		ActionFactory.SetEventCallback(EventResponderType_OnOtherKilled, OnOtherKilled);
		ActionFactory.SetQueryCallback(ContextualQueryType_ShouldAttack, ShouldAttack);
		ActionFactory.SetQueryCallback(ContextualQueryType_ShouldHurry, ShouldHurry);
	}
	
	public static NextBotActionFactory GetFactory()
	{
		return ActionFactory;
	}
	
	public CTFBotMainAction()
	{
		return view_as<CTFBotMainAction>(ActionFactory.Create());
	}
	
	property IntervalTimer m_undergroundTimer
	{
		public get()
		{
			return this.GetData("m_undergroundTimer");
		}
		public set(IntervalTimer undergroundTimer)
		{
			this.SetData("m_undergroundTimer", undergroundTimer);
		}
	}
}

static NextBotAction InitialContainedAction(CTFBotMainAction action, int actor)
{
	if (TF2_GetClientTeam(actor) == TFTeam_Invaders)
	{
		return CTFBotTacticalMonitor();
	}
	
	return NULL_ACTION;
}

static int OnStart(CTFBotMainAction action, int actor, NextBotAction priorAction)
{
	if (TF2_GetClientTeam(actor) != TFTeam_Invaders)
	{
		// not an invader - do nothing
		return action.Done("I'm not an invader!");
	}
	
	CTFPlayer(actor).m_isWaitingForFullReload = false;
	
	// if bot is already dead at this point, make sure it's dead
	// check for !IsAlive because bot could be DYING
	if (!IsPlayerAlive(actor))
	{
		return action.ChangeTo(CTFBotDead(), "I'm actually dead");
	}
	
	// we just spawned
	if (GetGameTime() - CTFPlayer(actor).GetSpawnTime() < 1.0)
	{
		// bots must quickly leave their spawn
		CTFPlayer(actor).m_flSpawnTimeLeft = CTFPlayer(actor).CalculateSpawnTime();
		CTFPlayer(actor).m_flSpawnTimeLeftMax = CTFPlayer(actor).m_flSpawnTimeLeft;
		
		char name[MAX_NAME_LENGTH];
		CTFPlayer(actor).GetInvaderName(name, sizeof(name));
		PrintCenterText(actor, "%t", "Invader_Spawned", name);
		
		EmitSoundToClient(actor, "ui/system_message_alert.wav", .channel = SNDCHAN_STATIC);
	}
	
	return action.Continue();
}

static int Update(CTFBotMainAction action, int actor, float interval)
{
	if (IsMannVsMachineMode() && TF2_GetClientTeam(actor) == TFTeam_Invaders)
	{
		CTFNavArea myArea = view_as<CTFNavArea>(CBaseCombatCharacter(actor).GetLastKnownArea());
		TFNavAttributeType spawnRoomFlag = TF2_GetClientTeam(actor) == TFTeam_Red ? RED_SPAWN_ROOM : BLUE_SPAWN_ROOM;
		
		if (myArea && myArea.HasAttributeTF(spawnRoomFlag))
		{
			// invading bots get uber while they leave their spawn so they don't drop their cash where players can't pick it up
			TF2_AddCondition(actor, TFCond_Ubercharged, 0.5);
			TF2_AddCondition(actor, TFCond_UberchargedHidden, 0.5);
			TF2_AddCondition(actor, TFCond_UberchargeFading, 0.5);
			TF2_AddCondition(actor, TFCond_ImmuneToPushback, 1.0);
			
			// force bots to walk out of spawn
			if (!CTFPlayer(actor).HasAttribute(AUTO_JUMP))
			{
				TF2Attrib_SetByName(actor, "no_jump", 1.0);
			}
			
			if (GameRules_GetRoundState() == RoundState_RoundRunning && CTFPlayer(actor).m_flSpawnTimeLeft != -1.0)
			{
				// pause spawn timer while stunned
				if (!TF2_IsPlayerInCondition(actor, TFCond_Dazed))
				{
					float velocity[3];
					CTFPlayer(actor).GetAbsVelocity(velocity);
					
					// as long as they are moving, slow down the timer drastically
					float flTimeToSubtract = GetVectorLength(velocity) >= GetEntPropFloat(actor, Prop_Send, "m_flMaxspeed") ? (interval / 4) : interval;
					CTFPlayer(actor).m_flSpawnTimeLeft -= flTimeToSubtract;
					
					if (CTFPlayer(actor).m_flSpawnTimeLeft <= 0.0)
					{
						ForcePlayerSuicide(actor);
						
						// kick players for dying to the spawn timer too many times
						int iMaxDeaths = sm_mitm_max_spawn_deaths.IntValue;
						if (iMaxDeaths && !sm_mitm_developer.BoolValue)
						{
							if (iMaxDeaths <= ++CTFPlayer(actor).m_spawnDeathCount)
							{
								KickClient(actor, "%t", "Invader_SpawnTimer_KickReason");
								CPrintToChatAll("%s %t", PLUGIN_TAG, "Invader_SpawnTimer_Kicked", actor);
							}
							else
							{
								CPrintToChat(actor, "%s %t", PLUGIN_TAG, "Invader_SpawnTimer_Warning", iMaxDeaths - CTFPlayer(actor).m_spawnDeathCount);
							}
						}
					}
				}
				
				if (CTFPlayer(actor).m_flSpawnTimeLeft > 0.0)
				{
					float flProgress = CTFPlayer(actor).m_flSpawnTimeLeft / CTFPlayer(actor).m_flSpawnTimeLeftMax;
					
					char szProgressBar[64];
					for (int i = 0; i < PROGRESS_BAR_NUM_BLOCKS; ++i)
					{
						bool bFilled = float(i) / PROGRESS_BAR_NUM_BLOCKS < flProgress;
						StrCat(szProgressBar, sizeof(szProgressBar), bFilled ? PROGRESS_BAR_CHAR_FILLED : PROGRESS_BAR_CHAR_EMPTY);
					}
					
					SetHudTextParams(-1.0, 0.65, interval, 255, 255, 255, 255);
					ShowSyncHudText(actor, g_hWarningHudSync, "%t", "Invader_SpawnTimer_Countdown", szProgressBar);
				}
			}
		}
		else
		{
			TF2Attrib_RemoveByName(actor, "no_jump");
		}
		
		float origin[3];
		GetClientAbsOrigin(actor, origin);
		
		// watch for bots that have fallen through the ground
		if (myArea && myArea.GetZVector(origin) - origin[2] > 100.0)
		{
			if (!action.m_undergroundTimer.HasStarted())
			{
				action.m_undergroundTimer.Start();
			}
			else if (action.m_undergroundTimer.IsGreaterThan(3.0))
			{
				LogMessage("\"%L\" underground (position \"%3.2f %3.2f %3.2f\")", actor, origin[0], origin[1], origin[2]);
				
				// teleport bot to a reasonable place
				float center[3];
				myArea.GetCenter(center);
				TeleportEntity(actor, center);
			}
		}
		else
		{
			action.m_undergroundTimer.Invalidate();
		}
	}
	
	CTFPlayer(actor).EquipRequiredWeapon();
	
	return action.Continue();
}

static void OnEnd(CTFBotMainAction action, int actor, NextBotAction nextAction)
{
	delete action.m_undergroundTimer;
}

static void CreateInitialAction(CTFBotMainAction action)
{
	action.m_undergroundTimer = new IntervalTimer();
}

static int OnKilled(CTFBotMainAction action, int actor, int attacker, int inflictor, float damage, int damagetype)
{
	return action.TryChangeTo(CTFBotDead(), RESULT_CRITICAL, "I died!");
}

static int OnContact(CTFBotMainAction action, int actor, int other, Address result)
{
	if (IsValidEntity(other) && !(view_as<SolidFlags_t>(GetEntProp(other, Prop_Data, "m_usSolidFlags")) & FSOLID_NOT_SOLID) && other != 0 && !IsEntityClient(other))
	{
		// Mini-bosses destroy non-Sentrygun objects they bump into (ie: Dispensers)
		if (IsMannVsMachineMode() && CTFPlayer(actor).IsMiniBoss())
		{
			if (IsBaseObject(other))
			{
				if (TF2_GetObjectType(other) != TFObject_Sentry || GetEntProp(other, Prop_Send, "m_bMiniBuilding"))
				{
					int damage = Max(GetEntProp(other, Prop_Data, "m_iMaxHealth"), GetEntProp(other, Prop_Data, "m_iHealth"));
					
					float victimCenter[3], actorCenter[3], toVictim[3];
					CBaseEntity(other).WorldSpaceCenter(victimCenter);
					CBaseEntity(actor).WorldSpaceCenter(actorCenter);
					SubtractVectors(victimCenter, actorCenter, toVictim);
					
					CTakeDamageInfo info = GetGlobalDamageInfo();
					info.Init(actor, actor, .damage = float(4 * damage), .bitsDamageType = DMG_BLAST);
					CalculateMeleeDamageForce(info, toVictim, actorCenter, 1.0);
					CBaseEntity(other).TakeDamage(info);
				}
			}
		}
	}
	
	return action.TryContinue();
}

static int OnOtherKilled(CTFBotMainAction action, int actor, int victim, int attacker, int inflictor, float damage, int damagetype)
{
	bool do_taunt = IsValidEntity(victim) && IsEntityClient(victim);
	
	if (do_taunt)
	{
		if (GetClientTeam(actor) != GetClientTeam(victim) && actor == attacker)
		{
			bool isTaunting = !CTFPlayer(attacker).HasTheFlag() && GetRandomFloat(0.0, 100.0) <= tf_bot_taunt_victim_chance.FloatValue;
			
			if (IsMannVsMachineMode() && CTFPlayer(attacker).IsMiniBoss())
			{
				// Bosses don't taunt puny humans
				isTaunting = false;
			}
			
			if (isTaunting)
			{
				// we just killed a human - taunt!
				return action.TrySuspendFor(CTFBotTaunt(), RESULT_IMPORTANT, "Taunting our victim");
			}
		}
	}
	
	return action.TryContinue();
}

static QueryResultType ShouldAttack(CTFBotMainAction action, INextBot bot, CKnownEntity knownEntity)
{
	if (g_pPopulationManager.IsValid())
	{
		// if I'm in my spawn room, obey the population manager's attack restrictions
		int me = bot.GetEntity();
		CTFNavArea myArea = view_as<CTFNavArea>(CBaseCombatCharacter(me).GetLastKnownArea());
		TFNavAttributeType spawnRoomFlag = TF2_GetClientTeam(me) == TFTeam_Red ? RED_SPAWN_ROOM : BLUE_SPAWN_ROOM;
		
		if (myArea && myArea.HasAttributeTF(spawnRoomFlag))
		{
			return g_pPopulationManager.CanBotsAttackWhileInSpawnRoom() ? ANSWER_YES : ANSWER_NO;
		}
	}
	
	return ANSWER_YES;
}

static QueryResultType ShouldHurry(CTFBotMainAction action, INextBot bot)
{
	if (g_pPopulationManager.IsValid())
	{
		// if I'm in my spawn room, obey the population manager's attack restrictions
		int me = bot.GetEntity();
		CTFNavArea myArea = view_as<CTFNavArea>(CBaseCombatCharacter(me).GetLastKnownArea());
		TFNavAttributeType spawnRoomFlag = TF2_GetClientTeam(me) == TFTeam_Red ? RED_SPAWN_ROOM : BLUE_SPAWN_ROOM;
		
		if (myArea && myArea.HasAttributeTF(spawnRoomFlag))
		{
			if (g_pPopulationManager.CanBotsAttackWhileInSpawnRoom())
			{
				// hurry to leave the spawn
				return ANSWER_YES;
			}
		}
	}
	
	return ANSWER_UNDEFINED;
}
