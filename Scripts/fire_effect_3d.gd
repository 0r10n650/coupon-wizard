@tool
extends Node3D

@export var effect_scale: float = 1.0:
	set(value):
		effect_scale = max(0.1, value)
		_update_scale()

@export var flicker_speed: float = 15.0
@export var base_energy: float = 2.0
@export var noise_amount: float = 0.5

@onready var light = $OmniLight3D
@onready var particles = $GPUParticles3D

var time_passed: float = 0.0
var _is_ready = false

func _ready():
	_is_ready = true
	_update_scale()

func _update_scale():
	if not _is_ready:
		return
		
	if light:
		light.omni_range = 5.0 * effect_scale
		
	if particles and particles.process_material:
		var mat = particles.process_material as ParticleProcessMaterial
		if mat:
			mat.emission_sphere_radius = 0.3 * effect_scale
			mat.scale_min = 0.5 * effect_scale
			mat.scale_max = 1.5 * effect_scale
			mat.gravity.y = 4.0 * effect_scale

func _process(delta):
	if Engine.is_editor_hint():
		return
		
	time_passed += delta * flicker_speed
	var noise = sin(time_passed) * 0.5 + sin(time_passed * 2.3) * 0.25 + sin(time_passed * 4.1) * 0.25
	if light:
		light.light_energy = base_energy + noise * noise_amount
