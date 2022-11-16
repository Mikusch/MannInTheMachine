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

#define MY_CURRENT_GUN	0

// Auto Jump
static CountdownTimer m_autoJumpTimer[MAXPLAYERS + 1];
static float m_flAutoJumpMin[MAXPLAYERS + 1];
static float m_flAutoJumpMax[MAXPLAYERS + 1];

// Engineer Robots
static ArrayList m_teleportWhereName[MAXPLAYERS + 1];

// Bot Spawner
static ArrayList m_eventChangeAttributes[MAXPLAYERS + 1];
static ArrayList m_tags[MAXPLAYERS + 1];
static WeaponRestrictionType m_weaponRestrictionFlags[MAXPLAYERS + 1];
static AttributeType m_attributeFlags[MAXPLAYERS + 1];
static char m_szIdleSound[MAXPLAYERS + 1][PLATFORM_MAX_PATH];
static float m_fModelScaleOverride[MAXPLAYERS + 1];
static MissionType m_mission[MAXPLAYERS + 1];
static MissionType m_prevMission[MAXPLAYERS + 1];
static int m_missionTarget[MAXPLAYERS + 1];
static float m_flSpawnTimeLeft[MAXPLAYERS + 1];
static int m_spawnPointEntity[MAXPLAYERS + 1];
static CTFBotSquad m_squad[MAXPLAYERS + 1];
static int m_hFollowingFlagTarget[MAXPLAYERS + 1];
static BombDeployingState_t m_nDeployingBombState[MAXPLAYERS + 1];
static char m_szInvaderName[MAXPLAYERS + 1][MAX_NAME_LENGTH];
static char m_szPrevName[MAXPLAYERS + 1][MAX_NAME_LENGTH];

// Non-resetting Properties
static int m_invaderPriority[MAXPLAYERS + 1];
static bool m_bWasMiniBoss[MAXPLAYERS + 1];
static int m_defenderQueuePoints[MAXPLAYERS + 1];
static int m_preferences[MAXPLAYERS + 1];
static Party m_party[MAXPLAYERS + 1];
static bool m_bIsPartyMenuActive[MAXPLAYERS + 1];

methodmap Player < CBaseCombatCharacter
{
	public Player(int entity)
	{
		return view_as<Player>(entity);
	}
	
	property CountdownTimer m_autoJumpTimer
	{
		public get()
		{
			return m_autoJumpTimer[this.index];
		}
		public set(CountdownTimer autoJumpTimer)
		{
			m_autoJumpTimer[this.index] = autoJumpTimer;
		}
	}
	
	property float m_flAutoJumpMin
	{
		public get()
		{
			return m_flAutoJumpMin[this.index];
		}
		public set(float flAutoJumpMin)
		{
			m_flAutoJumpMin[this.index] = flAutoJumpMin;
		}
	}
	
	property float m_flAutoJumpMax
	{
		public get()
		{
			return m_flAutoJumpMax[this.index];
		}
		public set(float flAutoJumpMax)
		{
			m_flAutoJumpMax[this.index] = flAutoJumpMax;
		}
	}
	
	property ArrayList m_eventChangeAttributes
	{
		public get()
		{
			return m_eventChangeAttributes[this.index];
		}
		public set(ArrayList attributes)
		{
			m_eventChangeAttributes[this.index] = attributes;
		}
	}
	
	property ArrayList m_tags
	{
		public get()
		{
			return m_tags[this.index];
		}
		public set(ArrayList tags)
		{
			m_tags[this.index] = tags;
		}
	}
	
	property WeaponRestrictionType m_weaponRestrictionFlags
	{
		public get()
		{
			return m_weaponRestrictionFlags[this.index];
		}
		public set(WeaponRestrictionType restrictionFlags)
		{
			m_weaponRestrictionFlags[this.index] = restrictionFlags;
		}
	}
	
	property AttributeType m_attributeFlags
	{
		public get()
		{
			return m_attributeFlags[this.index];
		}
		public set(AttributeType attributeFlag)
		{
			m_attributeFlags[this.index] = attributeFlag;
		}
	}
	
	property float m_fModelScaleOverride
	{
		public get()
		{
			return m_fModelScaleOverride[this.index];
		}
		public set(float fScale)
		{
			m_fModelScaleOverride[this.index] = fScale;
		}
	}
	
	property MissionType m_mission
	{
		public get()
		{
			return m_mission[this.index];
		}
		public set(MissionType mission)
		{
			m_mission[this.index] = mission;
		}
	}
	
	property MissionType m_prevMission
	{
		public get()
		{
			return m_prevMission[this.index];
		}
		public set(MissionType mission)
		{
			m_prevMission[this.index] = mission;
		}
	}
	
	property int m_missionTarget
	{
		public get()
		{
			return m_missionTarget[this.index];
		}
		public set(int missionTarget)
		{
			m_missionTarget[this.index] = missionTarget;
		}
	}
	
	property float m_flSpawnTimeLeft
	{
		public get()
		{
			return m_flSpawnTimeLeft[this.index];
		}
		public set(float flSpawnTimeLeft)
		{
			m_flSpawnTimeLeft[this.index] = flSpawnTimeLeft;
		}
	}
	
	property int m_spawnPointEntity
	{
		public get()
		{
			return m_spawnPointEntity[this.index];
		}
		public set(int spawnPoint)
		{
			m_spawnPointEntity[this.index] = spawnPoint;
		}
	}
	
	property int m_invaderPriority
	{
		public get()
		{
			return m_invaderPriority[this.index];
		}
		public set(int iPriority)
		{
			m_invaderPriority[this.index] = iPriority;
		}
	}
	
	property bool m_bWasMiniBoss
	{
		public get()
		{
			return m_bWasMiniBoss[this.index];
		}
		public set(bool bWasMiniBoss)
		{
			m_bWasMiniBoss[this.index] = bWasMiniBoss;
		}
	}
	
	property int m_defenderQueuePoints
	{
		public get()
		{
			return m_defenderQueuePoints[this.index];
		}
		public set(int defenderQueuePoints)
		{
			m_defenderQueuePoints[this.index] = defenderQueuePoints;
		}
	}
	
	property int m_preferences
	{
		public get()
		{
			return m_preferences[this.index];
		}
		public set(int preferences)
		{
			m_preferences[this.index] = preferences;
		}
	}
	
	property ArrayList m_teleportWhereName
	{
		public get()
		{
			return m_teleportWhereName[this.index];
		}
		public set(ArrayList teleportWhereName)
		{
			m_teleportWhereName[this.index] = teleportWhereName;
		}
	}
	
	property CTFBotSquad m_squad
	{
		public get()
		{
			return m_squad[this.index];
		}
		public set(CTFBotSquad squad)
		{
			m_squad[this.index] = squad;
		}
	}
	
	property int m_hFollowingFlagTarget
	{
		public get()
		{
			return m_hFollowingFlagTarget[this.index];
		}
		public set(int hFollowingFlagTarget)
		{
			m_hFollowingFlagTarget[this.index] = hFollowingFlagTarget;
		}
	}
	
	property BombDeployingState_t m_nDeployingBombState
	{
		public get()
		{
			return m_nDeployingBombState[this.index];
		}
		public set(BombDeployingState_t nDeployingBombState)
		{
			m_nDeployingBombState[this.index] = nDeployingBombState;
		}
	}
	
	property Party m_party
	{
		public get()
		{
			return m_party[this.index];
		}
		public set(Party party)
		{
			m_party[this.index] = party;
		}
	}
	
	property bool m_bIsPartyMenuActive
	{
		public get()
		{
			return m_bIsPartyMenuActive[this.index];
		}
		public set(bool bIsPartyMenuActive)
		{
			m_bIsPartyMenuActive[this.index] = bIsPartyMenuActive;
		}
	}
	
	public bool IsInvader()
	{
		if (IsClientSourceTV(this.index))
			return false;
		
		TFTeam team = TF2_GetClientTeam(this.index);
		return (team == TFTeam_Spectator || team == TFTeam_Invaders) && !this.HasPreference(PREF_DISABLE_SPAWNING);
	}
	
	public float GetSpawnTime()
	{
		return GetEntDataFloat(this.index, GetOffset("CTFPlayer::m_flSpawnTime"));
	}
	
	public TFTeam GetDisguiseTeam()
	{
		return view_as<TFTeam>(this.GetProp(Prop_Send, "m_nDisguiseTeam"));
	}
	
	public bool IsMiniBoss()
	{
		return this.GetProp(Prop_Send, "m_bIsMiniBoss") != 0;
	}
	
	public int GetFlagTarget()
	{
		return this.m_hFollowingFlagTarget;
	}
	
	public void SetFlagTarget(int flag)
	{
		this.m_hFollowingFlagTarget = flag;
	}
	
	public bool HasFlagTarget()
	{
		return IsValidEntity(this.m_hFollowingFlagTarget);
	}
	
	public void SetSpawnPoint(int spawnPoint)
	{
		this.m_spawnPointEntity = spawnPoint;
	}
	
	public BombDeployingState_t GetDeployingBombState()
	{
		return this.m_nDeployingBombState;
	}
	
	public void SetDeployingBombState(BombDeployingState_t nDeployingBombState)
	{
		this.m_nDeployingBombState = nDeployingBombState;
	}
	
	public void SetAutoJump(float flAutoJumpMin, float flAutoJumpMax)
	{
		this.m_flAutoJumpMin = flAutoJumpMin;
		this.m_flAutoJumpMax = flAutoJumpMax;
	}
	
	public void ClearWeaponRestrictions()
	{
		this.m_weaponRestrictionFlags = ANY_WEAPON;
	}
	
	public void SetWeaponRestriction(WeaponRestrictionType restrictionFlags)
	{
		this.m_weaponRestrictionFlags |= restrictionFlags;
	}
	
	public bool HasWeaponRestriction(WeaponRestrictionType restrictionFlags)
	{
		return this.m_weaponRestrictionFlags & restrictionFlags ? true : false;
	}
	
	public void SetAttribute(AttributeType attributeFlag)
	{
		this.m_attributeFlags |= attributeFlag;
	}
	
	public void ClearAttribute(AttributeType attributeFlag)
	{
		this.m_attributeFlags &= ~attributeFlag;
	}
	
	public void ClearAllAttributes()
	{
		this.m_attributeFlags = view_as<AttributeType>(0);
	}
	
	public bool HasAttribute(AttributeType attributeFlag)
	{
		return this.m_attributeFlags & attributeFlag ? true : false;
	}
	
	public void ClearTags()
	{
		this.m_tags.Clear();
	}
	
	public void AddTag(const char[] tag)
	{
		if (!this.HasTag(tag))
		{
			this.m_tags.PushString(tag);
		}
	}
	
	public void RemoveTag(const char[] tag)
	{
		for (int i = 0; i < this.m_tags.Length; ++i)
		{
			char m_tag[64];
			this.m_tags.GetString(i, m_tag, sizeof(m_tag));
			
			if (StrEqual(tag, m_tag))
			{
				this.m_tags.Erase(i);
				return;
			}
		}
	}
	
	public bool HasTag(const char[] tag)
	{
		for (int i = 0; i < this.m_tags.Length; ++i)
		{
			char m_tag[64];
			this.m_tags.GetString(i, m_tag, sizeof(m_tag));
			
			if (StrEqual(tag, m_tag))
			{
				return true;
			}
		}
		
		return false;
	}
	
	public void GetIdleSound(char[] buffer, int maxlen)
	{
		strcopy(buffer, maxlen, m_szIdleSound[this.index]);
	}
	
	public void SetIdleSound(const char[] soundName)
	{
		strcopy(m_szIdleSound[this.index], sizeof(m_szIdleSound[]), soundName);
	}
	
	public void ClearIdleSound()
	{
		m_szIdleSound[this.index][0] = EOS;
	}
	
	public void SetScaleOverride(float fScale)
	{
		this.m_fModelScaleOverride = fScale;
		
		SetModelScale(this.index, this.m_fModelScaleOverride > 0.0 ? this.m_fModelScaleOverride : 1.0);
	}
	
	public MissionType GetPrevMission()
	{
		return this.m_prevMission;
	}
	
	public void SetPrevMission(MissionType prevMission)
	{
		this.m_prevMission = prevMission;
	}
	
	public bool HasMission(MissionType mission)
	{
		return this.m_mission == mission ? true : false;
	}
	
	public bool IsOnAnyMission()
	{
		return this.m_mission == NO_MISSION ? false : true;
	}
	
	public MissionType GetMission()
	{
		return this.m_mission;
	}
	
	public void SetMission(MissionType mission)
	{
		this.SetPrevMission(this.m_mission);
		this.m_mission = mission;
		
		// Temp hack - some missions play an idle loop
		if (this.m_mission > NO_MISSION)
		{
			this.StartIdleSound();
		}
	}
	
	public int GetMissionTarget()
	{
		return this.m_missionTarget;
	}
	
	public void SetMissionTarget(int missionTarget)
	{
		this.m_missionTarget = missionTarget;
	}
	
	public void SetTeleportWhere(CUtlVector teleportWhereName)
	{
		for (int i = 0; i < teleportWhereName.Count(); ++i)
		{
			char name[64];
			PtrToString(Deref(teleportWhereName.Get(i)), name, sizeof(name));
			
			this.m_teleportWhereName.PushString(name);
		}
	}
	
	public ArrayList GetTeleportWhere()
	{
		return this.m_teleportWhereName;
	}
	
	public void ClearTeleportWhere()
	{
		this.m_teleportWhereName.Clear();
	}
	
	public void StartIdleSound()
	{
		this.StopIdleSound();
		
		if (!IsMannVsMachineMode())
			return;
		
		if (this.IsMiniBoss())
		{
			char pszSoundName[PLATFORM_MAX_PATH];
			
			TFClassType class = TF2_GetPlayerClass(this.index);
			switch (class)
			{
				case TFClass_Heavy:
				{
					strcopy(pszSoundName, sizeof(pszSoundName), "MVM.GiantHeavyLoop");
				}
				case TFClass_Soldier:
				{
					strcopy(pszSoundName, sizeof(pszSoundName), "MVM.GiantSoldierLoop");
				}
				
				case TFClass_DemoMan:
				{
					if (this.m_mission == MISSION_DESTROY_SENTRIES)
					{
						strcopy(pszSoundName, sizeof(pszSoundName), "MVM.SentryBusterLoop");
					}
					else
					{
						strcopy(pszSoundName, sizeof(pszSoundName), "MVM.GiantDemomanLoop");
					}
				}
				case TFClass_Scout:
				{
					strcopy(pszSoundName, sizeof(pszSoundName), "MVM.GiantScoutLoop");
				}
				case TFClass_Pyro:
				{
					strcopy(pszSoundName, sizeof(pszSoundName), "MVM.GiantPyroLoop");
				}
			}
			
			if (pszSoundName[0])
			{
				EmitGameSoundToAll(pszSoundName, this.index);
				this.SetIdleSound(pszSoundName);
			}
		}
	}
	
	public void StopIdleSound()
	{
		char idleSound[PLATFORM_MAX_PATH];
		this.GetIdleSound(idleSound, sizeof(idleSound));
		
		if (idleSound[0])
		{
			StopGameSound(this.index, idleSound);
			this.ClearIdleSound();
		}
	}
	
	public void SetName(const char[] name, bool bSetName)
	{
		strcopy(m_szInvaderName[this.index], sizeof(m_szInvaderName[]), name);
		
		// if requested, change client name
		if (bSetName && GetClientName(this.index, m_szPrevName[this.index], sizeof(m_szPrevName[])))
		{
			SetClientName(this.index, name);
		}
	}
	
	public int GetName(char[] buffer, int maxlen)
	{
		return strcopy(buffer, maxlen, m_szInvaderName[this.index]);
	}
	
	public void ResetName()
	{
		m_szInvaderName[this.index][0] = EOS;
		
		if (m_szPrevName[this.index][0])
		{
			SetClientName(this.index, m_szPrevName[this.index]);
			m_szPrevName[this.index][0] = EOS;
		}
	}
	
	public void SetDifficulty(DifficultyType difficulty)
	{
		this.SetProp(Prop_Send, "m_nBotSkill", difficulty);
	}
	
	public void ModifyMaxHealth(int nNewMaxHealth, bool bSetCurrentHealth = true, bool bAllowModelScaling = true)
	{
		if (TF2Util_GetEntityMaxHealth(this.index) != nNewMaxHealth)
		{
			TF2Attrib_SetByName(this.index, "hidden maxhealth non buffed", float(nNewMaxHealth - TF2Util_GetEntityMaxHealth(this.index)));
		}
		
		if (bSetCurrentHealth)
		{
			this.SetProp(Prop_Data, "m_iHealth", nNewMaxHealth);
		}
		
		if (bAllowModelScaling && this.IsMiniBoss())
		{
			SetModelScale(this.index, this.m_fModelScaleOverride > 0.0 ? this.m_fModelScaleOverride : tf_mvm_miniboss_scale.FloatValue);
		}
	}
	
	public void SetCustomCurrencyWorth(int nAmount)
	{
		this.SetProp(Prop_Send, "m_nCurrency", nAmount);
	}
	
	public void SetWaveSpawnPopulator(Address pWave)
	{
		SetEntData(this.index, GetOffset("CTFPlayer::m_pWaveSpawnPopulator"), pWave);
	}
	
	public void ClearEventChangeAttributes()
	{
		this.m_eventChangeAttributes.Clear();
	}
	
	public void AddEventChangeAttributes(EventChangeAttributes_t newEvent)
	{
		this.m_eventChangeAttributes.Push(newEvent);
	}
	
	public EventChangeAttributes_t GetEventChangeAttributes(Address pszEventName)
	{
		for (int i = 0; i < this.m_eventChangeAttributes.Length; ++i)
		{
			EventChangeAttributes_t attributes = this.m_eventChangeAttributes.Get(i);
			
			if (StrPtrEquals(attributes.m_eventName, pszEventName))
			{
				return attributes;
			}
		}
		return EventChangeAttributes_t(Address_Null);
	}
	
	public void OnEventChangeAttributes(EventChangeAttributes_t pEvent)
	{
		if (pEvent)
		{
			this.SetDifficulty(pEvent.m_skill);
			
			this.ClearWeaponRestrictions();
			this.SetWeaponRestriction(pEvent.m_weaponRestriction);
			
			this.SetMission(pEvent.m_mission);
			
			this.ClearAllAttributes();
			this.SetAttribute(pEvent.m_attributeFlags);
			
			if (IsMannVsMachineMode())
			{
				this.SetAttribute(BECOME_SPECTATOR_ON_DEATH);
				this.SetAttribute(RETAIN_BUILDINGS);
			}
			
			// cache off health value before we clear attribute because ModifyMaxHealth adds new attribute and reset the health
			int nHealth = this.GetProp(Prop_Data, "m_iHealth");
			int nMaxHealth = TF2Util_GetEntityMaxHealth(this.index);
			
			// remove any player attributes
			TF2Attrib_RemoveAll(this.index);
			// and add ones that we want specifically
			for (int i = 0; i < pEvent.m_characterAttributes.Count(); i++)
			{
				Address characterAttributes = pEvent.m_characterAttributes.Get(i, GetOffset("sizeof(static_attrib_t)"));
				int defIndex = Deref(characterAttributes + GetOffset("static_attrib_t::iDefIndex"), NumberType_Int16);
				
				Address pDef = TF2Econ_GetAttributeDefinitionAddress(defIndex);
				if (pDef)
				{
					float flValue = Deref(characterAttributes + GetOffset("static_attrib_t::m_value"));
					TF2Attrib_SetByDefIndex(this.index, defIndex, flValue);
				}
			}
			TF2Attrib_ClearCache(this.index);
			
			// set health back to what it was before we clear bot's attributes
			this.ModifyMaxHealth(nMaxHealth);
			this.SetProp(Prop_Data, "m_iHealth", nHealth);
			
			// give items to bot before apply attribute changes
			for (int i = 0; i < pEvent.m_items.Count(); i++)
			{
				char item[64];
				PtrToString(Deref(pEvent.m_items.Get(i)), item, sizeof(item));
				
				this.AddItem(item);
			}
			
			for (int i = 0; i < pEvent.m_itemsAttributes.Count(); i++)
			{
				Address itemAttributes = pEvent.m_itemsAttributes.Get(i, GetOffset("sizeof(item_attributes_t)"));
				
				char itemName[64];
				PtrToString(Deref(itemAttributes + GetOffset("item_attributes_t::m_itemName")), itemName, sizeof(itemName));
				
				int itemDef = GetItemDefinitionIndexByName(itemName);
				
				for (int iItemSlot = LOADOUT_POSITION_PRIMARY; iItemSlot < CLASS_LOADOUT_POSITION_COUNT; iItemSlot++)
				{
					int entity = TF2Util_GetPlayerLoadoutEntity(this.index, iItemSlot);
					
					if (entity != -1 && itemDef == GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"))
					{
						CUtlVector attributes = CUtlVector(itemAttributes + GetOffset("item_attributes_t::m_attributes"));
						for (int iAtt = 0; iAtt < attributes.Count(); ++iAtt)
						{
							Address attrib = attributes.Get(iAtt, GetOffset("sizeof(static_attrib_t)"));
							
							int defIndex = Deref(attrib + GetOffset("static_attrib_t::iDefIndex"), NumberType_Int16);
							float value = Deref(attrib + GetOffset("static_attrib_t::m_value"));
							
							TF2Attrib_SetByDefIndex(entity, defIndex, value);
						}
						
						if (entity != -1)
						{
							// update model incase we change style
							SDKCall_UpdateModelToClass(entity);
						}
						
						// move on to the next set of attributes
						break;
					}
				} // for each slot
			} // for each set of attributes
			
			// tags
			this.ClearTags();
			for (int i = 0; i < pEvent.m_tags.Count(); ++i)
			{
				char tag[64];
				PtrToString(Deref(pEvent.m_tags.Get(i)), tag, sizeof(tag));
				
				this.AddTag(tag);
			}
			
			// Request to Add in Endless
			if (g_pPopulationManager.IsInEndlessWaves())
			{
				g_pPopulationManager.EndlessSetAttributesForBot(this.index);
			}
		}
	}
	
	public void AddItem(const char[] szItemName)
	{
		int itemDefIndex = GetItemDefinitionIndexByName(szItemName);
		
		Handle item = GenerateItem(this.index, itemDefIndex);
		if (item)
		{
			// If we already have an item in that slot, remove it
			TFClassType class = TF2_GetPlayerClass(this.index);
			int slot = TF2Econ_GetItemLoadoutSlot(itemDefIndex, class);
			int newItemRegionMask = TF2Econ_GetItemEquipRegionMask(itemDefIndex);
			
			if (IsWearableSlot(slot))
			{
				// Remove any wearable that has a conflicting equip_region
				for (int wbl = 0; wbl < TF2Util_GetPlayerWearableCount(this.index); wbl++)
				{
					int pWearable = TF2Util_GetPlayerWearable(this.index, wbl);
					if (pWearable == -1)
						continue;
					
					int wearableDefIndex = GetEntProp(pWearable, Prop_Send, "m_iItemDefinitionIndex");
					if (wearableDefIndex == INVALID_ITEM_DEF_INDEX)
						continue;
					
					int wearableRegionMask = TF2Econ_GetItemEquipRegionMask(wearableDefIndex);
					if (wearableRegionMask & newItemRegionMask)
					{
						TF2_RemoveWearable(this.index, pWearable);
					}
				}
			}
			else
			{
				int entity = TF2Util_GetPlayerLoadoutEntity(this.index, slot);
				if (entity != -1)
				{
					RemovePlayerItem(this.index, entity);
					RemoveEntity(entity);
				}
			}
			
			int newItem = TF2Items_GiveNamedItem(this.index, item);
			if (newItem != -1)
			{
				if (TF2Util_IsEntityWearable(newItem))
				{
					TF2Util_EquipPlayerWearable(this.index, newItem);
				}
				else
				{
					EquipPlayerWeapon(this.index, newItem);
				}
			}
			
			SDKCall_PostInventoryApplication(this.index);
		}
		else
		{
			if (szItemName[0])
			{
				LogError("CTFBotSpawner::AddItemToBot: Invalid item %s.", szItemName);
			}
		}
		delete item;
	}
	
	public bool IsWeaponRestricted(int weapon)
	{
		if (weapon == -1)
		{
			return false;
		}
		
		if (TF2Util_IsEntityWearable(weapon))
		{
			// Always allow wearable weapons
			return false;
		}
		else
		{
			int weaponId = TF2Util_GetWeaponID(weapon);
			if (weaponId == TF_WEAPON_BUFF_ITEM || weaponId == TF_WEAPON_LUNCHBOX || weaponId == TF_WEAPON_PARACHUTE || weaponId == TF_WEAPON_GRAPPLINGHOOK)
			{
				// Always allow specific passive weapons
				return false;
			}
			else if (TF2Attrib_HookValueInt(0, "is_passive_weapon", weapon))
			{
				// Always allow weapons with is_passive_weapon attribute
				return false;
			}
		}
		
		// Get the weapon's loadout slot
		int itemdef = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		int iLoadoutSlot = TF2Econ_GetItemLoadoutSlot(itemdef, TF2_GetPlayerClass(this.index));
		
		if (this.HasWeaponRestriction(MELEE_ONLY))
		{
			return (iLoadoutSlot != LOADOUT_POSITION_MELEE);
		}
		
		if (this.HasWeaponRestriction(PRIMARY_ONLY))
		{
			return (iLoadoutSlot != LOADOUT_POSITION_PRIMARY);
		}
		
		if (this.HasWeaponRestriction(SECONDARY_ONLY))
		{
			return (iLoadoutSlot != LOADOUT_POSITION_SECONDARY);
		}
		
		return false;
	}
	
	public bool EquipRequiredWeapon()
	{
		if (this.HasWeaponRestriction(MELEE_ONLY))
		{
			// force use of melee weapons
			SDKCall_WeaponSwitch(this.index, GetPlayerWeaponSlot(this.index, TFWeaponSlot_Melee));
			return true;
		}
		
		if (this.HasWeaponRestriction(PRIMARY_ONLY))
		{
			SDKCall_WeaponSwitch(this.index, GetPlayerWeaponSlot(this.index, TFWeaponSlot_Primary));
			return true;
		}
		
		if (this.HasWeaponRestriction(SECONDARY_ONLY))
		{
			SDKCall_WeaponSwitch(this.index, GetPlayerWeaponSlot(this.index, TFWeaponSlot_Secondary));
			return true;
		}
		
		return false;
	}
	
	public bool IsBarrageAndReloadWeapon(int weapon)
	{
		if (weapon == MY_CURRENT_GUN)
		{
			weapon = this.GetPropEnt(Prop_Send, "m_hActiveWeapon");
		}
		
		if (weapon)
		{
			switch (TF2Util_GetWeaponID(weapon))
			{
				case TF_WEAPON_ROCKETLAUNCHER, TF_WEAPON_DIRECTHIT, TF_WEAPON_GRENADELAUNCHER, TF_WEAPON_PIPEBOMBLAUNCHER, TF_WEAPON_SCATTERGUN:
				{
					return true;
				}
			}
		}
		
		return false;
	}
	
	public int GetFlagToFetch()
	{
		int nCarriedFlags = 0;
		
		// MvM Engineer bot never pick up a flag
		if (IsMannVsMachineMode())
		{
			if (TF2_GetClientTeam(this.index) == TFTeam_Invaders && TF2_GetPlayerClass(this.index) == TFClass_Engineer)
			{
				return INVALID_ENT_REFERENCE;
			}
			
			if (this.HasAttribute(IGNORE_FLAG))
			{
				return INVALID_ENT_REFERENCE;
			}
			
			if (IsMannVsMachineMode() && this.HasFlagTarget())
			{
				return this.GetFlagTarget();
			}
		}
		
		ArrayList flagsList = new ArrayList();
		
		// Collect flags
		int flag = -1;
		while ((flag = FindEntityByClassname(flag, "item_teamflag")) != -1)
		{
			if (GetEntProp(flag, Prop_Send, "m_bDisabled"))
				continue;
			
			// If I'm carrying a flag, look for mine and early-out
			if (HasTheFlag(this.index))
			{
				if (GetEntPropEnt(flag, Prop_Send, "m_hOwnerEntity") == this.index)
				{
					delete flagsList;
					return EntIndexToEntRef(flag);
				}
			}
			
			switch (view_as<ETFFlagType>(GetEntProp(flag, Prop_Send, "m_nType")))
			{
				case TF_FLAGTYPE_CTF:
				{
					if (view_as<TFTeam>(GetEntProp(flag, Prop_Send, "m_iTeamNum")) == GetEnemyTeam(TF2_GetClientTeam(this.index)))
					{
						// we want to steal the other team's flag
						flagsList.Push(flag);
					}
				}
				
				case TF_FLAGTYPE_ATTACK_DEFEND, TF_FLAGTYPE_TERRITORY_CONTROL, TF_FLAGTYPE_INVADE:
				{
					if (view_as<TFTeam>(GetEntProp(flag, Prop_Send, "m_iTeamNum")) != GetEnemyTeam(TF2_GetClientTeam(this.index)))
					{
						// we want to move our team's flag or a neutral flag
						flagsList.Push(flag);
					}
				}
			}
			
			if (GetEntProp(flag, Prop_Send, "m_nFlagStatus") == TF_FLAGINFO_STOLEN)
			{
				nCarriedFlags++;
			}
		}
		
		int closestFlag = INVALID_ENT_REFERENCE;
		float flClosestFlagDist = FLT_MAX;
		int closestUncarriedFlag = INVALID_ENT_REFERENCE;
		float flClosestUncarriedFlagDist = FLT_MAX;
		
		if (IsMannVsMachineMode())
		{
			for (int i = 0; i < flagsList.Length; i++)
			{
				if (IsValidEntity(flagsList.Get(i)))
				{
					// Find the closest
					float flagOrigin[3], playerOrigin[3];
					GetEntPropVector(flagsList.Get(i), Prop_Data, "m_vecAbsOrigin", flagOrigin);
					this.GetAbsOrigin(playerOrigin);
					
					float origins[3];
					SubtractVectors(flagOrigin, playerOrigin, origins);
					
					float flDist = GetVectorLength(origins, true);
					if (flDist < flClosestFlagDist)
					{
						closestFlag = EntIndexToEntRef(flagsList.Get(i));
						flClosestFlagDist = flDist;
					}
					
					// Find the closest uncarried
					if (nCarriedFlags < flagsList.Length && GetEntProp(flagsList.Get(i), Prop_Send, "m_nFlagStatus") != TF_FLAGINFO_STOLEN)
					{
						if (flDist < flClosestUncarriedFlagDist)
						{
							closestUncarriedFlag = EntIndexToEntRef(flagsList.Get(i));
							flClosestUncarriedFlagDist = flDist;
						}
					}
				}
			}
		}
		
		delete flagsList;
		
		// If we have an uncarried flag, prioritize
		if (closestUncarriedFlag != INVALID_ENT_REFERENCE)
			return closestUncarriedFlag;
		
		return closestFlag;
	}
	
	public int GetFlagCaptureZone()
	{
		int zone = -1;
		while ((zone = FindEntityByClassname(zone, "func_capturezone")) != -1)
		{
			if (GetEntProp(zone, Prop_Data, "m_iTeamNum") == GetClientTeam(this.index))
			{
				return zone;
			}
		}
		
		return -1;
	}
	
	public float CalculateSpawnTime()
	{
		// factor in squad speed
		float flSpeed = this.IsInASquad() ? this.GetSquad().GetSlowestMemberSpeed() : this.GetPropFloat(Prop_Send, "m_flMaxspeed");
		float flTime = mitm_min_spawn_hurry_time.FloatValue * (400.0 / flSpeed);
		return Clamp(flTime, mitm_min_spawn_hurry_time.FloatValue, mitm_max_spawn_hurry_time.FloatValue);
	}
	
	public bool ShouldAutoJump()
	{
		if (!this.HasAttribute(AUTO_JUMP))
			return false;
		
		if (!m_autoJumpTimer[this.index].HasStarted())
		{
			m_autoJumpTimer[this.index].Start(GetRandomFloat(this.m_flAutoJumpMin, this.m_flAutoJumpMax));
			return true;
		}
		else if (m_autoJumpTimer[this.index].IsElapsed())
		{
			m_autoJumpTimer[this.index].Start(GetRandomFloat(this.m_flAutoJumpMin, this.m_flAutoJumpMax));
			return true;
		}
		
		return false;
	}
	
	public int GetClosestCaptureZone()
	{
		int captureZone = -1;
		float flClosestDistance = FLT_MAX;
		
		int tempCaptureZone = -1;
		while ((tempCaptureZone = FindEntityByClassname(tempCaptureZone, "func_capturezone")) != -1)
		{
			if (!GetEntProp(tempCaptureZone, Prop_Data, "m_bDisabled") && GetEntProp(tempCaptureZone, Prop_Data, "m_iTeamNum") == GetClientTeam(this.index))
			{
				float origin[3], center[3];
				this.GetAbsOrigin(origin);
				CBaseEntity(tempCaptureZone).WorldSpaceCenter(center);
				
				float fCurrentDistance = GetVectorDistance(origin, center);
				if (flClosestDistance > fCurrentDistance)
				{
					captureZone = tempCaptureZone;
					flClosestDistance = fCurrentDistance;
				}
			}
		}
		
		return captureZone;
	}
	
	public void DisguiseAsMemberOfEnemyTeam()
	{
		ArrayList enemyList = new ArrayList();
		
		for (int client = 1; client <= MaxClients; client++)
		{
			if (!IsClientInGame(client))
				continue;
			
			if (GetClientTeam(client) == GetClientTeam(this.index))
				continue;
			
			enemyList.Push(client);
		}
		
		TFClassType disguise = view_as<TFClassType>(GetRandomInt(view_as<int>(TFClass_Scout), view_as<int>(TFClass_Engineer)));
		
		if (enemyList.Length > 0)
		{
			disguise = TF2_GetPlayerClass(enemyList.Get(GetRandomInt(0, enemyList.Length - 1)));
		}
		
		TF2_DisguisePlayer(this.index, GetEnemyTeam(TF2_GetClientTeam(this.index)), disguise);
		delete enemyList;
	}
	
	public bool HasPreference(PreferenceType preference)
	{
		return this.m_preferences != -1 && this.m_preferences & view_as<int>(preference) != 0;
	}
	
	public bool SetPreference(PreferenceType preference, bool enable)
	{
		if (this.m_preferences == -1)
			return false;
		
		if (enable)
			this.m_preferences |= view_as<int>(preference);
		else
			this.m_preferences &= ~view_as<int>(preference);
		
		ClientPrefs_SavePreferences(this.index, this.m_preferences);
		
		return true;
	}
	
	public void MarkAsMissionEnemy()
	{
		SetEntData(this.index, GetOffset("CTFPlayer::m_bIsMissionEnemy"), true, 1);
	}
	
	public void MarkAsSupportEnemy()
	{
		SetEntData(this.index, GetOffset("CTFPlayer::m_bIsSupportEnemy"), true, 1);
	}
	
	public void MarkAsLimitedSupportEnemy()
	{
		SetEntData(this.index, GetOffset("CTFPlayer::m_bIsLimitedSupportEnemy"), true, 1);
	}
	
	public CTFBotSquad GetSquad()
	{
		return this.m_squad;
	}
	
	public void JoinSquad(CTFBotSquad squad)
	{
		if (squad)
		{
			squad.Join(this.index);
			this.m_squad = squad;
		}
	}
	
	public void LeaveSquad()
	{
		if (this.m_squad)
		{
			this.m_squad.Leave(this.index);
			this.m_squad = NULL_SQUAD;
		}
	}
	
	public bool IsInASquad()
	{
		return this.m_squad == NULL_SQUAD ? false : true;
	}
	
	public void DeleteSquad()
	{
		if (this.m_squad)
		{
			this.m_squad = NULL_SQUAD;
		}
	}
	
	public Party GetParty()
	{
		return this.m_party;
	}
	
	public void InviteToParty(Party party)
	{
		if (party)
		{
			party.AddInvite(this.index);
		}
	}
	
	public void JoinParty(Party party)
	{
		if (party)
		{
			party.Join(this.index);
			this.m_party = party;
		}
	}
	
	public void LeaveParty()
	{
		if (this.m_party)
		{
			this.m_party.Leave(this.index);
			this.m_party = NULL_PARTY;
		}
	}
	
	public bool IsInAParty()
	{
		return this.m_party == NULL_PARTY ? false : true;
	}
	
	public void DeleteParty()
	{
		if (this.m_party)
		{
			this.m_party = NULL_PARTY;
		}
	}
	
	public bool IsPartyMenuActive()
	{
		return this.m_bIsPartyMenuActive;
	}
	
	public void SetPartyMenuActive(bool bIsPartyMenuActive)
	{
		this.m_bIsPartyMenuActive = bIsPartyMenuActive;
	}
	
	public void Init()
	{
		this.m_autoJumpTimer = new CountdownTimer();
		this.m_teleportWhereName = new ArrayList(ByteCountToCells(64));
		this.m_eventChangeAttributes = new ArrayList();
		this.m_tags = new ArrayList(ByteCountToCells(64));
	}
	
	public void ResetOnTeamChange()
	{
		this.SetAutoJump(0.0, 0.0);
		this.m_autoJumpTimer.Invalidate();
		
		this.ClearTeleportWhere();
		this.ClearEventChangeAttributes();
		this.ClearTags();
		this.ClearWeaponRestrictions();
		this.ClearAllAttributes();
		this.ClearIdleSound();
		this.m_fModelScaleOverride = 0.0;
		this.m_flSpawnTimeLeft = -1.0;
		this.m_missionTarget = INVALID_ENT_REFERENCE;
		this.m_spawnPointEntity = INVALID_ENT_REFERENCE;
		this.m_hFollowingFlagTarget = INVALID_ENT_REFERENCE;
	}
	
	public void Reset()
	{
		this.ResetOnTeamChange();
		
		this.m_invaderPriority = 0;
		this.m_bWasMiniBoss = false;
		this.m_defenderQueuePoints = -1;
		this.m_preferences = -1;
		this.m_party = NULL_PARTY;
		this.m_bIsPartyMenuActive = false;
		
		m_szInvaderName[this.index][0] = EOS;
		m_szPrevName[this.index][0] = EOS;
	}
}

methodmap EventChangeAttributes_t
{
	public EventChangeAttributes_t(Address address)
	{
		return view_as<EventChangeAttributes_t>(address);
	}
	
	property Address m_eventName
	{
		public get()
		{
			return Deref(this + GetOffset("EventChangeAttributes_t::m_eventName"));
		}
	}
	
	property DifficultyType m_skill
	{
		public get()
		{
			return Deref(this + GetOffset("EventChangeAttributes_t::m_skill"));
		}
	}
	
	property WeaponRestrictionType m_weaponRestriction
	{
		public get()
		{
			return Deref(this + GetOffset("EventChangeAttributes_t::m_weaponRestriction"));
		}
	}
	
	property MissionType m_mission
	{
		public get()
		{
			return Deref(this + GetOffset("EventChangeAttributes_t::m_mission"));
		}
	}
	
	property any m_attributeFlags
	{
		public get()
		{
			return Deref(this + GetOffset("EventChangeAttributes_t::m_attributeFlags"));
		}
	}
	
	property CUtlVector m_items
	{
		public get()
		{
			return CUtlVector(this + GetOffset("EventChangeAttributes_t::m_items"));
		}
	}
	
	property CUtlVector m_itemsAttributes
	{
		public get()
		{
			return CUtlVector(this + GetOffset("EventChangeAttributes_t::m_itemsAttributes"));
		}
	}
	
	property CUtlVector m_characterAttributes
	{
		public get()
		{
			return CUtlVector(this + GetOffset("EventChangeAttributes_t::m_characterAttributes"));
		}
	}
	
	property CUtlVector m_tags
	{
		public get()
		{
			return CUtlVector(this + GetOffset("EventChangeAttributes_t::m_tags"));
		}
	}
};

methodmap CTFBotSpawner
{
	public CTFBotSpawner(Address spawner)
	{
		return view_as<CTFBotSpawner>(spawner);
	}
	
	property EventChangeAttributes_t m_defaultAttributes
	{
		public get()
		{
			return view_as<EventChangeAttributes_t>(this + GetOffset("CTFBotSpawner::m_defaultAttributes"));
		}
	}
	
	property CUtlVector m_eventChangeAttributes
	{
		public get()
		{
			return CUtlVector(this + GetOffset("CTFBotSpawner::m_eventChangeAttributes"));
		}
	}
	
	property int m_health
	{
		public get()
		{
			return Deref(this + GetOffset("CTFBotSpawner::m_health"));
		}
	}
	
	property TFClassType m_class
	{
		public get()
		{
			return Deref(this + GetOffset("CTFBotSpawner::m_class"));
		}
	}
	
	property float m_scale
	{
		public get()
		{
			return Deref(this + GetOffset("CTFBotSpawner::m_scale"));
		}
	}
	
	property float m_flAutoJumpMin
	{
		public get()
		{
			return Deref(this + GetOffset("CTFBotSpawner::m_flAutoJumpMin"));
		}
	}
	
	property float m_flAutoJumpMax
	{
		public get()
		{
			return Deref(this + GetOffset("CTFBotSpawner::m_flAutoJumpMax"));
		}
	}
	
	property CUtlVector m_teleportWhereName
	{
		public get()
		{
			return CUtlVector(this + GetOffset("CTFBotSpawner::m_teleportWhereName"));
		}
	}
	
	public void GetName(char[] buffer, int maxlen, const char[] defValue = "")
	{
		Address m_name = Deref(this + GetOffset("CTFBotSpawner::m_name"));
		if (m_name)
		{
			PtrToString(m_name, buffer, maxlen);
		}
		else if (defValue[0])
		{
			strcopy(buffer, maxlen, defValue);
		}
	}
	
	public Address GetClassIcon(int nSpawnNum = -1)
	{
		return Deref(SDKCall_GetClassIcon(this, nSpawnNum));
	}
};

methodmap CSquadSpawner
{
	public CSquadSpawner(Address address)
	{
		return view_as<CSquadSpawner>(address);
	}
	
	property float m_formationSize
	{
		public get()
		{
			return Deref(this + GetOffset("CSquadSpawner::m_formationSize"));
		}
	}
	
	property bool m_bShouldPreserveSquad
	{
		public get()
		{
			return Deref(this + GetOffset("CSquadSpawner::m_bShouldPreserveSquad"));
		}
	}
}

methodmap CMissionPopulator
{
	public CMissionPopulator(Address address)
	{
		return view_as<CMissionPopulator>(address);
	}
	
	property MissionType m_mission
	{
		public get()
		{
			return Deref(this + GetOffset("CMissionPopulator::m_mission"));
		}
	}
	
	property float m_cooldownDuration
	{
		public get()
		{
			return Deref(this + GetOffset("CMissionPopulator::m_cooldownDuration"));
		}
	}
	
	property Address m_spawner
	{
		public get()
		{
			return Deref(this + GetOffset("IPopulationSpawner::m_spawner"));
		}
	}
	
	property Address m_where
	{
		public get()
		{
			return view_as<Address>(this) + GetOffset("IPopulationSpawner::m_where");
		}
	}
}

methodmap CWave
{
	public CWave(Address address)
	{
		return view_as<CWave>(address);
	}
	
	property int m_nNumEngineersTeleportSpawned
	{
		public get()
		{
			return Deref(this + GetOffset("CWave::m_nNumEngineersTeleportSpawned"));
		}
		public set(int nNumEngineersTeleportSpawned)
		{
			WriteVal(this + GetOffset("CWave::m_nNumEngineersTeleportSpawned"), nNumEngineersTeleportSpawned);
		}
	}
	
	property int m_nNumSentryBustersKilled
	{
		public get()
		{
			return Deref(this + GetOffset("CWave::m_nNumSentryBustersKilled"));
		}
		public set(int nNumSentryBustersKilled)
		{
			WriteVal(this + GetOffset("CWave::m_nNumSentryBustersKilled"), nNumSentryBustersKilled);
		}
	}
	
	property int m_nSentryBustersSpawned
	{
		public get()
		{
			return Deref(this + GetOffset("CWave::m_nSentryBustersSpawned"));
		}
		public set(int nSentryBustersSpawned)
		{
			WriteVal(this + GetOffset("CWave::m_nSentryBustersSpawned"), nSentryBustersSpawned);
		}
	}
	
	public int NumSentryBustersSpawned()
	{
		return this.m_nSentryBustersSpawned;
	}
	
	public void IncrementSentryBustersSpawned()
	{
		this.m_nSentryBustersSpawned++;
	}
	
	public int NumSentryBustersKilled()
	{
		return this.m_nNumSentryBustersKilled;
	}
	
	public void IncrementSentryBustersKilled()
	{
		this.m_nNumSentryBustersKilled++;
	}
	
	public void ResetSentryBustersKilled()
	{
		this.m_nNumSentryBustersKilled = 0;
	}
	
	public int NumEngineersTeleportSpawned()
	{
		return this.m_nNumEngineersTeleportSpawned;
	}
	
	public void IncrementEngineerTeleportSpawned()
	{
		this.m_nNumEngineersTeleportSpawned++;
	}
}

methodmap CPopulationManager < CBaseEntity
{
	public CPopulationManager(int entity)
	{
		return view_as<CPopulationManager>(entity);
	}
	
	property bool m_canBotsAttackWhileInSpawnRoom
	{
		public get()
		{
			return GetEntData(this.index, GetOffset("CPopulationManager::m_canBotsAttackWhileInSpawnRoom"), 1) != 0;
		}
	}
	
	property bool m_bSpawningPaused
	{
		public get()
		{
			return GetEntData(this.index, GetOffset("CPopulationManager::m_bSpawningPaused"), 1) != 0;
		}
	}
	
	property Address m_defaultEventChangeAttributesName
	{
		public get()
		{
			return view_as<Address>(GetEntData(this.index, GetOffset("CPopulationManager::m_defaultEventChangeAttributesName")));
		}
	}
	
	property CUtlVector m_EndlessActiveBotUpgrades
	{
		public get()
		{
			return CUtlVector(GetEntityAddress(this.index) + GetOffset("CPopulationManager::m_EndlessActiveBotUpgrades"));
		}
	}
	
	public bool CanBotsAttackWhileInSpawnRoom()
	{
		return this.m_canBotsAttackWhileInSpawnRoom;
	}
	
	public bool IsSpawningPaused()
	{
		return this.m_bSpawningPaused;
	}
	
	public Address GetDefaultEventChangeAttributesName()
	{
		return this.m_defaultEventChangeAttributesName;
	}
	
	public void ResetMap()
	{
		SDKCall_ResetMap(this.index);
	}
	
	public CWave GetCurrentWave()
	{
		return CWave(SDKCall_GetCurrentWave(this.index));
	}
	
	public bool IsInEndlessWaves()
	{
		return SDKCall_IsInEndlessWaves(this.index);
	}
	
	public float GetHealthMultiplier(bool bIsTank = false)
	{
		return SDKCall_GetHealthMultiplier(this.index, bIsTank);
	}
	
	public void GetSentryBusterDamageAndKillThreshold(int &nDamage, int &nKills)
	{
		SDKCall_GetSentryBusterDamageAndKillThreshold(this.index, nDamage, nKills);
	}
	
	public void EndlessSetAttributesForBot(int player)
	{
		int nHealth = GetEntProp(player, Prop_Data, "m_iHealth");
		int nMaxHealth = TF2Util_GetEntityMaxHealth(player);
		
		for (int i = 0; i < this.m_EndlessActiveBotUpgrades.Count(); ++i)
		{
			CMvMBotUpgrade upgrade = this.m_EndlessActiveBotUpgrades.Get(i, GetOffset("sizeof(CMvMBotUpgrade)"));
			
			if (upgrade.bIsBotAttr == true)
			{
				Player(player).SetAttribute(view_as<AttributeType>(RoundFloat(upgrade.flValue)));
			}
			else if (upgrade.bIsSkillAttr == true)
			{
				Player(player).SetDifficulty(view_as<DifficultyType>(RoundFloat(upgrade.flValue)));
			}
			else
			{
				Address pDef = TF2Econ_GetAttributeDefinitionAddress(upgrade.iAttribIndex);
				if (pDef)
				{
					Address pAttrib = TF2Attrib_GetByDefIndex(player, upgrade.iAttribIndex);
					if (pAttrib)
					{
						TF2Attrib_SetValue(pAttrib, TF2Attrib_GetValue(pAttrib) + upgrade.flValue);
					}
					else
					{
						int iFormat = Deref(pDef + GetOffset("CEconItemAttributeDefinition::m_iDescriptionFormat"));
						float flValue = upgrade.flValue;
						if (iFormat == ATTDESCFORM_VALUE_IS_PERCENTAGE || iFormat == ATTDESCFORM_VALUE_IS_INVERTED_PERCENTAGE)
						{
							flValue += 1.0;
						}
						TF2Attrib_SetByDefIndex(player, upgrade.iAttribIndex, flValue);
					}
				}
			}
		}
		
		int nNewMaxHealth = TF2Util_GetEntityMaxHealth(player);
		SetEntProp(player, Prop_Data, "m_iHealth", nHealth + nNewMaxHealth - nMaxHealth);
	}
}

methodmap BombInfo_t
{
	public BombInfo_t(Address pThis)
	{
		return view_as<BombInfo_t>(pThis);
	}
	
	property float m_flMaxBattleFront
	{
		public get()
		{
			return Deref(this + GetOffset("BombInfo_t::m_flMaxBattleFront"));
		}
	}
}

methodmap CBaseTFBotHintEntity < CBaseEntity
{
	public CBaseTFBotHintEntity(int entity)
	{
		return view_as<CBaseTFBotHintEntity>(entity);
	}
	
	property bool m_isDisabled
	{
		public get()
		{
			return GetEntData(this.index, GetOffset("CBaseTFBotHintEntity::m_isDisabled"), 1) != 0;
		}
	}
	
	public bool IsEnabled()
	{
		return !this.m_isDisabled;
	}
	
	public bool OwnerObjectHasNoOwner()
	{
		int owner = this.GetPropEnt(Prop_Send, "m_hOwnerEntity");
		if (owner != -1 && IsBaseObject(owner))
		{
			if (GetEntPropEnt(owner, Prop_Send, "m_hBuilder") == -1)
			{
				return true;
			}
			else
			{
				if (TF2_GetPlayerClass(GetEntPropEnt(owner, Prop_Send, "m_hBuilder")) != TFClass_Engineer)
				{
					LogError("Object has an owner that's not engineer.");
				}
			}
		}
		return false;
	}
	
	public bool OwnerObjectFinishBuilding()
	{
		int owner = this.GetPropEnt(Prop_Send, "m_hOwnerEntity");
		if (owner != -1 && IsBaseObject(owner))
		{
			return !GetEntProp(owner, Prop_Send, "m_bBuilding");
		}
		return false;
	}
}

methodmap CWaveSpawnPopulator
{
	public CWaveSpawnPopulator(Address pThis)
	{
		return view_as<CWaveSpawnPopulator>(pThis);
	}
	
	property bool m_bSupportWave
	{
		public get()
		{
			return Deref(this + GetOffset("CWaveSpawnPopulator::m_bSupportWave"), NumberType_Int8);
		}
	}
	
	property bool m_bLimitedSupport
	{
		public get()
		{
			return Deref(this + GetOffset("CWaveSpawnPopulator::m_bLimitedSupport"), NumberType_Int8);
		}
	}
	
	public bool IsSupportWave()
	{
		return this.m_bSupportWave;
	}
	
	public bool IsLimitedSupportWave()
	{
		return this.m_bLimitedSupport;
	}
}

methodmap CMvMBotUpgrade
{
	public CMvMBotUpgrade(Address pThis)
	{
		return view_as<CMvMBotUpgrade>(pThis);
	}
	
	property Address szAttrib
	{
		public get()
		{
			return view_as<Address>(this + GetOffset("CMvMBotUpgrade::szAttrib"));
		}
	}
	
	property int iAttribIndex
	{
		public get()
		{
			return Deref(this + GetOffset("CMvMBotUpgrade::iAttribIndex"), NumberType_Int16);
		}
	}
	
	property float flValue
	{
		public get()
		{
			return Deref(this + GetOffset("CMvMBotUpgrade::flValue"));
		}
	}
	
	property bool bIsBotAttr
	{
		public get()
		{
			return Deref(this + GetOffset("CMvMBotUpgrade::bIsBotAttr"), NumberType_Int8);
		}
	}
	
	property bool bIsSkillAttr
	{
		public get()
		{
			return Deref(this + GetOffset("CMvMBotUpgrade::bIsSkillAttr"), NumberType_Int8);
		}
	}
}

methodmap CTFObjectiveResource < CBaseEntity
{
	public CTFObjectiveResource(int entity)
	{
		return view_as<CTFObjectiveResource>(entity);
	}
	
	public void SetFlagCarrierUpgradeLevel(int nLevel)
	{
		this.SetProp(Prop_Send, "m_nFlagCarrierUpgradeLevel", nLevel);
	}
	
	public void SetBaseMvMBombUpgradeTime(float nTime)
	{
		this.SetPropFloat(Prop_Send, "m_flMvMBaseBombUpgradeTime", nTime);
	}
	
	public void SetNextMvMBombUpgradeTime(float nTime)
	{
		this.SetPropFloat(Prop_Send, "m_flMvMNextBombUpgradeTime", nTime);
	}
	
	public bool GetMannVsMachineIsBetweenWaves()
	{
		return this.GetProp(Prop_Send, "m_bMannVsMachineBetweenWaves") != 0;
	}
	
	public void IncrementMannVsMachineWaveClassCount(any iszClassIconName, int iFlags)
	{
		for (int i = 0; i < this.GetPropArraySize(Prop_Send, "m_iszMannVsMachineWaveClassNames"); ++i)
		{
			if (GetEntData(this.index, FindSendPropInfo("CTFObjectiveResource", "m_iszMannVsMachineWaveClassNames") + (i * 4)) == iszClassIconName && (this.GetProp(Prop_Send, "m_nMannVsMachineWaveClassFlags", _, i) & iFlags))
			{
				this.SetProp(Prop_Send, "m_nMannVsMachineWaveClassCounts", this.GetProp(Prop_Send, "m_nMannVsMachineWaveClassCounts", _, i) + 1, _, i);
				
				if (this.GetProp(Prop_Send, "m_nMannVsMachineWaveClassCounts", _, i) <= 0)
				{
					this.SetProp(Prop_Send, "m_nMannVsMachineWaveClassCounts", 1, _, i);
				}
				
				return;
			}
		}
		
		for (int i = 0; i < this.GetPropArraySize(Prop_Send, "m_iszMannVsMachineWaveClassNames2"); ++i)
		{
			if (GetEntData(this.index, FindSendPropInfo("CTFObjectiveResource", "m_iszMannVsMachineWaveClassNames2") + (i * 4)) == iszClassIconName && (this.GetProp(Prop_Send, "m_nMannVsMachineWaveClassFlags2", _, i) & iFlags))
			{
				this.SetProp(Prop_Send, "m_nMannVsMachineWaveClassCounts2", this.GetProp(Prop_Send, "m_nMannVsMachineWaveClassCounts2", _, i) + 1, _, i);
				
				if (this.GetProp(Prop_Send, "m_nMannVsMachineWaveClassCounts2", _, i) <= 0)
				{
					this.SetProp(Prop_Send, "m_nMannVsMachineWaveClassCounts2", 1, _, i);
				}
				
				return;
			}
		}
	}
	
	public void SetMannVsMachineWaveClassActive(any iszClassIconName, bool bActive = true)
	{
		for (int i = 0; i < this.GetPropArraySize(Prop_Send, "m_iszMannVsMachineWaveClassNames"); ++i)
		{
			if (GetEntData(this.index, FindSendPropInfo("CTFObjectiveResource", "m_iszMannVsMachineWaveClassNames") + (i * 4)) == iszClassIconName)
			{
				this.SetProp(Prop_Send, "m_bMannVsMachineWaveClassActive", bActive, _, i);
				return;
			}
		}
		
		for (int i = 0; i < this.GetPropArraySize(Prop_Send, "m_iszMannVsMachineWaveClassNames2"); ++i)
		{
			if (GetEntData(this.index, FindSendPropInfo("CTFObjectiveResource", "m_iszMannVsMachineWaveClassNames2") + (i * 4)) == iszClassIconName)
			{
				this.SetProp(Prop_Send, "m_bMannVsMachineWaveClassActive2", bActive, _, i);
				return;
			}
		}
	}
	
	public TFTeam GetOwningTeam(int index)
	{
		if (index >= this.GetProp(Prop_Send, "m_iNumControlPoints"))
			return TFTeam_Unassigned;
		
		return view_as<TFTeam>(this.GetProp(Prop_Send, "m_iOwner", _, index));
	}
}

methodmap CMannVsMachineStats < CBaseEntity
{
	public CMannVsMachineStats(int entity)
	{
		return view_as<CMannVsMachineStats>(entity);
	}
	
	public int GetCurrentWave()
	{
		return this.GetProp(Prop_Send, "m_iCurrentWaveIdx");
	}
}
