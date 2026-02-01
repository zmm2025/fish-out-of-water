extends Area2D

## Emitted when a valid body enters the hitbox (e.g. Player). Connect to deal damage.
## Passes the body that entered.
signal hit_detected(body: Node2D)

## Names of bodies that can trigger a hit (e.g. "Player"). Empty array = any body.
@export var hit_targets: Array[String] = ["Player"]

## Radius of the circular hitbox. Adjust in Inspector or set in code to match sprite size.
## The CollisionShape2D child must use a CircleShape2D for this to take effect.
var _hitbox_radius: float = 24.0
@export var hitbox_radius: float = 24.0:
	set(value):
		_hitbox_radius = value
		_update_shape_radius()
	get:
		return _hitbox_radius


func _ready() -> void:
	_update_shape_radius()
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)


func _update_shape_radius() -> void:
	if not is_inside_tree():
		return
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not shape_node or not shape_node.shape is CircleShape2D:
		return
	(shape_node.shape as CircleShape2D).radius = _hitbox_radius
	if shape_node.shape is Resource:
		shape_node.shape.emit_changed()


func enable() -> void:
	monitoring = true
	monitorable = true


func disable() -> void:
	monitoring = false
	monitorable = false


func _on_body_entered(body: Node2D) -> void:
	if hit_targets.is_empty() or body.name in hit_targets:
		hit_detected.emit(body)
