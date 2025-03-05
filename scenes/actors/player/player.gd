extends CharacterBody2D

@export var speed: float = 200.0
@export var player_name: String = "Jogador"

@onready var name_text: Label = $player_name

func _ready() -> void:
	name_text.text = player_name

func _process(_delta: float) -> void:
	if multiplayer.get_unique_id() == int(name):
		var move_direction = Vector2.ZERO
		
		if Input.is_action_pressed("ui_right"):
			move_direction.x += 1
		if Input.is_action_pressed("ui_left"):
			move_direction.x -= 1
		if Input.is_action_pressed("ui_down"):
			move_direction.y += 1
		if Input.is_action_pressed("ui_up"):
			move_direction.y -= 1
		
		velocity = move_direction.normalized() * speed
		move_and_slide()
		rpc("sync_position", position)

@rpc("any_peer", "unreliable")
func sync_position(new_position):
	position = new_position
