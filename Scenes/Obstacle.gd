extends Area2D

var scroll_speed : float = 300.0

func _ready() -> void:
	# Connect collision signal directly here
	connect("body_entered", _on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.die()

func _process(delta: float) -> void:
	position.x -= scroll_speed * delta
	if position.x < -100:
		queue_free()

func set_tile_texture(texture: Texture2D) -> void:
	$Sprite.texture = texture

func set_speed(speed: float) -> void:
	scroll_speed = speed
