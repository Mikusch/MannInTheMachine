<div align="center">

# Mann in the Machine

**Mann vs. Machine, but the robots are player-controlled.**

<img src="banner.png" alt="Logo" width="500"/>

<sub>Logo by [Octatonic Sunrise](https://steamcommunity.com/profiles/76561198027701160)</sub>

</div>

---



**Mann in the Machine** is a SourceMod plugin that turns Mann vs. Machine into a player versus player gamemode.
Players take turns defending Mann Co. while everyone else joins the robot horde and attempts to destroy it instead!

> [!IMPORTANT]  
> This gamemode is intended to be played with at least 28 players (6 defenders + 22 robots).
> Most missions spawn robots in squads. If there aren't enough players to spawn the entire squad, the wave will softlock!

> [!WARNING]
> External MvM extensions such as rafmod are **not** supported and may cause server instability!

## Requirements

* [SourceMod 1.12](https://www.sourcemod.net/)
* [CBaseNPC](https://github.com/TF2-DMB/CBaseNPC)
* [Source Scramble](https://github.com/nosoop/SMExt-SourceScramble)
* [VScript](https://github.com/FortyTwoFortyTwo/VScript)
* [SM-Memory](https://github.com/Scags/SM-Memory)
* [TF2 Econ Data](https://github.com/nosoop/SM-TFEconData)
* [TF2 Attributes](https://github.com/FlaminSarge/tf2attributes)
* [TF2 Utils](https://github.com/nosoop/SM-TFUtils)
* [More Colors](https://github.com/DoctorMcKay/sourcemod-plugins/blob/master/scripting/include/morecolors.inc) (compile only)
* [Plugin State Manager](https://github.com/Mikusch/PluginStateManager/blob/master/addons/sourcemod/scripting/include/pluginstatemanager.inc) (compile only)

> [!NOTE]
> Ensure you're using the latest version of all dependencies.

## Frequently Asked Questions

### Which missions are supported?

All **official Valve missions** are fully supported, along with most custom missions.
If you encounter a mission that behaves unexpectedly, please [open an issue](https://github.com/Mikusch/MannInTheMachine/issues) and attach the population file.

Additionally, limited **VScript support** is available for population files.
Many common `CTFBot` functions have been reimplemented or replicated on `CTFPlayer`.

### How is this different from [Be With Robots](https://github.com/caxanga334/tf-bewithrobots-redux) or similar plugins?

Unlike other plugins, Mann in the Machine is a **PvP gamemode** and is **not** compatible with bots.

Players spawn as robots exactly as defined in the mission.
For example, if no giants are present in a wave, no one can spawn as a giant.
This ensures the original mission balance and design are preserved.

### Isn't this really unbalanced?

Sometimes. Converting a PvE gamemode into a PvP one naturally turns the balance on its head.
Having a **carefully selected mission rotation** as well as choosing the defender team size wisely can contribute to a balanced match.

Most missions were **not** designed for player-controlled robots, obviously.
**Advanced or Expert community-created missions** are recommended for the best experience.
Avoid **Intermediate and Normal** difficulty missions, as they are generally far too easy for defenders.

The gamemode includes a **wave skip** feature that allows automatic progression if defenders repeatedly lose.

### Does this support 100 players?

By default, no. However, you can use [Source Scramble Patches](https://github.com/Mikusch/SourceScramblePatches) to **increase the bot limit**.
Keep in mind that most missions won't spawn more than **22 bots at once**, so modifying the population file may be necessary to prevent long wait times between spawns.

### Can you play as the tank?

No. Please stop asking.

## Configuration

By default, the gamemode stays **as close to vanilla MvM as possible**, but you can customize various aspects.

**Example:**

```
mitm_custom_upgrades_file "scripts/items/mvm_upgrades_mitm_nogas.txt"   // Use custom upgrades file
sm_cvar tf_airblast_cray 0                                              // Reverts to pre-JI airblast
mitm_bot_taunt_on_upgrade 0                                             // Don't taunt on bomb upgrade
tf_bot_taunt_victim_chance 0                                            // No random chance to taunt on kill
```

For a full list of convars, type `find mitm_` into the server console with the plugin loaded or [check the code](https://github.com/Mikusch/MannInTheMachine/blob/master/addons/sourcemod/scripting/mitm/convars.sp).

> [!TIP]  
> Any convar that works in Mann vs. Machine also works with this plugin.
> For example, you may increase the size of the defender team using `tf_mvm_defenders_team_size`.

## Endless Mode

Mann in the Machine supports the scrapped **Endless Mode**, which allows missions to continue indefinitely while robots receive upgrades each wave.

To enable it, add `IsEndless 1` to your population file the or set the convar `tf_mvm_endless_force_on` to `1`.

### Configuration

The following convars can be used to customize Endless Mode:

* `tf_mvm_endless_wait_time`
* `tf_mvm_endless_bomb_reset`
* `tf_mvm_endless_bot_cash`
* `tf_mvm_endless_tank_boost`

You can customize bot upgrades by overriding the game's `scripts/items/mvm_botupgrades.txt` in the `custom` folder.
This repository contains a **custom bot upgrade file** optimized for Mann in the Machine.

## Contributors

* **[Mikusch](https://github.com/Mikusch)** - Code & gameplay
* **[Kenzzer](https://github.com/Kenzzer)** - Early coding assistance & library development
* **[trigger_hurt](https://steamcommunity.com/profiles/76561198036209556)** - Custom robot viewmodels

## Special Thanks

* **[Red Sun Over Paradise](https://redsun.tf)** - Playtesting & giving feedback
