extends Node2D

## Adds ambient lighting, fog particles, and atmospheric glow to any room.
## Attach as a child of the room's Geometry node or the room root.

@export var ambient_color := Color(0.08, 0.15, 0.12, 1)
@export var ambient_energy := 0.3
@export var fog_enabled := true
@export var fog_amount := 8
@export var fog_color := Color(0.15, 0.2, 0.25, 0.06)
@export var vignette_enabled := true
@export var room_half_width := 1000.0
@export var room_top := 60.0
@export var room_bottom := 420.0

static var _cached_ambient_tex: ImageTexture

var _ambient_light: PointLight2D
var _fog_particles: GPUParticles2D
var _vignette_top: Polygon2D
var _vignette_bottom: Polygon2D
var _vignette_left: Polygon2D
var _vignette_right: Polygon2D

func _ready() -> void:
	_add_ambient_light()
	if fog_enabled:
		_add_fog_particles()
	if vignette_enabled:
		_add_vignette()

func _add_ambient_light() -> void:
	_ambient_light = PointLight2D.new()
	_ambient_light.name = "AmbientLight"
	_ambient_light.color = ambient_color
	_ambient_light.energy = ambient_energy
	_ambient_light.blend_mode = PointLight2D.BLEND_MODE_ADD
	_ambient_light.shadow_enabled = false
	_ambient_light.position = Vector2(0, (room_top + room_bottom) * 0.5)
	if _cached_ambient_tex == null:
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		var center := Vector2(32, 32)
		var radius := 32.0
		for y in range(64):
			for x in range(64):
				var dist: float = Vector2(x, y).distance_to(center) / radius
				var a: float = 0.0
				if dist < 1.0:
					a = clampf(1.0 - dist * dist, 0.0, 1.0)
				img.set_pixel(x, y, Color(1, 1, 1, a))
		_cached_ambient_tex = ImageTexture.create_from_image(img)
	_ambient_light.texture = _cached_ambient_tex
	_ambient_light.texture_scale = 20.0
	add_child(_ambient_light)

func _add_fog_particles() -> void:
	_fog_particles = GPUParticles2D.new()
	_fog_particles.name = "FogParticles"
	_fog_particles.z_index = 6
	_fog_particles.amount = fog_amount
	_fog_particles.lifetime = 10.0
	_fog_particles.speed_scale = 0.2
	_fog_particles.randomness = 1.0
	_fog_particles.position = Vector2(0, (room_top + room_bottom) * 0.5)

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(1, -0.3, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 3.0
	mat.initial_velocity_max = 10.0
	mat.gravity = Vector3(0, 0, 0)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(room_half_width * 0.8, (room_bottom - room_top) * 0.4, 0)
	mat.scale_min = 3.0
	mat.scale_max = 8.0
	mat.color = fog_color

	var grad := Gradient.new()
	grad.set_color(0, Color(fog_color.r, fog_color.g, fog_color.b, 0.0))
	grad.add_point(0.2, fog_color)
	grad.add_point(0.8, fog_color)
	grad.set_color(1, Color(fog_color.r, fog_color.g, fog_color.b, 0.0))
	var gtex := GradientTexture1D.new()
	gtex.gradient = grad
	mat.color_ramp = gtex

	_fog_particles.process_material = mat
	add_child(_fog_particles)

func _add_vignette() -> void:
	var hw := room_half_width
	var vw := 200.0
	var vh := 120.0

	# Top vignette
	_vignette_top = Polygon2D.new()
	_vignette_top.z_index = 15
	_vignette_top.color = Color(0.0, 0.0, 0.0, 0.35)
	_vignette_top.polygon = PackedVector2Array([
		Vector2(-hw - 200, room_top - 200), Vector2(hw + 200, room_top - 200),
		Vector2(hw + 200, room_top + vh), Vector2(-hw - 200, room_top + vh)
	])
	add_child(_vignette_top)

	# Bottom vignette
	_vignette_bottom = Polygon2D.new()
	_vignette_bottom.z_index = 15
	_vignette_bottom.color = Color(0.0, 0.0, 0.0, 0.25)
	_vignette_bottom.polygon = PackedVector2Array([
		Vector2(-hw - 200, room_bottom - vh), Vector2(hw + 200, room_bottom - vh),
		Vector2(hw + 200, room_bottom + 200), Vector2(-hw - 200, room_bottom + 200)
	])
	add_child(_vignette_bottom)

	# Left edge darkening
	_vignette_left = Polygon2D.new()
	_vignette_left.z_index = 15
	_vignette_left.color = Color(0.0, 0.0, 0.0, 0.2)
	_vignette_left.polygon = PackedVector2Array([
		Vector2(-hw - 200, room_top - 200), Vector2(-hw + vw, room_top - 200),
		Vector2(-hw + vw, room_bottom + 200), Vector2(-hw - 200, room_bottom + 200)
	])
	add_child(_vignette_left)

	# Right edge darkening
	_vignette_right = Polygon2D.new()
	_vignette_right.z_index = 15
	_vignette_right.color = Color(0.0, 0.0, 0.0, 0.2)
	_vignette_right.polygon = PackedVector2Array([
		Vector2(hw - vw, room_top - 200), Vector2(hw + 200, room_top - 200),
		Vector2(hw + 200, room_bottom + 200), Vector2(hw - vw, room_bottom + 200)
	])
	add_child(_vignette_right)
