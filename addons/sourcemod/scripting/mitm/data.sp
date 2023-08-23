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

#define MY_CURRENT_GUN	0

// Auto Jump
static CountdownTimer m_autoJumpTimer[MAXPLAYERS + 1];
static float m_flAutoJumpMin[MAXPLAYERS + 1];
static float m_flAutoJumpMax[MAXPLAYERS + 1];

// Engineer Robots
static ArrayList m_teleportWhereName[MAXPLAYERS + 1];

// Bot Spawner
static ArrayList m_eventChangeAttributes[MAXPLAYERS + 1];
static ArrayList m_tags[MAXPLAYERS + 1];
static ArrayStack m_requiredWeaponStack[MAXPLAYERS + 1];
static CountdownTimer m_opportunisticTimer[MAXPLAYERS + 1];
static WeaponRestrictionType m_weaponRestrictionFlags[MAXPLAYERS + 1];
static AttributeType m_attributeFlags[MAXPLAYERS + 1];
static DifficultyType m_difficulty[MAXPLAYERS + 1];
static char m_szIdleSound[MAXPLAYERS + 1][PLATFORM_MAX_PATH];
static float m_fModelScaleOverride[MAXPLAYERS + 1];
static MissionType m_mission[MAXPLAYERS + 1];
static MissionType m_prevMission[MAXPLAYERS + 1];
static int m_missionTarget[MAXPLAYERS + 1];
static float m_flSpawnTimeLeft[MAXPLAYERS + 1];
static float m_flSpawnTimeLeftMax[MAXPLAYERS + 1];
static int m_spawnPointEntity[MAXPLAYERS + 1];
static CTFBotSquad m_squad[MAXPLAYERS + 1];
static int m_hFollowingFlagTarget[MAXPLAYERS + 1];
static char m_szInvaderName[MAXPLAYERS + 1][MAX_NAME_LENGTH];
static char m_szPrevName[MAXPLAYERS + 1][MAX_NAME_LENGTH];
static bool m_isWaitingForFullReload[MAXPLAYERS + 1];
static Handle m_annotationTimer[MAXPLAYERS + 1];

// PressXButton
static int m_inputButtons[MAXPLAYERS + 1];
static CountdownTimer m_fireButtonTimer[MAXPLAYERS + 1];
static CountdownTimer m_altFireButtonTimer[MAXPLAYERS + 1];
static CountdownTimer m_specialFireButtonTimer[MAXPLAYERS + 1];

// Non-resetting Properties
static int m_invaderPriority[MAXPLAYERS + 1];
static int m_invaderMiniBossPriority[MAXPLAYERS + 1];
static int m_defenderQueuePoints[MAXPLAYERS + 1];
static int m_preferences[MAXPLAYERS + 1];
static Party m_party[MAXPLAYERS + 1];
static bool m_bIsPartyMenuActive[MAXPLAYERS + 1];
static int m_iSpawnDeathCount[MAXPLAYERS + 1];

methodmap CTFPlayer < CBaseCombatCharacter
{
	public CTFPlayer(int entity)
	{
		return view_as<CTFPlayer>(entity);
	}
	
	property CountdownTimer m_autoJumpTimer
	{
		public get()
		{
			return m_autoJumpTimer[this.index];
		}
		public set(CountdownTimer autoJumpTimer)
		{
			m_autoJumpTimer[this.index] = autoJumpTimer;
		}
	}
	
	property float m_flAutoJumpMin
	{
		public get()
		{
			return m_flAutoJumpMin[this.index];
		}
		public set(float flAutoJumpMin)
		{
			m_flAutoJumpMin[this.index] = flAutoJumpMin;
		}
	}
	
	property float m_flAutoJumpMax
	{
		public get()
		{
			return m_flAutoJumpMax[this.index];
		}
		public set(float flAutoJumpMax)
		{
			m_flAutoJumpMax[this.index] = flAutoJumpMax;
		}
	}
	
	property ArrayList m_eventChangeAttributes
	{
		public get()
		{
			return m_eventChangeAttributes[this.index];
		}
		public set(ArrayList attributes)
		{
			m_eventChangeAttributes[this.index] = attributes;
		}
	}
	
	property ArrayList m_tags
	{
		public get()
		{
			return m_tags[this.index];
		}
		public set(ArrayList tags)
		{
			m_tags[this.index] = tags;
		}
	}
	
	property ArrayStack m_requiredWeaponStack
	{
		public get()
		{
			return m_requiredWeaponStack[this.index];
		}
		public set(ArrayStack requiredWeaponStack)
		{
			m_requiredWeaponStack[this.index] = requiredWeaponStack;
		}
	}
	
	property CountdownTimer m_opportunisticTimer
	{
		public get()
		{
			return m_opportunisticTimer[this.index];
		}
		public set(CountdownTimer opportunisticTimer)
		{
			m_opportunisticTimer[this.index] = opportunisticTimer;
		}
	}
	
	property WeaponRestrictionType m_weaponRestrictionFlags
	{
		public get()
		{
			return m_weaponRestrictionFlags[this.index];
		}
		public set(WeaponRestrictionType restrictionFlags)
		{
			m_weaponRestrictionFlags[this.index] = restrictionFlags;
		}
	}
	
	property AttributeType m_attributeFlags
	{
		public get()
		{
			return m_attributeFlags[this.index];
		}
		public set(AttributeType attributeFlag)
		{
			m_attributeFlags[this.index] = attributeFlag;
		}
	}
	
	property DifficultyType m_difficulty
	{
		public get()
		{
			return m_difficulty[this.index];
		}
		public set(DifficultyType difficulty)
		{
			m_difficulty[this.index] = difficulty;
		}
	}
	
	property float m_fModelScaleOverride
	{
		public get()
		{
			return m_fModelScaleOverride[this.index];
		}
		public set(float fScale)
		{
			m_fModelScaleOverride[this.index] = fScale;
		}
	}
	
	property MissionType m_mission
	{
		public get()
		{
			return m_mission[this.index];
		}
		public set(MissionType mission)
		{
			m_mission[this.index] = mission;
		}
	}
	
	property MissionType m_prevMission
	{
		public get()
		{
			return m_prevMission[this.index];
		}
		public set(MissionType mission)
		{
			m_prevMission[this.index] = mission;
		}
	}
	
	property int m_missionTarget
	{
		public get()
		{
			return m_missionTarget[this.index];
		}
		public set(int missionTarget)
		{
			m_missionTarget[this.index] = missionTarget;
		}
	}
	
	property float m_flSpawnTimeLeft
	{
		public get()
		{
			return m_flSpawnTimeLeft[this.index];
		}
		public set(float flSpawnTimeLeft)
		{
			m_flSpawnTimeLeft[this.index] = flSpawnTimeLeft;
		}
	}
	
	property float m_flSpawnTimeLeftMax
	{
		public get()
		{
			return m_flSpawnTimeLeftMax[this.index];
		}
		public set(float flSpawnTimeLeftMax)
		{
			m_flSpawnTimeLeftMax[this.index] = flSpawnTimeLeftMax;
		}
	}
	
	property int m_spawnPointEntity
	{
		public get()
		{
			return m_spawnPointEntity[this.index];
		}
		public set(int spawnPoint)
		{
			m_spawnPointEntity[this.index] = spawnPoint;
		}
	}
	
	property int m_invaderPriority
	{
		public get()
		{
			return m_invaderPriority[this.index];
		}
		public set(int invaderPriority)
		{
			m_invaderPriority[this.index] = invaderPriority;
		}
	}
	
	property int m_invaderMiniBossPriority
	{
		public get()
		{
			return m_invaderMiniBossPriority[this.index];
		}
		public set(int invaderMiniBossPriority)
		{
			m_invaderMiniBossPriority[this.index] = invaderMiniBossPriority;
		}
	}
	
	property int m_defenderQueuePoints
	{
		public get()
		{
			return m_defenderQueuePoints[this.index];
		}
		public set(int defenderQueuePoints)
		{
			m_defenderQueuePoints[this.index] = defenderQueuePoints;
		}
	}
	
	property int m_preferences
	{
		public get()
		{
			return m_preferences[this.index];
		}
		public set(int preferences)
		{
			m_preferences[this.index] = preferences;
		}
	}
	
	property ArrayList m_teleportWhereName
	{
		public get()
		{
			return m_teleportWhereName[this.index];
		}
		public set(ArrayList teleportWhereName)
		{
			m_teleportWhereName[this.index] = teleportWhereName;
		}
	}
	
	property CTFBotSquad m_squad
	{
		public get()
		{
			return m_squad[this.index];
		}
		public set(CTFBotSquad squad)
		{
			m_squad[this.index] = squad;
		}
	}
	
	property int m_hFollowingFlagTarget
	{
		public get()
		{
			return m_hFollowingFlagTarget[this.index];
		}
		public set(int hFollowingFlagTarget)
		{
			m_hFollowingFlagTarget[this.index] = hFollowingFlagTarget;
		}
	}
	
	property bool m_isWaitingForFullReload
	{
		public get()
		{
			return m_isWaitingForFullReload[this.index];
		}
		public set(bool isWaitingForFullReload)
		{
			m_isWaitingForFullReload[this.index] = isWaitingForFullReload;
		}
	}
	
	property Handle m_annotationTimer
	{
		public get()
		{
			return m_annotationTimer[this.index];
		}
		public set(Handle annotationTimer)
		{
			m_annotationTimer[this.index] = annotationTimer;
		}
	}
	
	property int m_inputButtons
	{
		public get()
		{
			return m_inputButtons[this.index];
		}
		public set(int inputButtons)
		{
			m_inputButtons[this.index] = inputButtons;
		}
	}
	
	property CountdownTimer m_fireButtonTimer
	{
		public get()
		{
			return m_fireButtonTimer[this.index];
		}
		public set(CountdownTimer fireButtonTimer)
		{
			m_fireButtonTimer[this.index] = fireButtonTimer;
		}
	}
	
	property CountdownTimer m_altFireButtonTimer
	{
		public get()
		{
			return m_altFireButtonTimer[this.index];
		}
		public set(CountdownTimer altFireButtonTimer)
		{
			m_altFireButtonTimer[this.index] = altFireButtonTimer;
		}
	}
	
	property CountdownTimer m_specialFireButtonTimer
	{
		public get()
		{
			return m_specialFireButtonTimer[this.index];
		}
		public set(CountdownTimer specialFireButtonTimer)
		{
			m_specialFireButtonTimer[this.index] = specialFireButtonTimer;
		}
	}
	
	property Party m_party
	{
		public get()
		{
			return m_party[this.index];
		}
		public set(Party party)
		{
			m_party[this.index] = party;
		}
	}
	
	property bool m_bIsPartyMenuActive
	{
		public get()
		{
			return m_bIsPartyMenuActive[this.index];
		}
		public set(bool bIsPartyMenuActive)
		{
			m_bIsPartyMenuActive[this.index] = bIsPartyMenuActive;
		}
	}
	
	property int m_iSpawnDeathCount
	{
		public get()
		{
			return m_iSpawnDeathCount[this.index];
		}
		public set(int iSpawnDeathCount)
		{
			m_iSpawnDeathCount[this.index] = iSpawnDeathCount;
		}
	}
	
	property BombDeployingState_t m_nDeployingBombState
	{
		public get()
		{
			return view_as<BombDeployingState_t>(GetEntData(this.index, GetOffset("CTFPlayer", "m_nDeployingBombState")));
		}
		public set(BombDeployingState_t nDeployingBombState)
		{
			SetEntData(this.index, GetOffset("CTFPlayer", "m_nDeployingBombState"), nDeployingBombState);
		}
	}
	
	property bool m_bIsMissionEnemy
	{
		public get()
		{
			return GetEntData(this.index, GetOffset("CTFPlayer", "m_bIsMissionEnemy"), 1) != 0;
		}
		public set(bool bIsMissionEnemy)
		{
			SetEntData(this.index, GetOffset("CTFPlayer", "m_bIsMissionEnemy"), bIsMissionEnemy, 1);
		}
	}
	
	property bool m_bIsSupportEnemy
	{
		public get()
		{
			return GetEntData(this.index, GetOffset("CTFPlayer", "m_bIsSupportEnemy"), 1) != 0;
		}
		public set(bool bIsSupportEnemy)
		{
			SetEntData(this.index, GetOffset("CTFPlayer", "m_bIsSupportEnemy"), bIsSupportEnemy, 1);
		}
	}
	
	property bool m_bIsLimitedSupportEnemy
	{
		public get()
		{
			GetEntData(this.index, GetOffset("CTFPlayer", "m_bIsLimitedSupportEnemy"), 1) != 0;
		}
		public set(bool bIsLimitedSupportEnemy)
		{
			SetEntData(this.index, GetOffset("CTFPlayer", "m_bIsLimitedSupportEnemy"), bIsLimitedSupportEnemy, 1);
		}
	}
	
	property float m_accumulatedSentryGunDamageDealt
	{
		public get()
		{
			return GetEntDataFloat(this.index, GetOffset("CTFPlayer", "m_accumulatedSentryGunDamageDealt"));
		}
		public set(float accumulatedSentryGunDamageDealt)
		{
			SetEntDataFloat(this.index, GetOffset("CTFPlayer", "m_accumulatedSentryGunDamageDealt"), accumulatedSentryGunDamageDealt);
		}
	}
	
	property int m_accumulatedSentryGunKillCount
	{
		public get()
		{
			return GetEntData(this.index, GetOffset("CTFPlayer", "m_accumulatedSentryGunKillCount"));
		}
		public set(int accumulatedSentryGunKillCount)
		{
			GetEntData(this.index, GetOffset("CTFPlayer", "m_accumulatedSentryGunKillCount"), accumulatedSentryGunKillCount);
		}
	}
	
	property Address m_iszClassIcon
	{
		public get()
		{
			return view_as<Address>(GetEntData(this.index, FindSendPropInfo("CTFPlayer", "m_iszClassIcon")));
		}
		public set(Address iszClassIcon)
		{
			SetEntData(this.index, FindSendPropInfo("CTFPlayer", "m_iszClassIcon"), iszClassIcon);
		}
	}
	
	property float m_flSpawnTime
	{
		public get()
		{
			return GetEntDataFloat(this.index, GetOffset("CTFPlayer", "m_flSpawnTime"));
		}
		public set(float flSpawnTime)
		{
			SetEntDataFloat(this.index, GetOffset("CTFPlayer", "m_flSpawnTime"), flSpawnTime);
		}
	}
	
	property Address m_pWaveSpawnPopulator
	{
		public set(Address pWaveSpawnPopulator)
		{
			SetEntData(this.index, GetOffset("CTFPlayer", "m_pWaveSpawnPopulator"), pWaveSpawnPopulator);
		}
	}
	
	public bool IsInvader()
	{
		if (IsClientSourceTV(this.index))
			return false;
		
		TFTeam team = TF2_GetClientTeam(this.index);
		return team == TFTeam_Invaders || (team == TFTeam_Spectator && !this.HasPreference(PREF_SPECTATOR_MODE));
	}
	
	public float GetSpawnTime()
	{
		return this.m_flSpawnTime;
	}
	
	public TFTeam GetDisguiseTeam()
	{
		return view_as<TFTeam>(this.GetProp(Prop_Send, "m_nDisguiseTeam"));
	}
	
	public bool IsMiniBoss()
	{
		return this.GetProp(Prop_Send, "m_bIsMiniBoss") != 0;
	}
	
	public int GetFlagTarget()
	{
		return this.m_hFollowingFlagTarget;
	}
	
	public void SetFlagTarget(int flag)
	{
		this.m_hFollowingFlagTarget = flag;
	}
	
	public bool HasFlagTarget()
	{
		return IsValidEntity(this.m_hFollowingFlagTarget);
	}
	
	public void SetSpawnPoint(int spawnPoint)
	{
		this.m_spawnPointEntity = spawnPoint;
	}
	
	public BombDeployingState_t GetDeployingBombState()
	{
		return this.m_nDeployingBombState;
	}
	
	public void SetDeployingBombState(BombDeployingState_t nDeployingBombState)
	{
		this.m_nDeployingBombState = nDeployingBombState;
	}
	
	public void SetAutoJump(float flAutoJumpMin, float flAutoJumpMax)
	{
		this.m_flAutoJumpMin = flAutoJumpMin;
		this.m_flAutoJumpMax = flAutoJumpMax;
	}
	
	public void ClearWeaponRestrictions()
	{
		this.m_weaponRestrictionFlags = ANY_WEAPON;
	}
	
	public void SetWeaponRestriction(WeaponRestrictionType restrictionFlags)
	{
		this.m_weaponRestrictionFlags |= restrictionFlags;
	}
	
	public void RemoveWeaponRestriction(WeaponRestrictionType restrictionFlags)
	{
		this.m_weaponRestrictionFlags &= ~restrictionFlags;
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
		int index = this.m_tags.FindString(tag);
		if (index != -1)
		{
			this.m_tags.Erase(index);
		}
	}
	
	public bool HasTag(const char[] tag)
	{
		return this.m_tags.FindString(tag) != -1;
	}
	
	public void GetIdleSound(char[] buffer, int maxlen)
	{
		strcopy(buffer, maxlen, m_szIdleSound[this.index]);
	}
	
	public void SetIdleSound(const char[] soundName)
	{
		strcopy(m_szIdleSound[this.index], sizeof(m_szIdleSound[]), soundName);
	}
	
	public void ClearIdleSound()
	{
		m_szIdleSound[this.index][0] = EOS;
	}
	
	public void SetScaleOverride(float fScale)
	{
		this.m_fModelScaleOverride = fScale;
		
		this.SetModelScale(this.m_fModelScaleOverride > 0.0 ? this.m_fModelScaleOverride : 1.0);
	}
	
	public MissionType GetPrevMission()
	{
		return this.m_prevMission;
	}
	
	public void SetPrevMission(MissionType prevMission)
	{
		this.m_prevMission = prevMission;
	}
	
	public bool HasMission(MissionType mission)
	{
		return this.m_mission == mission ? true : false;
	}
	
	public bool IsOnAnyMission()
	{
		return this.m_mission == NO_MISSION ? false : true;
	}
	
	public MissionType GetMission()
	{
		return this.m_mission;
	}
	
	public void SetMission(MissionType mission)
	{
		this.SetPrevMission(this.m_mission);
		this.m_mission = mission;
		
		// Temp hack - some missions play an idle loop
		if (this.m_mission > NO_MISSION)
		{
			this.StartIdleSound();
		}
	}
	
	public int GetMissionTarget()
	{
		return this.m_missionTarget;
	}
	
	public void SetMissionTarget(int missionTarget)
	{
		this.m_missionTarget = missionTarget;
	}
	
	public void SetTeleportWhere(CUtlVector teleportWhereName)
	{
		for (int i = 0; i < teleportWhereName.Count(); ++i)
		{
			char name[64];
			PtrToString(LoadFromAddress(teleportWhereName.Get(i), NumberType_Int32), name, sizeof(name));
			
			this.m_teleportWhereName.PushString(name);
		}
	}
	
	public ArrayList GetTeleportWhere()
	{
		return this.m_teleportWhereName;
	}
	
	public void ClearTeleportWhere()
	{
		this.m_teleportWhereName.Clear();
	}
	
	public void StartIdleSound()
	{
		this.StopIdleSound();
		
		if (!IsMannVsMachineMode())
			return;
		
		if (this.IsMiniBoss())
		{
			char pszSoundName[PLATFORM_MAX_PATH];
			
			TFClassType class = TF2_GetPlayerClass(this.index);
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
					if (this.m_mission == MISSION_DESTROY_SENTRIES)
					{
						strcopy(pszSoundName, sizeof(pszSoundName), "MVM.SentryBusterLoop");
					}
					else
					{
						strcopy(pszSoundName, sizeof(pszSoundName), "MVM.GiantDemomanLoop");
					}
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
				EmitGameSoundToAll(pszSoundName, this.index);
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
			StopGameSound(this.index, idleSound);
			this.ClearIdleSound();
		}
	}
	
	public void SetInvaderName(const char[] name, bool bSetName)
	{
		strcopy(m_szInvaderName[this.index], sizeof(m_szInvaderName[]), name);
		
		// if requested, change client name
		if (bSetName && GetClientName(this.index, m_szPrevName[this.index], sizeof(m_szPrevName[])))
		{
			SetClientName(this.index, name);
		}
	}
	
	public bool GetInvaderName(char[] buffer, int maxlen)
	{
		return strcopy(buffer, maxlen, m_szInvaderName[this.index]) != 0;
	}
	
	public void ResetInvaderName()
	{
		m_szInvaderName[this.index][0] = EOS;
		
		if (m_szPrevName[this.index][0])
		{
			SetClientName(this.index, m_szPrevName[this.index]);
			m_szPrevName[this.index][0] = EOS;
		}
	}
	
	public DifficultyType GetDifficulty()
	{
		return this.m_difficulty;
	}
	
	public void SetDifficulty(DifficultyType difficulty)
	{
		this.m_difficulty = difficulty;
		
		this.SetProp(Prop_Send, "m_nBotSkill", difficulty);
	}
	
	public bool IsDifficulty(DifficultyType skill)
	{
		return skill == this.m_difficulty;
	}
	
	public void ModifyMaxHealth(int nNewMaxHealth, bool bSetCurrentHealth = true, bool bAllowModelScaling = true)
	{
		if (TF2Util_GetEntityMaxHealth(this.index) != nNewMaxHealth)
		{
			TF2Attrib_SetByName(this.index, "hidden maxhealth non buffed", float(nNewMaxHealth - TF2Util_GetEntityMaxHealth(this.index)));
		}
		
		if (bSetCurrentHealth)
		{
			this.SetProp(Prop_Data, "m_iHealth", nNewMaxHealth);
		}
		
		if (bAllowModelScaling && this.IsMiniBoss())
		{
			this.SetModelScale(this.m_fModelScaleOverride > 0.0 ? this.m_fModelScaleOverride : tf_mvm_miniboss_scale.FloatValue);
		}
	}
	
	public void SetCustomCurrencyWorth(int nAmount)
	{
		this.SetProp(Prop_Send, "m_nCurrency", nAmount);
	}
	
	public void SetWaveSpawnPopulator(CWaveSpawnPopulator pWave)
	{
		this.m_pWaveSpawnPopulator = pWave;
	}
	
	public void ClearEventChangeAttributes()
	{
		this.m_eventChangeAttributes.Clear();
	}
	
	public void AddEventChangeAttributes(EventChangeAttributes_t newEvent)
	{
		this.m_eventChangeAttributes.Push(newEvent);
	}
	
	public EventChangeAttributes_t GetEventChangeAttributes(Address pszEventName)
	{
		for (int i = 0; i < this.m_eventChangeAttributes.Length; ++i)
		{
			EventChangeAttributes_t attributes = this.m_eventChangeAttributes.Get(i);
			
			if (StrPtrEquals(attributes.m_eventName, pszEventName))
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
			this.SetDifficulty(pEvent.m_skill);
			
			this.ClearWeaponRestrictions();
			this.SetWeaponRestriction(pEvent.m_weaponRestriction);
			
			this.SetMission(pEvent.m_mission);
			
			this.ClearAllAttributes();
			this.SetAttribute(pEvent.m_attributeFlags);
			
			if (IsMannVsMachineMode())
			{
				this.SetAttribute(BECOME_SPECTATOR_ON_DEATH);
				this.SetAttribute(RETAIN_BUILDINGS);
			}
			
			// cache off health value before we clear attribute because ModifyMaxHealth adds new attribute and reset the health
			int nHealth = this.GetProp(Prop_Data, "m_iHealth");
			int nMaxHealth = TF2Util_GetEntityMaxHealth(this.index);
			
			// remove any player attributes
			TF2Attrib_RemoveAll(this.index);
			// and add ones that we want specifically
			for (int i = 0; i < pEvent.m_characterAttributes.Count(); i++)
			{
				Address characterAttributes = pEvent.m_characterAttributes.Get(i, GetOffset(NULL_STRING, "sizeof(static_attrib_t)"));
				int defIndex = LoadFromAddress(characterAttributes + GetOffset("static_attrib_t", "iDefIndex"), NumberType_Int16);
				
				Address pDef = TF2Econ_GetAttributeDefinitionAddress(defIndex);
				if (pDef)
				{
					float flValue = LoadFromAddress(characterAttributes + GetOffset("static_attrib_t", "m_value"), NumberType_Int32);
					TF2Attrib_SetByDefIndex(this.index, defIndex, flValue);
				}
			}
			TF2Attrib_ClearCache(this.index);
			
			// set health back to what it was before we clear bot's attributes
			this.ModifyMaxHealth(nMaxHealth);
			this.SetProp(Prop_Data, "m_iHealth", nHealth);
			
			// give items to bot before apply attribute changes
			for (int i = 0; i < pEvent.m_items.Count(); i++)
			{
				char item[64];
				PtrToString(LoadFromAddress(pEvent.m_items.Get(i), NumberType_Int32), item, sizeof(item));
				
				this.AddItem(item);
			}
			
			for (int i = 0; i < pEvent.m_itemsAttributes.Count(); i++)
			{
				Address itemAttributes = pEvent.m_itemsAttributes.Get(i, GetOffset(NULL_STRING, "sizeof(item_attributes_t)"));
				
				char itemName[64];
				PtrToString(LoadFromAddress(itemAttributes + GetOffset("item_attributes_t", "m_itemName"), NumberType_Int32), itemName, sizeof(itemName));
				
				int itemDef = GetItemDefinitionIndexByName(itemName);
				
				for (int iItemSlot = LOADOUT_POSITION_PRIMARY; iItemSlot < CLASS_LOADOUT_POSITION_COUNT; iItemSlot++)
				{
					int entity = TF2Util_GetPlayerLoadoutEntity(this.index, iItemSlot);
					
					if (entity != -1 && itemDef == GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"))
					{
						CUtlVector attributes = CUtlVector(itemAttributes + GetOffset("item_attributes_t", "m_attributes"));
						for (int iAtt = 0; iAtt < attributes.Count(); ++iAtt)
						{
							Address attrib = attributes.Get(iAtt, GetOffset(NULL_STRING, "sizeof(static_attrib_t)"));
							
							int defIndex = LoadFromAddress(attrib + GetOffset("static_attrib_t", "iDefIndex"), NumberType_Int16);
							float value = LoadFromAddress(attrib + GetOffset("static_attrib_t", "m_value"), NumberType_Int32);
							
							TF2Attrib_SetByDefIndex(entity, defIndex, value);
						}
						
						if (entity != -1)
						{
							// update model incase we change style
							SDKCall_CEconEntity_UpdateModelToClass(entity);
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
				PtrToString(LoadFromAddress(pEvent.m_tags.Get(i), NumberType_Int32), tag, sizeof(tag));
				
				this.AddTag(tag);
			}
			
			// human skill attributes
			if (!IsFakeClient(this.index))
			{
				this.SetSkillAttributes();
			}
			
			// Request to Add in Endless
			if (g_pPopulationManager.IsInEndlessWaves())
			{
				g_pPopulationManager.EndlessSetAttributesForBot(this.index);
			}
		}
	}
	
	public void AddItem(const char[] szItemName)
	{
		int itemDefIndex = GetItemDefinitionIndexByName(szItemName);
		if (itemDefIndex != TF_ITEMDEF_DEFAULT)
		{
			// If we already have an item in that slot, remove it
			TFClassType class = TF2_GetPlayerClass(this.index);
			int slot = TF2Econ_GetItemLoadoutSlot(itemDefIndex, class);
			int newItemRegionMask = TF2Econ_GetItemEquipRegionMask(itemDefIndex);
			
			if (IsWearableSlot(slot))
			{
				// Remove any wearable that has a conflicting equip_region
				for (int wbl = 0; wbl < TF2Util_GetPlayerWearableCount(this.index); wbl++)
				{
					int pWearable = TF2Util_GetPlayerWearable(this.index, wbl);
					if (pWearable == -1)
						continue;
					
					int wearableDefIndex = GetEntProp(pWearable, Prop_Send, "m_iItemDefinitionIndex");
					if (wearableDefIndex == INVALID_ITEM_DEF_INDEX)
						continue;
					
					int wearableRegionMask = TF2Econ_GetItemEquipRegionMask(wearableDefIndex);
					if (wearableRegionMask & newItemRegionMask)
					{
						TF2_RemoveWearable(this.index, pWearable);
					}
				}
			}
			else
			{
				int entity = TF2Util_GetPlayerLoadoutEntity(this.index, slot);
				if (entity != -1)
				{
					RemovePlayerItem(this.index, entity);
					RemoveEntity(entity);
				}
			}
			
			SDKCall_BotGenerateAndWearItem(this.index, szItemName);
		}
		else
		{
			if (szItemName[0])
			{
				LogError("CTFBotSpawner::AddItemToBot: Invalid item %s.", szItemName);
			}
		}
	}
	
	public void SetSkillAttributes()
	{
		// average skill of a human player matches HARD bots
		switch (this.GetDifficulty())
		{
			case EASY:
			{
				if (TF2_GetPlayerClass(this.index) == TFClass_Pyro)
				{
					int weapon = TF2Util_GetPlayerLoadoutEntity(this.index, LOADOUT_POSITION_PRIMARY);
					if (weapon != -1)
					{
						TF2Attrib_SetByName(weapon, "airblast disabled", 1.0);
					}
				}
				
				MultiplyAttributeValue(this.index, "damage penalty", 0.75);
			}
			case NORMAL:
			{
				MultiplyAttributeValue(this.index, "damage penalty", 0.9);
			}
			case EXPERT:
			{
				MultiplyAttributeValue(this.index, "damage bonus", 1.1);
			}
		}
	}
	
	public bool EquipRequiredWeapon()
	{
		if (!this.m_requiredWeaponStack.Empty)
		{
			// ArrayStack.Top()
			int weapon = this.m_requiredWeaponStack.Pop();
			this.m_requiredWeaponStack.Push(weapon);
			return TF2Util_SetPlayerActiveWeapon(this.index, weapon);
		}
		
		if (tf_bot_melee_only.BoolValue || GameRules_GetProp("m_bPlayingMedieval") || this.HasWeaponRestriction(MELEE_ONLY))
		{
			// force use of melee weapons
			TF2Util_SetPlayerActiveWeapon(this.index, GetPlayerWeaponSlot(this.index, TFWeaponSlot_Melee));
			return true;
		}
		
		if (this.HasWeaponRestriction(PRIMARY_ONLY))
		{
			TF2Util_SetPlayerActiveWeapon(this.index, GetPlayerWeaponSlot(this.index, TFWeaponSlot_Primary));
			return true;
		}
		
		if (this.HasWeaponRestriction(SECONDARY_ONLY))
		{
			TF2Util_SetPlayerActiveWeapon(this.index, GetPlayerWeaponSlot(this.index, TFWeaponSlot_Secondary));
			return true;
		}
		
		return false;
	}
	
	public bool IsBarrageAndReloadWeapon(int weapon)
	{
		if (weapon == MY_CURRENT_GUN)
		{
			weapon = this.GetPropEnt(Prop_Send, "m_hActiveWeapon");
		}
		
		if (weapon != -1)
		{
			switch (TF2Util_GetWeaponID(weapon))
			{
				case TF_WEAPON_ROCKETLAUNCHER, TF_WEAPON_DIRECTHIT, TF_WEAPON_GRENADELAUNCHER, TF_WEAPON_PIPEBOMBLAUNCHER, TF_WEAPON_SCATTERGUN:
				{
					return true;
				}
			}
		}
		
		return false;
	}
	
	public void SetModelScale(float scale, float change_duration = 0.0)
	{
		float vecScale[3];
		vecScale[0] = scale;
		vecScale[1] = change_duration;
		
		SetVariantVector3D(vecScale);
		this.AcceptInput("SetModelScale");
	}
	
	public bool HasTheFlag()
	{
		return this.GetPropEnt(Prop_Send, "m_hItem") != -1;
	}
	
	public int GetFlagToFetch()
	{
		int nCarriedFlags = 0;
		
		// MvM Engineer bot never pick up a flag
		if (IsMannVsMachineMode())
		{
			if (TF2_GetClientTeam(this.index) == TFTeam_Invaders && TF2_GetPlayerClass(this.index) == TFClass_Engineer)
			{
				return INVALID_ENT_REFERENCE;
			}
			
			if (this.HasAttribute(IGNORE_FLAG))
			{
				return INVALID_ENT_REFERENCE;
			}
			
			if (IsMannVsMachineMode() && this.HasFlagTarget())
			{
				return this.GetFlagTarget();
			}
		}
		
		ArrayList flagsList = new ArrayList();
		
		// Collect flags
		int flag = -1;
		while ((flag = FindEntityByClassname(flag, "item_teamflag")) != -1)
		{
			if (GetEntProp(flag, Prop_Send, "m_bDisabled"))
				continue;
			
			// If I'm carrying a flag, look for mine and early-out
			if (this.HasTheFlag())
			{
				if (GetEntPropEnt(flag, Prop_Send, "m_hOwnerEntity") == this.index)
				{
					delete flagsList;
					return EntIndexToEntRef(flag);
				}
			}
			
			switch (view_as<ETFFlagType>(GetEntProp(flag, Prop_Send, "m_nType")))
			{
				case TF_FLAGTYPE_CTF:
				{
					if (view_as<TFTeam>(GetEntProp(flag, Prop_Send, "m_iTeamNum")) == GetEnemyTeam(TF2_GetClientTeam(this.index)))
					{
						// we want to steal the other team's flag
						flagsList.Push(flag);
					}
				}
				
				case TF_FLAGTYPE_ATTACK_DEFEND, TF_FLAGTYPE_TERRITORY_CONTROL, TF_FLAGTYPE_INVADE:
				{
					if (view_as<TFTeam>(GetEntProp(flag, Prop_Send, "m_iTeamNum")) != GetEnemyTeam(TF2_GetClientTeam(this.index)))
					{
						// we want to move our team's flag or a neutral flag
						flagsList.Push(flag);
					}
				}
			}
			
			if (GetEntProp(flag, Prop_Send, "m_nFlagStatus") == TF_FLAGINFO_STOLEN)
			{
				nCarriedFlags++;
			}
		}
		
		int closestFlag = INVALID_ENT_REFERENCE;
		float flClosestFlagDist = FLT_MAX;
		int closestUncarriedFlag = INVALID_ENT_REFERENCE;
		float flClosestUncarriedFlagDist = FLT_MAX;
		
		if (IsMannVsMachineMode())
		{
			for (int i = 0; i < flagsList.Length; i++)
			{
				if (IsValidEntity(flagsList.Get(i)))
				{
					// Find the closest
					float flagOrigin[3], playerOrigin[3];
					GetEntPropVector(flagsList.Get(i), Prop_Data, "m_vecAbsOrigin", flagOrigin);
					this.GetAbsOrigin(playerOrigin);
					
					float origins[3];
					SubtractVectors(flagOrigin, playerOrigin, origins);
					
					float flDist = GetVectorLength(origins, true);
					if (flDist < flClosestFlagDist)
					{
						closestFlag = EntIndexToEntRef(flagsList.Get(i));
						flClosestFlagDist = flDist;
					}
					
					// Find the closest uncarried
					if (nCarriedFlags < flagsList.Length && GetEntProp(flagsList.Get(i), Prop_Send, "m_nFlagStatus") != TF_FLAGINFO_STOLEN)
					{
						if (flDist < flClosestUncarriedFlagDist)
						{
							closestUncarriedFlag = EntIndexToEntRef(flagsList.Get(i));
							flClosestUncarriedFlagDist = flDist;
						}
					}
				}
			}
		}
		
		delete flagsList;
		
		// If we have an uncarried flag, prioritize
		if (closestUncarriedFlag != INVALID_ENT_REFERENCE)
			return closestUncarriedFlag;
		
		return closestFlag;
	}
	
	public int GetFlagCaptureZone()
	{
		int zone = -1;
		while ((zone = FindEntityByClassname(zone, "func_capturezone")) != -1)
		{
			if (GetEntProp(zone, Prop_Data, "m_iTeamNum") == GetClientTeam(this.index))
			{
				return zone;
			}
		}
		
		return -1;
	}
	
	public void PushRequiredWeapon(int weapon)
	{
		this.m_requiredWeaponStack.Push(weapon);
	}
	
	public void PopRequiredWeapon()
	{
		this.m_requiredWeaponStack.Pop();
	}
	
	public float CalculateSpawnTime()
	{
		if (sm_mitm_spawn_hurry_time.FloatValue <= 0.0)
			return -1.0;
		
		// factor in squad speed
		float flSpeed = this.IsInASquad() ? this.GetSquad().GetSlowestMemberSpeed() : this.GetPropFloat(Prop_Send, "m_flMaxspeed");
		return sm_mitm_spawn_hurry_time.FloatValue + (sm_mitm_spawn_hurry_time.FloatValue * (300.0 / flSpeed));
	}
	
	public bool ShouldAutoJump()
	{
		if (!this.HasAttribute(AUTO_JUMP))
			return false;
		
		if (!this.m_autoJumpTimer.HasStarted())
		{
			this.m_autoJumpTimer.Start(GetRandomFloat(this.m_flAutoJumpMin, this.m_flAutoJumpMax));
			return true;
		}
		else if (this.m_autoJumpTimer.IsElapsed())
		{
			this.m_autoJumpTimer.Start(GetRandomFloat(this.m_flAutoJumpMin, this.m_flAutoJumpMax));
			return true;
		}
		
		return false;
	}
	
	public void PressFireButton(float duration = -1.0)
	{
		this.m_inputButtons |= IN_ATTACK;
		this.m_fireButtonTimer.Start(duration);
	}
	
	public void PressAltFireButton(float duration = -1.0)
	{
		this.m_inputButtons |= IN_ATTACK2;
		this.m_altFireButtonTimer.Start(duration);
	}
	
	public void PressSpecialFireButton(float duration = -1.0)
	{
		this.m_inputButtons |= IN_ATTACK3;
		this.m_specialFireButtonTimer.Start(duration);
	}
	
	public NextBotAction OpportunisticallyUseWeaponAbilities()
	{
		if (!this.m_opportunisticTimer.IsElapsed())
		{
			return NULL_ACTION;
		}
		
		this.m_opportunisticTimer.Start(GetRandomFloat(0.1, 0.2));
		
		int numWeapons = this.GetPropArraySize(Prop_Send, "m_hMyWeapons");
		for (int i = 0; i < numWeapons; ++i)
		{
			int weapon = GetPlayerWeaponSlot(this.index, i);
			if (weapon == -1 || !TF2Util_IsEntityWeapon(weapon))
				continue;
			
			// if I have some kind of buff banner - use it!
			if (TF2Util_GetWeaponID(weapon) == TF_WEAPON_BUFF_ITEM)
			{
				if (this.GetPropFloat(Prop_Send, "m_flRageMeter") >= 100.0)
				{
					return CTFBotUseItem(weapon);
				}
			}
			else if (TF2Util_GetWeaponID(weapon) == TF_WEAPON_LUNCHBOX)
			{
				// if we have an eatable (drink, sandvich, etc) - eat it!
				if (SDKCall_CBaseCombatWeapon_HasAmmo(weapon))
				{
					// scout lunchboxes are also gated by their energy drink meter
					if (TF2_GetPlayerClass(this.index) != TFClass_Scout || this.GetPropFloat(Prop_Send, "m_flEnergyDrinkMeter") >= 100)
					{
						return CTFBotUseItem(weapon);
					}
				}
			}
		}
		
		return NULL_ACTION;
	}
	
	public int GetClosestCaptureZone()
	{
		int captureZone = -1;
		float flClosestDistance = FLT_MAX;
		
		int tempCaptureZone = -1;
		while ((tempCaptureZone = FindEntityByClassname(tempCaptureZone, "func_capturezone")) != -1)
		{
			if (!GetEntProp(tempCaptureZone, Prop_Data, "m_bDisabled") && GetEntProp(tempCaptureZone, Prop_Data, "m_iTeamNum") == GetClientTeam(this.index))
			{
				float origin[3], center[3];
				this.GetAbsOrigin(origin);
				CBaseEntity(tempCaptureZone).WorldSpaceCenter(center);
				
				float fCurrentDistance = GetVectorDistance(origin, center);
				if (flClosestDistance > fCurrentDistance)
				{
					captureZone = tempCaptureZone;
					flClosestDistance = fCurrentDistance;
				}
			}
		}
		
		return captureZone;
	}
	
	public void DisguiseAsMemberOfEnemyTeam()
	{
		ArrayList enemyList = new ArrayList();
		CollectPlayers(enemyList, GetEnemyTeam(TF2_GetClientTeam(this.index)));
		
		TFClassType disguise = view_as<TFClassType>(GetRandomInt(view_as<int>(TFClass_Scout), view_as<int>(TFClass_Engineer)));
		
		if (enemyList.Length > 0)
		{
			disguise = TF2_GetPlayerClass(enemyList.Get(GetRandomInt(0, enemyList.Length - 1)));
		}
		
		TF2_DisguisePlayer(this.index, GetEnemyTeam(TF2_GetClientTeam(this.index)), disguise);
		delete enemyList;
	}
	
	public bool HasPreference(MannInTheMachinePreference preference)
	{
		return this.m_preferences != -1 && this.m_preferences & view_as<int>(preference) != 0;
	}
	
	public bool SetPreference(MannInTheMachinePreference preference, bool enable)
	{
		if (this.m_preferences == -1)
			return false;
		
		if (enable)
			this.m_preferences |= view_as<int>(preference);
		else
			this.m_preferences &= ~view_as<int>(preference);
		
		ClientPrefs_SavePreferences(this.index, this.m_preferences);
		
		return true;
	}
	
	public void MarkAsMissionEnemy()
	{
		this.m_bIsMissionEnemy = true;
	}
	
	public void MarkAsSupportEnemy()
	{
		this.m_bIsSupportEnemy = true;
	}
	
	public void MarkAsLimitedSupportEnemy()
	{
		this.m_bIsLimitedSupportEnemy = true;
	}
	
	public Address GetClassIconName()
	{
		return this.m_iszClassIcon;
	}
	
	public void SetClassIconName(Address iszClassIcon)
	{
		this.m_iszClassIcon = iszClassIcon;
	}
	
	public CTFBotSquad GetSquad()
	{
		return this.m_squad;
	}
	
	public void JoinSquad(CTFBotSquad squad)
	{
		if (squad)
		{
			squad.Join(this.index);
			this.m_squad = squad;
		}
	}
	
	public void LeaveSquad()
	{
		if (this.m_squad)
		{
			this.m_squad.Leave(this.index);
			this.m_squad = NULL_SQUAD;
		}
	}
	
	public bool IsInASquad()
	{
		return this.m_squad == NULL_SQUAD ? false : true;
	}
	
	public void DeleteSquad()
	{
		if (this.m_squad)
		{
			this.m_squad = NULL_SQUAD;
		}
	}
	
	public Party GetParty()
	{
		return this.m_party;
	}
	
	public void InviteToParty(Party party)
	{
		if (party)
		{
			party.AddInvite(this.index);
		}
	}
	
	public void JoinParty(Party party)
	{
		if (party)
		{
			party.Join(this.index);
			this.m_party = party;
		}
	}
	
	public void LeaveParty()
	{
		if (this.m_party)
		{
			this.m_party.Leave(this.index);
			this.m_party = NULL_PARTY;
		}
	}
	
	public bool IsInAParty()
	{
		return this.m_party.IsValid() ? true : false;
	}
	
	public void DeleteParty()
	{
		if (this.m_party)
		{
			this.m_party = NULL_PARTY;
		}
	}
	
	public bool IsPartyMenuActive()
	{
		return this.m_bIsPartyMenuActive;
	}
	
	public void SetPartyMenuActive(bool bIsPartyMenuActive)
	{
		this.m_bIsPartyMenuActive = bIsPartyMenuActive;
	}
	
	public void Init()
	{
		this.m_autoJumpTimer = new CountdownTimer();
		this.m_teleportWhereName = new ArrayList(ByteCountToCells(64));
		this.m_eventChangeAttributes = new ArrayList();
		this.m_tags = new ArrayList(ByteCountToCells(64));
		this.m_requiredWeaponStack = new ArrayStack();
		this.m_opportunisticTimer = new CountdownTimer();
		this.m_fireButtonTimer = new CountdownTimer();
		this.m_altFireButtonTimer = new CountdownTimer();
		this.m_specialFireButtonTimer = new CountdownTimer();
	}
	
	public void ResetInvader()
	{
		this.SetAutoJump(0.0, 0.0);
		this.m_autoJumpTimer.Invalidate();
		
		this.ClearTeleportWhere();
		this.ClearEventChangeAttributes();
		this.ClearTags();
		this.m_requiredWeaponStack.Clear();
		this.ClearWeaponRestrictions();
		this.ClearAllAttributes();
		this.ClearIdleSound();
		
		this.m_fModelScaleOverride = 0.0;
		this.m_flSpawnTimeLeft = -1.0;
		this.m_flSpawnTimeLeftMax = -1.0;
		this.m_missionTarget = INVALID_ENT_REFERENCE;
		this.m_spawnPointEntity = INVALID_ENT_REFERENCE;
		this.m_hFollowingFlagTarget = INVALID_ENT_REFERENCE;
		this.m_isWaitingForFullReload = false;
		this.m_annotationTimer = null;
		
		this.m_inputButtons = 0;
		this.m_fireButtonTimer.Invalidate();
		this.m_altFireButtonTimer.Invalidate();
		this.m_specialFireButtonTimer.Invalidate();
		
		this.ResetInvaderName();
	}
	
	public void Reset()
	{
		this.m_invaderPriority = 0;
		this.m_invaderMiniBossPriority = 0;
		this.m_defenderQueuePoints = -1;
		this.m_preferences = -1;
		this.m_party = NULL_PARTY;
		this.m_bIsPartyMenuActive = false;
		this.m_iSpawnDeathCount = 0;
		
		m_szInvaderName[this.index][0] = EOS;
		m_szPrevName[this.index][0] = EOS;
	}
}

methodmap EventChangeAttributes_t < Address
{
	public EventChangeAttributes_t(Address pThis)
	{
		return view_as<EventChangeAttributes_t>(pThis);
	}
	
	property Address m_eventName
	{
		public get()
		{
			return LoadFromAddress(this + GetOffset("EventChangeAttributes_t", "m_eventName"), NumberType_Int32);
		}
	}
	
	property DifficultyType m_skill
	{
		public get()
		{
			return LoadFromAddress(this + GetOffset("EventChangeAttributes_t", "m_skill"), NumberType_Int32);
		}
	}
	
	property WeaponRestrictionType m_weaponRestriction
	{
		public get()
		{
			return LoadFromAddress(this + GetOffset("EventChangeAttributes_t", "m_weaponRestriction"), NumberType_Int32);
		}
	}
	
	property MissionType m_mission
	{
		public get()
		{
			return LoadFromAddress(this + GetOffset("EventChangeAttributes_t", "m_mission"), NumberType_Int32);
		}
	}
	
	property any m_attributeFlags
	{
		public get()
		{
			return LoadFromAddress(this + GetOffset("EventChangeAttributes_t", "m_attributeFlags"), NumberType_Int32);
		}
	}
	
	property CUtlVector m_items
	{
		public get()
		{
			return CUtlVector(this + GetOffset("EventChangeAttributes_t", "m_items"));
		}
	}
	
	property CUtlVector m_itemsAttributes
	{
		public get()
		{
			return CUtlVector(this + GetOffset("EventChangeAttributes_t", "m_itemsAttributes"));
		}
	}
	
	property CUtlVector m_characterAttributes
	{
		public get()
		{
			return CUtlVector(this + GetOffset("EventChangeAttributes_t", "m_characterAttributes"));
		}
	}
	
	property CUtlVector m_tags
	{
		public get()
		{
			return CUtlVector(this + GetOffset("EventChangeAttributes_t", "m_tags"));
		}
	}
};

methodmap CTFBotSpawner < Address
{
	public CTFBotSpawner(Address pThis)
	{
		return view_as<CTFBotSpawner>(pThis);
	}
	
	property EventChangeAttributes_t m_defaultAttributes
	{
		public get()
		{
			return view_as<EventChangeAttributes_t>(this + GetOffset("CTFBotSpawner", "m_defaultAttributes"));
		}
	}
	
	property CUtlVector m_eventChangeAttributes
	{
		public get()
		{
			return CUtlVector(this + GetOffset("CTFBotSpawner", "m_eventChangeAttributes"));
		}
	}
	
	property int m_health
	{
		public get()
		{
			return LoadFromAddress(this + GetOffset("CTFBotSpawner", "m_health"), NumberType_Int32);
		}
	}
	
	property TFClassType m_class
	{
		public get()
		{
			return LoadFromAddress(this + GetOffset("CTFBotSpawner", "m_class"), NumberType_Int32);
		}
	}
	
	property float m_scale
	{
		public get()
		{
			return LoadFromAddress(this + GetOffset("CTFBotSpawner", "m_scale"), NumberType_Int32);
		}
	}
	
	property float m_flAutoJumpMin
	{
		public get()
		{
			return LoadFromAddress(this + GetOffset("CTFBotSpawner", "m_flAutoJumpMin"), NumberType_Int32);
		}
	}
	
	property float m_flAutoJumpMax
	{
		public get()
		{
			return LoadFromAddress(this + GetOffset("CTFBotSpawner", "m_flAutoJumpMax"), NumberType_Int32);
		}
	}
	
	property CUtlVector m_teleportWhereName
	{
		public get()
		{
			return CUtlVector(this + GetOffset("CTFBotSpawner", "m_teleportWhereName"));
		}
	}
	
	public void GetName(char[] buffer, int maxlen, const char[] defValue = "")
	{
		Address m_name = LoadFromAddress(this + GetOffset("CTFBotSpawner", "m_name"), NumberType_Int32);
		if (m_name)
		{
			PtrToString(m_name, buffer, maxlen);
		}
		else if (defValue[0])
		{
			strcopy(buffer, maxlen, defValue);
		}
	}
	
	public Address GetClassIcon(int nSpawnNum = -1)
	{
		return LoadFromAddress(SDKCall_IPopulationSpawner_GetClassIcon(this, nSpawnNum), NumberType_Int32);
	}
};

methodmap CSquadSpawner < Address
{
	public CSquadSpawner(Address pThis)
	{
		return view_as<CSquadSpawner>(pThis);
	}
	
	property float m_formationSize
	{
		public get()
		{
			return LoadFromAddress(this + GetOffset("CSquadSpawner", "m_formationSize"), NumberType_Int32);
		}
	}
	
	property bool m_bShouldPreserveSquad
	{
		public get()
		{
			return LoadFromAddress(this + GetOffset("CSquadSpawner", "m_bShouldPreserveSquad"), NumberType_Int32);
		}
	}
}

methodmap CMissionPopulator < Address
{
	public CMissionPopulator(Address pThis)
	{
		return view_as<CMissionPopulator>(pThis);
	}
	
	property MissionType m_mission
	{
		public get()
		{
			return LoadFromAddress(this + GetOffset("CMissionPopulator", "m_mission"), NumberType_Int32);
		}
	}
	
	property float m_cooldownDuration
	{
		public get()
		{
			return LoadFromAddress(this + GetOffset("CMissionPopulator", "m_cooldownDuration"), NumberType_Int32);
		}
	}
	
	property Address m_spawner
	{
		public get()
		{
			return LoadFromAddress(this + GetOffset("IPopulationSpawner", "m_spawner"), NumberType_Int32);
		}
	}
	
	property Address m_where
	{
		public get()
		{
			return this + GetOffset("IPopulationSpawner", "m_where");
		}
	}
}

methodmap CWave < Address
{
	public CWave(Address pThis)
	{
		return view_as<CWave>(pThis);
	}
	
	property int m_nNumEngineersTeleportSpawned
	{
		public get()
		{
			return LoadFromAddress(this + GetOffset("CWave", "m_nNumEngineersTeleportSpawned"), NumberType_Int32);
		}
		public set(int nNumEngineersTeleportSpawned)
		{
			WriteVal(this + GetOffset("CWave", "m_nNumEngineersTeleportSpawned"), nNumEngineersTeleportSpawned);
		}
	}
	
	property int m_nNumSentryBustersKilled
	{
		public get()
		{
			return LoadFromAddress(this + GetOffset("CWave", "m_nNumSentryBustersKilled"), NumberType_Int32);
		}
		public set(int nNumSentryBustersKilled)
		{
			WriteVal(this + GetOffset("CWave", "m_nNumSentryBustersKilled"), nNumSentryBustersKilled);
		}
	}
	
	property int m_nSentryBustersSpawned
	{
		public get()
		{
			return LoadFromAddress(this + GetOffset("CWave", "m_nSentryBustersSpawned"), NumberType_Int32);
		}
		public set(int nSentryBustersSpawned)
		{
			WriteVal(this + GetOffset("CWave", "m_nSentryBustersSpawned"), nSentryBustersSpawned);
		}
	}
	
	public int NumSentryBustersSpawned()
	{
		return this.m_nSentryBustersSpawned;
	}
	
	public void IncrementSentryBustersSpawned()
	{
		this.m_nSentryBustersSpawned++;
	}
	
	public int NumSentryBustersKilled()
	{
		return this.m_nNumSentryBustersKilled;
	}
	
	public void IncrementSentryBustersKilled()
	{
		this.m_nNumSentryBustersKilled++;
	}
	
	public void ResetSentryBustersKilled()
	{
		this.m_nNumSentryBustersKilled = 0;
	}
	
	public int NumEngineersTeleportSpawned()
	{
		return this.m_nNumEngineersTeleportSpawned;
	}
	
	public void IncrementEngineerTeleportSpawned()
	{
		this.m_nNumEngineersTeleportSpawned++;
	}
}

methodmap CPopulationManager < CBaseEntity
{
	public CPopulationManager(int entity)
	{
		return view_as<CPopulationManager>(entity);
	}
	
	property bool m_bIsInitialized
	{
		public get()
		{
			return GetEntData(this.index, GetOffset("CPopulationManager", "m_bIsInitialized"), 1) != 0;
		}
		public set(bool bIsInitialized)
		{
			SetEntData(this.index, GetOffset("CPopulationManager", "m_bIsInitialized"), bIsInitialized, 1);
		}
	}
	
	property bool m_canBotsAttackWhileInSpawnRoom
	{
		public get()
		{
			return GetEntData(this.index, GetOffset("CPopulationManager", "m_canBotsAttackWhileInSpawnRoom"), 1) != 0;
		}
	}
	
	property bool m_bSpawningPaused
	{
		public get()
		{
			return GetEntData(this.index, GetOffset("CPopulationManager", "m_bSpawningPaused"), 1) != 0;
		}
	}
	
	property Address m_defaultEventChangeAttributesName
	{
		public get()
		{
			return view_as<Address>(GetEntData(this.index, GetOffset("CPopulationManager", "m_defaultEventChangeAttributesName")));
		}
	}
	
	property CUtlVector m_EndlessActiveBotUpgrades
	{
		public get()
		{
			return CUtlVector(GetEntityAddress(this.index) + GetOffset("CPopulationManager", "m_EndlessActiveBotUpgrades"));
		}
	}
	
	public bool CanBotsAttackWhileInSpawnRoom()
	{
		return this.m_canBotsAttackWhileInSpawnRoom;
	}
	
	public bool IsSpawningPaused()
	{
		return this.m_bSpawningPaused;
	}
	
	public Address GetDefaultEventChangeAttributesName()
	{
		return this.m_defaultEventChangeAttributesName;
	}
	
	public void ResetMap()
	{
		SDKCall_CPopulationManager_ResetMap(this.index);
	}
	
	public CWave GetCurrentWave()
	{
		return CWave(SDKCall_CPopulationManager_GetCurrentWave(this.index));
	}
	
	public bool IsInEndlessWaves()
	{
		return SDKCall_CPopulationManager_IsInEndlessWaves(this.index);
	}
	
	public float GetHealthMultiplier(bool bIsTank = false)
	{
		return SDKCall_CPopulationManager_GetHealthMultiplier(this.index, bIsTank);
	}
	
	public void GetSentryBusterDamageAndKillThreshold(int &nDamage, int &nKills)
	{
		SDKCall_CPopulationManager_GetSentryBusterDamageAndKillThreshold(this.index, nDamage, nKills);
	}
	
	public void EndlessSetAttributesForBot(int player)
	{
		int nHealth = GetEntProp(player, Prop_Data, "m_iHealth");
		int nMaxHealth = TF2Util_GetEntityMaxHealth(player);
		
		for (int i = 0; i < this.m_EndlessActiveBotUpgrades.Count(); ++i)
		{
			CMvMBotUpgrade upgrade = this.m_EndlessActiveBotUpgrades.Get(i, GetOffset(NULL_STRING, "sizeof(CMvMBotUpgrade)"));
			
			if (upgrade.bIsBotAttr)
			{
				CTFPlayer(player).SetAttribute(view_as<AttributeType>(RoundFloat(upgrade.flValue)));
			}
			else if (upgrade.bIsSkillAttr)
			{
				CTFPlayer(player).SetDifficulty(view_as<DifficultyType>(RoundFloat(upgrade.flValue)));
			}
			else
			{
				Address pDef = TF2Econ_GetAttributeDefinitionAddress(upgrade.iAttribIndex);
				if (pDef)
				{
					Address pAttrib = TF2Attrib_GetByDefIndex(player, upgrade.iAttribIndex);
					if (pAttrib)
					{
						TF2Attrib_SetValue(pAttrib, TF2Attrib_GetValue(pAttrib) + upgrade.flValue);
					}
					else
					{
						int iFormat = LoadFromAddress(pDef + GetOffset("CEconItemAttributeDefinition", "m_iDescriptionFormat"), NumberType_Int32);
						float flValue = upgrade.flValue;
						if (iFormat == ATTDESCFORM_VALUE_IS_PERCENTAGE || iFormat == ATTDESCFORM_VALUE_IS_INVERTED_PERCENTAGE)
						{
							flValue += 1.0;
						}
						TF2Attrib_SetByDefIndex(player, upgrade.iAttribIndex, flValue);
					}
				}
			}
		}
		
		int nNewMaxHealth = TF2Util_GetEntityMaxHealth(player);
		SetEntProp(player, Prop_Data, "m_iHealth", nHealth + nNewMaxHealth - nMaxHealth);
	}
}

methodmap BombInfo_t < Address
{
	public BombInfo_t(Address pThis)
	{
		return view_as<BombInfo_t>(pThis);
	}
	
	property float m_flMaxBattleFront
	{
		public get()
		{
			return LoadFromAddress(this + GetOffset("BombInfo_t", "m_flMaxBattleFront"), NumberType_Int32);
		}
	}
}

methodmap CBaseTFBotHintEntity < CBaseEntity
{
	public CBaseTFBotHintEntity(int entity)
	{
		return view_as<CBaseTFBotHintEntity>(entity);
	}
	
	property bool m_isDisabled
	{
		public get()
		{
			return GetEntData(this.index, GetOffset("CBaseTFBotHintEntity", "m_isDisabled"), 1) != 0;
		}
	}
	
	public bool IsEnabled()
	{
		return !this.m_isDisabled;
	}
	
	public bool OwnerObjectHasNoOwner()
	{
		int owner = this.GetPropEnt(Prop_Send, "m_hOwnerEntity");
		if (owner != -1 && IsBaseObject(owner))
		{
			if (GetEntPropEnt(owner, Prop_Send, "m_hBuilder") == -1)
			{
				return true;
			}
			else
			{
				if (TF2_GetPlayerClass(GetEntPropEnt(owner, Prop_Send, "m_hBuilder")) != TFClass_Engineer)
				{
					LogError("Object has an owner that's not engineer.");
				}
			}
		}
		return false;
	}
	
	public bool OwnerObjectFinishBuilding()
	{
		int owner = this.GetPropEnt(Prop_Send, "m_hOwnerEntity");
		if (owner != -1 && IsBaseObject(owner))
		{
			return !GetEntProp(owner, Prop_Send, "m_bBuilding");
		}
		return false;
	}
}

methodmap CWaveSpawnPopulator < Address
{
	public CWaveSpawnPopulator(Address pThis)
	{
		return view_as<CWaveSpawnPopulator>(pThis);
	}
	
	property bool m_bSupportWave
	{
		public get()
		{
			return LoadFromAddress(this + GetOffset("CWaveSpawnPopulator", "m_bSupportWave"), NumberType_Int8);
		}
	}
	
	property bool m_bLimitedSupport
	{
		public get()
		{
			return LoadFromAddress(this + GetOffset("CWaveSpawnPopulator", "m_bLimitedSupport"), NumberType_Int8);
		}
	}
	
	public bool IsSupportWave()
	{
		return this.m_bSupportWave;
	}
	
	public bool IsLimitedSupportWave()
	{
		return this.m_bLimitedSupport;
	}
}

methodmap CMvMBotUpgrade < Address
{
	public CMvMBotUpgrade(Address pThis)
	{
		return view_as<CMvMBotUpgrade>(pThis);
	}
	
	property Address szAttrib
	{
		public get()
		{
			return this + GetOffset("CMvMBotUpgrade", "szAttrib");
		}
	}
	
	property int iAttribIndex
	{
		public get()
		{
			return LoadFromAddress(this + GetOffset("CMvMBotUpgrade", "iAttribIndex"), NumberType_Int16);
		}
	}
	
	property float flValue
	{
		public get()
		{
			return LoadFromAddress(this + GetOffset("CMvMBotUpgrade", "flValue"), NumberType_Int32);
		}
	}
	
	property bool bIsBotAttr
	{
		public get()
		{
			return LoadFromAddress(this + GetOffset("CMvMBotUpgrade", "bIsBotAttr"), NumberType_Int8);
		}
	}
	
	property bool bIsSkillAttr
	{
		public get()
		{
			return LoadFromAddress(this + GetOffset("CMvMBotUpgrade", "bIsSkillAttr"), NumberType_Int8);
		}
	}
}

methodmap CTFObjectiveResource < CBaseEntity
{
	public CTFObjectiveResource(int entity)
	{
		return view_as<CTFObjectiveResource>(entity);
	}
	
	public void SetFlagCarrierUpgradeLevel(int nLevel)
	{
		this.SetProp(Prop_Send, "m_nFlagCarrierUpgradeLevel", nLevel);
	}
	
	public void SetBaseMvMBombUpgradeTime(float nTime)
	{
		this.SetPropFloat(Prop_Send, "m_flMvMBaseBombUpgradeTime", nTime);
	}
	
	public void SetNextMvMBombUpgradeTime(float nTime)
	{
		this.SetPropFloat(Prop_Send, "m_flMvMNextBombUpgradeTime", nTime);
	}
	
	public bool GetMannVsMachineIsBetweenWaves()
	{
		return this.GetProp(Prop_Send, "m_bMannVsMachineBetweenWaves") != 0;
	}
	
	public void IncrementMannVsMachineWaveClassCount(any iszClassIconName, int iFlags)
	{
		for (int i = 0; i < this.GetPropArraySize(Prop_Send, "m_iszMannVsMachineWaveClassNames"); ++i)
		{
			if (GetEntData(this.index, FindSendPropInfo("CTFObjectiveResource", "m_iszMannVsMachineWaveClassNames") + (i * 4)) == iszClassIconName && (this.GetProp(Prop_Send, "m_nMannVsMachineWaveClassFlags", _, i) & iFlags))
			{
				this.SetProp(Prop_Send, "m_nMannVsMachineWaveClassCounts", this.GetProp(Prop_Send, "m_nMannVsMachineWaveClassCounts", _, i) + 1, _, i);
				
				if (this.GetProp(Prop_Send, "m_nMannVsMachineWaveClassCounts", _, i) <= 0)
				{
					this.SetProp(Prop_Send, "m_nMannVsMachineWaveClassCounts", 1, _, i);
				}
				
				return;
			}
		}
		
		for (int i = 0; i < this.GetPropArraySize(Prop_Send, "m_iszMannVsMachineWaveClassNames2"); ++i)
		{
			if (GetEntData(this.index, FindSendPropInfo("CTFObjectiveResource", "m_iszMannVsMachineWaveClassNames2") + (i * 4)) == iszClassIconName && (this.GetProp(Prop_Send, "m_nMannVsMachineWaveClassFlags2", _, i) & iFlags))
			{
				this.SetProp(Prop_Send, "m_nMannVsMachineWaveClassCounts2", this.GetProp(Prop_Send, "m_nMannVsMachineWaveClassCounts2", _, i) + 1, _, i);
				
				if (this.GetProp(Prop_Send, "m_nMannVsMachineWaveClassCounts2", _, i) <= 0)
				{
					this.SetProp(Prop_Send, "m_nMannVsMachineWaveClassCounts2", 1, _, i);
				}
				
				return;
			}
		}
	}
	
	public void SetMannVsMachineWaveClassActive(any iszClassIconName, bool bActive = true)
	{
		for (int i = 0; i < this.GetPropArraySize(Prop_Send, "m_iszMannVsMachineWaveClassNames"); ++i)
		{
			if (GetEntData(this.index, FindSendPropInfo("CTFObjectiveResource", "m_iszMannVsMachineWaveClassNames") + (i * 4)) == iszClassIconName)
			{
				this.SetProp(Prop_Send, "m_bMannVsMachineWaveClassActive", bActive, _, i);
				return;
			}
		}
		
		for (int i = 0; i < this.GetPropArraySize(Prop_Send, "m_iszMannVsMachineWaveClassNames2"); ++i)
		{
			if (GetEntData(this.index, FindSendPropInfo("CTFObjectiveResource", "m_iszMannVsMachineWaveClassNames2") + (i * 4)) == iszClassIconName)
			{
				this.SetProp(Prop_Send, "m_bMannVsMachineWaveClassActive2", bActive, _, i);
				return;
			}
		}
	}
	
	public bool IsPopFileEventType(int fileType)
	{
		return this.GetProp(Prop_Send, "m_nMvMEventPopfileType") == fileType;
	}
	
	public TFTeam GetOwningTeam(int index)
	{
		if (index >= this.GetProp(Prop_Send, "m_iNumControlPoints"))
			return TFTeam_Unassigned;
		
		return view_as<TFTeam>(this.GetProp(Prop_Send, "m_iOwner", _, index));
	}
}

methodmap CTFGameRules < CBaseEntity
{
	public CTFGameRules(int entity)
	{
		return view_as<CTFGameRules>(entity);
	}
	
	public void SetCustomUpgradesFile(const char[] path)
	{
		if (FileExists(path, true, "GAME"))
		{
			AddFileToDownloadsTable(path);
			
			SetVariantString(path);
			this.AcceptInput("SetCustomUpgradesFile");
		}
		else if (path[0])
		{
			LogError("The custom upgrades file '%s' does not exist", path);
		}
	}
}
