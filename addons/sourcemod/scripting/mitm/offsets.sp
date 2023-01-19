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

void Offsets_Init(GameData hGameData)
{
	g_offsets = new StringMap();
	
	SetOffset(hGameData, "CTFBotSpawner", "m_class");
	SetOffset(hGameData, "CTFBotSpawner", "m_health");
	SetOffset(hGameData, "CTFBotSpawner", "m_scale");
	SetOffset(hGameData, "CTFBotSpawner", "m_flAutoJumpMin");
	SetOffset(hGameData, "CTFBotSpawner", "m_flAutoJumpMax");
	SetOffset(hGameData, "CTFBotSpawner", "m_eventChangeAttributes");
	SetOffset(hGameData, "CTFBotSpawner", "m_name");
	SetOffset(hGameData, "CTFBotSpawner", "m_teleportWhereName");
	SetOffset(hGameData, "CTFBotSpawner", "m_defaultAttributes");
	
	SetOffset(hGameData, "CSquadSpawner", "m_formationSize");
	SetOffset(hGameData, "CSquadSpawner", "m_bShouldPreserveSquad");
	
	SetOffset(hGameData, "CMissionPopulator", "m_mission");
	SetOffset(hGameData, "CMissionPopulator", "m_cooldownDuration");
	
	SetOffset(hGameData, "CWaveSpawnPopulator", "m_bSupportWave");
	SetOffset(hGameData, "CWaveSpawnPopulator", "m_bLimitedSupport");
	
	SetOffset(hGameData, "CPopulationManager", "m_canBotsAttackWhileInSpawnRoom");
	SetOffset(hGameData, "CPopulationManager", "m_bSpawningPaused");
	SetOffset(hGameData, "CPopulationManager", "m_EndlessActiveBotUpgrades");
	SetOffset(hGameData, "CPopulationManager", "m_defaultEventChangeAttributesName");
	
	SetOffset(hGameData, "CWave", "m_nSentryBustersSpawned");
	SetOffset(hGameData, "CWave", "m_nNumEngineersTeleportSpawned");
	SetOffset(hGameData, "CWave", "m_nNumSentryBustersKilled");
	
	SetOffset(hGameData, "IPopulationSpawner", "m_spawner");
	SetOffset(hGameData, "IPopulationSpawner", "m_where");
	
	SetOffset(hGameData, NULL_STRING, "sizeof(CMvMBotUpgrade)");
	SetOffset(hGameData, "CMvMBotUpgrade", "szAttrib");
	SetOffset(hGameData, "CMvMBotUpgrade", "iAttribIndex");
	SetOffset(hGameData, "CMvMBotUpgrade", "flValue");
	SetOffset(hGameData, "CMvMBotUpgrade", "bIsBotAttr");
	SetOffset(hGameData, "CMvMBotUpgrade", "bIsSkillAttr");
	
	SetOffset(hGameData, NULL_STRING, "sizeof(EventChangeAttributes_t)");
	SetOffset(hGameData, "EventChangeAttributes_t", "m_eventName");
	SetOffset(hGameData, "EventChangeAttributes_t", "m_skill");
	SetOffset(hGameData, "EventChangeAttributes_t", "m_weaponRestriction");
	SetOffset(hGameData, "EventChangeAttributes_t", "m_mission");
	SetOffset(hGameData, "EventChangeAttributes_t", "m_attributeFlags");
	SetOffset(hGameData, "EventChangeAttributes_t", "m_items");
	SetOffset(hGameData, "EventChangeAttributes_t", "m_itemsAttributes");
	SetOffset(hGameData, "EventChangeAttributes_t", "m_characterAttributes");
	SetOffset(hGameData, "EventChangeAttributes_t", "m_tags");
	
	SetOffset(hGameData, NULL_STRING, "sizeof(item_attributes_t)");
	SetOffset(hGameData, "item_attributes_t", "m_itemName");
	SetOffset(hGameData, "item_attributes_t", "m_attributes");
	
	SetOffset(hGameData, NULL_STRING, "sizeof(static_attrib_t)");
	SetOffset(hGameData, "static_attrib_t", "iDefIndex");
	SetOffset(hGameData, "static_attrib_t", "m_value");
	
	SetOffset(hGameData, NULL_STRING, "sizeof(BombInfo_t)");
	SetOffset(hGameData, "BombInfo_t", "m_flMaxBattleFront");
	
	SetOffset(hGameData, "CTFPlayer", "m_flSpawnTime");
	SetOffset(hGameData, "CTFPlayer", "m_bIsMissionEnemy");
	SetOffset(hGameData, "CTFPlayer", "m_bIsSupportEnemy");
	SetOffset(hGameData, "CTFPlayer", "m_bIsLimitedSupportEnemy");
	SetOffset(hGameData, "CTFPlayer", "m_pWaveSpawnPopulator");
	SetOffset(hGameData, "CTFPlayer", "m_accumulatedSentryGunDamageDealt");
	SetOffset(hGameData, "CTFPlayer", "m_accumulatedSentryGunKillCount");
	
	SetOffset(hGameData, "CTFWeaponBase", "m_bInAttack2");
	
	SetOffset(hGameData, "CCurrencyPack", "m_nAmount");
	SetOffset(hGameData, "CCurrencyPack", "m_bTouched");
	
	SetOffset(hGameData, "CEconItemAttributeDefinition", "m_iDescriptionFormat");
	SetOffset(hGameData, "CEconItemAttributeDefinition", "m_pszDescriptionString");
	
	SetOffset(hGameData, "CTakeDamageInfo", "m_bForceFriendlyFire");
	SetOffset(hGameData, "CTFNavArea", "m_distanceToBombTarget");
	SetOffset(hGameData, "CBaseTFBotHintEntity", "m_isDisabled");
	SetOffset(hGameData, "CTFGrenadePipebombProjectile", "m_flCreationTime");
	SetOffset(hGameData, "inputdata_t", "value");
	SetOffset(hGameData, "CTraceFilterSimple", "m_pPassEnt");
	SetOffset(hGameData, "CTFBotHintEngineerNest", "m_teleporters");
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

static void SetOffset(GameData hGameData, const char[] cls, const char[] prop)
{
	if (IsNullString(cls))
	{
		// Simple gamedata key lookup
		int offset = hGameData.GetOffset(prop);
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
		if (hGameData.GetKeyValue(base_key, base_prop, sizeof(base_prop)))
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
			
			int offset = base_offset + hGameData.GetOffset(key);
			g_offsets.SetValue(key, offset);
			
#if defined DEBUG
			LogMessage("Found gamedata offset: %s (offset %d) (base %d)", key, offset, base_offset);
#endif
		}
		else
		{
			int offset = hGameData.GetOffset(key);
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
