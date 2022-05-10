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

static char g_PlayerIdleSounds[MAXPLAYERS + 1][PLATFORM_MAX_PATH];
static WeaponRestrictionType g_PlayerWeaponRestrictionFlags[MAXPLAYERS + 1];
static AttributeType g_PlayerAttributeFlags[MAXPLAYERS + 1];
static int g_PlayerSpawnPointEntity[MAXPLAYERS + 1];
static float g_PlayerModelScaleOverride[MAXPLAYERS + 1];
static ArrayList g_PlayerTags[MAXPLAYERS + 1];

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
				
				int defIndex = LoadFromAddress(pDef, NumberType_Int16);
				float value = LoadFromAddress(pDef + view_as<Address>(0x4), NumberType_Int32);
				
				TF2Attrib_SetByDefIndex(this._client, defIndex, value);
			}
			
			this.ModifyMaxHealth(nMaxHealth);
			SetEntProp(this._client, Prop_Data, "m_iHealth", nHealth);
			
			// give items to bot before apply attribute changes
			for (int i = 0; i < pEvent.m_items.Count(); i++)
			{
				char item[64];
				LoadStringFromAddress(DereferencePointer(pEvent.m_items.Get(i)), item, sizeof(item));
				
				AddItem(this._client, item);
			}
			
			for (int i = 0; i < pEvent.m_itemsAttributes.Count(); i++)
			{
				Address itemAttributes = pEvent.m_itemsAttributes.Get(i);
				
				char itemName[64];
				LoadStringFromAddress(DereferencePointer(itemAttributes), itemName, sizeof(itemName));
				
				int itemDef = FindItemByName(itemName);
				
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
							
							int defIndex = LoadFromAddress(attrib, NumberType_Int16);
							float value = LoadFromAddress(attrib + view_as<Address>(0x4), NumberType_Int32);
							
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
				LoadStringFromAddress(DereferencePointer(pEvent.m_tags.Get(i)), tag, sizeof(tag));
				
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
		int itemdef = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")
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
	
	public void Reset()
	{
		delete this.m_tags;
		this.m_tags = new ArrayList(64);
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
			return LoadFromAddress(view_as<Address>(this) + view_as<Address>(g_OffsetWeaponRestriction), NumberType_Int32);
		}
	}
	
	property any m_attributeFlags
	{
		public get()
		{
			return LoadFromAddress(view_as<Address>(this) + view_as<Address>(g_OffsetAttributeFlags), NumberType_Int32);
		}
	}
	
	property CUtlVector m_items
	{
		public get()
		{
			return CUtlVector(view_as<Address>(this) + view_as<Address>(g_OffsetItems));
		}
	}
	
	property CUtlVector m_itemsAttributes
	{
		public get()
		{
			return CUtlVector(view_as<Address>(this) + view_as<Address>(g_OffsetItemsAttributes));
		}
	}
	
	property CUtlVector m_characterAttributes
	{
		public get()
		{
			return CUtlVector(view_as<Address>(this) + view_as<Address>(g_OffsetCharacterAttributes));
		}
	}
	
	property CUtlVector m_tags
	{
		public get()
		{
			return CUtlVector(view_as<Address>(this) + view_as<Address>(g_OffsetTags));
		}
	}
};

methodmap CTFBotSpawner
{
	public CTFBotSpawner(Address spawner)
	{
		return view_as<CTFBotSpawner>(spawner);
	}
	
	property Address _spawner
	{
		public get()
		{
			return view_as<Address>(this);
		}
	}
	
	property EventChangeAttributes_t m_defaultAttributes
	{
		public get()
		{
			return view_as<EventChangeAttributes_t>(this._spawner + view_as<Address>(g_OffsetDefaultAttributes));
		}
	}
	
	property int m_health
	{
		public get()
		{
			return LoadFromAddress(this._spawner + view_as<Address>(g_OffsetHealth), NumberType_Int32);
		}
	}
	
	property TFClassType m_class
	{
		public get()
		{
			return view_as<TFClassType>(LoadFromAddress(this._spawner + view_as<Address>(g_OffsetClass), NumberType_Int32));
		}
	}
	
	property float m_scale
	{
		public get()
		{
			return view_as<float>(LoadFromAddress(this._spawner + view_as<Address>(g_OffsetScale), NumberType_Int32));
		}
	}
	
	public EventChangeAttributes_t GetEventChangeAttributes()
	{
		return view_as<EventChangeAttributes_t>(this);
	}
	
	public int GetClassIcon(char[] buffer, int maxlen)
	{
		Address string_t = view_as<Address>(LoadFromAddress(this._spawner + view_as<Address>(g_OffsetClassIcon), NumberType_Int32));
		if (string_t != Address_Null)
			return UTIL_StringtToCharArray(string_t, buffer, maxlen);
		
		return strcopy(buffer, maxlen, g_aRawPlayerClassNamesShort[CTFBotSpawner(this._spawner).m_class]);
	}
};
