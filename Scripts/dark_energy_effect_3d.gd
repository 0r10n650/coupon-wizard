@tool
extends Node3D

@export var effect_scale: float = 1.0:
	set(value):
		effect_scale = max(0.1, value)
		_update_scale()

@export var pulse_speed: float = 4.0
@export var base_energy: float = 2.0
@export var pulse_amount: float = 1.0

@onready var light = $OmniLight3D
@onready var particles = $DarkVortex
@onready var sparks = $MagicSparks

var time_passed: float = 0.0
var _is_ready = false

func _ready():
	_is_ready = true
	_update_scale()

func _update_scale():
	if not _is_ready:
		return
		
	if light:
		light.omni_range = 4.0 * effect_scale
		
	if particles and particles.process_material:
		var mat = particles.process_material as ParticleProcessMaterial
		if mat:
			mat.emission_ring_radius = 0.6 * effect_scale
			mat.scale_min = 0.2 * effect_scale
			mat.scale_max = 0.8 * effect_scale
			mat.gravity.y = 1.5 * effect_scale
			
	if sparks and sparks.process_material:
		var smat = sparks.process_material as ParticleProcessMaterial
		if smat:
			smat.emission_sphere_radius = 0.2 * effect_scale
			smat.scale_min = 0.05 * effect_scale
			smat.scale_max = 0.15 * effect_scale
			smat.initial_velocity_min = 2.0 * effect_scale
			smat.initial_velocity_max = 4.0 * effect_scale

func _process(delta):
	if Engine.is_editor_hint():
		return
		
	time_passed += delta * pulse_speed
	var pulse = sin(time_passed) * pulse_amount + sin(time_passed * 3.1) * (pulse_amount * 0.3)
	if light:
		light.light_energy = base_energy + pulse
