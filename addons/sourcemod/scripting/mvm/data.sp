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

static bool g_PlayerAllowTeamChange[MAXPLAYERS + 1];
static BombDeployingState_t g_PlayerDeployingBombState[MAXPLAYERS + 1];
static int g_PlayerFollowingFlagTarget[MAXPLAYERS + 1] = { -1, ... };
static char g_PlayerIdleSounds[MAXPLAYERS + 1][PLATFORM_MAX_PATH];
static WeaponRestrictionType g_PlayerWeaponRestrictionFlags[MAXPLAYERS + 1];
static AttributeType g_PlayerAttributeFlags[MAXPLAYERS + 1];
static int g_PlayerSpawnPointEntity[MAXPLAYERS + 1];
static float g_PlayerModelScaleOverride[MAXPLAYERS + 1];
static ArrayList g_PlayerTags[MAXPLAYERS + 1];
static ArrayList g_PlayerEventChangeAttributes[MAXPLAYERS + 1];

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
	
	property bool m_bAllowTeamChange
	{
		public get()
		{
			return g_PlayerAllowTeamChange[this._client];
		}
		public set(bool bAllowTeamChange)
		{
			g_PlayerAllowTeamChange[this._client] = bAllowTeamChange;
		}
	}
	
	property BombDeployingState_t m_nDeployingBombState
	{
		public get()
		{
			return g_PlayerDeployingBombState[this._client];
		}
		public set(BombDeployingState_t nDeployingBombState)
		{
			g_PlayerDeployingBombState[this._client] = nDeployingBombState;
		}
	}
	
	property int m_hFollowingFlagTarget
	{
		public get()
		{
			return g_PlayerFollowingFlagTarget[this._client];
		}
		public set(int pFlag)
		{
			g_PlayerFollowingFlagTarget[this._client] = pFlag;
		}
	}
	
	property WeaponRestrictionType m_weaponRestrictionFlags
	{
		public get()
		{
			return g_PlayerWeaponRestrictionFlags[this._client];
		}
		public set(WeaponRestrictionType restrictionFlags)
		{
			g_PlayerWeaponRestrictionFlags[this._client] = restrictionFlags;
		}
	}
	
	property AttributeType m_attributeFlags
	{
		public get()
		{
			return g_PlayerAttributeFlags[this._client];
		}
		public set(AttributeType attributeFlag)
		{
			g_PlayerAttributeFlags[this._client] = attributeFlag;
		}
	}
	
	property ArrayList m_tags
	{
		public get()
		{
			return g_PlayerTags[this._client];
		}
		public set(ArrayList tags)
		{
			g_PlayerTags[this._client] = tags;
		}
	}
	
	property ArrayList m_eventChangeAttributes
	{
		public get()
		{
			return g_PlayerEventChangeAttributes[this._client];
		}
		public set(ArrayList attributes)
		{
			g_PlayerEventChangeAttributes[this._client] = attributes;
		}
	}
	
	property int m_spawnPointEntity
	{
		public get()
		{
			return g_PlayerSpawnPointEntity[this._client];
		}
		public set(int spawnPoint)
		{
			g_PlayerSpawnPointEntity[this._client] = spawnPoint;
		}
	}
	
	property float m_fModelScaleOverride
	{
		public get()
		{
			return g_PlayerModelScaleOverride[this._client];
		}
		public set(float fScale)
		{
			g_PlayerModelScaleOverride[this._client] = fScale;
		}
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
	
	public int GetIdleSound(char[] buffer, int maxlen)
	{
		return strcopy(buffer, maxlen, g_PlayerIdleSounds[this._client]);
	}
	
	public int SetIdleSound(const char[] soundName)
	{
		return strcopy(g_PlayerIdleSounds[this._client], sizeof(g_PlayerIdleSounds[]), soundName);
	}
	
	public void SetScaleOverride(float fScale)
	{
		this.m_fModelScaleOverride = fScale;
		
		SetModelScale(this._client, this.m_fModelScaleOverride > 0.0 ? this.m_fModelScaleOverride : 1.0);
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
			this.SetIdleSound("");
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
				
				AddItem(this._client, item);
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
	
	public bool IsWeaponRestricted(int weapon)
	{
		if (weapon == -1)
		{
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
			SetEntPropEnt(this._client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(this._client, TFWeaponSlot_Melee));
			return true;
		}
		
		if (this.HasWeaponRestriction(PRIMARY_ONLY))
		{
			SetEntPropEnt(this._client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(this._client, TFWeaponSlot_Primary));
			return true;
		}
		
		if (this.HasWeaponRestriction(SECONDARY_ONLY))
		{
			
			SetEntPropEnt(this._client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(this._client, TFWeaponSlot_Secondary));
			return true;
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
	
	public void Initialize()
	{
		this.m_tags = new ArrayList(64);
		this.m_eventChangeAttributes = new ArrayList();
	}
	
	public void Reset()
	{
		this.m_bAllowTeamChange = false;
		this.m_hFollowingFlagTarget = -1;
		this.m_weaponRestrictionFlags = ANY_WEAPON;
		this.m_attributeFlags = view_as<AttributeType>(0);
		this.m_spawnPointEntity = -1;
		this.m_fModelScaleOverride = 0.0;
		this.m_tags.Clear();
		this.m_eventChangeAttributes.Clear();
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
	
	property CUtlVector m_teleportWhereName
	{
		public get()
		{
			return CUtlVector(this + GetOffset("CTFBotSpawner::m_teleportWhereName"));
		}
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
			return view_as<TFClassType>(Deref(this + GetOffset("CTFBotSpawner::m_class")));
		}
	}
	
	property float m_scale
	{
		public get()
		{
			return view_as<float>(Deref(this + GetOffset("CTFBotSpawner::m_scale")));
		}
	}
	
	public void GetName(char[] buffer, int maxlen)
	{
		PtrToString(Deref(this + GetOffset("CTFBotSpawner::m_name")), buffer, maxlen);
	}
	
	public void GetClassIcon(char[] buffer, int maxlen)
	{
		Address string_t = view_as<Address>(Deref(this + GetOffset("CTFBotSpawner::m_iszClassIcon")));
		if (string_t != Address_Null)
			UTIL_StringtToCharArray(string_t, buffer, maxlen);
		else
			strcopy(buffer, maxlen, g_aRawPlayerClassNamesShort[this.m_class]);
	}
};
