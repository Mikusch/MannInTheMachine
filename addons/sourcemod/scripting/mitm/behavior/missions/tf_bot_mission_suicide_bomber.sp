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

methodmap CTFBotMissionSuicideBomber < NextBotAction
{
	public static void Init()
	{
		ActionFactory = new NextBotActionFactory("MissionSuicideBomber");
		ActionFactory.BeginDataMapDesc()
			.DefineIntField("m_detonateTimer")
			.DefineIntField("m_talkTimer")
			.DefineIntField("m_annotationTimer")
			.DefineEntityField("m_victim")
			.DefineVectorField("m_lastKnownVictimPosition")
			.DefineBoolField("m_bHasDetonated")
			.DefineBoolField("m_bWasSuccessful")
			.DefineBoolField("m_bWasKilled")
			.DefineVectorField("m_vecDetLocation")
		.EndDataMapDesc();
		ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
		ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
		ActionFactory.SetCallback(NextBotActionCallbackType_OnEnd, OnEnd);
		ActionFactory.SetEventCallback(EventResponderType_OnKilled, OnKilled);
	}
	
	public CTFBotMissionSuicideBomber()
	{
		CTFBotMissionSuicideBomber action = view_as<CTFBotMissionSuicideBomber>(ActionFactory.Create());
		action.m_detonateTimer = new CountdownTimer();
		action.m_talkTimer = new CountdownTimer();
		action.m_annotationTimer = new CountdownTimer();
		return action;
	}
	
	property CountdownTimer m_detonateTimer
	{
		public get()
		{
			return this.GetData("m_detonateTimer");
		}
		public set(CountdownTimer detonateTimer)
		{
			this.SetData("m_detonateTimer", detonateTimer);
		}
	}
	
	property CountdownTimer m_talkTimer
	{
		public get()
		{
			return this.GetData("m_talkTimer");
		}
		public set(CountdownTimer talkTimer)
		{
			this.SetData("m_talkTimer", talkTimer);
		}
	}
	
	property CountdownTimer m_annotationTimer
	{
		public get()
		{
			return this.GetData("m_detonateTimer");
		}
		public set(CountdownTimer detonateTimer)
		{
			this.SetData("m_detonateTimer", detonateTimer);
		}
	}
	
	property int m_victim
	{
		public get()
		{
			return this.GetDataEnt("m_victim");
		}
		public set(int victim)
		{
			this.SetDataEnt("m_victim", victim);
		}
	}
	
	property bool m_bHasDetonated
	{
		public get()
		{
			return this.GetData("m_bHasDetonated");
		}
		public set(bool bHasDetonated)
		{
			this.SetData("m_bHasDetonated", bHasDetonated);
		}
	}
	
	property bool m_bWasSuccessful
	{
		public get()
		{
			return this.GetData("m_bWasSuccessful");
		}
		public set(bool bWasSuccessful)
		{
			this.SetData("m_bWasSuccessful", bWasSuccessful);
		}
	}
	
	property bool m_bWasKilled
	{
		public get()
		{
			return this.GetData("m_bWasKilled");
		}
		public set(bool bWasKilled)
		{
			this.SetData("m_bWasKilled", bWasKilled);
		}
	}
}

static int OnStart(CTFBotMissionSuicideBomber action, int actor, NextBotAction priorAction)
{
	action.m_detonateTimer.Invalidate();
	action.m_annotationTimer.Invalidate();
	action.m_bHasDetonated = false;
	action.m_bWasSuccessful = false;
	action.m_bWasKilled = false;
	
	action.m_victim = Player(actor).GetMissionTarget();
	
	if (IsValidEntity(action.m_victim))
	{
		float vecAbsOrigin[3];
		GetEntPropVector(action.m_victim, Prop_Data, "m_vecAbsOrigin", vecAbsOrigin);
		action.SetDataVector("m_lastKnownVictimPosition", vecAbsOrigin);
		action.m_annotationTimer.Start(0.1);
	}
	
	return action.Continue();
}

static int Update(CTFBotMissionSuicideBomber action, int actor, float interval)
{
	if (action.m_annotationTimer.HasStarted() && action.m_annotationTimer.IsElapsed())
	{
		if (IsValidEntity(action.m_victim))
		{
			char text[64];
			Format(text, sizeof(text), "%T", "Invader_DestroySentries_DetonateSentry", actor);
			ShowAnnotation(actor, MITM_HINT_MASK | actor, text, action.m_victim, _, mitm_annotation_lifetime.FloatValue, "coach/coach_attack_here.wav");
			action.m_annotationTimer.Invalidate();
		}
	}
	
	// one we start detonating, there's no turning back
	if (action.m_detonateTimer.HasStarted())
	{
		if (action.m_detonateTimer.IsElapsed())
		{
			float vecAbsOrigin[3];
			GetClientAbsOrigin(actor, vecAbsOrigin);
			action.SetDataVector("m_vecDetLocation", vecAbsOrigin);
			Detonate(action, actor);
			
			// Send out an event
			if (action.m_bWasSuccessful && IsValidEntity(action.m_victim) && IsBaseObject(action.m_victim))
			{
				int owner = GetEntPropEnt(action.m_victim, Prop_Send, "m_hBuilder");
				if (owner != -1)
				{
					Event event = CreateEvent("mvm_sentrybuster_detonate");
					if (event)
					{
						float vecDetLocation[3];
						action.GetDataVector("m_vecDetLocation", vecDetLocation);
						
						event.SetInt("player", owner);
						event.SetFloat("det_x", vecDetLocation[0]);
						event.SetFloat("det_y", vecDetLocation[1]);
						event.SetFloat("det_z", vecDetLocation[2]);
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
		StartDetonate(action, actor, false, true);
		
		return action.Continue();
	}
	
	if (IsValidEntity(action.m_victim))
	{
		// update chase destination
		if (GetEntProp(action.m_victim, Prop_Data, "m_lifeState") == LIFE_ALIVE && !(GetEntProp(action.m_victim, Prop_Data, "m_fEffects") & EF_NODRAW))
		{
			float vecAbsOrigin[3];
			GetEntPropVector(action.m_victim, Prop_Data, "m_vecAbsOrigin", vecAbsOrigin);
			action.SetDataVector("m_lastKnownVictimPosition", vecAbsOrigin);
		}
		
		// if the engineer is carrying his sentry, he becomes the victim
		if (IsBaseObject(action.m_victim))
		{
			if (GetEntProp(action.m_victim, Prop_Send, "m_bCarried") && GetEntPropEnt(action.m_victim, Prop_Send, "m_hBuilder") != -1)
			{
				// path to the engineer carrying the sentry
				float vecAbsOrigin[3];
				GetEntPropVector(GetEntPropEnt(action.m_victim, Prop_Send, "m_hBuilder"), Prop_Data, "m_vecAbsOrigin", vecAbsOrigin);
				action.SetDataVector("m_lastKnownVictimPosition", vecAbsOrigin);
			}
		}
	}
	
	// Get to a third of the damage range before detonating
	float lastKnownVictimPosition[3];
	action.GetDataVector("m_lastKnownVictimPosition", lastKnownVictimPosition);
	float detonateRange = tf_bot_suicide_bomb_range.FloatValue / 3.0;
	if (IsDistanceBetweenLessThan(actor, lastKnownVictimPosition, detonateRange))
	{
		float where[3];
		AddVectors(lastKnownVictimPosition, Vector(0.0, 0.0, sv_stepsize.FloatValue), where);
		if (IsLineOfFireClearGivenPlayerAndPoint(actor, where))
		{
			StartDetonate(action, actor, true);
		}
	}
	
	if (action.m_talkTimer.IsElapsed())
	{
		action.m_talkTimer.Start(4.0);
		EmitGameSoundToAll("MVM.SentryBusterIntro", actor);
	}
	
	return action.Continue();
}

static void OnEnd(CTFBotMissionSuicideBomber action, int actor, NextBotAction nextAction)
{
	HideAnnotation(actor, MITM_HINT_MASK | actor);
	
	delete action.m_detonateTimer;
	delete action.m_talkTimer;
	delete action.m_annotationTimer;
}

static int OnKilled(CTFBotMissionSuicideBomber action, int actor, int attacker, int inflictor, float damage, int damagetype)
{
	if (!action.m_bHasDetonated)
	{
		if (!action.m_detonateTimer.HasStarted())
		{
			StartDetonate(action, actor);
		}
		else if (action.m_detonateTimer.IsElapsed())
		{
			Detonate(action, actor);
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

static void StartDetonate(CTFBotMissionSuicideBomber action, int actor, bool bWasSuccessful = false, bool bWasKilled = false)
{
	if (action.m_detonateTimer.HasStarted())
		return;
	
	if (!IsPlayerAlive(actor) || GetEntProp(actor, Prop_Data, "m_iHealth") < 1)
	{
		if (TF2_GetClientTeam(actor) != TFTeam_Spectator)
		{
			SetEntProp(actor, Prop_Data, "m_lifeState", LIFE_ALIVE);
			SetEntProp(actor, Prop_Data, "m_iHealth", 1);
		}
	}
	
	action.m_bWasSuccessful = bWasSuccessful;
	action.m_bWasKilled = bWasKilled;
	
	SetEntProp(actor, Prop_Data, "m_takedamage", DAMAGE_NO);
	
	FakeClientCommand(actor, "taunt");
	TF2_AddCondition(actor, TFCond_FreezeInput);
	action.m_detonateTimer.Start(2.0);
	EmitGameSoundToAll("MvM.SentryBusterSpin", actor);
}

static void Detonate(CTFBotMissionSuicideBomber action, int actor)
{
	// BLAST!
	action.m_bHasDetonated = true;
	
	float origin[3], angles[3];
	GetClientAbsOrigin(actor, origin);
	GetClientAbsAngles(actor, angles);
	
	TE_TFParticleEffect("explosionTrail_seeds_mvm", .vecOrigin = origin, .vecAngles = angles);
	TE_TFParticleEffect("fluidSmokeExpl_ring_mvm", .vecOrigin = origin, .vecAngles = angles);
	
	EmitGameSoundToAll("MVM.SentryBusterExplode", actor);
	
	UTIL_ScreenShake(origin, 25.0, 5.0, 5.0, 1000.0, SHAKE_START);
	
	if (!action.m_bWasSuccessful)
	{
		if (IsMannVsMachineMode())
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
	int obj = -1;
	while ((obj = FindEntityByClassname(obj, "obj_*")) != -1)
	{
		if (view_as<TFTeam>(GetEntProp(obj, Prop_Data, "m_iTeamNum")) <= TFTeam_Spectator)
			continue;
		
		victimList.Push(obj);
	}
	
	// Send out an event whenever players damaged us to the point where we had to detonate
	if (action.m_bWasKilled)
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
	
	// kill victims (including me)
	for (int i = 0; i < victimList.Length; ++i)
	{
		int victim = victimList.Get(i);
		
		float victimCenter[3], actorCenter[3];
		CBaseEntity(victim).WorldSpaceCenter(victimCenter);
		CBaseEntity(actor).WorldSpaceCenter(actorCenter);
		
		float toVictim[3];
		SubtractVectors(victimCenter, actorCenter, toVictim);
		
		if (GetVectorLength(toVictim) > tf_bot_suicide_bomb_range.FloatValue)
			continue;
		
		if (IsEntityClient(victim))
		{
			int colorHit[4] = { 255, 255, 255, 255 };
			UTIL_ScreenFade(victim, colorHit, 1.0, 0.1, FFADE_IN);
		}
		
		if (IsLineOfFireClearGivenPlayerAndEntity(actor, victim))
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
			SDKHooks_TakeDamage(victim, actor, actor, flDamage, DMG_BLAST, .damageForce = vecForce, .damagePosition = actorCenter, .bypassHooks = false);
			
			g_bForceFriendlyFire = false;
		}
	}
	
	delete victimList;
	
	// make sure we're removed (in case we detonated in our spawn area where we are invulnerable)
	ForcePlayerSuicide(actor);
	if (IsPlayerAlive(actor))
	{
		TF2_ChangeClientTeam(actor, TFTeam_Spectator);
	}
	
	if (action.m_bWasKilled)
	{
		// increment num sentry killed this wave
		CWave wave = g_pPopulationManager.IsValid() ? g_pPopulationManager.GetCurrentWave() : view_as<CWave>(Address_Null);
		if (wave)
		{
			wave.m_nSentryBustersSpawned++;
		}
	}
}
