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

methodmap CTFBotEscortSquadLeader < NextBotAction
{
	public static void Init()
	{
		ActionFactory = new NextBotActionFactory("EscortSquadLeader");
		ActionFactory.BeginDataMapDesc()
			.DefineIntField("m_actionToDoAfterSquadDisbands")
		.EndDataMapDesc();
		ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
		ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
	}
	
	public CTFBotEscortSquadLeader(NextBotAction actionToDoAfterSquadDisbands)
	{
		CTFBotEscortSquadLeader action = view_as<CTFBotEscortSquadLeader>(ActionFactory.Create());
		action.m_actionToDoAfterSquadDisbands = actionToDoAfterSquadDisbands;
		return action;
	}
	
	property NextBotAction m_actionToDoAfterSquadDisbands
	{
		public get()
		{
			return this.GetData("m_actionToDoAfterSquadDisbands");
		}
		public set(NextBotAction actionToDoAfterSquadDisbands)
		{
			this.SetData("m_actionToDoAfterSquadDisbands", actionToDoAfterSquadDisbands);
		}
	}
}

static int OnStart(CTFBotEscortSquadLeader action, int actor, NextBotAction prevAction)
{
	
	return action.Continue();
}

static int Update(CTFBotEscortSquadLeader action, int actor, float interval)
{
	if (interval <= 0.0)
	{
		return action.Continue();
	}
	
	CTFBotSquad squad = Player(actor).GetSquad();
	if (!squad)
	{
		if (action.m_actionToDoAfterSquadDisbands)
		{
			return action.ChangeTo(action.m_actionToDoAfterSquadDisbands, "Not in a Squad");
		}
		
		return action.Done("Not in a Squad");
	}
	
	int leader = squad.GetLeader();
	if (leader == -1 || !IsPlayerAlive(leader))
	{
		Player(actor).LeaveSquad();
		
		if (action.m_actionToDoAfterSquadDisbands)
		{
			return action.ChangeTo(action.m_actionToDoAfterSquadDisbands, "Squad leader is dead");
		}
		
		return action.Done("Squad leader is dead");
	}
	
	if (GameRules_IsMannVsMachineMode() && leader == actor)
	{
		// capture the flag
		return action.ChangeTo(CTFBotFetchFlag(), "I'm now the squad leader! Going for the flag!");
	}
	
	return action.Continue();
}
