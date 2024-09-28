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
enum MannInTheMachinePreference
{
	PREF_DEFENDER_DISABLE_QUEUE =				(1 << 0),	/**< Can not be chosen as defender from queue */
	PREF_SPECTATOR_MODE =						(1 << 1),	/**< Spectator mode, no spawning */
	PREF_INVADER_DISABLE_MINIBOSS =				(1 << 2),	/**< Can not become a giant robot */
	PREF_DISABLE_ANNOTATIONS =					(1 << 3),	/**< Disables clientside world annotations e.g. gate bot and sentry buster hints */
	PREF_IGNORE_PARTY_INVITES =					(1 << 4),	/**< Can not be invited to any parties */
	PREF_DEFENDER_DISABLE_REPLACEMENT =			(1 << 5),	/**< Can not be chosen as a replacement defender */
	PREF_INVADER_DISABLE_CUSTOM_VIEWMODELS =	(1 << 6),	/**< Disables custom robot viewmodels */
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
	public native bool HasPreference(MannInTheMachinePreference preference);
}

/**
 * Called when the plugin determines whether a player is allowed to become a defender.
 *
 * @param client		Client index.
 * @return				True if the player is allowed to become a defender, false otherwise.
 */
forward bool MannInTheMachine_OnIsValidDefender(int client);

/**
 * Called when the plugin determines whether a player is allowed to become an invader.
 *
 * @param client		Client index.
 * @param bIsMiniBoss	True if the next invader is a miniboss.
 * @return				True if the player is allowed to become an invader, false otherwise.
 */
forward bool MannInTheMachine_OnIsValidInvader(int client, bool bIsMiniBoss);

/**
 * Called when a Sentry Buster has successfully detonated their target.
 *
 * @param client		Client index.
 * @param victim		Entity index of the target.
 */
forward void MannInTheMachine_OnSentryBusterDetonate(int client, int victim);

/**
 * Returns whether the game is in Endless Waves mode.
 *
 * @return		True if the game is in Endless Waves mode.
 * @error		Invalid population manager.
 */
native bool MannInTheMachine_IsInEndlessWaves();

/**
 * Returns whether the game is Waiting For Players.
 *
 * @return		True if the game is in Waiting For Players.
 */
native bool MannInTheMachine_IsInWaitingForPlayers();

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
	MarkNativeAsOptional("MannInTheMachine_IsInWaitingForPlayers");
}
#endif
