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

static ArrayList g_hEntityProperties;

enum struct EntityProperties
{
	int m_ref;
	
	ArrayList m_teleportWhereName;
	int m_hGlowEntity;
	
	void Init(int ref)
	{
		this.m_ref = ref;
		this.m_teleportWhereName = new ArrayList(ByteCountToCells(64));
		this.m_hGlowEntity = INVALID_ENT_REFERENCE;
	}
	
	void Destroy()
	{
		delete this.m_teleportWhereName;
	}
}

/**
 * A methodmap that holds entity data.
 * Calling the constructor will create a list index for the entity and reuse it until the entity is deleted.
 * The data is stored in the associated EntityProperties enum struct.
 *
 */
methodmap Entity
{
	public Entity(int entity)
	{
		if (!IsValidEntity(entity))
		{
			return view_as<Entity>(INVALID_ENT_REFERENCE);
		}
		
		if (!g_hEntityProperties)
		{
			g_hEntityProperties = new ArrayList(sizeof(EntityProperties));
		}
		
		int ref = IsEntNetworkable(entity) ? EntIndexToEntRef(entity) : entity;
		
		if (!Entity.IsReferenceTracked(ref))
		{
			EntityProperties properties;
			properties.Init(ref);
			
			g_hEntityProperties.PushArray(properties);
		}
		
		return view_as<Entity>(ref);
	}
	
	property int m_ref
	{
		public get()
		{
			return view_as<int>(this);
		}
	}
	
	property int m_entindex
	{
		public get()
		{
			return EntRefToEntIndex(this.m_ref);
		}
	}
	
	property int m_listIndex
	{
		public get()
		{
			return g_hEntityProperties.FindValue(this.m_ref, EntityProperties::m_ref);
		}
	}
	
	property ArrayList m_teleportWhereName
	{
		public get()
		{
			return g_hEntityProperties.Get(this.m_listIndex, EntityProperties::m_teleportWhereName);
		}
	}
	
	property int m_hGlowEntity
	{
		public get()
		{
			return g_hEntityProperties.Get(this.m_listIndex, EntityProperties::m_hGlowEntity);
		}
		public set(int hGlowEntity)
		{
			g_hEntityProperties.Set(this.m_listIndex, hGlowEntity, EntityProperties::m_hGlowEntity);
		}
	}
	
	public void SetTeleportWhere(ArrayList teleportWhereName)
	{
		// deep copy strings
		for (int i = 0; i < teleportWhereName.Length; ++i)
		{
			char szTeleportWhereName[64];
			if (teleportWhereName.GetString(i, szTeleportWhereName, sizeof(szTeleportWhereName)))
			{
				this.m_teleportWhereName.PushString(szTeleportWhereName);
			}
		}
	}
	
	public ArrayList GetTeleportWhere()
	{
		return this.m_teleportWhereName.Clone();
	}
	
	public void SetGlowEntity(int hGlowEntity)
	{
		this.m_hGlowEntity = hGlowEntity;
	}
	
	public int GetGlowEntity()
	{
		return this.m_hGlowEntity;
	}
	
	public void Destroy()
	{
		int index = this.m_listIndex;
		if (index == -1)
			return;
		
		EntityProperties properties;
		if (g_hEntityProperties.GetArray(index, properties))
			properties.Destroy();
		
		g_hEntityProperties.Erase(index);
	}
	
	public static bool IsEntityTracked(int entity)
	{
		int ref = IsEntNetworkable(entity) ? EntIndexToEntRef(entity) : entity;
		return Entity.IsReferenceTracked(ref);
	}
	
	public static bool IsReferenceTracked(int ref)
	{
		return g_hEntityProperties.FindValue(ref, EntityProperties::m_ref) != -1;
	}
	
	public static void Init()
	{
		g_hEntityProperties = new ArrayList(sizeof(EntityProperties));
	}
}
