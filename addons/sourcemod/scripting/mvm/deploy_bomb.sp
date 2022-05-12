enum struct MvMBombDeploy
{
	CountdownTimer m_timer;
	float m_anchorPos[3];
	
	void Start(int me)
	{
		Player(me).m_nDeployingBombState = TF_BOMB_DEPLOYING_DELAY;
		this.m_timer.Start(tf_deploying_bomb_delay_time.FloatValue);
		
		// remember where we start deploying
		GetClientAbsOrigin(me, this.m_anchorPos);
		
		SetEntPropVector(me, Prop_Data, "m_vecAbsVelocity", { 0.0, 0.0, 0.0 } );
		
		if (GetEntProp(me, Prop_Send, "m_bIsMiniBoss"))
		{
			TF2Attrib_SetByName(me, "airblast vertical vulnerability multiplier", 0.0);
		}
	}
	
	void Update(int me)
	{
		int areaTrigger = -1;
		
		if (Player(me).m_nDeployingBombState != TF_BOMB_DEPLOYING_COMPLETE)
		{
			areaTrigger = GetClosestCaptureZone(me);
			if (areaTrigger == -1)
			{
				this.End(me);
				return;
			}
			
			const float movedRange = 20.0;
			
			float meOrigin[3];
			GetClientAbsOrigin(me, meOrigin);
			
			if (GetVectorDistance(this.m_anchorPos, meOrigin) > movedRange)
			{
				this.End(me);
				return;
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
		
		switch (Player(me).m_nDeployingBombState)
		{
			case TF_BOMB_DEPLOYING_DELAY:
			{
				PrintToServer("TF_BOMB_DEPLOYING_DELAY");
				if (this.m_timer.IsElapsed())
				{
					this.m_timer.Start(tf_deploying_bomb_time.FloatValue);
					Player(me).m_nDeployingBombState = TF_BOMB_DEPLOYING_ANIMATING;
					
					EmitGameSoundToAll(GetEntProp(me, Prop_Send, "m_bIsMiniBoss") ? "MVM.DeployBombGiant" : "MVM.DeployBombSmall", me);
				}
			}
			case TF_BOMB_DEPLOYING_ANIMATING:
			{
				PrintToServer("TF_BOMB_DEPLOYING_ANIMATING %f", this.m_timer.GetRemainingTime());
				if (this.m_timer.IsElapsed())
				{
					if (areaTrigger != -1)
					{
						SDKCall_Capture(areaTrigger, me);
					}
					
					this.m_timer.Start(2.0);
					Player(me).m_nDeployingBombState = TF_BOMB_DEPLOYING_COMPLETE;
					SetEntProp(me, Prop_Data, "m_takedamage", DAMAGE_NO);
					SetEntProp(me, Prop_Data, "m_fEffects", GetEntProp(me, Prop_Data, "m_fEffects") | EF_NODRAW);
					TF2_RemoveAllWeapons(me);
				}
			}
			case TF_BOMB_DEPLOYING_COMPLETE:
			{
				PrintToServer("TF_BOMB_DEPLOYING_COMPLETE");
				if (this.m_timer.IsElapsed())
				{
					Player(me).m_nDeployingBombState = TF_BOMB_DEPLOYING_NONE;
					SetEntProp(me, Prop_Data, "m_takedamage", DAMAGE_YES);
					SDKHooks_TakeDamage(me, me, me, 99999.9, DMG_CRUSH);
					this.End(me);
					return;
				}
			}
		}
	}
	
	void End(int me)
	{
		Player(me).m_nDeployingBombState = TF_BOMB_DEPLOYING_NONE;
		PrintToServer("End");
		if (GetEntProp(me, Prop_Send, "m_bIsMiniBoss"))
		{
			TF2Attrib_RemoveByName(me, "airblast vertical vulnerability multiplier");
		}
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
