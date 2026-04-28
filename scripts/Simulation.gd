extends Node

signal new_children(id)

const ChildScene = preload("res://scenes/child.tscn");

const ChildSpawnPoint: Vector2 = Vector2(424.0, 232.0);

var available_balls_semaphore: Semaphore;
var available_space_semaphore: Semaphore;
var basket_mutex: Mutex;

var basket_count: int = 0;
var basket_capacity: int = 1;
var children_data: Array = [];
var children_id: int = 0:
	set(valor):
		children_id = valor
		new_children.emit(children_id)

var running: bool = true;

var ui_mutex: Mutex;

var queue_cesto:  Array[int] = []
var queue_espaco: Array[int] = []
var queue_mutex:  Mutex


func _ready():
	ui_mutex = Mutex.new();
	basket_mutex = Mutex.new();
	queue_mutex  = Mutex.new();


func _join_queue(queue: Array, id: int) -> void:
	queue_mutex.lock()
	if not queue.has(id):
		queue.append(id)
	queue_mutex.unlock()


func _leave_queue(queue: Array, id: int) -> void:
	queue_mutex.lock()
	queue.erase(id)
	queue_mutex.unlock()


func _get_queue_index(queue: Array, id: int) -> int:
	queue_mutex.lock()
	var idx := queue.find(id)
	queue_mutex.unlock()
	return max(idx, 0)


func initialize(p_basket_capacity: int) -> void:
	basket_capacity = p_basket_capacity
	
	available_balls_semaphore  = Semaphore.new()
	available_space_semaphore = Semaphore.new()
	
	# Espaços livres = capacidade - bolas já presentes
	for i in range(basket_capacity):
		available_space_semaphore.post()
	
	SimLogger.log("Simulação iniciada. Capacidade do cesto: %d" % [basket_capacity])


func create_child(has_ball: bool, Tb_ms: float, Td_ms: float):
	var data = {
		"id": children_id,
		"has_ball": has_ball,
		"Tb": Tb_ms, "Td": Td_ms,
		"status": "IDLE",
		# posição inicial aleatoria
		"px": ChildSpawnPoint.x,
		"py": ChildSpawnPoint.y,
		"flip_h": false,  # <- adicione isso
	}
	
	ui_mutex.lock()
	children_data.append(data)
	ui_mutex.unlock()
	
	_spawn_child_node.call_deferred(data);

	var thread = Thread.new();
	thread.start(_child_thread.bind(data));
	
	var log_msg = "Nova Criança: ID: %d, Tb: %02ds, Td: %02ds, Has_Ball: %s" % [children_id, Tb_ms / 1000, Td_ms  / 1000, "Yes" if has_ball else "No"];
	SimLogger.log(log_msg);
	children_id += 1;


func _spawn_child_node(data: Dictionary) -> void:
	var node = ChildScene.instantiate();
	node.data = data;
	get_tree().current_scene.add_child(node);


func _child_thread(data: Dictionary) -> void:
	var has_ball: bool = data["has_ball"]
	var wander_target := Vector2(data["px"], data["py"])
	var wander_timer  := 0.0

	while running:
		if has_ball:
			# ── BRINCANDO ─────────────────────────────────────────
			_set_status(data, "BRINCANDO")
			SimLogger.log("%s: Começou a brincar." % data["id"])
			var start := Time.get_ticks_msec()
			var last  := start
			while Time.get_ticks_msec() - start < data["Tb"] and running:
				var now := Time.get_ticks_msec()
				var dt  := clampf((now - last) / 1000.0, 0.0, 0.05)
				last = now
				wander_timer -= dt
				if wander_timer <= 0.0:
					wander_timer  = randf_range(1.5, 3.0)
					wander_target = Vector2(
						randf_range(102.0, 811.0),
						randf_range(290.0, 476.0)
					)
				_move_toward(data, wander_target, dt)

			# ── AG_ESPACO: fase 1 — chegar ao cesto ───────────────
			_set_status(data, "AG_ESPACO")
			SimLogger.log("%s: Indo ao cesto para colocar a bola..." % data["id"])

			# Move em direção à base da fila SEM entrar nela ainda
			last = Time.get_ticks_msec()
			while running:
				var now := Time.get_ticks_msec()
				var dt  := clampf((now - last) / 1000.0, 0.0, 0.05)
				last = now
				_move_toward(data, BASE_ESPACO, dt)
				if _arrived_at(data, BASE_ESPACO):
					break

			# Entra na fila somente ao chegar — prioridade por chegada
			_join_queue(queue_espaco, data["id"])
			_set_status(data, "BLOQUEADO_AGUARDANDO_CESTO")
			SimLogger.log("%s: Entrou na fila do cesto (pos %d)." % [data["id"], _get_queue_index(queue_espaco, data["id"])])

			# ── AG_ESPACO: fase 2 — aguarda espaço, anda com a fila
			last = Time.get_ticks_msec()
			while running:
				var now := Time.get_ticks_msec()
				var dt  := clampf((now - last) / 1000.0, 0.0, 0.05)
				last = now
				var basket_target := _queue_position(queue_espaco, data["id"], false)
				_move_toward(data, basket_target, dt)
				
				# Só a primeira da fila tenta o semáforo
				if _get_queue_index(queue_espaco, data["id"]) == 0:
					if available_space_semaphore.try_wait():
						break
				OS.delay_usec(8000)

			basket_mutex.lock()
			basket_count += 1
			var snap := basket_count
			basket_mutex.unlock()

			available_balls_semaphore.post()
			_leave_queue(queue_espaco, data["id"])
			SimLogger.log("%s: Colocou a bola. [Cesto: %d/%d]" % [data["id"], snap, basket_capacity])
			has_ball = false

			# ── DESCANSANDO ───────────────────────────────────────
			_set_status(data, "DESCANSANDO")
			SimLogger.log("%s: Descansando..." % data["id"])
			var rest_target := Vector2(
				randf_range(102.0, 811.0),
				randf_range(290.0, 476.0)
			)
			start = Time.get_ticks_msec()
			last  = start
			while Time.get_ticks_msec() - start < data["Td"] and running:
				var now := Time.get_ticks_msec()
				var dt  := clampf((now - last) / 1000.0, 0.0, 0.05)
				last = now
				_move_toward(data, rest_target, dt)

		else:
			# ── AG_CESTO: fase 1 — chegar ao cesto ───────────────
			_set_status(data, "AG_CESTO")
			SimLogger.log("%s: Indo ao cesto buscar uma bola..." % data["id"])

			# Move em direção à base da fila SEM entrar nela ainda
			var last := Time.get_ticks_msec()
			while running:
				var now := Time.get_ticks_msec()
				var dt  := clampf((now - last) / 1000.0, 0.0, 0.05)
				last = now
				_move_toward(data, BASE_CESTO, dt)
				if _arrived_at(data, BASE_CESTO):
					break

			# Entra na fila somente ao chegar — prioridade por chegada
			_join_queue(queue_cesto, data["id"])
			_set_status(data, "BLOQUEADO_AGUARDANDO_BOLA")
			SimLogger.log("%s: Entrou na fila do cesto (pos %d)." % [data["id"], _get_queue_index(queue_cesto, data["id"])])

			# ── AG_CESTO: fase 2 — aguarda bola, anda com a fila ──
			last = Time.get_ticks_msec()
			while running:
				var now := Time.get_ticks_msec()
				var dt  := clampf((now - last) / 1000.0, 0.0, 0.05)
				last = now
				var cesto_target := _queue_position(queue_cesto, data["id"], true)
				_move_toward(data, cesto_target, dt)
				
				# Só a primeira da fila tenta o semáforo
				if _get_queue_index(queue_cesto, data["id"]) == 0:
					if available_balls_semaphore.try_wait():
						break
				OS.delay_usec(8000)

			basket_mutex.lock()
			basket_count -= 1
			var snap := basket_count
			basket_mutex.unlock()

			available_space_semaphore.post()
			_leave_queue(queue_cesto, data["id"])
			SimLogger.log("%s: Pegou uma bola! [Cesto: %d/%d]" % [data["id"], snap, basket_capacity])
			has_ball = true

	_set_status(data, "IDLE")
	SimLogger.log("%s: Thread encerrada." % data["id"])


const ARRIVAL_THRESHOLD := 5.0

func _arrived_at(data: Dictionary, target: Vector2) -> bool:
	var pos := Vector2(data["px"], data["py"])
	return pos.distance_to(target) <= ARRIVAL_THRESHOLD


# BASE_CESTO e BASE_ESPACO = posição base de cada fila no cenário
# QUEUE_OFFSET = deslocamento por posição na fila (ex: 32px à esquerda)
const BASE_CESTO  := Vector2(699.0, 253.0)
const BASE_ESPACO := Vector2(749.0, 276.0)
const CESTO_OFFSET := Vector2(-36.0, 0.0)  # fila cresce para a esquerda
const ESPACO_OFFSET := Vector2(0.0, 12.0)  # fila cresce para a esquerda


func _queue_position(queue: Array, id: int, is_cesto: bool) -> Vector2:
	var idx   := _get_queue_index(queue, id)
	var base  := BASE_CESTO if is_cesto else BASE_ESPACO
	if is_cesto:
		return base + CESTO_OFFSET * idx
	return base + ESPACO_OFFSET * idx


func _move_toward(data: Dictionary, target: Vector2, dt: float) -> void:
	var pos    := Vector2(data["px"], data["py"])
	var newpos := pos.move_toward(target, 90.0 * dt)
	var flip: bool = data["flip_h"];
	if abs(target.x - pos.x) > 2.0:
		flip = target.x < pos.x
	
	ui_mutex.lock()
	data["px"]     = newpos.x
	data["py"]     = newpos.y
	data["flip_h"] = flip
	ui_mutex.unlock()


func _set_status(data: Dictionary, status: String) -> void:
	ui_mutex.lock()
	data["status"] = status
	ui_mutex.unlock()
