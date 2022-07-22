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

enum struct EntityProperties
{
	int m_index;
	
	ArrayList m_teleportWhereName;
	int m_glowEntity;
	
	void Initialize(int entity)
	{
		this.m_index = entity;
		this.m_teleportWhereName = new ArrayList();
		this.m_glowEntity = INVALID_ENT_REFERENCE;
	}
	
	void Destroy()
	{
		delete this.m_teleportWhereName;
	}
}

static ArrayList g_EntityProperties;

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
		
		// doubly convert it to ensure it's a reference
		entity = EntIndexToEntRef(EntRefToEntIndex(entity));
		
		if (g_EntityProperties.FindValue(entity, EntityProperties::m_index) == -1)
		{
			// fill basic properties
			EntityProperties properties;
			properties.Initialize(entity);
			
			g_EntityProperties.PushArray(properties);
		}
		
		return view_as<Entity>(entity);
	}
	
	property int m_listIndex
	{
		public get()
		{
			return g_EntityProperties.FindValue(view_as<int>(this), EntityProperties::m_index);
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
	
	property int m_glowEntity
	{
		public get()
		{
			return g_EntityProperties.Get(this.m_listIndex, EntityProperties::m_glowEntity);
		}
		public set(int glowEntity)
		{
			g_EntityProperties.Set(this.m_listIndex, glowEntity, EntityProperties::m_glowEntity);
		}
	}
	
	public void SetTeleportWhere(ArrayList teleportWhereName)
	{
		// deep copy strings
		for (int i = 0; i < teleportWhereName.Length; i++)
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
		
		// finally, remove the list entry
		g_EntityProperties.Erase(this.m_listIndex);
	}
}
