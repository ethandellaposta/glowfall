extends CharacterBody2D

@export var speed: float = 90.0
@export var patrol_distance: float = 240.0
@export var max_hp: int = 3
@export var contact_damage: int = 1

@export var walk_anim_speed: float = 18.0
@export var attack_anim_speed: float = 24.0

@export var sprite_scale: float = 0.35

var hp: int
var _dir: int = 1
var _start_x: float
var _damage_cooldown: float = 0.0

@onready var sprite: AnimatedSprite2D = $Sprite

var _attacking: bool = false
var _dying: bool = false
var _bob_time: float = 0.0
const BOB_AMPLITUDE: float = 3.0
const BOB_FREQUENCY: float = 8.0

func _ready() -> void:
	hp = max_hp
	_start_x = global_position.x
	add_to_group("enemies")
	_setup_sprite_frames()
	if is_instance_valid(sprite):
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
		sprite.scale = Vector2.ONE * sprite_scale
		sprite.animation_finished.connect(_on_sprite_animation_finished)
		sprite.centered = true
		if sprite.sprite_frames != null and sprite.sprite_frames.get_frame_count("walk") > 0:
			sprite.play("walk")

func _physics_process(delta: float) -> void:
	if hp <= 0 or _dying:
		return
	var gravity := ProjectSettings.get_setting("physics/2d/default_gravity") as float
	velocity.y += gravity * delta

	if global_position.x > _start_x + patrol_distance:
		_dir = -1
	elif global_position.x < _start_x - patrol_distance:
		_dir = 1

	velocity.x = float(_dir) * speed
	_update_animation()
	_update_bob(delta)
	move_and_slide()

	if _damage_cooldown > 0.0:
		_damage_cooldown = maxf(0.0, _damage_cooldown - delta)

	if _damage_cooldown <= 0.0:
		var slide_count := get_slide_collision_count()
		for i in range(slide_count):
			var col := get_slide_collision(i)
			var other := col.get_collider()
			if other != null and other.has_method("take_damage"):
				other.call("take_damage", contact_damage, _dir)
				_damage_cooldown = 0.5
				_play_attack()
				break

func take_hit(damage: int, knockback: Vector2) -> void:
	if _dying:
		return
	hp -= damage
	velocity += knockback
	if hp <= 0:
		_dying = true
		velocity = Vector2.ZERO
		_play_death_effect()

func _update_animation() -> void:
	if not is_instance_valid(sprite):
		return
	if _dying:
		return
	sprite.flip_h = _dir < 0
	if _attacking:
		if sprite.animation != "attack":
			sprite.play("attack")
		return
	if absf(velocity.x) > 1.0:
		if sprite.animation != "walk":
			sprite.play("walk")
	else:
		if sprite.animation != "idle":
			sprite.play("idle")

func _update_bob(delta: float) -> void:
	if not is_instance_valid(sprite):
		return
	if absf(velocity.x) > 1.0 and not _attacking:
		_bob_time += delta * BOB_FREQUENCY
		sprite.offset.y = sin(_bob_time) * BOB_AMPLITUDE
	else:
		_bob_time = 0.0
		sprite.offset.y = 0.0

func _play_death_effect() -> void:
	if is_instance_valid(sprite):
		sprite.stop()
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1, 0.2, 0.2, 1), 0.1)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.1)
	tween.tween_property(self, "modulate", Color(1, 0.2, 0.2, 1), 0.1)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_callback(queue_free)

func _play_attack() -> void:
	_attacking = true
	_update_animation()

func _on_sprite_animation_finished() -> void:
	if not is_instance_valid(sprite):
		return
	if sprite.animation == "attack":
		_attacking = false

func _setup_sprite_frames() -> void:
	if not is_instance_valid(sprite):
		return
	var padding := 2
	var move_tex: Texture2D = load("res://gen/scuttle-moving.png") as Texture2D
	var attack_tex: Texture2D = load("res://gen/scuttle-attack-1.png") as Texture2D
	if move_tex == null or attack_tex == null:
		return
	var move_regions: Array[Rect2i] = _get_autocrop_regions(move_tex, 6, 6, 36, padding)
	var attack_regions: Array[Rect2i] = _get_autocrop_regions(attack_tex, 6, 6, 36, padding)
	var std_w := 0
	var std_h := 0
	for r in move_regions:
		std_w = maxi(std_w, r.size.x)
		std_h = maxi(std_h, r.size.y)
	for r in attack_regions:
		std_w = maxi(std_w, r.size.x)
		std_h = maxi(std_h, r.size.y)
	if std_w <= 0 or std_h <= 0:
		return

	var frames: SpriteFrames = SpriteFrames.new()
	_add_regions_animation(frames, "idle", move_tex, move_regions.slice(0, 6), std_w, std_h, walk_anim_speed * 0.5, true)
	_add_regions_animation(frames, "walk", move_tex, move_regions, std_w, std_h, walk_anim_speed, true)
	_add_regions_animation(frames, "attack", attack_tex, attack_regions, std_w, std_h, attack_anim_speed, false)
	sprite.sprite_frames = frames

func _get_autocrop_regions(tex: Texture2D, cols: int, rows: int, frame_count: int, padding: int) -> Array[Rect2i]:
	var out: Array[Rect2i] = []
	if tex == null:
		return out
	if cols <= 0 or rows <= 0 or frame_count <= 0:
		return out
	var img: Image = tex.get_image()
	if img == null:
		return out
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	var sheet_w := tex.get_width()
	var sheet_h := tex.get_height()
	var base_w := sheet_w / cols
	var base_h := sheet_h / rows
	if base_w <= 0 or base_h <= 0:
		return out
	for i in range(frame_count):
		var row := i / cols
		var col := i % cols
		if row >= rows:
			break
		var base := Rect2i(col * base_w, row * base_h, base_w, base_h)
		var bbox := _alpha_bbox(img, base)
		if bbox.size.x <= 0 or bbox.size.y <= 0:
			bbox = base
		bbox.position.x = maxi(base.position.x, bbox.position.x - padding)
		bbox.position.y = maxi(base.position.y, bbox.position.y - padding)
		bbox.size.x = mini(base.end.x - bbox.position.x, bbox.size.x + padding * 2)
		bbox.size.y = mini(base.end.y - bbox.position.y, bbox.size.y + padding * 2)
		out.append(bbox)
	return out

func _alpha_bbox(img: Image, rect: Rect2i) -> Rect2i:
	var min_x := rect.end.x
	var min_y := rect.end.y
	var max_x := rect.position.x - 1
	var max_y := rect.position.y - 1
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var a := img.get_pixel(x, y).a
			if a > 0.0:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2i(rect.position.x, rect.position.y, 0, 0)
	return Rect2i(min_x, min_y, (max_x - min_x) + 1, (max_y - min_y) + 1)

func _add_regions_animation(
		frames: SpriteFrames,
		anim_name: String,
		tex: Texture2D,
		regions: Array[Rect2i],
		std_w: int,
		std_h: int,
		speed: float,
		loop: bool
	) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, speed)
	frames.set_animation_loop(anim_name, loop)
	for r in regions:
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(r.position, r.size)
		atlas.filter_clip = true
		var left := int(floor(float(std_w - r.size.x) * 0.5))
		var top := int(floor(float(std_h - r.size.y) * 0.5))
		var right := std_w - r.size.x - left
		var bottom := std_h - r.size.y - top
		atlas.margin = Rect2(left, top, right, bottom)
		frames.add_frame(anim_name, atlas)

func _add_sheet_animation(
		frames: SpriteFrames,
		anim_name: String,
		sheet_path: String,
		cols: int,
		frame_count: int,
		speed: float,
		loop: bool
	) -> void:
	if cols <= 0 or frame_count <= 0:
		return
	var sheet_tex: Texture2D = load(sheet_path) as Texture2D
	if sheet_tex == null:
		return
	var sheet_w: int = sheet_tex.get_width()
	var sheet_h: int = sheet_tex.get_height()
	if sheet_w <= 0 or sheet_h <= 0:
		return
	var frame_w: int = sheet_w / cols
	if frame_w <= 0:
		return
	var rows: int = int(ceil(float(frame_count) / float(cols)))
	if rows <= 0:
		return
	var frame_h: int = sheet_h / rows
	if frame_h <= 0:
		return

	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, speed)
	frames.set_animation_loop(anim_name, loop)
	for i in range(frame_count):
		var row: int = i / cols
		var col: int = i % cols
		var region := Rect2(col * frame_w, row * frame_h, frame_w, frame_h)
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet_tex
		atlas.region = region
		frames.add_frame(anim_name, atlas)
