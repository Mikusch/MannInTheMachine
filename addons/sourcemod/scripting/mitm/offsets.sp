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

void Offsets_Init(GameData hGameConf)
{
	g_offsets = new StringMap();
	
	SetOffset(hGameConf, "CTFBotSpawner", "m_class");
	SetOffset(hGameConf, "CTFBotSpawner", "m_health");
	SetOffset(hGameConf, "CTFBotSpawner", "m_scale");
	SetOffset(hGameConf, "CTFBotSpawner", "m_flAutoJumpMin");
	SetOffset(hGameConf, "CTFBotSpawner", "m_flAutoJumpMax");
	SetOffset(hGameConf, "CTFBotSpawner", "m_eventChangeAttributes");
	SetOffset(hGameConf, "CTFBotSpawner", "m_name");
	SetOffset(hGameConf, "CTFBotSpawner", "m_teleportWhereName");
	SetOffset(hGameConf, "CTFBotSpawner", "m_defaultAttributes");
	
	SetOffset(hGameConf, "CSquadSpawner", "m_formationSize");
	SetOffset(hGameConf, "CSquadSpawner", "m_bShouldPreserveSquad");
	
	SetOffset(hGameConf, "CMissionPopulator", "m_mission");
	SetOffset(hGameConf, "CMissionPopulator", "m_cooldownDuration");
	
	SetOffset(hGameConf, "CWaveSpawnPopulator", "m_bSupportWave");
	SetOffset(hGameConf, "CWaveSpawnPopulator", "m_bLimitedSupport");
	
	SetOffset(hGameConf, "CPopulationManager", "m_bIsInitialized");
	SetOffset(hGameConf, "CPopulationManager", "m_canBotsAttackWhileInSpawnRoom");
	SetOffset(hGameConf, "CPopulationManager", "m_bSpawningPaused");
	SetOffset(hGameConf, "CPopulationManager", "m_EndlessActiveBotUpgrades");
	SetOffset(hGameConf, "CPopulationManager", "m_defaultEventChangeAttributesName");
	
	SetOffset(hGameConf, "CWave", "m_nSentryBustersSpawned");
	SetOffset(hGameConf, "CWave", "m_nNumEngineersTeleportSpawned");
	SetOffset(hGameConf, "CWave", "m_nNumSentryBustersKilled");
	
	SetOffset(hGameConf, "IPopulationSpawner", "m_spawner");
	SetOffset(hGameConf, "IPopulationSpawner", "m_where");
	
	SetOffset(hGameConf, NULL_STRING, "sizeof(CMvMBotUpgrade)");
	SetOffset(hGameConf, "CMvMBotUpgrade", "szAttrib");
	SetOffset(hGameConf, "CMvMBotUpgrade", "iAttribIndex");
	SetOffset(hGameConf, "CMvMBotUpgrade", "flValue");
	SetOffset(hGameConf, "CMvMBotUpgrade", "bIsBotAttr");
	SetOffset(hGameConf, "CMvMBotUpgrade", "bIsSkillAttr");
	
	SetOffset(hGameConf, NULL_STRING, "sizeof(EventChangeAttributes_t)");
	SetOffset(hGameConf, "EventChangeAttributes_t", "m_eventName");
	SetOffset(hGameConf, "EventChangeAttributes_t", "m_skill");
	SetOffset(hGameConf, "EventChangeAttributes_t", "m_weaponRestriction");
	SetOffset(hGameConf, "EventChangeAttributes_t", "m_mission");
	SetOffset(hGameConf, "EventChangeAttributes_t", "m_attributeFlags");
	SetOffset(hGameConf, "EventChangeAttributes_t", "m_items");
	SetOffset(hGameConf, "EventChangeAttributes_t", "m_itemsAttributes");
	SetOffset(hGameConf, "EventChangeAttributes_t", "m_characterAttributes");
	SetOffset(hGameConf, "EventChangeAttributes_t", "m_tags");
	
	SetOffset(hGameConf, NULL_STRING, "sizeof(item_attributes_t)");
	SetOffset(hGameConf, "item_attributes_t", "m_itemName");
	SetOffset(hGameConf, "item_attributes_t", "m_attributes");
	
	SetOffset(hGameConf, NULL_STRING, "sizeof(static_attrib_t)");
	SetOffset(hGameConf, "static_attrib_t", "iDefIndex");
	SetOffset(hGameConf, "static_attrib_t", "m_value");
	
	SetOffset(hGameConf, NULL_STRING, "sizeof(BombInfo_t)");
	SetOffset(hGameConf, "BombInfo_t", "m_flMaxBattleFront");
	
	SetOffset(hGameConf, "CTFPlayer", "m_flSpawnTime");
	SetOffset(hGameConf, "CTFPlayer", "m_nDeployingBombState");
	SetOffset(hGameConf, "CTFPlayer", "m_bIsMissionEnemy");
	SetOffset(hGameConf, "CTFPlayer", "m_bIsSupportEnemy");
	SetOffset(hGameConf, "CTFPlayer", "m_bIsLimitedSupportEnemy");
	SetOffset(hGameConf, "CTFPlayer", "m_pWaveSpawnPopulator");
	SetOffset(hGameConf, "CTFPlayer", "m_accumulatedSentryGunDamageDealt");
	SetOffset(hGameConf, "CTFPlayer", "m_accumulatedSentryGunKillCount");
	
	SetOffset(hGameConf, "CTFWeaponBase", "m_bInAttack2");
	
	SetOffset(hGameConf, "CCurrencyPack", "m_nAmount");
	SetOffset(hGameConf, "CCurrencyPack", "m_bTouched");
	
	SetOffset(hGameConf, "CEconItemAttributeDefinition", "m_iDescriptionFormat");
	SetOffset(hGameConf, "CEconItemAttributeDefinition", "m_pszDescriptionString");
	
	SetOffset(hGameConf, "CTFNavArea", "m_distanceToBombTarget");
	SetOffset(hGameConf, "CBaseTFBotHintEntity", "m_isDisabled");
	SetOffset(hGameConf, "CTFGrenadePipebombProjectile", "m_flCreationTime");
	SetOffset(hGameConf, "CBaseObject", "m_vecBuildOrigin");
	SetOffset(hGameConf, "inputdata_t", "value");
	SetOffset(hGameConf, "CTraceFilterSimple", "m_pPassEnt");
	SetOffset(hGameConf, "CTFBotHintEngineerNest", "m_teleporters");
	SetOffset(hGameConf, NULL_STRING, "sizeof(CHandle)");
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

static void SetOffset(GameData hGameConf, const char[] cls, const char[] prop)
{
	if (IsNullString(cls))
	{
		// Simple gamedata key lookup
		int offset = hGameConf.GetOffset(prop);
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
		if (hGameConf.GetKeyValue(base_key, base_prop, sizeof(base_prop)))
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
			
			int offset = base_offset + hGameConf.GetOffset(key);
			g_offsets.SetValue(key, offset);
			
#if defined DEBUG
			LogMessage("Found gamedata offset: %s (offset %d) (base %d)", key, offset, base_offset);
#endif
		}
		else
		{
			int offset = hGameConf.GetOffset(key);
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
