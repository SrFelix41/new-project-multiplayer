extends Control

@onready var campo_ip = $VBoxContainer/CampoIP
@onready var botao_servidor = $VBoxContainer/BotaoServidor
@onready var botao_cliente = $VBoxContainer/BotaoCliente

func _ready() -> void:
	print("✅ Menu carregado com sucesso!")  # Verifique se isso aparece no Output
	botao_servidor.pressed.connect(_iniciar_servidor)
	botao_cliente.pressed.connect(_iniciar_cliente)

func _iniciar_servidor():
	print("🖥️ Iniciando o servidor...")
	var scene = preload("res://scenes/game/main.tscn").instantiate()
	get_tree().root.add_child(scene)
	scene.call_deferred("iniciar_servidor")
	queue_free()

func _iniciar_cliente():
	var ip = campo_ip.text if campo_ip.text != "" else "127.0.0.1"
	print("🎮 Conectando ao servidor em: ", ip)
	
	var scene = preload("res://scenes/game/main.tscn").instantiate()
	get_tree().root.add_child(scene)
	
	await get_tree().process_frame
	scene.call_deferred("connect_to_server", ip)
	
	queue_free()
