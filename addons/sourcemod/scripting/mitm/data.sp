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
static float m_flRequiredSpawnLeaveTime[MAXPLAYERS + 1];
static int m_spawnPointEntity[MAXPLAYERS + 1];
static CTFBotSquad m_squad[MAXPLAYERS + 1];
static int m_hFollowingFlagTarget[MAXPLAYERS + 1];
static BombDeployingState_t m_nDeployingBombState[MAXPLAYERS + 1];
static char m_szOldClientName[MAXPLAYERS + 1][MAX_NAME_LENGTH];

// Non-resetting Properties
static int m_invaderPriority[MAXPLAYERS + 1];
static bool m_bWasMiniBoss[MAXPLAYERS + 1];
static int m_defenderQueuePoints[MAXPLAYERS + 1];
static int m_preferences[MAXPLAYERS + 1];
static Party m_party[MAXPLAYERS + 1];

methodmap Player
{
	public Player(int client)
	{
		return view_as<Player>(client);
	}
	
	property int _client
	{
		public get()
		{
			return view_as<int>(this);
		}
	}
	
	property float m_flAutoJumpMin
	{
		public get()
		{
			return m_flAutoJumpMin[this._client];
		}
		public set(float flAutoJumpMin)
		{
			m_flAutoJumpMin[this._client] = flAutoJumpMin;
		}
	}
	
	property float m_flAutoJumpMax
	{
		public get()
		{
			return m_flAutoJumpMax[this._client];
		}
		public set(float flAutoJumpMax)
		{
			m_flAutoJumpMax[this._client] = flAutoJumpMax;
		}
	}
	
	property ArrayList m_eventChangeAttributes
	{
		public get()
		{
			return m_eventChangeAttributes[this._client];
		}
		public set(ArrayList attributes)
		{
			m_eventChangeAttributes[this._client] = attributes;
		}
	}
	
	property ArrayList m_tags
	{
		public get()
		{
			return m_tags[this._client];
		}
		public set(ArrayList tags)
		{
			m_tags[this._client] = tags;
		}
	}
	
	property WeaponRestrictionType m_weaponRestrictionFlags
	{
		public get()
		{
			return m_weaponRestrictionFlags[this._client];
		}
		public set(WeaponRestrictionType restrictionFlags)
		{
			m_weaponRestrictionFlags[this._client] = restrictionFlags;
		}
	}
	
	property AttributeType m_attributeFlags
	{
		public get()
		{
			return m_attributeFlags[this._client];
		}
		public set(AttributeType attributeFlag)
		{
			m_attributeFlags[this._client] = attributeFlag;
		}
	}
	
	property float m_fModelScaleOverride
	{
		public get()
		{
			return m_fModelScaleOverride[this._client];
		}
		public set(float fScale)
		{
			m_fModelScaleOverride[this._client] = fScale;
		}
	}
	
	property MissionType m_mission
	{
		public get()
		{
			return m_mission[this._client];
		}
		public set(MissionType mission)
		{
			m_mission[this._client] = mission;
		}
	}
	
	property MissionType m_prevMission
	{
		public get()
		{
			return m_prevMission[this._client];
		}
		public set(MissionType mission)
		{
			m_prevMission[this._client] = mission;
		}
	}
	
	property int m_missionTarget
	{
		public get()
		{
			return m_missionTarget[this._client];
		}
		public set(int missionTarget)
		{
			m_missionTarget[this._client] = missionTarget;
		}
	}
	
	property float m_flRequiredSpawnLeaveTime
	{
		public get()
		{
			return m_flRequiredSpawnLeaveTime[this._client];
		}
		public set(float flSpawnEnterTime)
		{
			m_flRequiredSpawnLeaveTime[this._client] = flSpawnEnterTime;
		}
	}
	
	property int m_spawnPointEntity
	{
		public get()
		{
			return m_spawnPointEntity[this._client];
		}
		public set(int spawnPoint)
		{
			m_spawnPointEntity[this._client] = spawnPoint;
		}
	}
	
	property int m_invaderPriority
	{
		public get()
		{
			return m_invaderPriority[this._client];
		}
		public set(int iPriority)
		{
			m_invaderPriority[this._client] = iPriority;
		}
	}
	
	property bool m_bWasMiniBoss
	{
		public get()
		{
			return m_bWasMiniBoss[this._client];
		}
		public set(bool bWasMiniBoss)
		{
			m_bWasMiniBoss[this._client] = bWasMiniBoss;
		}
	}
	
	property int m_defenderQueuePoints
	{
		public get()
		{
			return m_defenderQueuePoints[this._client];
		}
		public set(int defenderQueuePoints)
		{
			m_defenderQueuePoints[this._client] = defenderQueuePoints;
		}
	}
	
	property int m_preferences
	{
		public get()
		{
			return m_preferences[this._client];
		}
		public set(int preferences)
		{
			m_preferences[this._client] = preferences;
		}
	}
	
	property ArrayList m_teleportWhereName
	{
		public get()
		{
			return m_teleportWhereName[this._client];
		}
		public set(ArrayList teleportWhereName)
		{
			m_teleportWhereName[this._client] = teleportWhereName;
		}
	}
	
	property CTFBotSquad m_squad
	{
		public get()
		{
			return m_squad[this._client];
		}
		public set(CTFBotSquad squad)
		{
			m_squad[this._client] = squad;
		}
	}
	
	property int m_hFollowingFlagTarget
	{
		public get()
		{
			return m_hFollowingFlagTarget[this._client];
		}
		public set(int hFollowingFlagTarget)
		{
			m_hFollowingFlagTarget[this._client] = hFollowingFlagTarget;
		}
	}
	
	property BombDeployingState_t m_nDeployingBombState
	{
		public get()
		{
			return m_nDeployingBombState[this._client];
		}
		public set(BombDeployingState_t nDeployingBombState)
		{
			m_nDeployingBombState[this._client] = nDeployingBombState;
		}
	}
	
	property Party m_party
	{
		public get()
		{
			return m_party[this._client];
		}
		public set(Party party)
		{
			m_party[this._client] = party;
		}
	}
	
	public bool IsInvader()
	{
		if (IsClientSourceTV(this._client))
			return false;
		
		TFTeam team = TF2_GetClientTeam(this._client);
		return (team == TFTeam_Spectator || team == TFTeam_Invaders) && !this.HasPreference(PREF_DISABLE_SPAWNING);
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
		strcopy(buffer, maxlen, m_szIdleSound[this._client]);
	}
	
	public void SetIdleSound(const char[] soundName)
	{
		strcopy(m_szIdleSound[this._client], sizeof(m_szIdleSound[]), soundName);
	}
	
	public void ClearIdleSound()
	{
		this.SetIdleSound("");
	}
	
	public void SetScaleOverride(float fScale)
	{
		this.m_fModelScaleOverride = fScale;
		
		SetModelScale(this._client, this.m_fModelScaleOverride > 0.0 ? this.m_fModelScaleOverride : 1.0);
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
		
		if (GetEntProp(this._client, Prop_Send, "m_bIsMiniBoss"))
		{
			char pszSoundName[PLATFORM_MAX_PATH];
			
			TFClassType class = TF2_GetPlayerClass(this._client);
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
				EmitGameSoundToAll(pszSoundName, this._client);
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
			StopGameSound(this._client, idleSound);
			this.ClearIdleSound();
		}
	}
	
	public void SetName(const char[] name)
	{
		if (GetClientName(this._client, m_szOldClientName[this._client], sizeof(m_szOldClientName[])))
		{
			SetClientName(this._client, name);
		}
	}
	
	public void ResetName()
	{
		if (m_szOldClientName[this._client][0] == EOS)
			return;
		
		SetClientName(this._client, m_szOldClientName[this._client]);
		strcopy(m_szOldClientName[this._client], sizeof(m_szOldClientName[]), "");
	}
	
	public void ModifyMaxHealth(int nNewMaxHealth, bool bSetCurrentHealth = true, bool bAllowModelScaling = true)
	{
		int maxHealth = TF2Util_GetEntityMaxHealth(this._client);
		if (maxHealth != nNewMaxHealth)
		{
			TF2Attrib_SetByName(this._client, "hidden maxhealth non buffed", float(nNewMaxHealth - maxHealth));
		}
		
		if (bSetCurrentHealth)
		{
			SetEntProp(this._client, Prop_Data, "m_iHealth", nNewMaxHealth);
		}
		
		if (bAllowModelScaling && GetEntProp(this._client, Prop_Send, "m_bIsMiniBoss"))
		{
			SetModelScale(this._client, this.m_fModelScaleOverride > 0.0 ? this.m_fModelScaleOverride : tf_mvm_miniboss_scale.FloatValue);
		}
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
	
	public void SetDifficulty(DifficultyType difficulty)
	{
		SetEntProp(this._client, Prop_Send, "m_nBotSkill", difficulty);
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
			int nHealth = GetEntProp(this._client, Prop_Data, "m_iHealth");
			int nMaxHealth = TF2Util_GetEntityMaxHealth(this._client);
			
			// remove any player attributes
			TF2Attrib_RemoveAll(this._client);
			// and add ones that we want specifically
			for (int i = 0; i < pEvent.m_characterAttributes.Count(); i++)
			{
				Address characterAttributes = pEvent.m_characterAttributes.Get(i, 8); // static_attrib_t
				int defIndex = Deref(characterAttributes, NumberType_Int16);
				
				Address pDef = TF2Econ_GetAttributeDefinitionAddress(defIndex);
				if (pDef)
				{
					float flValue = Deref(characterAttributes + view_as<Address>(0x4));
					TF2Attrib_SetByDefIndex(this._client, defIndex, flValue);
				}
			}
			
			// set health back to what it was before we clear bot's attributes
			this.ModifyMaxHealth(nMaxHealth);
			SetEntProp(this._client, Prop_Data, "m_iHealth", nHealth);
			
			// give items to bot before apply attribute changes
			for (int i = 0; i < pEvent.m_items.Count(); i++)
			{
				char item[64];
				PtrToString(Deref(pEvent.m_items.Get(i)), item, sizeof(item));
				
				this.AddItem(item);
			}
			
			for (int i = 0; i < pEvent.m_itemsAttributes.Count(); i++)
			{
				Address itemAttributes = pEvent.m_itemsAttributes.Get(i);
				
				char itemName[64];
				PtrToString(Deref(itemAttributes), itemName, sizeof(itemName));
				
				int itemDef = GetItemDefinitionByName(itemName);
				
				for (int iItemSlot = LOADOUT_POSITION_PRIMARY; iItemSlot < CLASS_LOADOUT_POSITION_COUNT; iItemSlot++)
				{
					int entity = TF2Util_GetPlayerLoadoutEntity(this._client, iItemSlot);
					
					if (entity != -1 && itemDef == GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"))
					{
						CUtlVector m_attributes = CUtlVector(itemAttributes + view_as<Address>(0x8));
						for (int iAtt = 0; iAtt < m_attributes.Count(); ++iAtt)
						{
							Address attrib = m_attributes.Get(iAtt, 8); // item_attributes_t
							
							int defIndex = Deref(attrib, NumberType_Int16);
							float value = Deref(attrib + view_as<Address>(0x4));
							
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
		}
	}
	
	public void AddItem(const char[] pszItemName)
	{
		int defindex = GetItemDefinitionByName(pszItemName);
		
		// If we already have an item in that slot, remove it
		TFClassType class = TF2_GetPlayerClass(this._client);
		int slot = TF2Econ_GetItemLoadoutSlot(defindex, class);
		int newItemRegionMask = TF2Econ_GetItemEquipRegionMask(defindex);
		
		if (IsWearableSlot(slot))
		{
			// Remove any wearable that has a conflicting equip_region
			for (int wbl = 0; wbl < TF2Util_GetPlayerWearableCount(this._client); wbl++)
			{
				int pWearable = TF2Util_GetPlayerWearable(this._client, wbl);
				if (pWearable == -1)
					continue;
				
				int wearableDefindex = GetEntProp(pWearable, Prop_Send, "m_iItemDefinitionIndex");
				if (wearableDefindex == DEFINDEX_UNDEFINED)
					continue;
				
				int wearableRegionMask = TF2Econ_GetItemEquipRegionMask(wearableDefindex);
				
				if (wearableRegionMask & newItemRegionMask)
				{
					TF2_RemoveWearable(this._client, pWearable);
				}
			}
		}
		else
		{
			int entity = TF2Util_GetPlayerLoadoutEntity(this._client, slot);
			if (entity != -1)
			{
				RemovePlayerItem(this._client, entity);
				RemoveEntity(entity);
			}
		}
		
		int item = CreateRobotItem(this._client, defindex);
		
		if (TF2Util_IsEntityWearable(item))
			TF2Util_EquipPlayerWearable(this._client, item);
		else
			EquipPlayerWeapon(this._client, item);
		
		SDKCall_PostInventoryApplication(this._client);
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
			else if (TF2Attrib_GetByName(weapon, "is_passive_weapon"))
			{
				// Always allow weapons with is_passive_weapon attribute
				return false;
			}
		}
		
		// Get the weapon's loadout slot
		int itemdef = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		int iLoadoutSlot = TF2Econ_GetItemLoadoutSlot(itemdef, TF2_GetPlayerClass(this._client));
		
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
			SDKCall_WeaponSwitch(this._client, GetPlayerWeaponSlot(this._client, TFWeaponSlot_Melee));
			return true;
		}
		
		if (this.HasWeaponRestriction(PRIMARY_ONLY))
		{
			SDKCall_WeaponSwitch(this._client, GetPlayerWeaponSlot(this._client, TFWeaponSlot_Primary));
			return true;
		}
		
		if (this.HasWeaponRestriction(SECONDARY_ONLY))
		{
			SDKCall_WeaponSwitch(this._client, GetPlayerWeaponSlot(this._client, TFWeaponSlot_Secondary));
			return true;
		}
		
		return false;
	}
	
	public bool IsBarrageAndReloadWeapon(int weapon)
	{
		if (weapon == MY_CURRENT_GUN)
		{
			weapon = GetEntPropEnt(this._client, Prop_Send, "m_hActiveWeapon");
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
			if (TF2_GetClientTeam(this._client) == TFTeam_Invaders && TF2_GetPlayerClass(this._client) == TFClass_Engineer)
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
		int flag = MaxClients + 1;
		while ((flag = FindEntityByClassname(flag, "item_teamflag")) != -1)
		{
			if (GetEntProp(flag, Prop_Send, "m_bDisabled"))
				continue;
			
			// If I'm carrying a flag, look for mine and early-out
			if (HasTheFlag(this._client))
			{
				if (GetEntPropEnt(flag, Prop_Send, "m_hOwnerEntity") == this._client)
				{
					delete flagsList;
					return EntIndexToEntRef(flag);
				}
			}
			
			switch (view_as<ETFFlagType>(GetEntProp(flag, Prop_Send, "m_nType")))
			{
				case TF_FLAGTYPE_CTF:
				{
					if (view_as<TFTeam>(GetEntProp(flag, Prop_Send, "m_iTeamNum")) == GetEnemyTeam(TF2_GetClientTeam(this._client)))
					{
						// we want to steal the other team's flag
						flagsList.Push(flag);
					}
				}
				
				case TF_FLAGTYPE_ATTACK_DEFEND, TF_FLAGTYPE_TERRITORY_CONTROL, TF_FLAGTYPE_INVADE:
				{
					if (view_as<TFTeam>(GetEntProp(flag, Prop_Send, "m_iTeamNum")) != GetEnemyTeam(TF2_GetClientTeam(this._client)))
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
		float flClosestFlagDist = float(cellmax);
		int closestUncarriedFlag = INVALID_ENT_REFERENCE;
		float flClosestUncarriedFlagDist = float(cellmax);
		
		if (IsMannVsMachineMode())
		{
			for (int i = 0; i < flagsList.Length; i++)
			{
				if (IsValidEntity(flagsList.Get(i)))
				{
					// Find the closest
					float flagOrigin[3], playerOrigin[3];
					GetEntPropVector(flagsList.Get(i), Prop_Data, "m_vecAbsOrigin", flagOrigin);
					GetClientAbsOrigin(this._client, playerOrigin);
					
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
		int zone = MaxClients + 1;
		while ((zone = FindEntityByClassname(zone, "func_capturezone")) != -1)
		{
			if (GetEntProp(zone, Prop_Data, "m_iTeamNum") == GetClientTeam(this._client))
			{
				return zone;
			}
		}
		
		return -1;
	}
	
	public bool ShouldAutoJump()
	{
		if (!this.HasAttribute(AUTO_JUMP))
			return false;
		
		if (!m_autoJumpTimer[this._client].HasStarted())
		{
			m_autoJumpTimer[this._client].Start(GetRandomFloat(this.m_flAutoJumpMin, this.m_flAutoJumpMax));
			return true;
		}
		else if (m_autoJumpTimer[this._client].IsElapsed())
		{
			m_autoJumpTimer[this._client].Start(GetRandomFloat(this.m_flAutoJumpMin, this.m_flAutoJumpMax));
			return true;
		}
		
		return false;
	}
	
	public int GetClosestCaptureZone()
	{
		int captureZone = -1;
		float flClosestDistance = float(cellmax);
		
		int tempCaptureZone = MaxClients + 1;
		while ((tempCaptureZone = FindEntityByClassname(tempCaptureZone, "func_capturezone")) != -1)
		{
			if (!GetEntProp(tempCaptureZone, Prop_Data, "m_bDisabled") && GetEntProp(tempCaptureZone, Prop_Data, "m_iTeamNum") == GetClientTeam(this._client))
			{
				float origin[3], center[3];
				GetClientAbsOrigin(this._client, origin);
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
			
			if (TF2_GetClientTeam(client) == TF2_GetClientTeam(this._client))
				continue;
			
			enemyList.Push(client);
		}
		
		TFClassType disguise = view_as<TFClassType>(GetRandomInt(view_as<int>(TFClass_Scout), view_as<int>(TFClass_Engineer)));
		
		if (enemyList.Length > 0)
		{
			disguise = TF2_GetPlayerClass(enemyList.Get(GetRandomInt(0, enemyList.Length - 1)));
		}
		
		TF2_DisguisePlayer(this._client, GetEnemyTeam(TF2_GetClientTeam(this._client)), disguise);
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
		
		ClientPrefs_SavePreferences(this._client, this.m_preferences);
		
		return true;
	}
	
	public void MarkAsSupportEnemy()
	{
		SetEntData(this._client, GetOffset("CTFPlayer::m_bIsSupportEnemy"), true, 1);
	}
	
	public void MarkAsLimitedSupportEnemy()
	{
		SetEntData(this._client, GetOffset("CTFPlayer::m_bIsLimitedSupportEnemy"), true, 1);
	}
	
	public CTFBotSquad GetSquad()
	{
		return this.m_squad;
	}
	
	public void JoinSquad(CTFBotSquad squad)
	{
		if (squad)
		{
			squad.Join(this._client);
			this.m_squad = squad;
		}
	}
	
	public void LeaveSquad()
	{
		if (this.m_squad)
		{
			this.m_squad.Leave(this._client);
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
			party.AddInvite(this._client);
		}
	}
	
	public void JoinParty(Party party)
	{
		if (party)
		{
			party.Join(this._client);
			this.m_party = party;
		}
	}
	
	public void LeaveParty()
	{
		if (this.m_party)
		{
			this.m_party.Leave(this._client);
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
	
	public void Init()
	{
		this.m_teleportWhereName = new ArrayList(64);
		this.m_eventChangeAttributes = new ArrayList();
		this.m_tags = new ArrayList(64);
	}
	
	public void ResetOnTeamChange()
	{
		this.SetAutoJump(0.0, 0.0);
		m_autoJumpTimer[this._client].Invalidate();
		
		this.ClearTeleportWhere();
		this.ClearEventChangeAttributes();
		this.ClearTags();
		this.ClearWeaponRestrictions();
		this.ClearAllAttributes();
		this.ClearIdleSound();
		this.m_fModelScaleOverride = 0.0;
		this.m_flRequiredSpawnLeaveTime = 0.0;
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
		
		strcopy(m_szOldClientName[this._client], sizeof(m_szOldClientName[]), "");
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
}

methodmap CPopulationManager
{
	public CPopulationManager(int entity)
	{
		return view_as<CPopulationManager>(entity);
	}
	
	property int _index
	{
		public get()
		{
			return view_as<int>(this);
		}
	}
	
	property bool m_canBotsAttackWhileInSpawnRoom
	{
		public get()
		{
			return GetEntData(this._index, GetOffset("CPopulationManager::m_canBotsAttackWhileInSpawnRoom"), 1) != 0;
		}
	}
	
	property bool m_bSpawningPaused
	{
		public get()
		{
			return GetEntData(this._index, GetOffset("CPopulationManager::m_bSpawningPaused"), 1) != 0;
		}
	}
	
	property Address m_defaultEventChangeAttributesName
	{
		public get()
		{
			return view_as<Address>(GetEntData(this._index, GetOffset("CPopulationManager::m_defaultEventChangeAttributesName")));
		}
	}
	
	property CUtlVector m_EndlessActiveBotUpgrades
	{
		public get()
		{
			return CUtlVector(GetEntityAddress(this._index) + GetOffset("CPopulationManager::m_EndlessActiveBotUpgrades"));
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
		SDKCall_ResetMap(this._index);
	}
	
	public CWave GetCurrentWave()
	{
		return CWave(SDKCall_GetCurrentWave(this._index));
	}
	
	public bool IsInEndlessWaves()
	{
		return SDKCall_IsInEndlessWaves(this._index);
	}
	
	public float GetHealthMultiplier(bool bIsTank = false)
	{
		return SDKCall_GetHealthMultiplier(this._index, bIsTank);
	}
	
	public void GetSentryBusterDamageAndKillThreshold(int &nDamage, int &nKills)
	{
		SDKCall_GetSentryBusterDamageAndKillThreshold(this._index, nDamage, nKills);
	}
	
	public void EndlessSetAttributesForBot(int player)
	{
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
}

CPopulationManager GetPopulationManager()
{
	// There is only ever one population manager, so this should be safe...
	return CPopulationManager(FindEntityByClassname(MaxClients + 1, "info_populator"));
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

methodmap CBaseTFBotHintEntity
{
	public CBaseTFBotHintEntity(int entity)
	{
		return view_as<CBaseTFBotHintEntity>(entity);
	}
	
	property int _index
	{
		public get()
		{
			return view_as<int>(this);
		}
	}
	
	property bool m_isDisabled
	{
		public get()
		{
			return GetEntData(this._index, GetOffset("CBaseTFBotHintEntity::m_isDisabled"), 1) != 0;
		}
	}
	
	public bool IsEnabled()
	{
		return !this.m_isDisabled;
	}
	
	public bool OwnerObjectHasNoOwner()
	{
		int owner = GetEntPropEnt(this._index, Prop_Send, "m_hOwnerEntity");
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
		int owner = GetEntPropEnt(this._index, Prop_Send, "m_hOwnerEntity");
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
