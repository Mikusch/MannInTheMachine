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

enum struct MvMBombDeploy
{
	int player;
	CountdownTimer m_timer;
	float m_anchorPos[3];
	
	void Start()
	{
		this.Reset();
		
		Player(this.player).m_nDeployingBombState = TF_BOMB_DEPLOYING_DELAY;
		this.m_timer.Start(tf_deploying_bomb_delay_time.FloatValue);
		
		// remember where we start deploying
		GetClientAbsOrigin(this.player, this.m_anchorPos);
		TF2_AddCondition(this.player, TFCond_FreezeInput);
		SetEntPropVector(this.player, Prop_Data, "m_vecAbsVelocity", ZERO_VECTOR);
		
		if (GetEntProp(this.player, Prop_Send, "m_bIsMiniBoss"))
		{
			TF2Attrib_SetByName(this.player, "airblast vertical vulnerability multiplier", 0.0);
		}
	}
	
	void Update()
	{
		int areaTrigger = -1;
		
		if (Player(this.player).m_nDeployingBombState != TF_BOMB_DEPLOYING_COMPLETE)
		{
			areaTrigger = GetClosestCaptureZone(this.player);
			if (areaTrigger == -1)
			{
				this.End();
				return;
			}
			
			const float movedRange = 20.0;
			
			float meOrigin[3];
			GetClientAbsOrigin(this.player, meOrigin);
			
			if (GetVectorDistance(this.m_anchorPos, meOrigin) > movedRange)
			{
				this.End();
				return;
			}
			
			// slam facing towards bomb hole
			float areaCenter[3], meCenter[3];
			CBaseEntity(areaTrigger).WorldSpaceCenter(areaCenter);
			CBaseEntity(this.player).WorldSpaceCenter(meCenter);
			
			float to[3];
			SubtractVectors(areaCenter, meCenter, to);
			NormalizeVector(to, to);
			
			float desiredAngles[3];
			GetVectorAngles(to, desiredAngles);
			
			TeleportEntity(this.player, .angles = desiredAngles);
		}
		
		switch (Player(this.player).m_nDeployingBombState)
		{
			case TF_BOMB_DEPLOYING_DELAY:
			{
				if (this.m_timer.IsElapsed())
				{
					SetVariantInt(1);
					AcceptEntityInput(this.player, "SetForcedTauntCam");
					
					SDKCall_PlaySpecificSequence(this.player, "primary_deploybomb");
					this.m_timer.Start(tf_deploying_bomb_time.FloatValue);
					Player(this.player).m_nDeployingBombState = TF_BOMB_DEPLOYING_ANIMATING;
					
					EmitGameSoundToAll(GetEntProp(this.player, Prop_Send, "m_bIsMiniBoss") ? "MVM.DeployBombGiant" : "MVM.DeployBombSmall", this.player);
				}
			}
			case TF_BOMB_DEPLOYING_ANIMATING:
			{
				if (this.m_timer.IsElapsed())
				{
					if (areaTrigger != -1)
					{
						SDKCall_Capture(areaTrigger, this.player);
					}
					
					this.m_timer.Start(2.0);
					EmitGameSoundToAll("Announcer.MVM_Robots_Planted");
					Player(this.player).m_nDeployingBombState = TF_BOMB_DEPLOYING_COMPLETE;
					SetEntProp(this.player, Prop_Data, "m_takedamage", DAMAGE_NO);
					SetEntProp(this.player, Prop_Data, "m_fEffects", GetEntProp(this.player, Prop_Data, "m_fEffects") | EF_NODRAW);
					TF2_RemoveAllWeapons(this.player);
				}
			}
			case TF_BOMB_DEPLOYING_COMPLETE:
			{
				if (this.m_timer.IsElapsed())
				{
					Player(this.player).m_nDeployingBombState = TF_BOMB_DEPLOYING_NONE;
					SetEntProp(this.player, Prop_Data, "m_takedamage", DAMAGE_YES);
					SDKHooks_TakeDamage(this.player, this.player, this.player, 99999.9, DMG_CRUSH);
					this.End();
					return;
				}
			}
		}
	}
	
	void End()
	{
		SetVariantInt(0);
		AcceptEntityInput(this.player, "SetForcedTauntCam");
		
		TF2_RemoveCondition(this.player, TFCond_FreezeInput);
		
		if (Player(this.player).m_nDeployingBombState == TF_BOMB_DEPLOYING_ANIMATING)
		{
			SDKCall_DoAnimationEvent(this.player, PLAYERANIMEVENT_SPAWN);
		}
		
		if (GetEntProp(this.player, Prop_Send, "m_bIsMiniBoss"))
		{
			TF2Attrib_RemoveByName(this.player, "airblast vertical vulnerability multiplier");
		}
		
		Player(this.player).m_nDeployingBombState = TF_BOMB_DEPLOYING_NONE;
	}
	
	void Reset()
	{
		this.m_timer.Invalidate();
		this.m_anchorPos = NULL_VECTOR;
	}
}

int GetClosestCaptureZone(int player)
{
	int captureZone = -1;
	float flClosestDistance = float(cellmax);
	
	int tempCaptureZone = MaxClients + 1;
	while ((tempCaptureZone = FindEntityByClassname(tempCaptureZone, "func_capturezone")) != -1)
	{
		if (!GetEntProp(tempCaptureZone, Prop_Data, "m_bDisabled") && GetEntProp(tempCaptureZone, Prop_Data, "m_iTeamNum") == GetClientTeam(player))
		{
			float origin[3], center[3];
			GetClientAbsOrigin(player, origin);
			CBaseEntity(tempCaptureZone).WorldSpaceCenter(center);
			
			float fCurrentDistance = GetVectorDistance(origin, center);
			if (flClosestDistance > fCurrentDistance)
			{
				captureZone = tempCaptureZone;
				flClosestDistance = fCurrentDistance;
			}
		}
	}
	
	return captureZone;
}
