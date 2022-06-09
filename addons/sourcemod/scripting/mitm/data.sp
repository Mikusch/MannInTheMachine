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

#pragma semicolon 1
#pragma newdecls required

#define DONT_UPGRADE	-1
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

// Non-resetting Properties
static int m_invaderPriority[MAXPLAYERS + 1];
static bool m_bWasMiniBoss[MAXPLAYERS + 1];
static int m_defenderQueuePoints[MAXPLAYERS + 1];
static int m_preferences[MAXPLAYERS + 1];

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
		return this.m_hFollowingFlagTarget != -1;
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
		strcopy(m_szIdleSound[this._client], sizeof(m_szIdleSound[]), "");
	}
	
	public void SetScaleOverride(float fScale)
	{
		this.m_fModelScaleOverride = fScale;
		
		SetModelScale(this._client, this.m_fModelScaleOverride > 0.0 ? this.m_fModelScaleOverride : 1.0);
	}
	
	public bool HasMission(MissionType mission)
	{
		return this.m_mission == mission ? true : false;
	}
	
	public bool IsOnAnyMission()
	{
		return this.m_mission == NO_MISSION ? false : true;
	}
	
	public void SetMission(MissionType mission)
	{
		this.m_prevMission = this.m_mission;
		this.m_mission = mission;
		
		// Temp hack - some missions play an idle loop
		if (this.m_mission > NO_MISSION)
		{
			this.StartIdleSound();
		}
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
		
		if (!GameRules_IsMannVsMachineMode())
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
	
	public EventChangeAttributes_t GetEventChangeAttributes(const char[] pszEventName)
	{
		for (int i = 0; i < this.m_eventChangeAttributes.Length; ++i)
		{
			EventChangeAttributes_t attributes = this.m_eventChangeAttributes.Get(i);
			
			char eventName[64];
			attributes.GetEventName(eventName, sizeof(eventName));
			if (StrEqual(eventName, pszEventName, false))
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
			SetEntProp(this._client, Prop_Send, "m_nBotSkill", pEvent.m_skill);
			
			this.ClearWeaponRestrictions();
			this.SetWeaponRestriction(pEvent.m_weaponRestriction);
			
			this.SetMission(pEvent.m_mission);
			
			this.ClearAllAttributes();
			this.SetAttribute(pEvent.m_attributeFlags);
			
			if (GameRules_IsMannVsMachineMode())
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
				// static_attrib_t
				Address pDef = pEvent.m_characterAttributes.Get(i, 8);
				
				int defIndex = Deref(pDef, NumberType_Int16);
				float value = Deref(pDef + view_as<Address>(0x4));
				
				TF2Attrib_SetByDefIndex(this._client, defIndex, value);
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
							// item_attributes_t
							Address attrib = m_attributes.Get(iAtt, 8);
							
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
			int pEntity = TF2Util_GetPlayerLoadoutEntity(this._client, slot);
			if (pEntity != -1)
			{
				RemovePlayerItem(this._client, pEntity);
				RemoveEntity(pEntity);
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
		if (GameRules_IsMannVsMachineMode())
		{
			if (TF2_GetClientTeam(this._client) == TFTeam_Invaders && TF2_GetPlayerClass(this._client) == TFClass_Engineer)
			{
				return -1;
			}
			
			if (this.HasAttribute(IGNORE_FLAG))
			{
				return -1;
			}
			
			if (this.HasFlagTarget())
			{
				return this.GetFlagTarget();
			}
		}
		
		ArrayList flagsVector = new ArrayList();
		
		// Collect flags
		int flag = MaxClients + 1;
		while ((flag = FindEntityByClassname(flag, "item_teamflag")) != -1)
		{
			if (GetEntProp(flag, Prop_Send, "m_bDisabled"))
				continue;
			
			// If I'm carrying a flag, look for mine and early-out
			if (SDKCall_HasTheFlag(this._client))
			{
				if (GetEntPropEnt(flag, Prop_Send, "m_hOwnerEntity") == this._client)
				{
					delete flagsVector;
					return flag;
				}
			}
			
			switch (view_as<ETFFlagType>(GetEntProp(flag, Prop_Send, "m_nType")))
			{
				case TF_FLAGTYPE_CTF:
				{
					if (view_as<TFTeam>(GetEntProp(flag, Prop_Send, "m_iTeamNum")) == GetEnemyTeam(TF2_GetClientTeam(this._client)))
					{
						// we want to steal the other team's flag
						flagsVector.Push(flag);
					}
				}
				
				case TF_FLAGTYPE_ATTACK_DEFEND, TF_FLAGTYPE_TERRITORY_CONTROL, TF_FLAGTYPE_INVADE:
				{
					if (view_as<TFTeam>(GetEntProp(flag, Prop_Send, "m_iTeamNum")) != GetEnemyTeam(TF2_GetClientTeam(this._client)))
					{
						// we want to move our team's flag or a neutral flag
						flagsVector.Push(flag);
					}
				}
			}
			
			if (GetEntProp(flag, Prop_Send, "m_nFlagStatus") == TF_FLAGINFO_STOLEN)
			{
				nCarriedFlags++;
			}
		}
		
		int pClosestFlag = -1;
		float flClosestFlagDist = float(cellmax);
		int pClosestUncarriedFlag = -1;
		float flClosestUncarriedFlagDist = float(cellmax);
		
		if (GameRules_IsMannVsMachineMode())
		{
			for (int i = 0; i < flagsVector.Length; i++)
			{
				flag = flagsVector.Get(i);
				
				// Find the closest
				float flagOrigin[3], playerOrigin[3];
				GetEntPropVector(flag, Prop_Data, "m_vecAbsOrigin", flagOrigin);
				GetClientAbsOrigin(this._client, playerOrigin);
				
				float origins[3];
				SubtractVectors(flagOrigin, playerOrigin, origins);
				
				float flDist = GetVectorLength(origins, true);
				if (flDist < flClosestFlagDist)
				{
					pClosestFlag = flag;
					flClosestFlagDist = flDist;
				}
				
				// Find the closest uncarried
				if (nCarriedFlags < flagsVector.Length && GetEntProp(flag, Prop_Send, "m_nFlagStatus") != TF_FLAGINFO_STOLEN)
				{
					if (flDist < flClosestUncarriedFlagDist)
					{
						pClosestUncarriedFlag = flag;
						flClosestUncarriedFlagDist = flDist;
					}
				}
			}
		}
		
		delete flagsVector;
		
		// If we have an uncarried flag, prioritize
		if (pClosestUncarriedFlag != -1)
			return pClosestUncarriedFlag;
		
		return pClosestFlag;
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
		ArrayList enemyVector = new ArrayList(MaxClients);
		
		for (int client = 1; client <= MaxClients; client++)
		{
			if (!IsClientInGame(client))
				continue;
			
			if (TF2_GetClientTeam(client) == TF2_GetClientTeam(this._client))
				continue;
			
			enemyVector.Push(client);
		}
		
		TFClassType disguise = view_as<TFClassType>(GetRandomInt(view_as<int>(TFClass_Scout), view_as<int>(TFClass_Engineer)));
		
		if (enemyVector.Length > 0)
		{
			disguise = TF2_GetPlayerClass(enemyVector.Get(GetRandomInt(0, enemyVector.Length - 1)));
		}
		
		TF2_DisguisePlayer(this._client, GetEnemyTeam(TF2_GetClientTeam(this._client)), disguise);
		delete enemyVector;
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
	
	public void Initialize()
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
		this.m_spawnPointEntity = -1;
		this.m_hFollowingFlagTarget = -1;
	}
	
	public void Reset()
	{
		this.ResetOnTeamChange();
		
		this.m_invaderPriority = 0;
		this.m_bWasMiniBoss = false;
		this.m_defenderQueuePoints = -1;
		this.m_preferences = -1;
	}
}

methodmap EventChangeAttributes_t
{
	public EventChangeAttributes_t(Address address)
	{
		return view_as<EventChangeAttributes_t>(address);
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
	
	public void GetEventName(char[] buffer, int maxlen)
	{
		PtrToString(Deref(this + GetOffset("EventChangeAttributes_t::m_eventName")), buffer, maxlen);
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
	
	public void GetName(char[] buffer, int maxlen)
	{
		Address m_name = Deref(this + GetOffset("CTFBotSpawner::m_name"));
		if (m_name)
		{
			PtrToString(m_name, buffer, maxlen);
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
	
	public void ResetMap()
	{
		SDKCall_ResetMap(this._index);
	}
	
	public bool IsSpawningPaused()
	{
		return view_as<bool>(GetEntData(this._index, GetOffset("CPopulationManager::m_bSpawningPaused")));
	}
	
	public CWave GetCurrentWave()
	{
		return CWave(SDKCall_GetCurrentWave(this._index));
	}
	
	public float GetHealthMultiplier(bool bIsTank = false)
	{
		return SDKCall_GetHealthMultiplier(this._index, bIsTank);
	}
	
	public void GetSentryBusterDamageAndKillThreshold(int &nDamage, int &nKills)
	{
		SDKCall_GetSentryBusterDamageAndKillThreshold(this._index, nDamage, nKills);
	}
	
	public void GetDefaultEventChangeAttributesName(char[] buffer, int maxlen)
	{
		PtrToString(GetEntData(this._index, GetOffset("CPopulationManager::m_defaultEventChangeAttributesName")), buffer, maxlen);
	}
}

CPopulationManager GetPopulationManager()
{
	// There is only ever one population manager, so this should be safe...
	return CPopulationManager(FindEntityByClassname(MaxClients + 1, "info_populator"));
}
