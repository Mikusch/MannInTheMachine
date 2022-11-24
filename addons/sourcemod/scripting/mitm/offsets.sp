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

static StringMap g_offsets;

void Offsets_Init(GameData gamedata)
{
	g_offsets = new StringMap();
	
	SetOffset(gamedata, "CTFBotSpawner", "m_class");
	SetOffset(gamedata, "CTFBotSpawner", "m_health");
	SetOffset(gamedata, "CTFBotSpawner", "m_scale");
	SetOffset(gamedata, "CTFBotSpawner", "m_flAutoJumpMin");
	SetOffset(gamedata, "CTFBotSpawner", "m_flAutoJumpMax");
	SetOffset(gamedata, "CTFBotSpawner", "m_eventChangeAttributes");
	SetOffset(gamedata, "CTFBotSpawner", "m_name");
	SetOffset(gamedata, "CTFBotSpawner", "m_teleportWhereName");
	SetOffset(gamedata, "CTFBotSpawner", "m_defaultAttributes");
	
	SetOffset(gamedata, "CSquadSpawner", "m_formationSize");
	SetOffset(gamedata, "CSquadSpawner", "m_bShouldPreserveSquad");
	
	SetOffset(gamedata, "CMissionPopulator", "m_mission");
	SetOffset(gamedata, "CMissionPopulator", "m_cooldownDuration");
	
	SetOffset(gamedata, "CWaveSpawnPopulator", "m_bSupportWave");
	SetOffset(gamedata, "CWaveSpawnPopulator", "m_bLimitedSupport");
	
	SetOffset(gamedata, "CPopulationManager", "m_canBotsAttackWhileInSpawnRoom");
	SetOffset(gamedata, "CPopulationManager", "m_bSpawningPaused");
	SetOffset(gamedata, "CPopulationManager", "m_EndlessActiveBotUpgrades");
	SetOffset(gamedata, "CPopulationManager", "m_defaultEventChangeAttributesName");
	
	SetOffset(gamedata, "CWave", "m_nSentryBustersSpawned");
	SetOffset(gamedata, "CWave", "m_nNumEngineersTeleportSpawned");
	SetOffset(gamedata, "CWave", "m_nNumSentryBustersKilled");
	
	SetOffset(gamedata, "IPopulationSpawner", "m_spawner");
	SetOffset(gamedata, "IPopulationSpawner", "m_where");
	
	SetOffset(gamedata, NULL_STRING, "sizeof(CMvMBotUpgrade)");
	SetOffset(gamedata, "CMvMBotUpgrade", "szAttrib");
	SetOffset(gamedata, "CMvMBotUpgrade", "iAttribIndex");
	SetOffset(gamedata, "CMvMBotUpgrade", "flValue");
	SetOffset(gamedata, "CMvMBotUpgrade", "bIsBotAttr");
	SetOffset(gamedata, "CMvMBotUpgrade", "bIsSkillAttr");
	
	SetOffset(gamedata, NULL_STRING, "sizeof(EventChangeAttributes_t)");
	SetOffset(gamedata, "EventChangeAttributes_t", "m_eventName");
	SetOffset(gamedata, "EventChangeAttributes_t", "m_skill");
	SetOffset(gamedata, "EventChangeAttributes_t", "m_weaponRestriction");
	SetOffset(gamedata, "EventChangeAttributes_t", "m_mission");
	SetOffset(gamedata, "EventChangeAttributes_t", "m_attributeFlags");
	SetOffset(gamedata, "EventChangeAttributes_t", "m_items");
	SetOffset(gamedata, "EventChangeAttributes_t", "m_itemsAttributes");
	SetOffset(gamedata, "EventChangeAttributes_t", "m_characterAttributes");
	SetOffset(gamedata, "EventChangeAttributes_t", "m_tags");
	
	SetOffset(gamedata, NULL_STRING, "sizeof(item_attributes_t)");
	SetOffset(gamedata, "item_attributes_t", "m_itemName");
	SetOffset(gamedata, "item_attributes_t", "m_attributes");
	
	SetOffset(gamedata, NULL_STRING, "sizeof(static_attrib_t)");
	SetOffset(gamedata, "static_attrib_t", "iDefIndex");
	SetOffset(gamedata, "static_attrib_t", "m_value");
	
	SetOffset(gamedata, NULL_STRING, "sizeof(BombInfo_t)");
	SetOffset(gamedata, "BombInfo_t", "m_flMaxBattleFront");
	
	SetOffset(gamedata, "CTFPlayer", "m_flSpawnTime");
	SetOffset(gamedata, "CTFPlayer", "m_bIsMissionEnemy");
	SetOffset(gamedata, "CTFPlayer", "m_bIsSupportEnemy");
	SetOffset(gamedata, "CTFPlayer", "m_bIsLimitedSupportEnemy");
	SetOffset(gamedata, "CTFPlayer", "m_pWaveSpawnPopulator");
	SetOffset(gamedata, "CTFPlayer", "m_accumulatedSentryGunDamageDealt");
	SetOffset(gamedata, "CTFPlayer", "m_accumulatedSentryGunKillCount");
	
	SetOffset(gamedata, "CTFWeaponBase", "m_bInAttack2");
	
	SetOffset(gamedata, "CCurrencyPack", "m_nAmount");
	SetOffset(gamedata, "CCurrencyPack", "m_bTouched");
	
	SetOffset(gamedata, "CEconItemAttributeDefinition", "m_iDescriptionFormat");
	SetOffset(gamedata, "CEconItemAttributeDefinition", "m_pszDescriptionString");
	
	SetOffset(gamedata, "CTakeDamageInfo", "m_bForceFriendlyFire");
	SetOffset(gamedata, "CTFNavArea", "m_distanceToBombTarget");
	SetOffset(gamedata, "CBaseTFBotHintEntity", "m_isDisabled");
	SetOffset(gamedata, "CTFGrenadePipebombProjectile", "m_flCreationTime");
	SetOffset(gamedata, "inputdata_t", "value");
	SetOffset(gamedata, "CTraceFilterSimple", "m_pPassEnt");
	SetOffset(gamedata, "CTFBotHintEngineerNest", "m_teleporters");
}

any GetOffset(const char[] cls, const char[] prop)
{
	int offset;
	
	if (IsNullString(cls))
	{
		if (!g_offsets.GetValue(prop, offset))
		{
			ThrowError("Offset '%s' not present in map", prop);
		}
	}
	else
	{
		char key[64];
		Format(key, sizeof(key), "%s::%s", cls, prop);
		
		if (!g_offsets.GetValue(key, offset))
		{
			ThrowError("Offset '%s' not present in map", key);
		}
	}
	
	return offset;
}

static void SetOffset(GameData gamedata, const char[] cls, const char[] prop)
{
	if (IsNullString(cls))
	{
		// Simple gamedata key lookup
		int offset = gamedata.GetOffset(prop);
		if (offset == -1)
		{
			ThrowError("Offset '%s' could not be found", prop);
		}
		
		g_offsets.SetValue(prop, offset);
		
#if defined DEBUG
		LogMessage("Found gamedata offset: %s (offset %d)", prop, offset);
#endif
	}
	else
	{
		char key[64], base_key[64], base_prop[64];
		Format(key, sizeof(key), "%s::%s", cls, prop);
		Format(base_key, sizeof(base_key), "%s_BaseOffset", cls);
		
		// Get the actual offset, calculated using a base offset if present
		if (gamedata.GetKeyValue(base_key, base_prop, sizeof(base_prop)))
		{
			int base_offset = FindSendPropInfo(cls, base_prop);
			if (base_offset == -1)
			{
				// If we found nothing, search on CBaseEntity instead
				base_offset = FindSendPropInfo("CBaseEntity", base_prop);
				if (base_offset == -1)
				{
					ThrowError("Base offset '%s::%s' could not be found", cls, base_prop);
				}
			}
			
			int offset = base_offset + gamedata.GetOffset(key);
			g_offsets.SetValue(key, offset);
			
#if defined DEBUG
			LogMessage("Found gamedata offset: %s (offset %d) (base %d)", key, offset, base_offset);
#endif
		}
		else
		{
			int offset = gamedata.GetOffset(key);
			if (offset == -1)
			{
				ThrowError("Offset '%s' could not be found", key);
			}
			
			g_offsets.SetValue(key, offset);
			
#if defined DEBUG
			LogMessage("Found gamedata offset: %s (offset %d)", key, offset);
#endif
		}
	}
}
