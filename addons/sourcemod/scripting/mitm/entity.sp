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

static ArrayList g_EntityProperties;

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
		
		if (!g_EntityProperties)
		{
			g_EntityProperties = new ArrayList(sizeof(EntityProperties));
		}
		
		int ref = IsValidEdict(entity) ? EntIndexToEntRef(entity) : entity;
		
		if (g_EntityProperties.FindValue(ref, EntityProperties::m_ref) == -1)
		{
			// fill basic properties
			EntityProperties properties;
			properties.Init(ref);
			
			g_EntityProperties.PushArray(properties);
		}
		
		return view_as<Entity>(ref);
	}
	
	property int m_listIndex
	{
		public get()
		{
			return g_EntityProperties.FindValue(view_as<int>(this), EntityProperties::m_ref);
		}
	}
	
	property ArrayList m_teleportWhereName
	{
		public get()
		{
			return g_EntityProperties.Get(this.m_listIndex, EntityProperties::m_teleportWhereName);
		}
		public set(ArrayList teleportWhereName)
		{
			g_EntityProperties.Set(this.m_listIndex, teleportWhereName, EntityProperties::m_teleportWhereName);
		}
	}
	
	property int m_hGlowEntity
	{
		public get()
		{
			return g_EntityProperties.Get(this.m_listIndex, EntityProperties::m_hGlowEntity);
		}
		public set(int glowEntity)
		{
			g_EntityProperties.Set(this.m_listIndex, glowEntity, EntityProperties::m_hGlowEntity);
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
		return this.m_teleportWhereName;
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
		if (this.m_listIndex == -1)
			return;
		
		EntityProperties properties;
		if (g_EntityProperties.GetArray(this.m_listIndex, properties))
		{
			// properly dispose of contained handles
			properties.Destroy();
		}
		
		// finally, remove the entry from local storage
		g_EntityProperties.Erase(this.m_listIndex);
	}
}
