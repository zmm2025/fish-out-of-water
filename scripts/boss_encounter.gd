extends Node

## Boss encounter sequence scene. Loads config from resources/boss_encounter_config.tres
## unless overridden in Inspector. Call start_encounter(player, enemy) to run the sequence.

const DEFAULT_CONFIG_PATH := "res://resources/boss_encounter_config.tres"

## Override in Inspector to use a different config. If null, loads from DEFAULT_CONFIG_PATH.
@export var config: Resource

var _config: Resource
var _player: CharacterBody2D

## True while the boss camera is active and dual-subject tracking is running.
var is_encounter_active: bool = false
var _enemy: Node2D


func _ready() -> void:
	_config = config
	if not _config:
		_config = load(DEFAULT_CONFIG_PATH) as Resource
	if not _config:
		push_error("BossEncounter: No config assigned and default path failed: %s" % DEFAULT_CONFIG_PATH)


func start_encounter(player: CharacterBody2D, enemy: Node2D) -> void:
	if not _config:
		return
	_player = player
	_enemy = enemy
	player.movement_locked = true
	enemy.show_dialogue_line("...huh?")
	_run_sequence()


func _run_sequence() -> void:
	await get_tree().create_timer(_config.pre_black_duration).timeout
	_show_black_overlay()
	await get_tree().create_timer(_config.black_duration).timeout
	_reveal_boss()


func _show_black_overlay() -> void:
	var overlay := get_node_or_null("EncounterOverlay/ColorRect") as ColorRect
	if overlay:
		overlay.color = _config.black_color
		overlay.visible = true


func _reveal_boss() -> void:
	var overlay := get_node_or_null("EncounterOverlay/ColorRect") as ColorRect
	if overlay:
		overlay.visible = false

	if _player:
		_player.movement_locked = false
	if _enemy and _enemy.has_method("hide_dialogue"):
		_enemy.hide_dialogue()

	var boss_texture := load(_config.boss_sprite_path) as Texture2D
	if boss_texture and _enemy and _enemy.has_method("set_sprite_texture"):
		_enemy.set_sprite_texture(boss_texture)
	if _enemy:
		if _enemy.has_method("switch_to_boss_form"):
			_enemy.switch_to_boss_form()
		_enemy.global_position = _config.get_boss_position()
		if _enemy.has_method("enable_hitbox"):
			_enemy.enable_hitbox()

	var player_cam := _player.get_node_or_null("Camera") as Camera2D if _player else null
	var boss_cam := get_node_or_null("BossCamera") as Camera2D
	if player_cam:
		player_cam.enabled = false
	if boss_cam:
		boss_cam.enabled = true

	is_encounter_active = true


func _process(_delta: float) -> void:
	if not is_encounter_active or not _player or not _config:
		return
	_update_boss_camera()


func _update_boss_camera() -> void:
	var boss_cam := get_node_or_null("BossCamera") as Camera2D
	if not _enemy or not boss_cam:
		return

	var player_pos := _player.global_position
	var boss_pos := _enemy.global_position

	# Extend a point past the boss (along player->boss line) by boss_protection_margin pixels
	var extended_boss := boss_pos
	var margin: float = float(_config.boss_protection_margin)
	if margin > 0:
		var delta := boss_pos - player_pos
		var dist := delta.length()
		if dist > 0.0001:
			extended_boss = boss_pos + (delta / dist) * margin

	var min_pos := Vector2(
		minf(player_pos.x, extended_boss.x) - _config.camera_padding,
		minf(player_pos.y, extended_boss.y) - _config.camera_padding
	)
	var max_pos := Vector2(
		maxf(player_pos.x, extended_boss.x) + _config.camera_padding,
		maxf(player_pos.y, extended_boss.y) + _config.camera_padding
	)
	var bbox_size := max_pos - min_pos
	var center := (min_pos + max_pos) / 2.0

	var view_size := get_viewport().get_visible_rect().size
	var zoom_x: float = view_size.x / bbox_size.x if bbox_size.x > 0 else _config.camera_initial_zoom
	var zoom_y: float = view_size.y / bbox_size.y if bbox_size.y > 0 else _config.camera_initial_zoom
	var zoom_value := minf(zoom_x, zoom_y)
	# Never zoom in past the initial view size (only zoom out)
	zoom_value = minf(zoom_value, _config.camera_initial_zoom)
	boss_cam.zoom = Vector2(zoom_value, zoom_value)

	var half_view_y := (view_size.y / 2.0) / boss_cam.zoom.y
	var max_camera_center_y: float = _config.camera_floor_limit - half_view_y
	center.y = minf(center.y, max_camera_center_y)
	boss_cam.global_position = center
