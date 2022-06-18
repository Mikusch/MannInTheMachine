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

static int m_victim[MAXPLAYERS + 1];
static float m_lastKnownVictimPosition[MAXPLAYERS + 1][3];

static CountdownTimer m_talkTimer[MAXPLAYERS + 1];
static CountdownTimer m_detonateTimer[MAXPLAYERS + 1];

static bool m_bHasDetonated[MAXPLAYERS + 1];
static bool m_bWasSuccessful[MAXPLAYERS + 1];
static bool m_bWasKilled[MAXPLAYERS + 1];

static float m_vecDetLocation[MAXPLAYERS + 1][3];

void CTFBotMissionSuicideBomber_OnStart(int me)
{
	m_detonateTimer[me].Invalidate();
	m_bHasDetonated[me] = false;
	m_bWasSuccessful[me] = false;
	m_bWasKilled[me] = false;
	
	m_victim[me] = EntIndexToEntRef(Player(me).GetMissionTarget());
	
	if (IsValidEntity(m_victim[me]))
	{
		GetEntPropVector(m_victim[me], Prop_Data, "m_vecAbsOrigin", m_lastKnownVictimPosition[me]);
	}
}

bool CTFBotMissionSuicideBomber_Update(int me)
{
	// one we start detonating, there's no turning back
	if (m_detonateTimer[me].HasStarted())
	{
		if (m_detonateTimer[me].IsElapsed())
		{
			GetClientAbsOrigin(me, m_vecDetLocation[me]);
			Detonate(me);
			
			// Send out an event
			if (m_bWasSuccessful[me] && IsValidEntity(m_victim[me]) && HasEntProp(m_victim[me], Prop_Send, "m_hBuilder"))
			{
				int owner = GetEntPropEnt(m_victim[me], Prop_Send, "m_hBuilder");
				if (owner != -1)
				{
					Event event = CreateEvent("mvm_sentrybuster_detonate");
					if (event)
					{
						event.SetInt("player", owner);
						event.SetFloat("det_x", m_vecDetLocation[me][0]);
						event.SetFloat("det_y", m_vecDetLocation[me][1]);
						event.SetFloat("det_z", m_vecDetLocation[me][2]);
						FireEvent(event);
					}
				}
			}
			
			// KABOOM!
			return false;
		}
		
		return true;
	}
	
	if (GetEntProp(me, Prop_Data, "m_iHealth") == 1)
	{
		// low on health - detonate where we are!
		StartDetonate(me, false, true);
		
		return true;
	}
	
	if (IsValidEntity(m_victim[me]))
	{
		// update chase destination
		if (GetEntProp(m_victim[me], Prop_Data, "m_lifeState") == LIFE_ALIVE && !(GetEntProp(m_victim[me], Prop_Data, "m_fEffects") & EF_NODRAW))
		{
			GetEntPropVector(m_victim[me], Prop_Data, "m_vecAbsOrigin", m_lastKnownVictimPosition[me]);
		}
		
		// if the engineer is carrying his sentry, he becomes the victim
		if (HasEntProp(m_victim[me], Prop_Send, "m_hBuilder"))
		{
			if (GetEntProp(m_victim[me], Prop_Send, "m_bCarried") && GetEntPropEnt(m_victim[me], Prop_Send, "m_hBuilder") != -1)
			{
				// path to the engineer carrying the sentry
				GetEntPropVector(GetEntPropEnt(m_victim[me], Prop_Send, "m_hBuilder"), Prop_Data, "m_vecAbsOrigin", m_lastKnownVictimPosition[me]);
			}
		}
	}
	
	// Get to a third of the damage range before detonating
	float detonateRange = tf_bot_suicide_bomb_range.FloatValue / 3.0;
	if (IsDistanceBetweenLessThan(me, m_lastKnownVictimPosition[me], detonateRange) && GetEntProp(me, Prop_Send, "m_hGroundEntity") != -1)
	{
		float where[3];
		AddVectors(m_lastKnownVictimPosition[me], Vector(0.0, 0.0, sv_stepsize.FloatValue), where);
		if (IsLineOfFireClear(me, where))
		{
			StartDetonate(me, true);
		}
	}
	
	if (m_talkTimer[me].IsElapsed())
	{
		m_talkTimer[me].Start(4.0);
		EmitGameSoundToAll("MVM.SentryBusterIntro", me);
	}
	
	return true;
}

void CTFBotMissionSuicideBomber_OnKilled(int me)
{
	if (!m_bHasDetonated[me])
	{
		if (!m_detonateTimer[me].HasStarted())
		{
			StartDetonate(me);
		}
		else if (m_detonateTimer[me].IsElapsed())
		{
			Detonate(me);
		}
		else
		{
			// We're in detonate mode, and something's trying to kill us.  Prevent it.
			if (TF2_GetClientTeam(me) != TFTeam_Spectator)
			{
				SetEntProp(me, Prop_Data, "m_lifeState", LIFE_ALIVE);
				SetEntProp(me, Prop_Data, "m_iHealth", 1);
			}
		}
	}
}

static void StartDetonate(int me, bool bWasSuccessful = false, bool bWasKilled = false)
{
	if (m_detonateTimer[me].HasStarted())
		return;
	
	if (!IsPlayerAlive(me) || GetEntProp(me, Prop_Data, "m_iHealth") < 1)
	{
		if (TF2_GetClientTeam(me) != TFTeam_Spectator)
		{
			SetEntProp(me, Prop_Data, "m_lifeState", LIFE_ALIVE);
			SetEntProp(me, Prop_Data, "m_iHealth", 1);
		}
	}
	
	m_bWasSuccessful[me] = bWasSuccessful;
	m_bWasKilled[me] = bWasKilled;
	
	SetEntProp(me, Prop_Data, "m_takedamage", DAMAGE_NO);
	
	FakeClientCommand(me, "taunt");
	TF2_AddCondition(me, TFCond_FreezeInput);
	m_detonateTimer[me].Start(2.0);
	EmitGameSoundToAll("MvM.SentryBusterSpin", me);
}

static void Detonate(int me)
{
	// BLAST!
	m_bHasDetonated[me] = true;
	
	float origin[3], angles[3];
	GetClientAbsOrigin(me, origin);
	GetClientAbsAngles(me, angles);
	
	TE_TFParticleEffect("explosionTrail_seeds_mvm", .vecOrigin = origin, .vecAngles = angles);
	TE_TFParticleEffect("fluidSmokeExpl_ring_mvm", .vecOrigin = origin, .vecAngles = angles);
	
	EmitGameSoundToAll("MVM.SentryBusterExplode", me);
	
	UTIL_ScreenShake(origin, 25.0, 5.0, 5.0, 1000.0, SHAKE_START);
	
	if (!m_bWasSuccessful[me])
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
	if (m_bWasKilled[me])
	{
		Event event = CreateEvent("mvm_sentrybuster_killed");
		if (event)
		{
			event.SetInt("sentry_buster", me);
			FireEvent(event);
		}
	}
	
	// Clear my mission before we have everyone take damage so I will die with the rest
	Player(me).SetMission(NO_MISSION);
	SetEntProp(me, Prop_Data, "m_takedamage", DAMAGE_YES);
	
	// kill victims (including me)
	for (int i = 0; i < victimList.Length; ++i)
	{
		int victim = victimList.Get(i);
		
		float victimCenter[3], meCenter[3];
		CBaseEntity(victim).WorldSpaceCenter(victimCenter);
		CBaseEntity(me).WorldSpaceCenter(meCenter);
		
		float toVictim[3];
		SubtractVectors(victimCenter, meCenter, toVictim);
		
		if (GetVectorLength(toVictim) > tf_bot_suicide_bomb_range.FloatValue)
			continue;
		
		if (0 < victim <= MaxClients)
		{
			int colorHit[4] = { 255, 255, 255, 255 };
			UTIL_ScreenFade(victim, colorHit, 1.0, 0.1, FFADE_IN);
		}
		
		if (IsLineOfFireClear3(me, victim))
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
			SDKHooks_TakeDamage(victim, me, me, flDamage, DMG_BLAST, .damageForce = vecForce, .damagePosition = meCenter, .bypassHooks = false);
			
			g_bForceFriendlyFire = false;
		}
	}
	
	// make sure we're removed (in case we detonated in our spawn area where we are invulnerable)
	ForcePlayerSuicide(me);
	if (IsPlayerAlive(me))
	{
		TF2_ChangeClientTeam(me, TFTeam_Spectator);
	}
	
	if (m_bWasKilled[me])
	{
		// increment num sentry killed this wave
		CWave wave = GetPopulationManager().GetCurrentWave();
		if (wave)
		{
			wave.m_nSentryBustersSpawned++;
		}
	}
}
