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

methodmap CTFBotMvMEngineerTeleportSpawn < NextBotAction
{
	public static void Init()
	{
		ActionFactory = new NextBotActionFactory("MvMEngineerTeleportSpawn");
		ActionFactory.BeginDataMapDesc()
			.DefineIntField("m_teleportDelay")
			.DefineEntityField("m_hintEntity")
			.DefineBoolField("m_bFirstTeleportSpawn")
		.EndDataMapDesc();
		ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
		ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
		ActionFactory.SetCallback(NextBotActionCallbackType_OnEnd, OnEnd);
	}
	
	public CTFBotMvMEngineerTeleportSpawn(int hint, bool bFirstTeleportSpawn)
	{
		CTFBotMvMEngineerTeleportSpawn action = view_as<CTFBotMvMEngineerTeleportSpawn>(ActionFactory.Create());
		action.m_teleportDelay = new CountdownTimer();
		action.m_hintEntity = hint;
		action.m_bFirstTeleportSpawn = bFirstTeleportSpawn;
		return action;
	}
	
	property CountdownTimer m_teleportDelay
	{
		public get()
		{
			return this.GetData("m_teleportDelay");
		}
		public set(CountdownTimer teleportDelay)
		{
			this.SetData("m_teleportDelay", teleportDelay);
		}
	}
	
	property int m_hintEntity
	{
		public get()
		{
			return this.GetDataEnt("m_hintEntity");
		}
		public set(int hintEntity)
		{
			this.SetDataEnt("m_hintEntity", hintEntity);
		}
	}
	
	property bool m_bFirstTeleportSpawn
	{
		public get()
		{
			return this.GetData("m_bFirstTeleportSpawn");
		}
		public set(bool bFirstTeleportSpawn)
		{
			this.SetData("m_bFirstTeleportSpawn", bFirstTeleportSpawn);
		}
	}
}

static int OnStart(CTFBotMvMEngineerTeleportSpawn action, int actor, NextBotAction priorAction)
{
	if (!Player(actor).HasAttribute(TELEPORT_TO_HINT))
	{
		return action.Done("Cannot teleport to hint with out Attributes TeleportToHint");
	}
	
	return action.Continue();
}

static int Update(CTFBotMvMEngineerTeleportSpawn action, int actor, float interval)
{
	if (!action.m_teleportDelay.HasStarted())
	{
		float origin[3];
		GetEntPropVector(action.m_hintEntity, Prop_Data, "m_vecAbsOrigin", origin);
		
		action.m_teleportDelay.Start(0.1);
		if (IsValidEntity(action.m_hintEntity))
			SDKCall_PushAllPlayersAway(origin, 400.0, 500.0, TFTeam_Defenders);
	}
	else if (action.m_teleportDelay.IsElapsed())
	{
		if (!IsValidEntity(action.m_hintEntity))
			return action.Done("Cannot teleport to hint as m_hintEntity is NULL");
		
		// teleport the engineer to the sentry spawn point
		float angles[3], origin[3];
		GetEntPropVector(action.m_hintEntity, Prop_Data, "m_angAbsRotation", angles);
		GetEntPropVector(action.m_hintEntity, Prop_Data, "m_vecAbsOrigin", origin);
		origin[2] += 10.0; // move up off the around a little bit to prevent the engineer from getting stuck in the ground
		
		TeleportEntity(actor, origin, angles);
		
		TE_TFParticleEffect("teleported_blue", origin);
		TE_TFParticleEffect("player_sparkles_blue", origin);
		
		if (action.m_bFirstTeleportSpawn)
		{
			// notify players that engineer's teleported into the map
			TE_TFParticleEffect("teleported_mvm_bot", origin);
			EmitGameSoundToAll("Engineer.MVM_BattleCry07", actor);
			EmitGameSoundToAll("MVM.Robot_Engineer_Spawn", action.m_hintEntity);
			
			if (g_pPopulationManager.IsValid())
			{
				CWave pWave = g_pPopulationManager.GetCurrentWave();
				if (pWave)
				{
					if (pWave.m_nNumEngineersTeleportSpawned == 0)
					{
						BroadcastSound(255, "Announcer.MVM_First_Engineer_Teleport_Spawned");
					}
					else
					{
						BroadcastSound(255, "Announcer.MVM_Another_Engineer_Teleport_Spawned");
					}
					
					pWave.m_nNumEngineersTeleportSpawned++;
				}
			}
		}
		
		return action.Done("Teleported");
	}
	
	return action.Continue();
}

static void OnEnd(CTFBotMvMEngineerTeleportSpawn action, int actor, NextBotAction nextAction)
{
	delete action.m_teleportDelay;
}
