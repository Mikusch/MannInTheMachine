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
	
	SetOffset(gamedata, "CTFBotSpawner::m_class");
	SetOffset(gamedata, "CTFBotSpawner::m_health");
	SetOffset(gamedata, "CTFBotSpawner::m_scale");
	SetOffset(gamedata, "CTFBotSpawner::m_flAutoJumpMin");
	SetOffset(gamedata, "CTFBotSpawner::m_flAutoJumpMax");
	SetOffset(gamedata, "CTFBotSpawner::m_eventChangeAttributes");
	SetOffset(gamedata, "CTFBotSpawner::m_name");
	SetOffset(gamedata, "CTFBotSpawner::m_teleportWhereName");
	SetOffset(gamedata, "CTFBotSpawner::m_defaultAttributes");
	
	SetOffset(gamedata, "CSquadSpawner::m_formationSize");
	SetOffset(gamedata, "CSquadSpawner::m_bShouldPreserveSquad");
	
	SetOffset(gamedata, "CMissionPopulator::m_mission");
	SetOffset(gamedata, "CMissionPopulator::m_cooldownDuration");
	
	SetOffset(gamedata, "CWaveSpawnPopulator::m_bSupportWave");
	SetOffset(gamedata, "CWaveSpawnPopulator::m_bLimitedSupport");
	
	SetOffset(gamedata, "CPopulationManager::m_canBotsAttackWhileInSpawnRoom");
	SetOffset(gamedata, "CPopulationManager::m_bSpawningPaused");
	SetOffset(gamedata, "CPopulationManager::m_EndlessActiveBotUpgrades");
	SetOffset(gamedata, "CPopulationManager::m_defaultEventChangeAttributesName");
	
	SetOffset(gamedata, "CWave::m_nSentryBustersSpawned");
	SetOffset(gamedata, "CWave::m_nNumEngineersTeleportSpawned");
	
	SetOffset(gamedata, "IPopulationSpawner::m_spawner");
	SetOffset(gamedata, "IPopulationSpawner::m_where");
	
	SetOffset(gamedata, "sizeof(CMvMBotUpgrade)");
	SetOffset(gamedata, "CMvMBotUpgrade::iAttribIndex");
	SetOffset(gamedata, "CMvMBotUpgrade::flValue");
	SetOffset(gamedata, "CMvMBotUpgrade::bIsBotAttr");
	SetOffset(gamedata, "CMvMBotUpgrade::bIsSkillAttr");
	
	SetOffset(gamedata, "sizeof(EventChangeAttributes_t)");
	SetOffset(gamedata, "EventChangeAttributes_t::m_eventName");
	SetOffset(gamedata, "EventChangeAttributes_t::m_skill");
	SetOffset(gamedata, "EventChangeAttributes_t::m_weaponRestriction");
	SetOffset(gamedata, "EventChangeAttributes_t::m_mission");
	SetOffset(gamedata, "EventChangeAttributes_t::m_attributeFlags");
	SetOffset(gamedata, "EventChangeAttributes_t::m_items");
	SetOffset(gamedata, "EventChangeAttributes_t::m_itemsAttributes");
	SetOffset(gamedata, "EventChangeAttributes_t::m_characterAttributes");
	SetOffset(gamedata, "EventChangeAttributes_t::m_tags");
	
	SetOffset(gamedata, "sizeof(item_attributes_t)");
	SetOffset(gamedata, "item_attributes_t::m_itemName");
	SetOffset(gamedata, "item_attributes_t::m_attributes");
	
	SetOffset(gamedata, "sizeof(static_attrib_t)");
	SetOffset(gamedata, "static_attrib_t::iDefIndex");
	SetOffset(gamedata, "static_attrib_t::m_value");
	
	SetOffset(gamedata, "sizeof(BombInfo_t)");
	SetOffset(gamedata, "BombInfo_t::m_flMaxBattleFront");
	
	SetOffset(gamedata, "CTFPlayer::m_flSpawnTime");
	SetOffset(gamedata, "CTFPlayer::m_bIsMissionEnemy");
	SetOffset(gamedata, "CTFPlayer::m_bIsSupportEnemy");
	SetOffset(gamedata, "CTFPlayer::m_bIsLimitedSupportEnemy");
	SetOffset(gamedata, "CTFPlayer::m_pWaveSpawnPopulator");
	SetOffset(gamedata, "CTFPlayer::m_accumulatedSentryGunDamageDealt");
	SetOffset(gamedata, "CTFPlayer::m_accumulatedSentryGunKillCount");
	
	SetOffset(gamedata, "CTFWeaponBase::m_bInAttack2");
	
	SetOffset(gamedata, "CCurrencyPack::m_nAmount");
	SetOffset(gamedata, "CCurrencyPack::m_bTouched");
	
	SetOffset(gamedata, "CTakeDamageInfo::m_bForceFriendlyFire");
	SetOffset(gamedata, "CTFNavArea::m_distanceToBombTarget");
	SetOffset(gamedata, "CBaseTFBotHintEntity::m_isDisabled");
	SetOffset(gamedata, "CTFGrenadePipebombProjectile::m_flCreationTime");
	SetOffset(gamedata, "inputdata_t::value");
	SetOffset(gamedata, "CEconItemAttributeDefinition::m_iDescriptionFormat");
	SetOffset(gamedata, "CTraceFilterSimple::m_pPassEnt");
}

any GetOffset(const char[] name)
{
	int offset;
	if (!g_offsets.GetValue(name, offset))
	{
		ThrowError("Offset \"%s\" not found in map", name);
	}
	
	return offset;
}

static void SetOffset(GameData gamedata, const char[] name)
{
	int offset = gamedata.GetOffset(name);
	if (offset == -1)
	{
		ThrowError("Offset \"%s\" not found in gamedata", name);
	}
	
	g_offsets.SetValue(name, offset);
}
