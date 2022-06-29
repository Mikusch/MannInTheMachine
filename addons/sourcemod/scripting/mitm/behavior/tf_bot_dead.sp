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

static IntervalTimer m_deadTimer[MAXPLAYERS + 1];

void CTFBotDead_Init()
{
	ActionFactory = new NextBotActionFactory("Dead");
	ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, CTFBotDead_OnStart);
	ActionFactory.SetCallback(NextBotActionCallbackType_Update, CTFBotDead_Update);
}

NextBotAction CTFBotDead_Create()
{
	return ActionFactory.Create();
}

static int CTFBotDead_OnStart(NextBotAction action, int actor, NextBotAction priorAction)
{
	m_deadTimer[actor].Start();
	
	return action.Continue();
}

static int CTFBotDead_Update(NextBotAction action, int actor, float interval)
{
	if (IsPlayerAlive(actor))
	{
		// how did this happen?
		return action.ChangeTo(CTFBotMainAction_Create(), "This should not happen!");
	}
	
	if (m_deadTimer[actor].IsGreaterThen(5.0))
	{
		if (Player(actor).HasAttribute(REMOVE_ON_DEATH))
		{
			// remove dead bots
			ServerCommand("kickid %d", GetClientUserId(actor));
		}
		else if (Player(actor).HasAttribute(BECOME_SPECTATOR_ON_DEATH))
		{
			g_bAllowTeamChange = true;
			TF2_ChangeClientTeam(actor, TFTeam_Spectator);
			g_bAllowTeamChange = false;
			return action.Done();
		}
	}
	
	return action.Continue();
}
