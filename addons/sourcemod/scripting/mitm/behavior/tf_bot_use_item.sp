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

methodmap CTFBotUseItem < NextBotAction
{
	public static void Init()
	{
		ActionFactory = new NextBotActionFactory("UseItem");
		ActionFactory.BeginDataMapDesc()
			.DefineEntityField("m_item")
			.DefineIntField("m_cooldownTimer")
		.EndDataMapDesc();
		ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
		ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
		ActionFactory.SetCallback(NextBotActionCallbackType_OnEnd, OnEnd);
	}
	
	public CTFBotUseItem(int item)
	{
		CTFBotUseItem action = view_as<CTFBotUseItem>(ActionFactory.Create());
		action.m_item = item;
		action.m_cooldownTimer = new CountdownTimer();
		return action;
	}
	
	property int m_item
	{
		public get()
		{
			return this.GetDataEnt("m_item");
		}
		public set(int item)
		{
			this.SetDataEnt("m_item", item);
		}
	}
	
	property CountdownTimer m_cooldownTimer
	{
		public get()
		{
			return this.GetData("m_cooldownTimer");
		}
		public set(CountdownTimer cooldownTimer)
		{
			this.SetData("m_cooldownTimer", cooldownTimer);
		}
	}
}

static int OnStart(CTFBotUseItem action, int actor, NextBotAction priorAction)
{
	CTFPlayer(actor).PushRequiredWeapon(action.m_item);
	
	action.m_cooldownTimer.Start(GetEntPropFloat(action.m_item, Prop_Send, "m_flNextPrimaryAttack") - GetGameTime() + 0.25);
	
	return action.Continue();
}

static int Update(CTFBotUseItem action, int actor, float interval)
{
	if (!IsValidEntity(action.m_item))
	{
		return action.Done("NULL item");
	}
	
	int myCurrentWeapon = GetEntPropEnt(actor, Prop_Send, "m_hActiveWeapon");
	
	if (!IsValidEntity(myCurrentWeapon))
	{
		return action.Done("NULL weapon");
	}
	
	if (action.m_cooldownTimer.HasStarted())
	{
		if (action.m_cooldownTimer.IsElapsed())
		{
			// use it
			CTFPlayer(actor).PressFireButton();
			action.m_cooldownTimer.Invalidate();
		}
	}
	else // used
	{
		// some items use the taunt system - wait for the taunt to end
		if (!TF2_IsPlayerInCondition(actor, TFCond_Taunting))
		{
			return action.Done("Item used");
		}
	}
	
	return action.Continue();
}

static void OnEnd(CTFBotUseItem action, int actor, NextBotAction nextAction)
{
	CTFPlayer(actor).PopRequiredWeapon();
	
	delete action.m_cooldownTimer;
}
