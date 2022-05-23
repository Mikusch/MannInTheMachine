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

enum PreferenceType
{
	PREF_DONT_BE_DEFENDER = (1 << 0),
	PREF_NO_SPAWNING = (1 << 1),
}

static Cookie g_cookieQueuePoints;
static Cookie g_cookiePreferences;

void ClientPrefs_Initialize()
{
	g_cookieQueuePoints = new Cookie("mitm_queue", "Mann in the Machine: Queue Points", CookieAccess_Protected);
	g_cookiePreferences = new Cookie("mitm_prefs", "Mann in the Machine: Preferences", CookieAccess_Protected);
}

void ClientPrefs_RefreshQueue(int client)
{
	char szValue[12];
	g_cookieQueuePoints.Get(client, szValue, sizeof(szValue));
	Player(client).m_defenderQueuePoints = StringToInt(szValue);
}

void ClientPrefs_RefreshPreferences(int client)
{
	char szValue[12];
	g_cookiePreferences.Get(client, szValue, sizeof(szValue));
	Player(client).m_preferences = StringToInt(szValue);
}

void ClientPrefs_SaveQueue(int client, int value)
{
	char szValue[12];
	IntToString(value, szValue, sizeof(szValue));
	g_cookieQueuePoints.Set(client, szValue);
}

void ClientPrefs_SavePreferences(int client, int value)
{
	char szValue[12];
	IntToString(value, szValue, sizeof(szValue));
	g_cookiePreferences.Set(client, szValue);
}
