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

methodmap CTFBotMvMDeployBomb < NextBotAction
{
	public static void Init()
	{
		ActionFactory = new NextBotActionFactory("MvMDeployBomb");
		ActionFactory.BeginDataMapDesc()
			.DefineIntField("m_timer")
			.DefineVectorField("m_anchorPos")
		.EndDataMapDesc();
		ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
		ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
		ActionFactory.SetCallback(NextBotActionCallbackType_OnEnd, OnEnd);
		ActionFactory.SetEventCallback(EventResponderType_OnContact, OnContact);
	}
	
	property CountdownTimer m_timer
	{
		public get()
		{
			return this.GetData("m_timer");
		}
		public set(CountdownTimer timer)
		{
			this.SetData("m_timer", timer);
		}
	}
	
	public CTFBotMvMDeployBomb()
	{
		CTFBotMvMDeployBomb action = view_as<CTFBotMvMDeployBomb>(ActionFactory.Create());
		action.m_timer = new CountdownTimer();
		return action;
	}
}

static int OnStart(CTFBotMvMDeployBomb action, int actor, NextBotAction priorAction)
{
	CTFPlayer(actor).SetDeployingBombState(TF_BOMB_DEPLOYING_DELAY);
	action.m_timer.Start(tf_deploying_bomb_delay_time.FloatValue);
	
	// remember where we start deploying
	float vecAbsOrigin[3];
	GetClientAbsOrigin(actor, vecAbsOrigin);
	action.SetDataVector("m_anchorPos", vecAbsOrigin);
	TeleportEntity(actor, .velocity = ZERO_VECTOR);
	SetEntityFlags(actor, GetEntityFlags(actor) | FL_FROZEN);
	
	if (CTFPlayer(actor).IsMiniBoss())
	{
		TF2Attrib_SetByName(actor, "airblast vertical vulnerability multiplier", 0.0);
	}
	
	return action.Continue();
}

static int Update(CTFBotMvMDeployBomb action, int actor, float interval)
{
	int areaTrigger = -1;
	
	if (CTFPlayer(actor).GetDeployingBombState() != TF_BOMB_DEPLOYING_COMPLETE)
	{
		areaTrigger = CTFPlayer(actor).GetClosestCaptureZone();
		if (!IsValidEntity(areaTrigger))
		{
			return action.Done("No capture zone!");
		}
		
		float meOrigin[3];
		GetClientAbsOrigin(actor, meOrigin);
		
		// if we've been moved, give up and go back to normal behavior
		float anchorPos[3];
		action.GetDataVector("m_anchorPos", anchorPos);
		const float movedRange = 20.0;
		if (GetVectorDistance(anchorPos, meOrigin) > movedRange)
		{
			return action.Done("I've been pushed");
		}
		
		// slam facing towards bomb hole
		float areaCenter[3], actorCenter[3];
		CBaseEntity(areaTrigger).WorldSpaceCenter(areaCenter);
		CBaseEntity(actor).WorldSpaceCenter(actorCenter);
		
		float to[3];
		SubtractVectors(areaCenter, actorCenter, to);
		NormalizeVector(to, to);
		
		float desiredAngles[3];
		GetVectorAngles(to, desiredAngles);
		
		TeleportEntity(actor, .angles = desiredAngles);
	}
	
	switch (CTFPlayer(actor).GetDeployingBombState())
	{
		case TF_BOMB_DEPLOYING_DELAY:
		{
			if (action.m_timer.IsElapsed())
			{
				SetVariantInt(1);
				AcceptEntityInput(actor, "SetForcedTauntCam");
				
				SDKCall_CTFPlayer_PlaySpecificSequence(actor, "primary_deploybomb");
				action.m_timer.Start(tf_deploying_bomb_time.FloatValue);
				CTFPlayer(actor).SetDeployingBombState(TF_BOMB_DEPLOYING_ANIMATING);
				
				EmitGameSoundToAll(CTFPlayer(actor).IsMiniBoss() ? "MVM.DeployBombGiant" : "MVM.DeployBombSmall", actor);
				
				SDKCall_CTeamplayRoundBasedRules_PlayThrottledAlert(255, "Announcer.MVM_Bomb_Alert_Deploying", 5.0);
			}
		}
		case TF_BOMB_DEPLOYING_ANIMATING:
		{
			if (action.m_timer.IsElapsed())
			{
				if (IsValidEntity(areaTrigger))
				{
					SDKCall_CCaptureZone_Capture(areaTrigger, actor);
				}
				
				action.m_timer.Start(2.0);
				BroadcastSound(255, "Announcer.MVM_Robots_Planted");
				CTFPlayer(actor).SetDeployingBombState(TF_BOMB_DEPLOYING_COMPLETE);
				SetEntProp(actor, Prop_Data, "m_takedamage", DAMAGE_NO);
				SetEntProp(actor, Prop_Data, "m_fEffects", GetEntProp(actor, Prop_Data, "m_fEffects") | EF_NODRAW);
				TF2_RemoveAllWeapons(actor);
			}
		}
		case TF_BOMB_DEPLOYING_COMPLETE:
		{
			if (action.m_timer.IsElapsed())
			{
				CTFPlayer(actor).SetDeployingBombState(TF_BOMB_DEPLOYING_NONE);
				SetEntProp(actor, Prop_Data, "m_takedamage", DAMAGE_YES);
				SDKHooks_TakeDamage(actor, actor, actor, 99999.9, DMG_CRUSH);
				return action.Done("I've deployed successfully");
			}
		}
	}
	
	return action.Continue();
}

static void OnEnd(CTFBotMvMDeployBomb action, int actor, NextBotAction nextAction)
{
	if (CTFPlayer(actor).GetDeployingBombState() == TF_BOMB_DEPLOYING_ANIMATING)
	{
		// reset the in-progress deploy animation
		SDKCall_CTFPlayer_DoAnimationEvent(actor, PLAYERANIMEVENT_SPAWN);
	}
	
	if (CTFPlayer(actor).IsMiniBoss())
	{
		TF2Attrib_RemoveByName(actor, "airblast vertical vulnerability multiplier");
	}
	
	CTFPlayer(actor).SetDeployingBombState(TF_BOMB_DEPLOYING_NONE);
	
	SetVariantInt(0);
	AcceptEntityInput(actor, "SetForcedTauntCam");
	SetEntityFlags(actor, GetEntityFlags(actor) & ~FL_FROZEN);
	
	delete action.m_timer;
}

static int OnContact(CTFBotMvMDeployBomb action, int actor, int other, Address result)
{
	// so event doesn't fall thru to buried action which will then redo transition to this state as we stay in contact with the zone
	return action.TryToSustain(RESULT_CRITICAL);
}
