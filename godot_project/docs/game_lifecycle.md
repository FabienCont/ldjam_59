# Game Lifecycle & Node Interaction Documentation

## Overview

This is a turn-based strategy game where two players (**Player 0** and **AI Player 1**) compete to capture each other's castle. Each player controls kingdoms connected by roads, and sends troops or missives to conquer neutral or enemy territories.

---

## Core Nodes & Resources

| Node / Resource | Role |
|---|---|
| `GameManager` (autoload) | Global state machine: tracks game state, turn state, level progression |
| `LevelNode` | Root of a level scene; manages kingdoms, roads, turn execution, AI |
| `KingdomNode` | A territory on the map; owns troops, flags, and emits collision events |
| `KingdomDefinitionResource` | Data bag for a kingdom: `owner_index`, `troups_number`, `is_castle` |
| `RoadNode` | Bidirectional edge between two `KingdomNode`s |
| `TroupsDefinitionResource` | Data bag for a troop movement: owner, quantity, step, road path |
| `SoldierHandlerNode` | Manages spawning and tracking of `SoldierNode`s over multiple turns |
| `MissiveHandlerNode` | Sends a `MissiveNode` from the castle to a non-castle kingdom before sending troops |
| `SoldierNode` | Visual unit that moves along the road toward a destination |
| `MissiveNode` | Visual courier that moves along the road to unlock a non-castle attack |

---

## Game States

### `GameManager.GameState`

```
NOT_STARTED → STARTED → FINISH
```

- **NOT_STARTED**: Initial state after `setup()` is called (level load or restart).
- **STARTED**: Set by `start_new_game()` when the level is ready.
- **FINISH**: Set by `end_game(winner)` when a win condition is met.

### `GameManager.TurnState`

```
WAITING ↔ PLAYING
```

- **WAITING**: Player can interact with kingdoms and select movements.
- **PLAYING**: Turn is in progress; movement handlers are executing. Player input is blocked.

---

## Level Progression

```
GameManager.reset()
    → current_level = -1
    → setup()

GameManager.get_next_level()
    → current_level += 1
    → setup()
    → returns "res://scenes/level/<LevelName>.tscn"
```

Level order: `Level0.tscn → Level2.tscn → Level3.tscn → Level1.tscn`

`SceneManager.change_scene_with_path()` handles the animated fade-out / fade-in transition.

---

## Level Initialization (`LevelNode._ready`)

1. All `RoadNode` children in the `Roads` node are iterated to build two dictionaries:
   - `dicoKingdomNeighbours`: `KingdomNode → [neighbour KingdomNode, ...]`
   - `dicoKingdomNeighboursRoads`: `KingdomNode → [RoadNode, ...]`

2. All `KingdomNode` children in the `Kingdoms` node are iterated in order:
   - **Index 0** → Player castle (`owner_index = 0`, `is_castle = true`, default 20 troops)
   - **Index 1..N-2** → Neutral territories (`owner_index = -1`, `is_castle = false`, default 20 troops)
   - **Index N-1 (last)** → AI castle (`owner_index = 1`, `is_castle = true`, default 20 troops)

3. Each `KingdomNode` receives its `neighbours` and `roads_to_neighbours` arrays.
4. Each `KingdomNode.kingdom_selected` signal is connected to `LevelNode.select_kingdom`.

> A `force_unit_number` export on `KingdomNode` can override the default troop count.

---

## Turn Lifecycle — Detailed Walkthrough

### Phase 1 — Player Input (`TurnState.WAITING`)

Player clicks a kingdom. The `KingdomNode` emits `kingdom_selected(self)`.  
`LevelNode.select_kingdom(kingdom_node)` handles the event:

#### Selection Logic

```
Click on owned kingdom (owner_index == 0)
    → kingdomSelected = that kingdom (highlighted)

Click on a second different kingdom (while one is already selected)
    → Attempt to issue a command
    → If no valid path found → deselect both, abort

Click on the already-selected kingdom
    → Deselect it
```

#### Command Issued: Castle → Any Kingdom (Direct Troop Send)

Triggered when the **selected kingdom is a castle** (`is_castle == true`).

```
get_shortest_path(kingdomSelected, targetKingdom, player_index)
    → Only travels through owned (owner_index == 0) or the destination node
    → Returns ordered Array[KingdomNode] (departure → ... → destination)

send_troup(kingdomSelected, targetKingdom, roadsFound, player_index)
    → Creates SoldierHandlerNode + TroupsDefinitionResource
    → quantity = ceil(castle.troups_number / 2)
    → step starts at -1 (will be incremented to 0 on first play_turn)
    → LevelNode.add_handler(SoldierHandlerNode)
```

#### Command Issued: Non-Castle Kingdom → Any Kingdom (Missive + Troops)

Triggered when the **selected kingdom is NOT a castle**.

```
Step 1 — Missive path: castle (kingdoms[0]) → selected_kingdom
    get_shortest_path(kingdoms[0], kingdomSelected, player_index)

Step 2 — Troops path: selected_kingdom → target_kingdom
    get_shortest_path(kingdomSelected, targetKingdom, player_index)

send_missive(castle, kingdomSelected, missivePath, troopsPath, player_index)
    → Creates MissiveHandlerNode + TroupsDefinitionResource
    → quantity = 1 (single missive courier)
    → LevelNode.add_handler(MissiveHandlerNode)
```

### Phase 2 — AI Turn (`play_turn_ia(1)`)

Runs **synchronously before** `GameManager.play_turn()` is called.

#### AI Strategy

The AI castle is always `kingdoms[kingdoms.size() - 1]`.

**If castle has > 5 troops (direct attack mode):**

```
For each non-owned kingdom (shuffled randomly):
    Compute get_shortest_path(castle, target, 1)

Priority order:
    1. Shortest path to an enemy (owner_index == 0) kingdom
    2. Shortest path to a neutral (owner_index == -1) kingdom
    3. Fallback: longest path found (furthest kingdom)

→ send_troup(castle, chosen_target, chosen_path, 1)
```

**If castle has ≤ 5 troops (missive delegation mode):**

```
For each owned non-castle kingdom (sorted by highest troop count):
    For each non-owned kingdom (shuffled randomly):
        Compute missive path: castle → own_kingdom
        Compute troop path: own_kingdom → target

Priority order:
    1. Shortest combined distance to enemy kingdom
    2. Shortest combined distance to neutral kingdom
    3. Fallback: longest combined distance

→ send_missive(castle, own_kingdom, missivePath, troopsPath, 1)
```

### Phase 3 — Turn Execution (`GameManager.play_turn()`)

```
GameManager.turn += 1
GameManager.start_new_turn.emit()        ← all SoldierHandlerNodes and MissiveHandlerNodes receive this
GameManager.turn_state = PLAYING
```

### Phase 4 — Handler Execution (per turn signal)

#### `SoldierHandlerNode.play_turn()`

```
troups.step += 1
Check: step+1 <= road_path.size()-1  (still has next node)
Check: current road_path[step] is still owned by this player
    → If not: free_handler() (troops disbanded)

Create timer (0.13s interval) → spawn()
```

#### `SoldierHandlerNode.spawn()` (called repeatedly by timer)

```
kingdom_departure = road_path[step]

If kingdom_departure.troups_number <= 1:
    Stop spawning (no more troops to send)
    If no soldiers alive → free_handler()
Else:
    kingdom_departure.troups_number -= 1
    Instantiate SoldierNode
    soldier.troupsOrigin = troups
    soldier.global_position = kingdom_departure.kingdomNode.global_position
    Append to list_soldier
    spawned_quantity += 1
    If spawned_quantity == quantity → stop timer
    add_child(soldier)
```

#### `SoldierNode._process(delta)`

```
Each frame:
    Read road_path[step + 1] as current destination
    Move position.move_toward(destination, delta * 120)
    Flip sprite based on direction
```

#### `SoldierNode` arrives at `KingdomNode`

Detected by `KingdomNode.on_area_entered(area)`:

```
If soldier is heading to this kingdom (road_path[step+1].kingdomPath == self):
    → call kingdom_node.soldier_arrived(soldier)
```

#### `KingdomNode.soldier_arrived(soldier_node)`

```
If kingdom.owner_index == -1 (neutral):
    kingdom.owner_index = soldier.owner_index
    kingdom.troups_number += 1
    soldier.arrive()

Elif kingdom is friendly (same owner):
    kingdom.troups_number += 1
    soldier.arrive()

Else (enemy kingdom):
    If kingdom.troups_number <= 0:
        kingdom.owner_index = soldier.owner_index
        kingdom.troups_number = 1
        soldier.arrive()
    Else:
        kingdom.troups_number -= 1
        soldier.die()
```

#### `SoldierHandlerNode` — Soldier death/arrival callbacks

```
on_soldier_arrived(soldier):
    remove_soldier(soldier)
    If all soldiers gone:
        If step+1 >= road_path.size()-1 → free_handler() (destination reached)
        Else → finish_turn.emit(self)  (continue next turn)

on_soldier_died(soldier):
    troups.quantity -= 1
    remove_soldier(soldier)
    If quantity == 0 → free_handler() (all troops dead)
    Elif all soldiers gone:
        If step+1 >= road_path.size()-1 → free_handler()
        Else → finish_turn.emit(self)
```

#### `MissiveHandlerNode.play_turn()`

```
troups.step += 1
Create timer (0.10s interval) → spawn()
```

#### `MissiveHandlerNode.spawn()`

```
Instantiate MissiveNode
missive.troupsOrigin = troups
missive.global_position = road_path[step].kingdomNode.global_position
add_child(missive)
spawned_quantity += 1
Stop timer immediately (only one missive per handler)
```

#### `MissiveNode._process(delta)`

```
Each frame:
    Read road_path[step + 1] as current destination
    Move global_position.move_toward(destination, delta * 150)
    Flip sprite based on direction
```

#### `MissiveNode` arrives at `KingdomNode`

Detected by `KingdomNode.on_area_entered` → `kingdom_node.missive_arrived(missive_node)`.

Combat rules are **identical to SoldierNode** except an enemy kingdom simply kills the missive (`missive_node.die()`) without subtracting troops.

#### `MissiveHandlerNode.on_missive_arrived(_missive_node)`

```
If step+1 >= road_path.size()-1  (missive reached its kingdom):
    Create new SoldierHandlerNode from road_path_troops
    quantity = ceil(kingdom_destination.troups_number / 2)
    Emit handler_added(troupsHandler) → LevelNode queues it for next round
    free_handler()
Emit finish_turn(self)
```

> The missive path travels from the **castle** to a **non-castle owned kingdom**.  
> Once the missive arrives, a `SoldierHandlerNode` is queued via `handler_added` and starts its road on the **next turn** (`handler_nodes_next_round`).

---

### Phase 5 — End of Turn Detection

`LevelNode.check_end_turn()` is called whenever:
- A handler emits `finish_turn`
- A handler emits `handler_free`

```
is_turn_finished = (handler_nodes_finished.size() == handler_nodes.size())

If true → end_turn()
```

### Phase 6 — `LevelNode.end_turn()`

```
handler_nodes_finished = []

For each handler in handler_nodes_next_round:
    add_handler(handler)   ← queued handlers (from missives) become active
handler_nodes_next_round = []

GameManager.end_turn()     → turn_state = WAITING

check_game_finished()
```

### Phase 7 — Win Condition Check (`check_game_finished`)

```
If kingdoms[0].owner_index == 1:
    → AI captured player castle → GameManager.end_game(1)  [AI wins]
    → game_finished signal emitted

If kingdoms[last].owner_index == 0:
    → Player captured AI castle → GameManager.end_game(0)  [Player wins]
    → game_finished signal emitted
```

---

## Full Turn Sequence Diagram

```
[Player Input]
    Player clicks own kingdom A → kingdomSelected = A
    Player clicks target kingdom B
        │
        ├─ A is castle → send_troup(A, B, path, 0)
        │                  → add SoldierHandlerNode
        │
        └─ A is not castle → send_missive(castle, A, missivePath, troopsPath, 0)
                               → add MissiveHandlerNode

[AI Input]  (synchronous, same frame)
    play_turn_ia(1)
        → evaluate best target
        → send_troup() or send_missive()
        → add SoldierHandlerNode or MissiveHandlerNode

[GameManager.play_turn()]
    turn += 1
    emit start_new_turn          ← all active handlers receive this

[Per Handler — each turn signal]
    SoldierHandlerNode.play_turn()
        → step += 1
        → spawn SoldierNodes via timer
        → SoldierNodes move each frame
        → SoldierNode arrives at KingdomNode
            → soldier_arrived() or soldier.die()
        → When all soldiers resolved: finish_turn or free_handler

    MissiveHandlerNode.play_turn()
        → step += 1
        → spawn one MissiveNode via timer
        → MissiveNode moves each frame
        → MissiveNode arrives at KingdomNode
            → missive_arrived() → create SoldierHandlerNode (queued)
        → finish_turn emitted

[check_end_turn()]
    All handlers finished or freed?
        → end_turn()
            → promote queued handlers
            → GameManager.end_turn() → TurnState = WAITING
            → check_game_finished()
                → winner? → GameManager.end_game(winner)
                → no winner? → loop back to [Player Input]
```

---

## Pathfinding Rules (`get_shortest_path`)

The path algorithm is a **recursive depth-first search with pruning**:

- Finds the **shortest kingdom-hop path** from departure to destination.
- **Traversal constraint**: intermediate kingdoms must be **owned by `owner_index`** (friendly territory). The destination can be neutral or enemy.
- Each road can only be used **once** per search (cycle prevention).
- Returns an ordered `Array[KingdomNode]` including both departure and destination.
- Returns an empty array if no valid path exists.

---

## Collision Rules Summary

| Unit Type | Hits friendly kingdom | Hits enemy/neutral kingdom | Hits enemy unit |
|---|---|---|---|
| `SoldierNode` | `troups_number += 1`, arrive | Combat (troops decrement) | `die()` |
| `MissiveNode` | `troups_number += 1`, arrive | `die()` (killed silently) | `die()` |

---

## Owner Index Reference

| Value | Meaning |
|---|---|
| `0` | Player |
| `1` | AI |
| `-1` | Neutral (unowned) |
