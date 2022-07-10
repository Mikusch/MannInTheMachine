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

static int m_victim[MAXPLAYERS + 1];
static float m_lastKnownVictimPosition[MAXPLAYERS + 1][3];

static CountdownTimer m_talkTimer[MAXPLAYERS + 1];
static CountdownTimer m_detonateTimer[MAXPLAYERS + 1];

static bool m_bHasDetonated[MAXPLAYERS + 1];
static bool m_bWasSuccessful[MAXPLAYERS + 1];
static bool m_bWasKilled[MAXPLAYERS + 1];

static float m_vecDetLocation[MAXPLAYERS + 1][3];

void CTFBotMissionSuicideBomber_Init()
{
	ActionFactory = new NextBotActionFactory("MissionSuicideBomber");
	ActionFactory.BeginDataMapDesc()
	// TODO
	.EndDataMapDesc();
	ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, CTFBotMissionSuicideBomber_OnStart);
	ActionFactory.SetCallback(NextBotActionCallbackType_Update, CTFBotMissionSuicideBomber_Update);
	ActionFactory.SetEventCallback(EventResponderType_OnKilled, CTFBotMissionSuicideBomber_OnKilled);
}

NextBotAction CTFBotMissionSuicideBomber_Create()
{
	return ActionFactory.Create();
}

static int CTFBotMissionSuicideBomber_OnStart(NextBotAction action, int actor, NextBotAction priorAction)
{
	m_detonateTimer[actor].Invalidate();
	m_bHasDetonated[actor] = false;
	m_bWasSuccessful[actor] = false;
	m_bWasKilled[actor] = false;
	
	m_victim[actor] = EntIndexToEntRef(Player(actor).GetMissionTarget());
	
	if (IsValidEntity(m_victim[actor]))
	{
		GetEntPropVector(m_victim[actor], Prop_Data, "m_vecAbsOrigin", m_lastKnownVictimPosition[actor]);
	}
	
	return action.Continue();
}

static int CTFBotMissionSuicideBomber_Update(NextBotAction action, int actor, float interval)
{
	// one we start detonating, there's no turning back
	if (m_detonateTimer[actor].HasStarted())
	{
		if (m_detonateTimer[actor].IsElapsed())
		{
			GetClientAbsOrigin(actor, m_vecDetLocation[actor]);
			Detonate(actor);
			
			// Send out an event
			if (m_bWasSuccessful[actor] && IsValidEntity(m_victim[actor]) && HasEntProp(m_victim[actor], Prop_Send, "m_hBuilder"))
			{
				int owner = GetEntPropEnt(m_victim[actor], Prop_Send, "m_hBuilder");
				if (owner != -1)
				{
					Event event = CreateEvent("mvm_sentrybuster_detonate");
					if (event)
					{
						event.SetInt("player", owner);
						event.SetFloat("det_x", m_vecDetLocation[actor][0]);
						event.SetFloat("det_y", m_vecDetLocation[actor][1]);
						event.SetFloat("det_z", m_vecDetLocation[actor][2]);
						FireEvent(event);
					}
				}
			}
			
			// KABOOM!
			return action.Done("KABOOM!");
		}
		
		return action.Continue();
	}
	
	if (GetEntProp(actor, Prop_Data, "m_iHealth") == 1)
	{
		// low on health - detonate where we are!
		StartDetonate(actor, false, true);
		
		return action.Continue();
	}
	
	if (IsValidEntity(m_victim[actor]))
	{
		// update chase destination
		if (GetEntProp(m_victim[actor], Prop_Data, "m_lifeState") == LIFE_ALIVE && !(GetEntProp(m_victim[actor], Prop_Data, "m_fEffects") & EF_NODRAW))
		{
			GetEntPropVector(m_victim[actor], Prop_Data, "m_vecAbsOrigin", m_lastKnownVictimPosition[actor]);
		}
		
		// if the engineer is carrying his sentry, he becomes the victim
		if (HasEntProp(m_victim[actor], Prop_Send, "m_hBuilder"))
		{
			if (GetEntProp(m_victim[actor], Prop_Send, "m_bCarried") && GetEntPropEnt(m_victim[actor], Prop_Send, "m_hBuilder") != -1)
			{
				// path to the engineer carrying the sentry
				GetEntPropVector(GetEntPropEnt(m_victim[actor], Prop_Send, "m_hBuilder"), Prop_Data, "m_vecAbsOrigin", m_lastKnownVictimPosition[actor]);
			}
		}
	}
	
	// Get to a third of the damage range before detonating
	float detonateRange = tf_bot_suicide_bomb_range.FloatValue / 3.0;
	if (IsDistanceBetweenLessThan(actor, m_lastKnownVictimPosition[actor], detonateRange))
	{
		float where[3];
		AddVectors(m_lastKnownVictimPosition[actor], Vector(0.0, 0.0, sv_stepsize.FloatValue), where);
		if (IsLineOfFireClear(actor, where))
		{
			StartDetonate(actor, true);
		}
	}
	
	if (m_talkTimer[actor].IsElapsed())
	{
		m_talkTimer[actor].Start(4.0);
		EmitGameSoundToAll("MVM.SentryBusterIntro", actor);
	}
	
	return action.Continue();
}

static int CTFBotMissionSuicideBomber_OnKilled(NextBotAction action, int actor, int attacker, int inflictor, float damage, int damagetype)
{
	if (!m_bHasDetonated[actor])
	{
		if (!m_detonateTimer[actor].HasStarted())
		{
			StartDetonate(actor);
		}
		else if (m_detonateTimer[actor].IsElapsed())
		{
			Detonate(actor);
		}
		else
		{
			// We're in detonate mode, and something's trying to kill us.  Prevent it.
			if (TF2_GetClientTeam(actor) != TFTeam_Spectator)
			{
				SetEntProp(actor, Prop_Data, "m_lifeState", LIFE_ALIVE);
				SetEntProp(actor, Prop_Data, "m_iHealth", 1);
			}
		}
	}
	
	return action.TryContinue();
}

static void StartDetonate(int actor, bool bWasSuccessful = false, bool bWasKilled = false)
{
	if (m_detonateTimer[actor].HasStarted())
		return;
	
	if (!IsPlayerAlive(actor) || GetEntProp(actor, Prop_Data, "m_iHealth") < 1)
	{
		if (TF2_GetClientTeam(actor) != TFTeam_Spectator)
		{
			SetEntProp(actor, Prop_Data, "m_lifeState", LIFE_ALIVE);
			SetEntProp(actor, Prop_Data, "m_iHealth", 1);
		}
	}
	
	m_bWasSuccessful[actor] = bWasSuccessful;
	m_bWasKilled[actor] = bWasKilled;
	
	SetEntProp(actor, Prop_Data, "m_takedamage", DAMAGE_NO);
	
	FakeClientCommand(actor, "taunt");
	TF2_AddCondition(actor, TFCond_FreezeInput);
	m_detonateTimer[actor].Start(2.0);
	EmitGameSoundToAll("MvM.SentryBusterSpin", actor);
}

static void Detonate(int actor)
{
	// BLAST!
	m_bHasDetonated[actor] = true;
	
	float origin[3], angles[3];
	GetClientAbsOrigin(actor, origin);
	GetClientAbsAngles(actor, angles);
	
	TE_TFParticleEffect("explosionTrail_seeds_mvm", .vecOrigin = origin, .vecAngles = angles);
	TE_TFParticleEffect("fluidSmokeExpl_ring_mvm", .vecOrigin = origin, .vecAngles = angles);
	
	EmitGameSoundToAll("MVM.SentryBusterExplode", actor);
	
	UTIL_ScreenShake(origin, 25.0, 5.0, 5.0, 1000.0, SHAKE_START);
	
	if (!m_bWasSuccessful[actor])
	{
		if (GameRules_IsMannVsMachineMode())
		{
			HaveAllPlayersSpeakConceptIfAllowed("TLK_MVM_SENTRY_BUSTER_DOWN", TFTeam_Defenders);
		}
	}
	
	ArrayList victimList = new ArrayList();
	
	// players
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (TF2_GetClientTeam(client) <= TFTeam_Spectator)
			continue;
		
		if (!IsPlayerAlive(client))
			continue;
		
		victimList.Push(client);
	}
	
	// objects
	int obj = MaxClients + 1;
	while ((obj = FindEntityByClassname(obj, "obj_*")) != -1)
	{
		if (view_as<TFTeam>(GetEntProp(obj, Prop_Data, "m_iTeamNum")) <= TFTeam_Spectator)
			continue;
		
		victimList.Push(obj);
	}
	
	// Send out an event whenever players damaged us to the point where we had to detonate
	if (m_bWasKilled[actor])
	{
		Event event = CreateEvent("mvm_sentrybuster_killed");
		if (event)
		{
			event.SetInt("sentry_buster", actor);
			FireEvent(event);
		}
	}
	
	// Clear my mission before we have everyone take damage so I will die with the rest
	Player(actor).SetMission(NO_MISSION);
	SetEntProp(actor, Prop_Data, "m_takedamage", DAMAGE_YES);
	
	// kill victims (including actor)
	for (int i = 0; i < victimList.Length; ++i)
	{
		int victim = victimList.Get(i);
		
		float victimCenter[3], meCenter[3];
		CBaseEntity(victim).WorldSpaceCenter(victimCenter);
		CBaseEntity(actor).WorldSpaceCenter(meCenter);
		
		float toVictim[3];
		SubtractVectors(victimCenter, meCenter, toVictim);
		
		if (GetVectorLength(toVictim) > tf_bot_suicide_bomb_range.FloatValue)
			continue;
		
		if (IsEntityClient(victim))
		{
			int colorHit[4] = { 255, 255, 255, 255 };
			UTIL_ScreenFade(victim, colorHit, 1.0, 0.1, FFADE_IN);
		}
		
		if (IsLineOfFireClear3(actor, victim))
		{
			NormalizeVector(toVictim, toVictim);
			
			int nDamage = Max(TF2Util_GetEntityMaxHealth(victim), GetEntProp(victim, Prop_Data, "m_iHealth"));
			
			float flDamage = float(4 * nDamage);
			if (tf_bot_suicide_bomb_friendly_fire.BoolValue)
			{
				g_bForceFriendlyFire = true;
			}
			
			float vecForce[3];
			CalculateMeleeDamageForce(toVictim, flDamage, 1.0, vecForce);
			SDKHooks_TakeDamage(victim, actor, actor, flDamage, DMG_BLAST, .damageForce = vecForce, .damagePosition = meCenter, .bypassHooks = false);
			
			g_bForceFriendlyFire = false;
		}
	}
	
	// make sure we're removed (in case we detonated in our spawn area where we are invulnerable)
	ForcePlayerSuicide(actor);
	if (IsPlayerAlive(actor))
	{
		TF2_ChangeClientTeam(actor, TFTeam_Spectator);
	}
	
	if (m_bWasKilled[actor])
	{
		// increment num sentry killed this wave
		CWave wave = GetPopulationManager().GetCurrentWave();
		if (wave)
		{
			wave.m_nSentryBustersSpawned++;
		}
	}
}
