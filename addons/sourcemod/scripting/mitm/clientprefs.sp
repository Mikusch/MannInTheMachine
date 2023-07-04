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

char g_PreferenceNames[][] =
{
	"Preference_DisableDefender",
	"Preference_SpectatorMode",
	"Preference_DisableMiniBoss",
	"Preference_DisableAnnotations",
	"Preference_IgnorePartyInvites",
	"Preference_DisableDefenderReplacement",
};

static Cookie g_hCookieQueuePoints;
static Cookie g_hCookiePreferences;

void ClientPrefs_Init()
{
	g_hCookieQueuePoints = new Cookie("mitm_queue", "Mann in the Machine: Queue Points", CookieAccess_Protected);
	g_hCookiePreferences = new Cookie("mitm_prefs", "Mann in the Machine: Preferences", CookieAccess_Protected);
}

void ClientPrefs_RefreshQueue(int client)
{
	char szValue[12];
	g_hCookieQueuePoints.Get(client, szValue, sizeof(szValue));
	CTFPlayer(client).m_defenderQueuePoints = StringToInt(szValue);
}

void ClientPrefs_RefreshPreferences(int client)
{
	char szValue[12];
	g_hCookiePreferences.Get(client, szValue, sizeof(szValue));
	CTFPlayer(client).m_preferences = StringToInt(szValue);
}

void ClientPrefs_SaveQueue(int client, int value)
{
	char szValue[12];
	IntToString(value, szValue, sizeof(szValue));
	g_hCookieQueuePoints.Set(client, szValue);
}

void ClientPrefs_SavePreferences(int client, int value)
{
	char szValue[12];
	IntToString(value, szValue, sizeof(szValue));
	g_hCookiePreferences.Set(client, szValue);
}
