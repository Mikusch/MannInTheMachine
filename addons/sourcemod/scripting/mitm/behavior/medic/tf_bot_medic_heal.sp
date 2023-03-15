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

methodmap CTFBotMedicHeal < NextBotAction
{
	public static void Init()
	{
		ActionFactory = new NextBotActionFactory("MedicHeal");
		ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
	}
	
	public CTFBotMedicHeal()
	{
		return view_as<CTFBotMedicHeal>(ActionFactory.Create());
	}
}

static int Update(CTFBotMedicHeal action, int actor, float interval)
{
	// if we're in a squad, and the only other members are medics, disband the squad
	if (Player(actor).IsInASquad())
	{
		CTFBotSquad squad = Player(actor).GetSquad();
		if (IsMannVsMachineMode() && squad.IsLeader(actor))
		{
			return action.ChangeTo(CTFBotFetchFlag(), "I'm now a squad leader! Going for the flag!");
		}
		
		if (!squad.ShouldPreserveSquad())
		{
			ArrayList memberList = new ArrayList();
			squad.CollectMembers(memberList);
			
			int i;
			for (i = 0; i < memberList.Length; i++)
			{
				if (TF2_GetPlayerClass(memberList.Get(i)) != TFClass_Medic)
				{
					break;
				}
			}
			
			if (i == memberList.Length)
			{
				// squad is obsolete
				for (i = 0; i < memberList.Length; ++i)
				{
					Player(memberList.Get(i)).LeaveSquad();
				}
			}
			
			delete memberList;
		}
	}
	else
	{
		// not in a squad - for now, assume whatever mission I was on is over
		Player(actor).SetMission(NO_MISSION);
	}
	
	if (SelectPatient(actor) == -1)
	{
		// no patients
		
		if (IsMannVsMachineMode())
		{
			// no-one is left to heal - get the flag!
			return action.ChangeTo(CTFBotFetchFlag(), "Everyone is gone! Going for the flag");
		}
	}
	
	return action.Continue();
}

static int SelectPatient(int actor)
{
	ArrayList livePlayerList = new ArrayList();
	CollectPlayers(livePlayerList, TF2_GetClientTeam(actor), COLLECT_ONLY_LIVING_PLAYERS);
	
	for (int i = 0; i < livePlayerList.Length; ++i)
	{
		int client = livePlayerList.Get(i);
		
		if (client == actor)
			continue;
		
		// always heal the flag carrier, regardless of class
		// squads always heal the leader
		if (!Player(client).HasTheFlag() && !Player(actor).IsInASquad())
		{
			TFClassType class = TF2_GetPlayerClass(client);
			if (class == TFClass_Medic ||
				class == TFClass_Sniper ||
				class == TFClass_Engineer ||
				class == TFClass_Spy)
			{
				// these classes can't be our primary heal target (although they will get opportunistic healing)
				continue;
			}
		}
		
		delete livePlayerList;
		return client;
	}
	
	delete livePlayerList;
	return -1;
}
