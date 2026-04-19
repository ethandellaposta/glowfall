# Glowfall — Metroidvania Platformer

A Godot 4.6 2D metroidvania platformer template powered by [KoBeWi's Metroidvania-System](https://github.com/KoBeWi/Metroidvania-System).

## Getting Started

1. **Open in Godot 4.6+** — double-click `project.godot` or open it from the Godot project manager.
2. On first launch the MetSys plugin will add its autoload and **restart the editor automatically** — this is normal.
3. Press **F5** (or the Play button) to run the game.

## Controls

| Action | Key |
|--------|-----|
| Move left / right | Arrow keys or A / D |
| Jump (+ double jump once unlocked) | Space / Enter |

## Project Structure

```
project.godot              – project config (autoloads, plugin, display)
MetSysSettings.tres        – Metroidvania-System settings (cell size, theme)
MapData.txt                – MetSys map data (edit via the MetSys Map Editor tab)
scenes/
  Main.tscn                – main scene (Game + Player + HUD)
  Game.gd                  – room loading, player tracking, HUD orchestration
  player/
    Player.tscn            – player scene (collision, sprite, attack area)
    Player.gd              – movement, jumping, state management
    PlayerCombat.gd        – melee hit detection
    PlayerAnimation.gd     – animation state machine + frame setup
  enemy/
    Enemy.tscn             – enemy scene (collision, sprite)
    Enemy.gd               – patrol, damage, knockback, death
    EnemySpriteSetup.gd    – sprite sheet setup
  sprites/
    SpriteFrameBuilder.gd  – shared sprite frame utilities
  objects/
    CityParallax.tscn      – parallax city background
    CityParallax.gd        – tiled parallax layer management
    InteriorBackdrop.tscn  – interior room backdrop
  components/
    Global.gd              – autoload: abilities, save/load, charms
    RoomLoader.gd          – room load/unload logic
    SaveManager.gd         – JSON save/load to user://save.json
    CharmManager.gd        – charm definitions, equip/unequip
  rooms/
    Roof.tscn              – starting room (rooftop)
    Street.tscn            – street level, double-jump pickup
    TopFloor.tscn          – top floor interior
    Door.gd                – room transitions, ability gating
    FloorBlocks.gd         – procedural floor block generation
    AbilityPickup.gd       – collectible ability grants
    WaterHazard.gd         – damage zone
  ui/
    HUD.tscn               – HUD overlay
    HUD.gd                 – room info, messages
addons/
  MetroidvaniaSystem/      – KoBeWi's MetSys addon
```

## How the Rooms Work

- Each room is a standalone scene with walls, a floor, `Marker2D` spawn points, and `Door` nodes.
- **Doors** (`Door.gd`) trigger a room change when the player touches them. Set `target_room_path`, `target_spawn`, and optionally `required_ability` in the inspector.
- **Ability pickups** (`AbilityPickup.gd`) grant a named ability (stored in `Global.abilities`). The default pickup grants `double_jump`, which lets the player jump a second time in mid-air.
- The orange door on the Roof requires `double_jump` — go to Street first, grab the pickup on the platform, then return.

## Using the MetSys Map Editor

1. In the Godot editor, click the **MetSys** tab at the top (next to 2D / 3D / Script).
2. Place cells on the grid to represent your rooms.
3. Switch to **Scene Assign Mode** and assign `Roof.tscn`, `Street.tscn`, `TopFloor.tscn` to their cells.
4. Set border passages between adjacent rooms so MetSys knows where transitions happen.
5. Save — the data is written to `MapData.txt`.

Once the map is set up, MetSys will automatically track which room the player is in, discover cells as you explore, and you can add a Minimap node (`addons/MetroidvaniaSystem/Template/Nodes/Minimap.tscn`) to your HUD.

## Extending

- **Add a new room**: duplicate an existing room scene, add geometry/enemies, place `Door` nodes, add a `RoomInstance` child (from `addons/MetroidvaniaSystem/Nodes/RoomInstance.tscn`), then register it in the MetSys Map Editor.
- **Add a new ability**: create an `AbilityPickup` with a custom `ability` name, then check `Global.has_ability(&"your_ability")` wherever you need gating.
- **Enemies**: add `CharacterBody2D` or `Area2D` nodes with patrol/chase AI scripts to any room scene.
- **Save system**: `Global.save()` / `Global.load_save()` persist room, spawn, abilities, and MetSys map data to `user://save.json`.

## License

Game code is yours. The MetroidvaniaSystem addon is MIT-licensed — see `addons/MetroidvaniaSystem/` for details.
