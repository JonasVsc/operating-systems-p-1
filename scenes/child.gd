extends CharacterBody2D

@export var speed: float = 300.0

func _physics_process(_delta: float) -> void:
	# 1. Captura o vetor de entrada (Normalizado para evitar movimento diagonal rápido)
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# 2. Aplica a velocidade baseada na direção
	if direction != Vector2.ZERO:
		velocity = direction * speed
	else:
		# Suavização para parar (atrito)
		velocity = velocity.move_toward(Vector2.ZERO, speed)

	# 3. Função nativa que processa o movimento e colisões
	move_and_slide()
