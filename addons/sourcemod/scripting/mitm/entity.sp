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

enum struct EntityProperties
{
	int m_hEntity;
	
	ArrayList m_teleportWhereName;
	
	void Initialize(int entity)
	{
		this.m_hEntity = entity;
		this.m_teleportWhereName = new ArrayList();
	}
	
	void Destroy()
	{
		delete this.m_teleportWhereName;
	}
}

static ArrayList g_EntityProperties;

methodmap Entity
{
	public Entity(int entity)
	{
		if (!IsValidEntity(entity))
			return view_as<Entity>(INVALID_ENT_REFERENCE);
		
		//Doubly convert it to ensure it is an entity reference
		entity = EntIndexToEntRef(EntRefToEntIndex(entity));
		
		if (g_EntityProperties.FindValue(entity, EntityProperties::m_hEntity) == -1)
		{
			EntityProperties properties;
			properties.Initialize(entity);
			
			g_EntityProperties.PushArray(properties);
		}
		
		return view_as<Entity>(entity);
	}
	
	property int _listIndex
	{
		public get()
		{
			return g_EntityProperties.FindValue(view_as<int>(this), EntityProperties::m_hEntity);
		}
	}
	
	property ArrayList m_teleportWhereName
	{
		public get()
		{
			return g_EntityProperties.Get(this._listIndex, EntityProperties::m_teleportWhereName);
		}
		public set(ArrayList teleportWhereName)
		{
			g_EntityProperties.Set(this._listIndex, teleportWhereName, EntityProperties::m_teleportWhereName);
		}
	}
	
	public void SetTeleportWhere(ArrayList teleportWhereName)
	{
		this.m_teleportWhereName = teleportWhereName.Clone();
	}
	
	public void Destroy()
	{
		g_EntityProperties.Erase(this._listIndex);
	}
	
	public static void InitializePropertyList()
	{
		g_EntityProperties = new ArrayList(sizeof(EntityProperties));
	}
}
