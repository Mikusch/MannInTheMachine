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

static IntervalTimer m_undergroundTimer[MAXPLAYERS + 1];

void CTFBotMainAction_Init()
{
	ActionFactory = new NextBotActionFactory("MainAction");
	ActionFactory.SetCallback(NextBotActionCallbackType_InitialContainedAction, CTFBotMainAction_InitialContainedAction);
	ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, CTFBotMainAction_OnStart);
	ActionFactory.SetCallback(NextBotActionCallbackType_Update, CTFBotMainAction_Update);
	ActionFactory.SetEventCallback(EventResponderType_OnKilled, CTFBotMainAction_OnKilled);
	ActionFactory.SetEventCallback(EventResponderType_OnOtherKilled, CTFBotMainAction_OnOtherKilled);
}

NextBotAction CTFBotMainAction_Create()
{
	return ActionFactory.Create();
}

NextBotActionFactory CTFBotMainAction_GetFactory()
{
	return ActionFactory;
}

static NextBotAction CTFBotMainAction_InitialContainedAction(NextBotAction action, int actor)
{
	return CTFBotScenarioMonitor_Create();
}

static int CTFBotMainAction_OnStart(NextBotAction action, int actor, NextBotAction priorAction)
{
	action.SetData("m_isWaitingForFullReload", false);
	
	// if bot is already dead at this point, make sure it's dead
	// check for !IsAlive because bot could be DYING
	if (!IsPlayerAlive(actor))
	{
		return action.ChangeTo(CTFBotDead_Create(), "I'm actually dead");
	}
	
	return action.Continue();
}

static int CTFBotMainAction_Update(NextBotAction action, int actor, float interval)
{
	PrintToServer("CTFBotMainAction_Update");
	
	if (TF2_GetClientTeam(actor) != TFTeam_Blue && TF2_GetClientTeam(actor) != TFTeam_Red)
	{
		// not on a team - do nothing
		return action.Done("Not on a playing team");
	}
	
	if (GameRules_IsMannVsMachineMode() && TF2_GetClientTeam(actor) == TFTeam_Invaders)
	{
		if (Player(actor).HasTag("bot_gatebot"))
		{
			SetHudTextParams(0.05, 0.05, interval, 255, 255, 255, 255);
			ShowSyncHudText(actor, g_InfoHudSync, "%t", "Invader_GateBot");
		}
		
		CTFNavArea myArea = view_as<CTFNavArea>(CBaseCombatCharacter(actor).GetLastKnownArea());
		TFNavAttributeType spawnRoomFlag = TF2_GetClientTeam(actor) == TFTeam_Red ? RED_SPAWN_ROOM : BLUE_SPAWN_ROOM;
		
		if (myArea && myArea.HasAttributeTF(spawnRoomFlag))
		{
			// invading bots get uber while they leave their spawn so they don't drop their cash where players can't pick it up
			TF2_AddCondition(actor, TFCond_Ubercharged, 0.5);
			TF2_AddCondition(actor, TFCond_UberchargedHidden, 0.5);
			TF2_AddCondition(actor, TFCond_UberchargeFading, 0.5);
			
			// force bots to walk out of spawn
			if (!Player(actor).HasAttribute(AUTO_JUMP))
			{
				TF2Attrib_SetByName(actor, "no_jump", 1.0);
			}
			
			if (mitm_spawn_hurry_time.FloatValue)
			{
				if (!Player(actor).m_flRequiredSpawnLeaveTime)
				{
					// minibosses and bomb carriers are slow and get more time to leave
					float flTime = (GetEntProp(actor, Prop_Send, "m_bIsMiniBoss") || SDKCall_HasTheFlag(actor)) ? mitm_spawn_hurry_time.FloatValue * 1.5 : mitm_spawn_hurry_time.FloatValue;
					Player(actor).m_flRequiredSpawnLeaveTime = GetGameTime() + flTime;
				}
				else
				{
					if (TF2_IsPlayerInCondition(actor, TFCond_Dazed))
					{
						// If we are stunned in our spawn, extend the time
						Player(actor).m_flRequiredSpawnLeaveTime += interval;
					}
					
					float flTimeLeft = Player(actor).m_flRequiredSpawnLeaveTime - GetGameTime();
					if (flTimeLeft <= 0.0)
					{
						ForcePlayerSuicide(actor);
					}
					else if (flTimeLeft <= 15.0)
					{
						// motivate them to leave their spawn
						SetHudTextParams(-1.0, 0.7, interval, 255, 255, 255, 255);
						ShowSyncHudText(actor, g_WarningHudSync, "%t", "Invader_HurryOutOfSpawn", flTimeLeft);
					}
				}
			}
			else
			{
				Player(actor).m_flRequiredSpawnLeaveTime = 0.0;
			}
		}
		else
		{
			// not in spawn, reset their time
			Player(actor).m_flRequiredSpawnLeaveTime = 0.0;
			
			TF2Attrib_RemoveByName(actor, "no_jump");
		}
		
		float origin[3];
		GetClientAbsOrigin(actor, origin);
		
		// watch for bots that have fallen through the ground
		if (myArea && myArea.GetZVector(origin) - origin[2] > 100.0)
		{
			if (!m_undergroundTimer[actor].HasStarted())
			{
				m_undergroundTimer[actor].Start();
			}
			else if (m_undergroundTimer[actor].IsGreaterThen(3.0))
			{
				char auth[MAX_AUTHID_LENGTH], teamName[MAX_TEAM_NAME_LENGTH];
				GetClientAuthId(actor, AuthId_Engine, auth, sizeof(auth), false);
				GetTeamName(GetClientTeam(actor), teamName, sizeof(teamName));
				
				LogMessage("\"%N<%i><%s><%s>\" underground (position \"%3.2f %3.2f %3.2f\")", 
						   actor, 
						   GetClientUserId(actor), 
						   auth, 
						   teamName, 
						   origin[0], origin[1], origin[2]);
				
				// teleport bot to a reasonable place
				float center[3];
				myArea.GetCenter(center);
				TeleportEntity(actor, center);
			}
		}
		else
		{
			m_undergroundTimer[actor].Invalidate();
		}
		
		// TODO: Check if this is a good place
		/*if ( me->ShouldAutoJump() )
		{
			me->GetLocomotionInterface()->Jump();
		}*/
	}
	
	// TODO
	if (TF2_GetPlayerClass(actor) == TFClass_DemoMan)
	{
		// dont auto reload, so we fire stickies fast
		//me->SetAutoReload( false );
	}
	else
	{
		// reload weapons
		//me->SetAutoReload( true );
	}
	
	return action.Continue();
}

static int CTFBotMainAction_OnKilled(NextBotAction action, int actor, int attacker, int inflictor, float damage, int damagetype)
{
	return action.TryChangeTo(CTFBotDead_Create(), RESULT_CRITICAL, "I died!");
}

static int CTFBotMainAction_OnOtherKilled(NextBotAction action, int actor, int victim, int attacker, int inflictor, float damage, int damagetype)
{
	bool do_taunt = IsEntityClient(victim);
	
	if (do_taunt)
	{
		if (TF2_GetClientTeam(actor) != TF2_GetClientTeam(victim) && actor == attacker)
		{
			bool isTaunting = !SDKCall_HasTheFlag(attacker) && GetRandomFloat(0.0, 100.0) <= tf_bot_taunt_victim_chance.FloatValue;
			
			if (GetEntProp(attacker, Prop_Send, "m_bIsMiniBoss"))
			{
				// Bosses don't taunt puny humans
				isTaunting = false;
			}
			
			if (isTaunting)
			{
				// we just killed a human - taunt!
				return action.TrySuspendFor(CTFBotTaunt_Create(), RESULT_IMPORTANT, "Taunting our victim");
			}
		}
	}
	
	return action.TryContinue();
}
