@tool
extends Node2D

## Emitted when the player enters the detection radius.
signal player_entered_range
## Emitted when the player leaves the detection radius.
signal player_exited_range

## True while the player is within the detection area.
var is_player_near: bool = false

## True after the first encounter has been triggered (prevents re-triggering).
var _encounter_triggered: bool = false

## Radius of the detection area (pixels). Adjust in the Inspector to change how close the player must be to trigger detection.
var _detection_radius: float = 80.0
@export var detection_radius: float = 80.0:
	set(value):
		_detection_radius = value
		_update_detection_shape_radius()
	get:
		return _detection_radius

## In the editor, which form to show for configuring collisions. Switch to Boss to configure the boss hitbox while seeing the boss sprite.
var _editor_form_preview: int = 0
@export_enum("Small", "Boss") var editor_form_preview: int = 0:
	set(value):
		_editor_form_preview = value
		_update_editor_preview()
	get:
		return _editor_form_preview


func _ready() -> void:
	add_to_group("enemies")
	_update_detection_shape_radius()
	_sync_solid_bodies()
	if Engine.is_editor_hint():
		_update_editor_preview()
		return
	var detection_area := get_node_or_null("SmallForm/DetectionArea") as Area2D
	if detection_area:
		detection_area.body_entered.connect(_on_body_entered)
		detection_area.body_exited.connect(_on_body_exited)


func _sync_solid_bodies() -> void:
	var small_visible := _is_small_form_visible()
	var small_body := get_node_or_null("SmallForm/SolidBody") as StaticBody2D
	var boss_body := get_node_or_null("BossForm/SolidBody") as StaticBody2D
	if small_body:
		small_body.collision_layer = 1 if small_visible else 0
	if boss_body:
		boss_body.collision_layer = 0 if small_visible else 1


func _is_small_form_visible() -> bool:
	var small := get_node_or_null("SmallForm") as Node2D
	return small != null and small.visible


func _update_editor_preview() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	var small := get_node_or_null("SmallForm") as Node2D
	var boss := get_node_or_null("BossForm") as Node2D
	if small and boss:
		small.visible = _editor_form_preview == 0
		boss.visible = _editor_form_preview == 1
		_sync_solid_bodies()


func _update_detection_shape_radius() -> void:
	if not is_inside_tree():
		return
	var detection_node := get_node_or_null("SmallForm/DetectionArea/DetectionShape")
	if not detection_node:
		return
	var shape := detection_node.shape as CircleShape2D
	if shape:
		shape.radius = detection_radius
		shape.emit_changed()


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		is_player_near = true
		if not _encounter_triggered:
			_encounter_triggered = true
			player_entered_range.emit()


func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		is_player_near = false
		player_exited_range.emit()


## Displays dialogue text above the enemy. The label is positioned in world space as a child of this node.
func show_dialogue_line(text: String) -> void:
	var label := get_node_or_null("DialogueLabel") as Label
	if label:
		label.text = text
		label.visible = true


## Hides the dialogue label and clears its text.
func hide_dialogue() -> void:
	var label := get_node_or_null("DialogueLabel") as Label
	if label:
		label.text = ""
		label.visible = false


## Switches to boss form (hides small form, shows boss form).
func switch_to_boss_form() -> void:
	var small := get_node_or_null("SmallForm") as Node2D
	var boss := get_node_or_null("BossForm") as Node2D
	if small:
		small.visible = false
	if boss:
		boss.visible = true
	_sync_solid_bodies()


## Replaces the boss sprite texture. Use when you need a different boss variant.
func set_sprite_texture(texture: Texture2D) -> void:
	var sprite := get_node_or_null("BossForm/Sprite2D") as Sprite2D
	if sprite:
		sprite.texture = texture


## Enables the Hitbox so it can detect hits (e.g. when in boss form).
func enable_hitbox() -> void:
	var hitbox := get_node_or_null("BossForm/Hitbox")
	if hitbox and hitbox.has_method("enable"):
		hitbox.enable()


## Disables the Hitbox.
func disable_hitbox() -> void:
	var hitbox := get_node_or_null("BossForm/Hitbox")
	if hitbox and hitbox.has_method("disable"):
		hitbox.disable()
