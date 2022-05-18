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

// Bomb Upgrade
static CountdownTimer m_upgradeTimer[MAXPLAYERS + 1];
static CountdownTimer m_buffPulseTimer[MAXPLAYERS + 1];
static int m_upgradeLevel[MAXPLAYERS + 1];

// Auto Jump
static CountdownTimer m_autoJumpTimer[MAXPLAYERS + 1];
static float m_flAutoJumpMin[MAXPLAYERS + 1];
static float m_flAutoJumpMax[MAXPLAYERS + 1];

// Spy Robots
static CountdownTimer m_waitTimer[MAXPLAYERS + 1];
static int m_attempt[MAXPLAYERS + 1];

// Engineer Robots
static ArrayList m_teleportWhereName[MAXPLAYERS + 1];

// Bot Spawner
static ArrayList m_eventChangeAttributes[MAXPLAYERS + 1];
static ArrayList m_tags[MAXPLAYERS + 1];
static WeaponRestrictionType m_weaponRestrictionFlags[MAXPLAYERS + 1];
static AttributeType m_attributeFlags[MAXPLAYERS + 1];
static BombDeployingState_t m_nDeployingBombState[MAXPLAYERS + 1];
static char m_szIdleSound[MAXPLAYERS + 1][PLATFORM_MAX_PATH];
static float m_fModelScaleOverride[MAXPLAYERS + 1];
static float m_flRequiredSpawnLeaveTime[MAXPLAYERS + 1];
static int m_spawnPointEntity[MAXPLAYERS + 1];
static int m_hFollowingFlagTarget[MAXPLAYERS + 1];

// Non-resetting Properties
static int m_invaderPriority[MAXPLAYERS + 1];

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
	
	property int m_upgradeLevel
	{
		public get()
		{
			return m_upgradeLevel[this._client];
		}
		public set(int upgradeLevel)
		{
			m_upgradeLevel[this._client] = upgradeLevel;
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
	
	property int m_attempt
	{
		public get()
		{
			return m_attempt[this._client];
		}
		public set(int attempt)
		{
			m_attempt[this._client] = attempt;
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
	
	property int m_hFollowingFlagTarget
	{
		public get()
		{
			return m_hFollowingFlagTarget[this._client];
		}
		public set(int pFlag)
		{
			m_hFollowingFlagTarget[this._client] = pFlag;
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
					strcopy(pszSoundName, sizeof(pszSoundName), "MVM.GiantDemomanLoop");
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
			this.ClearWeaponRestrictions();
			this.SetWeaponRestriction(pEvent.m_weaponRestriction);
			
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
		
		if (TF2Util_IsEntityWearable(weapon) || TF2Util_GetWeaponID(weapon) == TF_WEAPON_LUNCHBOX)
		{
			// Always allow wearable weapons and lunchbox items
			return false;
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
			
			if (this.m_hFollowingFlagTarget != -1)
			{
				return this.m_hFollowingFlagTarget;
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
	
	public bool UpgradeStart()
	{
		if (!tf_mvm_bot_allow_flag_carrier_to_fight.BoolValue)
		{
			this.SetAttribute(SUPPRESS_FIRE);
		}
		
		// mini-bosses don't upgrade - they are already tough
		if (GetEntProp(this._client, Prop_Send, "m_bIsMiniBoss"))
		{
			// Set threat level to max
			this.m_upgradeLevel = DONT_UPGRADE;
			SetEntProp(TFObjectiveResource(), Prop_Send, "m_nFlagCarrierUpgradeLevel", 4);
			SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMBaseBombUpgradeTime", -1.0);
			SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMNextBombUpgradeTime", -1.0);
		}
		else
		{
			this.m_upgradeLevel = 0;
			m_upgradeTimer[this._client].Start(tf_mvm_bot_flag_carrier_interval_to_1st_upgrade.FloatValue);
			SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMBaseBombUpgradeTime", GetGameTime());
			SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMNextBombUpgradeTime", GetGameTime() + m_upgradeTimer[this._client].GetRemainingTime());
		}
	}
	
	public bool UpgradeOverTime()
	{
		if (this.m_upgradeLevel != DONT_UPGRADE)
		{
			CTFNavArea myArea = view_as<CTFNavArea>(CBaseCombatCharacter(this._client).GetLastKnownArea());
			TFNavAttributeType spawnRoomFlag = TF2_GetClientTeam(this._client) == TFTeam_Red ? RED_SPAWN_ROOM : BLUE_SPAWN_ROOM;
			
			if (myArea && myArea.HasAttributeTF(spawnRoomFlag))
			{
				// don't start counting down until we leave the spawn
				m_upgradeTimer[this._client].Start(tf_mvm_bot_flag_carrier_interval_to_1st_upgrade.FloatValue);
				SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMBaseBombUpgradeTime", GetGameTime());
				SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMNextBombUpgradeTime", GetGameTime() + m_upgradeTimer[this._client].GetRemainingTime());
			}
			
			// do defensive buff effect ourselves (since we're not a soldier)
			if (this.m_upgradeLevel > 0 && m_buffPulseTimer[this._client].IsElapsed())
			{
				m_buffPulseTimer[this._client].Start(1.0);
				
				const float buffRadius = 450.0;
				
				for (int client = 1; client <= MaxClients; client++)
				{
					if (!IsClientInGame(client))
						continue;
					
					if (TF2_GetClientTeam(client) != TF2_GetClientTeam(this._client))
						continue;
					
					if (!IsPlayerAlive(client))
						continue;
					
					if (IsRangeLessThan(this._client, client, buffRadius))
					{
						TF2_AddCondition(client, TFCond_DefenseBuffNoCritBlock, 1.2);
					}
				}
			}
			
			// the flag carrier gets stronger the longer he holds the flag
			if (m_upgradeTimer[this._client].IsElapsed())
			{
				const int maxLevel = 3;
				
				if (this.m_upgradeLevel < maxLevel)
				{
					++this.m_upgradeLevel;
					
					EmitGameSoundToAll("MVM.Warning");
					
					switch (this.m_upgradeLevel)
					{
						//---------------------------------------
						case 1:
						{
							m_upgradeTimer[this._client].Start(tf_mvm_bot_flag_carrier_interval_to_2nd_upgrade.FloatValue);
							
							// permanent buff banner effect (handled above)
							
							// update the objective resource so clients have the information
							SetEntProp(TFObjectiveResource(), Prop_Send, "m_nFlagCarrierUpgradeLevel", 1);
							SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMBaseBombUpgradeTime", GetGameTime());
							SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMNextBombUpgradeTime", GetGameTime() + m_upgradeTimer[this._client].GetRemainingTime());
							HaveAllPlayersSpeakConceptIfAllowed("TLK_MVM_BOMB_CARRIER_UPGRADE1", TFTeam_Defenders);
							DispatchParticleEffect("mvm_levelup1", PATTACH_POINT_FOLLOW, this._client, "head");
							return true;
						}
						
						//---------------------------------------
						case 2:
						{
							m_upgradeTimer[this._client].Start(tf_mvm_bot_flag_carrier_interval_to_3rd_upgrade.FloatValue);
							
							TF2Attrib_SetByName(this._client, "health regen", tf_mvm_bot_flag_carrier_health_regen.FloatValue);
							
							// update the objective resource so clients have the information
							SetEntProp(TFObjectiveResource(), Prop_Send, "m_nFlagCarrierUpgradeLevel", 2);
							SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMBaseBombUpgradeTime", GetGameTime());
							SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMNextBombUpgradeTime", GetGameTime() + m_upgradeTimer[this._client].GetRemainingTime());
							HaveAllPlayersSpeakConceptIfAllowed("TLK_MVM_BOMB_CARRIER_UPGRADE2", TFTeam_Defenders);
							DispatchParticleEffect("mvm_levelup2", PATTACH_POINT_FOLLOW, this._client, "head");
							return true;
						}
						
						//---------------------------------------
						case 3:
						{
							// add critz
							TF2_AddCondition(this._client, TFCond_Kritzkrieged);
							
							// update the objective resource so clients have the information
							SetEntProp(TFObjectiveResource(), Prop_Send, "m_nFlagCarrierUpgradeLevel", 3);
							SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMBaseBombUpgradeTime", -1.0);
							SetEntPropFloat(TFObjectiveResource(), Prop_Send, "m_flMvMNextBombUpgradeTime", -1.0);
							HaveAllPlayersSpeakConceptIfAllowed("TLK_MVM_BOMB_CARRIER_UPGRADE3", TFTeam_Defenders);
							DispatchParticleEffect("mvm_levelup3", PATTACH_POINT_FOLLOW, this._client, "head");
							return true;
						}
					}
				}
			}
		}
		
		return false;
	}
	
	public void SpyLeaveSpawnRoomStart()
	{
		// disguise as enemy team
		this.DisguiseAsMemberOfEnemyTeam();
		
		// cloak
		SDKCall_DoClassSpecialSkill(this._client);
		
		// wait a few moments to guarantee a minimum time between announcing Spies and their attack
		m_waitTimer[this._client].Start(2.0 + GetRandomFloat(0.0, 1.0));
		
		this.m_attempt = 0;
	}
	
	public void SpyLeaveSpawnRoomUpdate()
	{
		if (m_waitTimer[this._client].HasStarted() && m_waitTimer[this._client].IsElapsed())
		{
			int victim = -1;
			
			ArrayList enemyVector = new ArrayList(MaxClients);
			
			for (int client = 1; client <= MaxClients; client++)
			{
				if (!IsClientInGame(client))
					continue;
				
				if (TF2_GetClientTeam(client) == TF2_GetClientTeam(this._client))
					continue;
				
				if (!IsPlayerAlive(client))
					continue;
				
				enemyVector.Push(client);
			}
			
			// randomly shuffle our enemies
			enemyVector.Sort(Sort_Random, Sort_Integer);
			
			int n = enemyVector.Length;
			while (n > 1)
			{
				int k = GetRandomInt(0, n - 1);
				n--;
				
				int tmp = enemyVector.Get(n);
				enemyVector.Set(n, enemyVector.Get(k));
				enemyVector.Set(k, tmp);
			}
			
			for (int i = 0; i < enemyVector.Length; ++i)
			{
				if (this.TeleportNearVictim(enemyVector.Get(i), this.m_attempt))
				{
					victim = enemyVector.Get(i);
					break;
				}
			}
			
			// if we didn't find a victim, try again in a bit
			if (victim == -1)
			{
				m_waitTimer[this._client].Start(1.0);
				
				++this.m_attempt;
				
				delete enemyVector;
				return;
			}
			
			m_waitTimer[this._client].Invalidate();
			delete enemyVector;
			return;
		}
	}
	
	public bool TeleportNearVictim(int victim, int attempt)
	{
		if (victim == -1)
		{
			return false;
		}
		
		if (!CBaseCombatCharacter(victim).GetLastKnownArea())
		{
			return false;
		}
		
		ArrayList ambushVector = new ArrayList(); // vector of hidden but near-to-victim areas
		
		const float maxSurroundTravelRange = 6000.0;
		
		float surroundTravelRange = 1500.0 + 500.0 * attempt;
		if (surroundTravelRange > maxSurroundTravelRange)
		{
			surroundTravelRange = maxSurroundTravelRange;
		}
		
		// collect walkable areas surrounding this victim
		SurroundingAreasCollector areaVector;
		areaVector = TheNavMesh.CollectSurroundingAreas(CBaseCombatCharacter(victim).GetLastKnownArea(), surroundTravelRange, sv_stepsize.FloatValue, sv_stepsize.FloatValue);
		
		// keep subset that isn't visible to the victim's team
		for (int i = 0; i < areaVector.Count(); i++)
		{
			CTFNavArea area = view_as<CTFNavArea>(areaVector.Get(i));
			
			if (!IsAreaValidForWanderingPopulation(area))
			{
				continue;
			}
			
			if (IsAreaPotentiallyVisibleToTeam(area, TF2_GetClientTeam(victim)))
			{
				continue;
			}
			
			ambushVector.Push(area);
		}
		
		if (ambushVector.Length == 0)
		{
			delete ambushVector;
			return false;
		}
		
		int maxTries = Min(10, ambushVector.Length);
		
		for (int retry = 0; retry < maxTries; ++retry)
		{
			int which = GetRandomInt(0, ambushVector.Length - 1);
			CNavArea area = ambushVector.Get(which);
			float where[3];
			area.GetCenter(where);
			AddVectors(where, Vector(0.0, 0.0, sv_stepsize.FloatValue), where);
			
			if (SDKCall_IsSpaceToSpawnHere(where))
			{
				TeleportEntity(this._client, where, ZERO_VECTOR, ZERO_VECTOR);
				delete ambushVector;
				return true;
			}
		}
		
		delete ambushVector;
		return false;
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
	
	public void Initialize()
	{
		this.m_teleportWhereName = new ArrayList(64);
		this.m_eventChangeAttributes = new ArrayList();
		this.m_tags = new ArrayList(64);
	}
	
	public void Reset()
	{
		m_upgradeTimer[this._client].Invalidate();
		m_buffPulseTimer[this._client].Invalidate();
		this.m_upgradeLevel = DONT_UPGRADE;
		
		this.SetAutoJump(0.0, 0.0);
		m_autoJumpTimer[this._client].Invalidate();
		
		m_waitTimer[this._client].Invalidate();
		this.m_attempt = 0;
		
		this.ClearTeleportWhere();
		
		this.ClearEventChangeAttributes();
		this.ClearTags();
		this.ClearWeaponRestrictions();
		this.ClearAllAttributes();
		this.ClearIdleSound();
		this.m_nDeployingBombState = TF_BOMB_DEPLOYING_NONE;
		this.m_fModelScaleOverride = 0.0;
		this.m_flRequiredSpawnLeaveTime = 0.0;
		this.m_spawnPointEntity = -1;
		this.m_hFollowingFlagTarget = -1;
	}
}

methodmap EventChangeAttributes_t
{
	public EventChangeAttributes_t(Address address)
	{
		return view_as<EventChangeAttributes_t>(address);
	}
	
	property WeaponRestrictionType m_weaponRestriction
	{
		public get()
		{
			return Deref(this + GetOffset("EventChangeAttributes_t::m_weaponRestriction"));
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
		PtrToString(Deref(this + GetOffset("CTFBotSpawner::m_name")), buffer, maxlen);
	}
	
	public void GetClassIcon(char[] buffer, int maxlen)
	{
		Address string_t = Deref(this + GetOffset("CTFBotSpawner::m_iszClassIcon"));
		if (string_t != Address_Null)
			UTIL_StringtToCharArray(string_t, buffer, maxlen);
		else
			strcopy(buffer, maxlen, g_aRawPlayerClassNamesShort[this.m_class]);
	}
};

methodmap CObjectTeleporter
{
	public CObjectTeleporter(int entity)
	{
		return view_as<CObjectTeleporter>(entity);
	}
	
	property CUtlVector m_teleportWhereName
	{
		public get()
		{
			return CUtlVector(GetEntityAddress(view_as<int>(this)) + GetOffset("CObjectTeleporter::m_teleportWhereName"));
		}
	}
	
	public void SetTeleportWhere(ArrayList teleportWhereName)
	{
		// deep copy strings
		for (int i = 0; i < teleportWhereName.Length; ++i)
		{
			char name[64];
			teleportWhereName.GetString(i, name, sizeof(name));
			
			this.m_teleportWhereName.AddToTail(StringToPtr(name, sizeof(name)));
		}
	}
}
