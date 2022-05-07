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
	
	public int GetIdleSound(char[] buffer, int maxlen)
	{
		return strcopy(buffer, maxlen, g_PlayerIdleSounds[view_as<int>(this)]);
	}
	
	public int SetIdleSound(const char[] soundName)
	{
		return strcopy(g_PlayerIdleSounds[view_as<int>(this)], sizeof(g_PlayerIdleSounds[]), soundName);
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
}

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
