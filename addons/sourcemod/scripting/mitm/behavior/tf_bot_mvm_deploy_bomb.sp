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

static float m_anchorPos[MAXPLAYERS + 1][3];
static CountdownTimer m_timer[MAXPLAYERS + 1];
static BombDeployingState_t m_nDeployingBombState[MAXPLAYERS + 1];

void CTFBotMvMDeployBomb_Init()
{
	ActionFactory = new NextBotActionFactory("MvMDeployBomb");
	ActionFactory.BeginDataMapDesc()
	// TODO
	.EndDataMapDesc();
	ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, CTFBotMvMDeployBomb_OnStart);
	ActionFactory.SetCallback(NextBotActionCallbackType_Update, CTFBotMvMDeployBomb_Update);
	ActionFactory.SetCallback(NextBotActionCallbackType_OnEnd, CTFBotMvMDeployBomb_OnEnd);
	ActionFactory.SetEventCallback(EventResponderType_OnContact, CTFBotMvMDeployBomb_OnContact);
}

NextBotAction CTFBotMvMDeployBomb_Create()
{
	return ActionFactory.Create();
}

static int CTFBotMvMDeployBomb_OnStart(NextBotAction action, int actor, NextBotAction priorAction)
{
	m_nDeployingBombState[actor] = TF_BOMB_DEPLOYING_DELAY;
	m_timer[actor].Start(tf_deploying_bomb_delay_time.FloatValue);
	
	// remember where we start deploying
	GetClientAbsOrigin(actor, m_anchorPos[actor]);
	TF2_AddCondition(actor, TFCond_FreezeInput);
	SetEntPropVector(actor, Prop_Data, "m_vecAbsVelocity", ZERO_VECTOR);
	
	if (GetEntProp(actor, Prop_Send, "m_bIsMiniBoss"))
	{
		TF2Attrib_SetByName(actor, "airblast vertical vulnerability multiplier", 0.0);
	}
	
	return action.Continue();
}

static int CTFBotMvMDeployBomb_Update(NextBotAction action, int actor, float interval)
{
	int areaTrigger = -1;
	
	if (m_nDeployingBombState[actor] != TF_BOMB_DEPLOYING_COMPLETE)
	{
		areaTrigger = Player(actor).GetClosestCaptureZone();
		if (!IsValidEntity(areaTrigger))
		{
			return action.Done("No capture zone!");
		}
		
		float meOrigin[3];
		GetClientAbsOrigin(actor, meOrigin);
		
		// if we've been moved, give up and go back to normal behavior
		const float movedRange = 20.0;
		if (GetVectorDistance(m_anchorPos[actor], meOrigin) > movedRange)
		{
			return action.Done("I've been pushed");
		}
		
		// slam facing towards bomb hole
		float areaCenter[3], meCenter[3];
		CBaseEntity(areaTrigger).WorldSpaceCenter(areaCenter);
		CBaseEntity(actor).WorldSpaceCenter(meCenter);
		
		float to[3];
		SubtractVectors(areaCenter, meCenter, to);
		NormalizeVector(to, to);
		
		float desiredAngles[3];
		GetVectorAngles(to, desiredAngles);
		
		TeleportEntity(actor, .angles = desiredAngles);
	}
	
	switch (m_nDeployingBombState[actor])
	{
		case TF_BOMB_DEPLOYING_DELAY:
		{
			if (m_timer[actor].IsElapsed())
			{
				SetVariantInt(1);
				AcceptEntityInput(actor, "SetForcedTauntCam");
				
				SDKCall_PlaySpecificSequence(actor, "primary_deploybomb");
				m_timer[actor].Start(tf_deploying_bomb_time.FloatValue);
				m_nDeployingBombState[actor] = TF_BOMB_DEPLOYING_ANIMATING;
				
				EmitGameSoundToAll(GetEntProp(actor, Prop_Send, "m_bIsMiniBoss") ? "MVM.DeployBombGiant" : "MVM.DeployBombSmall", actor);
				
				SDKCall_PlayThrottledAlert(255, "Announcer.MVM_Bomb_Alert_Deploying", 5.0);
			}
		}
		case TF_BOMB_DEPLOYING_ANIMATING:
		{
			if (m_timer[actor].IsElapsed())
			{
				if (IsValidEntity(areaTrigger))
				{
					SDKCall_Capture(areaTrigger, actor);
				}
				
				m_timer[actor].Start(2.0);
				TFGameRules_BroadcastSound(255, "Announcer.MVM_Robots_Planted");
				m_nDeployingBombState[actor] = TF_BOMB_DEPLOYING_COMPLETE;
				SetEntProp(actor, Prop_Data, "m_takedamage", DAMAGE_NO);
				SetEntProp(actor, Prop_Data, "m_fEffects", GetEntProp(actor, Prop_Data, "m_fEffects") | EF_NODRAW);
				TF2_RemoveAllWeapons(actor);
			}
		}
		case TF_BOMB_DEPLOYING_COMPLETE:
		{
			if (m_timer[actor].IsElapsed())
			{
				m_nDeployingBombState[actor] = TF_BOMB_DEPLOYING_NONE;
				SetEntProp(actor, Prop_Data, "m_takedamage", DAMAGE_YES);
				SDKHooks_TakeDamage(actor, actor, actor, 99999.9, DMG_CRUSH);
				return action.Done("I've deployed successfully");
			}
		}
	}
	
	return action.Continue();
}

static void CTFBotMvMDeployBomb_OnEnd(NextBotAction action, int actor, NextBotAction nextAction)
{
	if (m_nDeployingBombState[actor] == TF_BOMB_DEPLOYING_ANIMATING)
	{
		SDKCall_DoAnimationEvent(actor, PLAYERANIMEVENT_SPAWN);
	}
	
	if (GetEntProp(actor, Prop_Send, "m_bIsMiniBoss"))
	{
		TF2Attrib_RemoveByName(actor, "airblast vertical vulnerability multiplier");
	}
	
	m_nDeployingBombState[actor] = TF_BOMB_DEPLOYING_NONE;
	
	SetVariantInt(0);
	AcceptEntityInput(actor, "SetForcedTauntCam");
	TF2_RemoveCondition(actor, TFCond_FreezeInput);
}

static int CTFBotMvMDeployBomb_OnContact(NextBotAction action, int actor, int other, Address result)
{
	// so event doesn't fall thru to buried action which will then redo transition to this state as we stay in contact with the zone
	return action.TryToSustain(RESULT_CRITICAL);
}

bool IsDeployingBomb(int client)
{
	return m_nDeployingBombState[client] != TF_BOMB_DEPLOYING_NONE;
}
