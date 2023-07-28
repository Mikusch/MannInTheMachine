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

#pragma semicolon 1
#pragma newdecls required

void MemPatches_Init(GameData hGameData)
{
	CreateMemoryPatch(hGameData, "CMissionPopulator::UpdateMission::MVM_INVADERS_TEAM_SIZE");
	CreateMemoryPatch(hGameData, "CWaveSpawnPopulator::Update::MVM_INVADERS_TEAM_SIZE");
}

static void CreateMemoryPatch(GameData hGameData, const char[] name)
{
	MemoryPatch patch = MemoryPatch.CreateFromConf(hGameData, name);
	
	if (!patch.Validate())
	{
		LogError("Failed to verify patch %s", name);
	}
	else if (patch.Enable())
	{
		LogMessage("Enabled memory patch %s", name);
	}
}
