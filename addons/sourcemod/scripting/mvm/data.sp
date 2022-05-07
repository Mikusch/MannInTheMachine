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

methodmap EventChangeAttributes_t
{
	public EventChangeAttributes_t(Address address)
	{
		return view_as<EventChangeAttributes_t>(address);
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
			return view_as<EventChangeAttributes_t>(view_as<Address>(this) + view_as<Address>(g_OffsetDefaultAttributes));
		}
	}
	
	public EventChangeAttributes_t GetEventChangeAttributes()
	{
		return view_as<EventChangeAttributes_t>(this);
	}
};
