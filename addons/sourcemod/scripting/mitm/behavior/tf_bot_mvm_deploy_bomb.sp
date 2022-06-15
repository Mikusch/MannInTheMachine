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

#pragma semicolon 1
#pragma newdecls required

static float m_anchorPos[MAXPLAYERS + 1][3];
static CountdownTimer m_timer[MAXPLAYERS + 1];
static BombDeployingState_t m_nDeployingBombState[MAXPLAYERS + 1];

void CTFBotMvMDeployBomb_OnStart(int me)
{
	m_nDeployingBombState[me] = TF_BOMB_DEPLOYING_DELAY;
	m_timer[me].Start(tf_deploying_bomb_delay_time.FloatValue);
	
	// remember where we start deploying
	GetClientAbsOrigin(me, m_anchorPos[me]);
	TF2_AddCondition(me, TFCond_FreezeInput);
	SetEntPropVector(me, Prop_Data, "m_vecAbsVelocity", ZERO_VECTOR);
	
	if (GetEntProp(me, Prop_Send, "m_bIsMiniBoss"))
	{
		TF2Attrib_SetByName(me, "airblast vertical vulnerability multiplier", 0.0);
	}
}

bool CTFBotMvMDeployBomb_Update(int me)
{
	int areaTrigger = -1;
	
	if (m_nDeployingBombState[me] != TF_BOMB_DEPLOYING_COMPLETE)
	{
		areaTrigger = Player(me).GetClosestCaptureZone();
		if (areaTrigger == -1)
		{
			return false;
		}
		
		float meOrigin[3];
		GetClientAbsOrigin(me, meOrigin);
		
		// if we've been moved, give up and go back to normal behavior
		const float movedRange = 20.0;
		if (GetVectorDistance(m_anchorPos[me], meOrigin) > movedRange)
		{
			return false;
		}
		
		// slam facing towards bomb hole
		float areaCenter[3], meCenter[3];
		CBaseEntity(areaTrigger).WorldSpaceCenter(areaCenter);
		CBaseEntity(me).WorldSpaceCenter(meCenter);
		
		float to[3];
		SubtractVectors(areaCenter, meCenter, to);
		NormalizeVector(to, to);
		
		float desiredAngles[3];
		GetVectorAngles(to, desiredAngles);
		
		TeleportEntity(me, .angles = desiredAngles);
	}
	
	switch (m_nDeployingBombState[me])
	{
		case TF_BOMB_DEPLOYING_DELAY:
		{
			if (m_timer[me].IsElapsed())
			{
				SetVariantInt(1);
				AcceptEntityInput(me, "SetForcedTauntCam");
				
				SDKCall_PlaySpecificSequence(me, "primary_deploybomb");
				m_timer[me].Start(tf_deploying_bomb_time.FloatValue);
				m_nDeployingBombState[me] = TF_BOMB_DEPLOYING_ANIMATING;
				
				EmitGameSoundToAll(GetEntProp(me, Prop_Send, "m_bIsMiniBoss") ? "MVM.DeployBombGiant" : "MVM.DeployBombSmall", me);
				
				SDKCall_PlayThrottledAlert(255, "Announcer.MVM_Bomb_Alert_Deploying", 5.0);
			}
		}
		case TF_BOMB_DEPLOYING_ANIMATING:
		{
			if (m_timer[me].IsElapsed())
			{
				if (areaTrigger != -1)
				{
					SDKCall_Capture(areaTrigger, me);
				}
				
				m_timer[me].Start(2.0);
				TFGameRules_BroadcastSound(255, "Announcer.MVM_Robots_Planted");
				m_nDeployingBombState[me] = TF_BOMB_DEPLOYING_COMPLETE;
				SetEntProp(me, Prop_Data, "m_takedamage", DAMAGE_NO);
				SetEntProp(me, Prop_Data, "m_fEffects", GetEntProp(me, Prop_Data, "m_fEffects") | EF_NODRAW);
				TF2_RemoveAllWeapons(me);
			}
		}
		case TF_BOMB_DEPLOYING_COMPLETE:
		{
			if (m_timer[me].IsElapsed())
			{
				m_nDeployingBombState[me] = TF_BOMB_DEPLOYING_NONE;
				SetEntProp(me, Prop_Data, "m_takedamage", DAMAGE_YES);
				SDKHooks_TakeDamage(me, me, me, 99999.9, DMG_CRUSH);
				return false;
			}
		}
	}
	
	return true;
}

void CTFBotMvMDeployBomb_OnEnd(int me)
{
	SetVariantInt(0);
	AcceptEntityInput(me, "SetForcedTauntCam");
	
	TF2_RemoveCondition(me, TFCond_FreezeInput);
	
	if (m_nDeployingBombState[me] == TF_BOMB_DEPLOYING_ANIMATING)
	{
		SDKCall_DoAnimationEvent(me, PLAYERANIMEVENT_SPAWN);
	}
	
	if (GetEntProp(me, Prop_Send, "m_bIsMiniBoss"))
	{
		TF2Attrib_RemoveByName(me, "airblast vertical vulnerability multiplier");
	}
	
	m_nDeployingBombState[me] = TF_BOMB_DEPLOYING_NONE;
}

bool IsDeployingBomb(int client)
{
	return m_nDeployingBombState[client] != TF_BOMB_DEPLOYING_NONE;
}
