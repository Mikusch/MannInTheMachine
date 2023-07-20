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

methodmap CTFBotScenarioMonitor < NextBotAction
{
	public static void Init()
	{
		ActionFactory = new NextBotActionFactory("ScenarioMonitor");
		ActionFactory.SetCallback(NextBotActionCallbackType_InitialContainedAction, InitialContainedAction);
		ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
	}
	
	public CTFBotScenarioMonitor()
	{
		return view_as<CTFBotScenarioMonitor>(ActionFactory.Create());
	}
}

static NextBotAction InitialContainedAction(CTFBotScenarioMonitor action, int actor)
{
	if (CTFPlayer(actor).IsInASquad())
	{
		if (CTFPlayer(actor).GetSquad().IsLeader(actor))
		{
			// I'm the leader of this Squad, so I can do what I want and the other Squaddies will support actor
			return DesiredScenarioAndClassAction(actor);
		}
		
		// Medics are the exception - they always heal, and have special squad logic in their heal logic
		if (TF2_GetPlayerClass(actor) == TFClass_Medic)
		{
			return CTFBotMedicHeal();
		}
		
		// I'm in a Squad but not the leader, do "escort and support" Squad behavior
		// until the Squad disbands, and then do my normal thing
		return CTFBotEscortSquadLeader(DesiredScenarioAndClassAction(actor));
	}
	
	return DesiredScenarioAndClassAction(actor);
}

static int Update(CTFBotScenarioMonitor action, int actor, float interval)
{
	if (CTFPlayer(actor).HasTheFlag())
	{
		if (tf_bot_flag_kill_on_touch.BoolValue)
		{
			ForcePlayerSuicide(actor);
			return action.Done("Flag kill");
		}
		
		return action.SuspendFor(CTFBotDeliverFlag(), "I've picked up the flag! Running it in...");
	}
	
	return action.Continue();
}

static NextBotAction DesiredScenarioAndClassAction(int actor)
{
	switch (CTFPlayer(actor).GetMission())
	{
		case MISSION_DESTROY_SENTRIES:
			return CTFBotMissionSuicideBomber();
		
		case MISSION_SNIPER:
			return CTFBotSniperLurk();
	}
	
	if (IsMannVsMachineMode())
	{
		if (TF2_GetPlayerClass(actor) == TFClass_Spy)
		{
			return CTFBotSpyLeaveSpawnRoom();
		}
		
		if (TF2_GetPlayerClass(actor) == TFClass_Medic)
		{
			// if I'm being healed by another medic, I should do something else other than healing
			bool bIsBeingHealedByAMedic = false;
			int nNumHealers = GetEntProp(actor, Prop_Send, "m_nNumHealers");
			for (int i = 0; i < nNumHealers; ++i)
			{
				int healer = TF2Util_GetPlayerHealer(actor, i);
				if (IsEntityClient(healer))
				{
					bIsBeingHealedByAMedic = true;
					break;
				}
			}
			
			if (!bIsBeingHealedByAMedic)
			{
				return CTFBotMedicHeal();
			}
		}
		
		if (TF2_GetPlayerClass(actor) == TFClass_Engineer)
		{
			return CTFBotMvMEngineerIdle();
		}
		
		if (CTFPlayer(actor).HasAttribute(AGGRESSIVE))
		{
			// push for the point first, then attack
			return CTFBotPushToCapturePoint(CTFBotFetchFlag());
		}
		
		// capture the flag
		return CTFBotFetchFlag();
	}
	
	return NULL_ACTION;
}
