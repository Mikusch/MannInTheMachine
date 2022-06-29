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

void CTFBotFetchFlag_Init()
{
	ActionFactory = new NextBotActionFactory("FetchFlag");
	ActionFactory.BeginDataMapDesc()
		.DefineBoolField("m_isTemporary")
	.EndDataMapDesc();
	ActionFactory.SetCallback(NextBotActionCallbackType_Update, CTFBotFetchFlag_Update);
}

NextBotAction CTFBotFetchFlag_Create(bool isTemporary = false)
{
	NextBotAction action = ActionFactory.Create();
	action.SetData("m_isTemporary", isTemporary);
	
	return action;
}

static int CTFBotFetchFlag_Update(NextBotAction action, int actor, float interval)
{
	int flag = Player(actor).GetFlagToFetch();
	
	if (flag == -1)
	{
		return action.Done("No flag");
	}
	
	if (GameRules_IsMannVsMachineMode() && GetEntProp(flag, Prop_Send, "m_nFlagStatus") == TF_FLAGINFO_HOME)
	{
		if (GetGameTime() - GetEntDataFloat(actor, GetOffset("CTFPlayer::m_flSpawnTime")) < 1.0 && TF2_GetClientTeam(actor) != TFTeam_Spectator)
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
