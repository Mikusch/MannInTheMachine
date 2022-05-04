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

bool IsMannVsMachineMode()
{
	return view_as<bool>(GameRules_GetProp("m_bPlayingMannVsMachine"));
}

int GetPopulator()
{
	return FindEntityByClassname(MaxClients + 1, "info_populator");
}

void SetModelScale(int entity, float scale, float duration = 0.0)
{
	float vecScale[3];
	vecScale[0] = scale;
	vecScale[1] = scale;
	vecScale[2] = duration;
	
	SetVariantVector3D(vecScale);
	AcceptEntityInput(entity, "SetModelScale");
}

void AddItem(int player, const char[] pszItemName)
{
	int defindex = FindItemByName(pszItemName);
	
	Handle hItem = TF2Items_CreateItem(PRESERVE_ATTRIBUTES);
	
	char classname[64];
	TF2Econ_GetItemClassName(defindex, classname, sizeof(classname));
	
	TF2Items_SetClassname(hItem, classname);
	TF2Items_SetItemIndex(hItem, defindex);
	TF2Items_SetLevel(hItem, 1);
	
	int item = TF2Items_GiveNamedItem(player, hItem);
	
	delete hItem;
	
	SetEntProp(item, Prop_Send, "m_bValidatedAttachedEntity", true);
	
	// TODO: Wearable support
	EquipPlayerWeapon(player, item);
}

static int FindItemByName(const char[] name)
{
	if (!name[0])
	{
		return TF_ITEMDEF_DEFAULT;
	}
	
	static StringMap s_ItemDefsByName;
	if (s_ItemDefsByName)
	{
		int value = TF_ITEMDEF_DEFAULT;
		return s_ItemDefsByName.GetValue(name, value) ? value : TF_ITEMDEF_DEFAULT;
	}
	
	s_ItemDefsByName = new StringMap();
	
	ArrayList itemList = TF2Econ_GetItemList();
	char nameBuffer[64];
	for (int i, nItems = itemList.Length; i < nItems; i++)
	{
		int itemdef = itemList.Get(i);
		TF2Econ_GetItemName(itemdef, nameBuffer, sizeof(nameBuffer));
		s_ItemDefsByName.SetValue(nameBuffer, itemdef);
	}
	delete itemList;
	
	return FindItemByName(name);
}
