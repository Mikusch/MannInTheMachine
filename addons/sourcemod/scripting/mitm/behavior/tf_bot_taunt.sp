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

static CountdownTimer m_tauntTimer[MAXPLAYERS + 1];
static CountdownTimer m_tauntEndTimer[MAXPLAYERS + 1];

void CTFBotTaunt_Init()
{
	ActionFactory = new NextBotActionFactory("Taunt");
	ActionFactory.BeginDataMapDesc()
		.DefineBoolField("m_didTaunt")
	.EndDataMapDesc();
	ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, CTFBotTaunt_OnStart);
	ActionFactory.SetCallback(NextBotActionCallbackType_Update, CTFBotTaunt_Update);
}

NextBotAction CTFBotTaunt_Create()
{
	return ActionFactory.Create();
}

static int CTFBotTaunt_OnStart(NextBotAction action, int actor, NextBotAction priorAction)
{
	m_tauntTimer[actor].Start(GetRandomFloat(0.0, 1.0));
	action.SetData("m_didTaunt", false);
	
	return action.Continue();
}

static int CTFBotTaunt_Update(NextBotAction action, int actor, float interval)
{
	if (m_tauntTimer[actor].IsElapsed())
	{
		if (action.GetData("m_didTaunt"))
		{
			// Stop taunting after a while
			if (m_tauntEndTimer[actor].IsElapsed() && view_as<taunts_t>(GetEntProp(actor, Prop_Send, "m_iTauntIndex")) == TAUNT_LONG)
			{
				FakeClientCommand(actor, "stop_taunt");
			}
			
			if (TF2_IsPlayerInCondition(actor, TFCond_Taunting) == false)
			{
				return action.Done("Taunt finished");
			}
		}
		else
		{
			FakeClientCommand(actor, "taunt");
			// Start a timer to end our taunt in case we're still going after awhile
			m_tauntEndTimer[actor].Start(GetRandomFloat(3.0, 5.0));
			
			action.SetData("m_didTaunt", true);
		}
	}
	
	return action.Continue();
}
