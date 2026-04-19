#!/usr/bin/env python3

import argparse
import json
import math
import random
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple


def _clamp(v: int, lo: int, hi: int) -> int:
    return max(lo, min(hi, v))


DIRS: Dict[str, Tuple[int, int]] = {
    "N": (0, -1),
    "S": (0, 1),
    "W": (-1, 0),
    "E": (1, 0),
}
OPP: Dict[str, str] = {"N": "S", "S": "N", "W": "E", "E": "W"}


@dataclass(frozen=True)
class Pos:
    x: int
    y: int


@dataclass
class Edge:
    a: int
    b: int
    kind: str  # "open" | "locked"
    lock: Optional[str] = None
    dir_from_a: Optional[str] = None


@dataclass
class Room:
    id: int
    pos: Pos
    biome: str
    tags: List[str]


class MapGenError(RuntimeError):
    pass


def _neighbors(p: Pos) -> List[Tuple[str, Pos]]:
    out = []
    for d, (dx, dy) in DIRS.items():
        out.append((d, Pos(p.x + dx, p.y + dy)))
    return out


def _manhattan(a: Pos, b: Pos) -> int:
    return abs(a.x - b.x) + abs(a.y - b.y)


def _ascii(map_w: int, map_h: int, id_at: Dict[Pos, int], rooms: List[Room], edges: List[Edge]) -> str:
    # Simple tile-per-room. Doors are not drawn; this is a quick visual sanity check.
    grid = [["  " for _ in range(map_w)] for _ in range(map_h)]

    # mark start/boss/etc.
    tag_by_id = {r.id: set(r.tags) for r in rooms}

    for p, rid in id_at.items():
        ch = ".."
        if "start" in tag_by_id[rid]:
            ch = "ST"
        elif "boss" in tag_by_id[rid]:
            ch = "BS"
        elif "ability" in tag_by_id[rid]:
            ch = "AB"
        elif "key" in tag_by_id[rid]:
            ch = "KY"
        grid[p.y][p.x] = ch

    lines = []
    for y in range(map_h):
        lines.append(" ".join(grid[y]))
    return "\n".join(lines)


def _svg_map(m: Dict) -> str:
    meta = m.get("meta", {})
    grid = meta.get("grid", {})
    map_w = int(grid.get("width", 1))
    map_h = int(grid.get("height", 1))
    rooms = list(m.get("rooms", []))
    edges = list(m.get("edges", []))

    cell = 64
    pad = 24
    tile = cell - 10
    offset = (cell - tile) // 2

    svg_w = pad * 2 + map_w * cell
    svg_h = pad * 2 + map_h * cell

    def room_fill(tags: List[str]) -> str:
        ts = set(tags)
        if "start" in ts:
            return "#2ecc71"
        if "boss" in ts:
            return "#9b59b6"
        if "key" in ts:
            return "#f1c40f"
        if "ability" in ts:
            return "#e056fd"
        return "#4b7bec"

    pos_by_id: Dict[int, Tuple[int, int]] = {}
    tags_by_id: Dict[int, List[str]] = {}
    for r in rooms:
        rid = int(r.get("id", -1))
        pos_by_id[rid] = (int(r.get("x", 0)), int(r.get("y", 0)))
        tags_by_id[rid] = list(r.get("tags", []))

    out: List[str] = []
    out.append(f'<svg xmlns="http://www.w3.org/2000/svg" width="{svg_w}" height="{svg_h}" viewBox="0 0 {svg_w} {svg_h}">')
    out.append('<rect x="0" y="0" width="100%" height="100%" fill="#0b1020"/>')

    for e in edges:
        a = int(e.get("a", -1))
        b = int(e.get("b", -1))
        if a not in pos_by_id or b not in pos_by_id:
            continue
        ax, ay = pos_by_id[a]
        bx, by = pos_by_id[b]
        x1 = pad + ax * cell + cell / 2
        y1 = pad + ay * cell + cell / 2
        x2 = pad + bx * cell + cell / 2
        y2 = pad + by * cell + cell / 2
        kind = str(e.get("kind", "open"))
        stroke = "#ff4d4d" if kind == "locked" else "#9aa4b2"
        dash = " stroke-dasharray=\"10 8\"" if kind == "locked" else ""
        out.append(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{stroke}" stroke-width="5" stroke-linecap="round"{dash}/>' )

    for rid, (rx, ry) in pos_by_id.items():
        tags = tags_by_id.get(rid, [])
        x = pad + rx * cell + offset
        y = pad + ry * cell + offset
        fill = room_fill(tags)
        out.append(f'<rect x="{x}" y="{y}" width="{tile}" height="{tile}" rx="10" ry="10" fill="{fill}" opacity="0.92" stroke="#0b1020" stroke-width="4"/>')
        out.append(f'<text x="{x + tile/2}" y="{y + tile/2 + 6}" text-anchor="middle" font-family="monospace" font-size="18" fill="#0b1020">{rid}</text>')
        label = "".join([t[0].upper() for t in tags])
        if label:
            out.append(f'<text x="{x + tile/2}" y="{y + tile - 10}" text-anchor="middle" font-family="monospace" font-size="12" fill="#0b1020">{label}</text>')

    seed = meta.get("seed", "")
    out.append(f'<text x="{pad}" y="{pad - 6}" font-family="monospace" font-size="14" fill="#9aa4b2">seed={seed}</text>')
    out.append("</svg>")
    return "\n".join(out)


def generate_map(
    *,
    seed: int,
    biome: str,
    width: int,
    height: int,
    rooms: int,
    critical_path: int,
    branchiness: float,
    lock_name: str,
) -> Dict:
    rng = random.Random(seed)

    width = _clamp(width, 5, 100)
    height = _clamp(height, 5, 100)
    rooms = _clamp(rooms, 4, width * height)
    critical_path = _clamp(critical_path, 3, rooms)
    branchiness = max(0.0, min(1.0, branchiness))

    # Occupancy
    id_at: Dict[Pos, int] = {}
    rooms_list: List[Room] = []
    edges: List[Edge] = []
    edge_set: Set[Tuple[int, int]] = set()

    def add_room(p: Pos, tags: Optional[List[str]] = None) -> int:
        rid = len(rooms_list)
        rooms_list.append(Room(id=rid, pos=p, biome=biome, tags=list(tags or [])))
        id_at[p] = rid
        return rid

    def add_edge(a: int, b: int, kind: str = "open", lock: Optional[str] = None, dir_from_a: Optional[str] = None) -> None:
        x, y = (a, b) if a < b else (b, a)
        if (x, y) in edge_set:
            return
        edge_set.add((x, y))
        edges.append(Edge(a=a, b=b, kind=kind, lock=lock, dir_from_a=dir_from_a))

    # start at center-ish
    start_pos = Pos(width // 2, height // 2)
    start_id = add_room(start_pos, tags=["start"])

    # Build a critical path as a self-avoiding walk.
    current = start_pos
    path_ids = [start_id]
    for _ in range(critical_path - 1):
        candidates: List[Tuple[str, Pos]] = []
        for d, np in _neighbors(current):
            if not (0 <= np.x < width and 0 <= np.y < height):
                continue
            if np in id_at:
                continue
            candidates.append((d, np))
        if not candidates:
            raise MapGenError("Failed to build critical path (dead end). Try a different seed or larger grid.")
        d, np = rng.choice(candidates)
        nid = add_room(np)
        add_edge(id_at[current], nid, kind="open", dir_from_a=d)
        current = np
        path_ids.append(nid)

    # Mark end of critical path as boss.
    rooms_list[path_ids[-1]].tags.append("boss")

    # Decide where lock is placed along path (a locked edge to enter boss region).
    # We'll lock the edge between path_ids[lock_idx-1] -> path_ids[lock_idx]
    # and place the key earlier in the graph.
    lock_idx = rng.randint(max(2, critical_path // 2), critical_path - 1)
    locked_a = path_ids[lock_idx - 1]
    locked_b = path_ids[lock_idx]

    # mutate edge kind if it exists
    for e in edges:
        if (e.a == locked_a and e.b == locked_b) or (e.a == locked_b and e.b == locked_a):
            e.kind = "locked"
            e.lock = lock_name
            break

    # Grow additional rooms with a frontier biased by branchiness.
    frontier: List[Pos] = [r.pos for r in rooms_list]
    attempts = 0
    while len(rooms_list) < rooms and attempts < rooms * 50:
        attempts += 1

        if rng.random() < branchiness:
            base = rng.choice(frontier)
        else:
            # bias growth near the critical path for more corridor-like worlds
            base = rooms_list[rng.choice(path_ids)].pos

        nbs = [(d, np) for d, np in _neighbors(base) if 0 <= np.x < width and 0 <= np.y < height and np not in id_at]
        if not nbs:
            continue
        d, np = rng.choice(nbs)
        nid = add_room(np)
        add_edge(id_at[base], nid, kind="open", dir_from_a=d)
        frontier.append(np)

        # Occasionally add an extra connection to reduce dead ends.
        if rng.random() < 0.25:
            existing_nbs = [(dd, pp) for dd, pp in _neighbors(np) if pp in id_at and id_at[pp] != nid]
            rng.shuffle(existing_nbs)
            for dd, pp in existing_nbs[:2]:
                add_edge(nid, id_at[pp], kind="open", dir_from_a=dd)

    if len(rooms_list) < rooms:
        raise MapGenError("Failed to place requested number of rooms. Try bigger grid or different seed.")

    # Place a key room on the accessible side of the lock.
    # We'll pick a room not beyond the lock along critical path.
    accessible_ids = set(path_ids[: lock_idx])

    # Expand accessible set through open edges only (so we don't accidentally put key behind its own lock)
    changed = True
    while changed:
        changed = False
        for e in edges:
            if e.kind == "locked":
                continue
            if e.a in accessible_ids and e.b not in accessible_ids:
                accessible_ids.add(e.b)
                changed = True
            elif e.b in accessible_ids and e.a not in accessible_ids:
                accessible_ids.add(e.a)
                changed = True

    candidate_key_rooms = [rid for rid in accessible_ids if rid not in (start_id, locked_a, locked_b) and "boss" not in rooms_list[rid].tags]
    if not candidate_key_rooms:
        candidate_key_rooms = [start_id]
    key_room_id = rng.choice(candidate_key_rooms)
    rooms_list[key_room_id].tags.append("key")

    # Place an ability room somewhere before the lock as well (optional but metroidvania-flavored)
    candidate_ability_rooms = [rid for rid in accessible_ids if rid not in (start_id, key_room_id) and "boss" not in rooms_list[rid].tags]
    if candidate_ability_rooms:
        ability_room_id = rng.choice(candidate_ability_rooms)
        rooms_list[ability_room_id].tags.append("ability")

    exits_by_room: Dict[int, List[Dict]] = {r.id: [] for r in rooms_list}
    dirs_by_room: Dict[int, Set[str]] = {r.id: set() for r in rooms_list}

    pos_by_id: Dict[int, Pos] = {r.id: r.pos for r in rooms_list}

    def dir_between(a: int, b: int) -> str:
        pa = pos_by_id[a]
        pb = pos_by_id[b]
        dx = pb.x - pa.x
        dy = pb.y - pa.y
        if dx == 1 and dy == 0:
            return "E"
        if dx == -1 and dy == 0:
            return "W"
        if dx == 0 and dy == 1:
            return "S"
        if dx == 0 and dy == -1:
            return "N"
        raise MapGenError(f"Non-adjacent edge between rooms {a} and {b}")

    def exit_geom(d: str) -> Dict[str, int | str]:
        if d == "E":
            return {"shape": "door", "x": 930, "y": 310, "w": 48, "h": 96}
        if d == "W":
            return {"shape": "door", "x": -930, "y": 310, "w": 48, "h": 96}
        if d == "N":
            return {"shape": "door", "x": 0, "y": 180, "w": 48, "h": 96}
        if d == "S":
            return {"shape": "hole", "x": 0, "y": 520, "w": 240, "h": 200}
        raise MapGenError(f"Unknown direction: {d}")

    for e in edges:
        d_ab = dir_between(e.a, e.b)
        d_ba = OPP[d_ab]
        ga = exit_geom(d_ab)
        gb = exit_geom(d_ba)
        exits_by_room[e.a].append(
            {
                "dir": d_ab,
                "to": e.b,
                "kind": e.kind,
                "lock": e.lock,
                "target_spawn": f"SpawnFrom{d_ba}",
                **ga,
            }
        )
        exits_by_room[e.b].append(
            {
                "dir": d_ba,
                "to": e.a,
                "kind": e.kind,
                "lock": e.lock,
                "target_spawn": f"SpawnFrom{d_ab}",
                **gb,
            }
        )
        dirs_by_room[e.a].add(d_ab)
        dirs_by_room[e.b].add(d_ba)

    layouts_by_room: Dict[int, Dict] = {}
    for r in rooms_list:
        room_seed = (seed * 1000003) + (r.id * 9176) + (r.pos.x * 193) + (r.pos.y * 971)
        room_rng = random.Random(room_seed)

        plats: List[Dict[str, int]] = []
        room_half_w = 1000
        floor_y = 420
        floor_h = 60
        wall_x = 1000
        wall_y = 60
        wall_w = 60
        wall_h = 800
        max_step = 120
        if "S" in dirs_by_room[r.id]:
            hole_w = 240
            gap_w = hole_w + 80
            seg_w = int(room_half_w - gap_w / 2)
            left_x = int(-gap_w / 2 - seg_w / 2)
            right_x = int(gap_w / 2 + seg_w / 2)
            plats.append({"x": left_x, "y": floor_y, "w": seg_w, "h": floor_h})
            plats.append({"x": right_x, "y": floor_y, "w": seg_w, "h": floor_h})
        else:
            plats.append({"x": 0, "y": floor_y, "w": room_half_w * 2, "h": floor_h})
        plats.append({"x": -wall_x, "y": wall_y, "w": wall_w, "h": wall_h})
        plats.append({"x": wall_x, "y": wall_y, "w": wall_w, "h": wall_h})

        if "N" in dirs_by_room[r.id]:
            step1_y = floor_y - max_step
            step2_y = step1_y - max_step
            step3_y = step2_y - max_step
            plats.append({"x": -520, "y": step1_y, "w": 360, "h": 40})
            plats.append({"x": 0, "y": step2_y, "w": 420, "h": 40})
            plats.append({"x": 520, "y": step3_y, "w": 360, "h": 40})
            plats.append({"x": 0, "y": step3_y, "w": 320, "h": 40})
        else:
            if room_rng.random() < 0.85:
                y = int(floor_y - max_step)
                x = int(room_rng.choice([-520, -260, 0, 260, 520]))
                w = int(room_rng.choice([240, 280, 360, 420]))
                plats.append({"x": x, "y": y, "w": w, "h": 40})
            if room_rng.random() < 0.45:
                y = int(floor_y - max_step * 2)
                x = int(room_rng.choice([-520, -260, 0, 260, 520]))
                w = int(room_rng.choice([240, 280, 360]))
                plats.append({"x": x, "y": y, "w": w, "h": 40})
            if room_rng.random() < 0.25:
                y = int(floor_y - max_step * 3)
                x = int(room_rng.choice([-340, 0, 340]))
                w = int(room_rng.choice([200, 240, 280]))
                plats.append({"x": x, "y": y, "w": w, "h": 40})

        spawns: Dict[str, Dict[str, int]] = {
            "SpawnDefault": {"x": -860, "y": 210},
            "SpawnFromW": {"x": -860, "y": 210},
            "SpawnFromE": {"x": 860, "y": 210},
            "SpawnFromN": {"x": 0, "y": 120},
            "SpawnFromS": {"x": 0, "y": 210},
        }

        layouts_by_room[r.id] = {
            "platforms": plats,
            "spawns": spawns,
            "exits": sorted(exits_by_room[r.id], key=lambda ex: (ex["dir"], ex["to"])),
        }

    # Output
    rooms_out = [
        {
            "id": r.id,
            "x": r.pos.x,
            "y": r.pos.y,
            "biome": r.biome,
            "tags": r.tags,
            "layout": layouts_by_room.get(r.id, {}),
        }
        for r in rooms_list
    ]

    edges_out = []
    for e in edges:
        d = dir_between(e.a, e.b)
        edges_out.append(
            {
                "a": e.a,
                "b": e.b,
                "dir": d,
                "kind": e.kind,
                "lock": e.lock,
            }
        )

    meta = {
        "seed": seed,
        "biome": biome,
        "grid": {"width": width, "height": height},
        "room_px": {"w": 2000, "h": 1200},
        "counts": {"rooms": len(rooms_list), "edges": len(edges)},
        "critical_path_length": critical_path,
        "lock": {"name": lock_name, "edge": {"a": locked_a, "b": locked_b}, "key_room": key_room_id},
        "start_room": start_id,
        "boss_room": path_ids[-1],
    }

    return {"meta": meta, "rooms": rooms_out, "edges": edges_out}


def main() -> int:
    ap = argparse.ArgumentParser(description="Seeded procedural metroidvania map generator (single biome).")
    ap.add_argument("--seed", type=int, default=12345)
    ap.add_argument("--biome", type=str, default="biolume_canopy")
    ap.add_argument("--width", type=int, default=16)
    ap.add_argument("--height", type=int, default=10)
    ap.add_argument("--rooms", type=int, default=24)
    ap.add_argument("--critical-path", type=int, default=10)
    ap.add_argument("--branchiness", type=float, default=0.65, help="0..1; higher = more side branches")
    ap.add_argument("--lock-name", type=str, default="double_jump")
    ap.add_argument("--json-out", type=str, default="")
    ap.add_argument("--svg-out", type=str, default="")
    ap.add_argument("--ascii", action="store_true")

    args = ap.parse_args()

    try:
        m = generate_map(
            seed=args.seed,
            biome=args.biome,
            width=args.width,
            height=args.height,
            rooms=args.rooms,
            critical_path=args.critical_path,
            branchiness=args.branchiness,
            lock_name=args.lock_name,
        )
    except MapGenError as e:
        print(f"ERROR: {e}")
        return 2

    out_path = args.json_out
    if not out_path:
        out_path = str(Path(__file__).resolve().parent / "world.json")
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(m, f, indent=2)

    if args.svg_out:
        with open(args.svg_out, "w", encoding="utf-8") as f:
            f.write(_svg_map(m))
    if not args.json_out:
        print(json.dumps(m, indent=2))

    if args.ascii:
        # Build lookups for preview
        id_at: Dict[Pos, int] = {}
        rooms: List[Room] = []
        for r in m["rooms"]:
            rr = Room(id=r["id"], pos=Pos(r["x"], r["y"]), biome=r["biome"], tags=list(r["tags"]))
            rooms.append(rr)
            id_at[rr.pos] = rr.id
        edges = [Edge(a=e["a"], b=e["b"], kind=e["kind"], lock=e.get("lock")) for e in m["edges"]]

        w = m["meta"]["grid"]["width"]
        h = m["meta"]["grid"]["height"]
        print("\nASCII preview (rooms only):")
        print(_ascii(w, h, id_at, rooms, edges))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
