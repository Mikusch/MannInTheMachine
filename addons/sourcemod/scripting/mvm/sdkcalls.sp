/*
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

static Handle g_SDKCallRemovePlayerAttributes;

void SDKCalls_Initialize(GameData gamedata)
{
	g_SDKCallRemovePlayerAttributes = PrepSDKCall_RemovePlayerAttributes(gamedata);
}

static Handle PrepSDKCall_RemovePlayerAttributes(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayer::RemovePlayerAttributes");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: CTFPlayer::RemovePlayerAttributes");
	
	return call;
}

void SDKCall_RemovePlayerAttributes(int player, bool setBonuses)
{
	if (g_SDKCallRemovePlayerAttributes)
		SDKCall(g_SDKCallRemovePlayerAttributes, player, setBonuses);
}
