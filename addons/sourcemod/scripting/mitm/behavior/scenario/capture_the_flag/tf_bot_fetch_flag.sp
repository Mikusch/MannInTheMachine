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

methodmap CTFBotFetchFlag < NextBotAction
{
	public static void Init()
	{
		ActionFactory = new NextBotActionFactory("FetchFlag");
		ActionFactory.BeginDataMapDesc()
			.DefineBoolField("m_isTemporary")
		.EndDataMapDesc();
		ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
	}
	
	public CTFBotFetchFlag(bool isTemporary = false)
	{
		CTFBotFetchFlag action = view_as<CTFBotFetchFlag>(ActionFactory.Create());
		action.m_isTemporary = isTemporary;
		return action;
	}
	
	property bool m_isTemporary
	{
		public get()
		{
			return this.GetData("m_isTemporary");
		}
		public set(bool isTemporary)
		{
			this.SetData("m_isTemporary", isTemporary);
		}
	}
}

static int Update(CTFBotFetchFlag action, int actor, float interval)
{
	int flag = Player(actor).GetFlagToFetch();
	
	if (!IsValidEntity(flag))
	{
		return action.Done("No flag");
	}
	
	if (IsMannVsMachineMode() && GetEntProp(flag, Prop_Send, "m_nFlagStatus") == TF_FLAGINFO_HOME)
	{
		if (GetGameTime() - Player(actor).GetSpawnTime() < 1.0 && TF2_GetClientTeam(actor) != TFTeam_Spectator)
		{
			// we just spawned - give us the flag
			SDKCall_PickUp(flag, actor, true);
		}
		else
		{
			if (action.GetData("m_isTemporary"))
			{
				return action.Done("Flag unreachable");
			}
			
			return action.Continue();
		}
	}
	
	return action.Continue();
}
