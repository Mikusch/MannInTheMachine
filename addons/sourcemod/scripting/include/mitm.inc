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

#if defined __mitm_included
	#endinput
#endif

#define __mitm_included

#include <cbasenpc>

#pragma semicolon 1
#pragma newdecls required

/**
 * Preference types.
 */
enum PreferenceType
{
	PREF_DISABLE_DEFENDER = (1 << 0),			/**< Can not be chosen as Defender. */
	PREF_DISABLE_SPAWNING = (1 << 1),			/**< Spectator mode. No spawning at all. */
	PREF_DISABLE_GIANT = (1 << 2),				/**< Can not become a Giant Robot. */
	PREF_DISABLE_SPAWN_NOTIFICATION = (1 << 3),	/**< Disables clientside sounds when spawning as Robot. */
	PREF_DISABLE_ANNOTATIONS = (1 << 4),		/**< Disables clientside world annotations e.g. Gate Bot and Sentry Buster hints. */
	PREF_IGNORE_PARTY_INVITES = (1 << 5),		/**< Can not be invited to parties. */
}

methodmap MannInTheMachinePlayer < CBaseCombatCharacter
{
	public MannInTheMachinePlayer(int client)
	{
		return view_as<MannInTheMachinePlayer>(client);
	}
	
	/**
	 * Returns whether this player has one or more preferences enabled.
	 *
	 * @param preference	Preference bits to check.
	 * @return				True if the player has the given preferences enabled.
	 */
	public native bool HasPreference(PreferenceType preference);
}

/**
 * Called when the plugin determines whether a player is allowed to become a Defender.
 *
 * @param client		Client index.
 * @return				True if the player is allowed to become a Defender, false otherwise.
 */
forward bool MannInTheMachine_OnIsValidDefender(int client);

/**
 * Called when the plugin determines whether a player is allowed to become an Invader.
 *
 * @param client		Client index.
 * @param isMiniBoss	True if the next Invader is a Giant.
 * @return				True if the player is allowed to become an Invader, false otherwise.
 */
forward bool MannInTheMachine_OnIsValidInvader(int client, bool isMiniBoss);

/**
 * Returns whether the game is in "Endless Waves" mode.
 *
 * @return		True if the game is in "Endless Waves" mode.
 * @error		Invalid population manager.
 */
native bool MannInTheMachine_IsInEndlessWaves();

public SharedPlugin __pl_mitm =
{
	name = "mitm",
	file = "mitm.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_mitm_SetNTVOptional()
{
	MarkNativeAsOptional("MannInTheMachinePlayer.HasPreference");
	MarkNativeAsOptional("MannInTheMachine_IsInEndlessWaves");
}
#endif
