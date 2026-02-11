# Afterlight Protocol (Working Title)

## One-Line Pitch
A lonely, luminous metroidvania on an abandoned, overgrown planet where bioluminescent, semi-radioactive ecosystems have replaced civilization—and a reclamation construct must decide what “restoration” should mean.

## High Concept
- **Setting**: A long-abandoned world reclaimed by mutated, bioluminescent life.
- **Player**: A constructed reclamation/terraforming unit awakened and deployed to assess and restore the planet for returning organic life.
- **Core Conflict**: Reclamation vs. adaptation.
- **Tone**: Quiet, beautiful, unsettling. Not grimdark; not horror.

## Design Pillars
- **Exploration First**: Dense, interconnected traversal; shortcuts; verticality; hidden routes.
- **Ecology as Antagonist**: Enemies and bosses are keystone species, not villains.
- **Systems Over Magic**: Abilities are modules/activations, not spells.
- **Consequential Restoration**: Purifying regions changes them permanently (and meaningfully).

## Target Player Experience
- **Lonely immersion**: Minimal exposition; environmental storytelling; sparse UI.
- **Tactile movement**: Responsive platforming; traversal upgrades define progression.
- **Meaningful choices**: Endgame decision reframes the entire mission.

## Genre + Structure
- **Genre**: 2D Metroidvania (precision platforming + light-weight, fluid combat).
- **World layout**: A connected grid of “rooms” with both horizontal and vertical traversal.
- **Progression**: Ability-gated exploration and biome unlocks.

## Protagonist
**Reclamation Unit (constructed being)**
- Silent, purpose-driven, analytical.
- Minimal or no spoken dialogue.
- Visual evolution over time: begins clean and utilitarian; gradually integrates traits from the new biosphere.

## Core Gameplay Loop
Explore → Cleanse → Adapt → Unlock → Descend → Confront → Decide

- **Explore**: Navigate ruins overtaken by glowing ecosystems.
- **Cleanse/Reclaim**: Purge nodes / plant beacons to stabilize zones.
- **Adapt**: Earn modules/resistances to survive deeper biomes.
- **Unlock**: New traversal/combat tools open routes.
- **Confront**: Bosses represent keystone species sustaining their biome.
- **Decide**: Late-game choice determines the planet’s future.

## Movement + Combat (Baseline)
### Movement
- Run, jump, wall interactions (optional), dash (upgrade), double-jump (upgrade).
- High emphasis on **verticality** and **flow**.

### Combat
- Precision-based attacks and dodges with short commitment.
- Enemies are ecosystem responses: spores, swarms, electric organisms, crystalline growths.

## Ability / Module Progression (Examples)
All framed as systems activating.

- **Stabilize Dash**
  - Short burst movement.
  - Leaves a “neutralized” trail through contaminated zones.
- **Pulse Field**
  - EMP-like wave that disrupts bio-mechanical organisms.
- **Adapt Module**
  - Temporary resistance to a mutation type (radiation, electric, corrosive, spores).
- **Reclaim Beacon**
  - Plant purification towers that reduce hazard, unlock doors, or change room states.
- **Overclock Mode**
  - Brief damage and movement boost.
  - Costs stability / increases corruption risk.

## World / Biomes (Initial Set)
Each biome is a former human function overtaken by mutation.

### Biolume Canopy
Overgrown megacity towers wrapped in glowing vines.
- **Threats**: floating pollen predators, spore wolves, vine-serpents.
- **Mechanic hook**: radiation exposure slowly builds until nodes are stabilized.

### Submerged Transit Sector
Flooded subway systems turned into bioluminescent coral tunnels.
- **Threats**: electric eel colonies, pulse-jellies, prism-shell crustaceans.
- **Mechanic hook**: underwater traversal upgrade; pressure/oxygen management (optional).

### Reactor Garden
A power plant converted into a crystalline jungle.
- **Threats**: aggressive radiation-adapted organisms; crystalline growth turrets.
- **Mechanic hook**: hazard zones; overcharge interactions (power conduits that alter abilities).

### Orbital Relay Ruins
High-altitude satellite dish arrays, fractured and storm-swept.
- **Threats**: windborne predators; storm entities.
- **Mechanic hook**: wind traversal; radiation storms; late-game navigation.

## Bosses (Tragic, Not Evil)
Bosses are ecological “pillars.” Defeating them changes the biome.

- **The Bloom Sovereign**
  - A massive floral entity grown through a skyscraper.
  - Defeat consequence: canopy begins fading; the biome becomes quieter and less alive.

- **The Reactor Heart**
  - A semi-sentient radiation core that grew nervous tissue.
  - Defeat consequence: the glow dims across the region; hazard patterns change.

- **The Tide Engine**
  - A fusion of legacy transit AI and coral super-organism.
  - Defeat consequence: water levels destabilize; routes shift.

## Narrative Delivery
- Environmental storytelling via:
  - Ruins, signage fragments, machine logs, and biome transformations.
  - Rare “system pings” from mission protocols.
- The world is thriving—just not for the old definition of life.

## Endgame Decision
After reclaiming major zones, access the central Terraform Core.

- **Complete Restoration**
  - Human-compatible biosphere.
  - Bioluminescent life collapses.

- **Adaptive Integration**
  - Hybrid biosphere.
  - Human return uncertain.

- **Shutdown**
  - Mission terminated.
  - Evolution continues without interference.

No moral binary—only philosophy.

## Visual Direction
- Soft glow against dark, ruined silhouettes.
- Neon biology: spores, tendrils, crystal-flesh, coral circuitry.
- Minimal HUD; strong silhouette readability.

## Audio Direction
- Wind, distant hum, organic crackle.
- Sparse music in exploration; tonal cues in boss fights.
- Region “after” states have noticeably different ambience.

## Implementation Notes (Current Prototype)
This repo currently contains a minimal Godot prototype using **KoBeWi/Metroidvania-System**:
- Rooms are independent scenes with `Door` transitions and spawn points.
- `RoomInstance` is present in rooms for MetSys tracking.
- Save data persists room/spawn/abilities and MetSys runtime save data.

## Next Steps
- Replace placeholder rooms with biome-themed tilesets and lighting.
- Add 1–2 enemy types per biome and one miniboss.
- Add a `Minimap` UI node and connect it to MetSys.
- Implement “reclaim beacon” as a room-state-changing interactable.
