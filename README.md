# Plio — Metroidvania Platformer

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
project.godot          – project config (autoloads, plugin, display)
MetSysSettings.tres    – Metroidvania-System settings (cell size, theme, map data path)
MapData.txt            – MetSys map data (edit via the MetSys Map Editor tab)
scripts/
  Global.gd            – autoload: abilities, save/load, MetSys save data persistence
  Game.gd              – main scene script: room loading, player tracking, HUD
  Player.gd            – CharacterBody2D platformer controller (run, jump, double-jump)
  Door.gd              – Area2D door: transitions between rooms, optional ability gate
  AbilityPickup.gd     – Area2D collectible: grants an ability (e.g. double_jump)
  HUD.gd               – simple HUD: room name, abilities, popup messages
scenes/
  Main.tscn            – main scene (Game + Player + HUD)
  Player.tscn          – player (blue rectangle, camera, collision)
  ui/HUD.tscn          – HUD overlay
  rooms/
    RoomA.tscn          – starting room, doors to RoomB and RoomC (locked)
    RoomB.tscn          – contains the double-jump pickup + a platform
    RoomC.tscn          – unlocked after picking up double_jump in RoomB
addons/
  MetroidvaniaSystem/   – KoBeWi's MetSys addon (map editor, room tracking, minimap, save)
```

## How the Rooms Work

- Each room is a standalone scene with walls, a floor, `Marker2D` spawn points, and `Door` nodes.
- **Doors** (`Door.gd`) trigger a room change when the player touches them. Set `target_room_path`, `target_spawn`, and optionally `required_ability` in the inspector.
- **Ability pickups** (`AbilityPickup.gd`) grant a named ability (stored in `Global.abilities`). The default pickup grants `double_jump`, which lets the player jump a second time in mid-air.
- The orange door in RoomA requires `double_jump` — go to RoomB first, grab the pickup on the platform, then return.

## Using the MetSys Map Editor

1. In the Godot editor, click the **MetSys** tab at the top (next to 2D / 3D / Script).
2. Place cells on the grid to represent your rooms.
3. Switch to **Scene Assign Mode** and assign `RoomA.tscn`, `RoomB.tscn`, `RoomC.tscn` to their cells.
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
