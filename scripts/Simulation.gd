extends Node

signal new_children(id)

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


func _ready():
	ui_mutex = Mutex.new();
	basket_mutex = Mutex.new();
	print("Simulation is ready to start");


func initialize(p_basket_capacity: int, p_initial_balls: int) -> void:
	basket_capacity = p_basket_capacity
	basket_count = p_initial_balls  # bolas já no cesto no início

	available_balls_semaphore  = Semaphore.new()
	available_space_semaphore = Semaphore.new()

	# Espaços livres = capacidade - bolas já presentes
	for i in range(basket_capacity - p_initial_balls):
		available_space_semaphore.post()

	# Bolas já disponíveis no cesto
	for i in range(p_initial_balls):
		available_balls_semaphore.post()
		
	SimLogger.log("Simulação iniciada. Cesto: %d/%d" % [basket_count, basket_capacity])
		


func create_child(child_name: String, has_ball: bool, Tb_ms: float, Td_ms: float):
	var data = {
		"id": children_id, "name": child_name,
		"has_ball": has_ball,
		"Tb": Tb_ms, "Td": Td_ms,
		"status": "IDLE",
		"log": []
	}
	ui_mutex.lock()
	children_data.append(data)
	ui_mutex.unlock()

	var thread = Thread.new();
	thread.start(_child_thread.bind(data));
	
	var log_msg = "Nova Criança: ID: %d, Name: %s, Tb: %02ds, Td: %02ds, Has_Ball: %s" % [children_id, child_name, Tb_ms / 1000, Td_ms  / 1000, "Yes" if has_ball else "No"];
	SimLogger.log(log_msg);
	children_id += 1;


func _child_thread(data: Dictionary) -> void:
	var has_ball: bool = data["has_ball"]

	while running:
		if has_ball:
			_set_status(data, "BRINCANDO")
			SimLogger.log("%s: Começou a brincar com a bola." % data["name"])
			_busy_wait(data["Tb"])

			_set_status(data, "AG_ESPACO")
			SimLogger.log("%s: Tentando colocar a bola no cesto..." % data["name"])
			available_space_semaphore.wait()

			basket_mutex.lock()
			basket_count += 1
			var count_snap = basket_count
			basket_mutex.unlock()

			available_balls_semaphore.post()
			SimLogger.log("%s: Colocou a bola no cesto. [Cesto: %d/%d]" % [data["name"], count_snap, basket_capacity])
			has_ball = false

			_set_status(data, "DESCANSANDO")
			SimLogger.log("%s: Descansando..." % data["name"])
			_busy_wait(data["Td"])

		else:
			_set_status(data, "AG_CESTO")
			SimLogger.log("%s: Aguardando uma bola no cesto..." % data["name"])
			available_balls_semaphore.wait()

			basket_mutex.lock()
			basket_count -= 1
			var count_snap = basket_count
			basket_mutex.unlock()

			available_space_semaphore.post()
			SimLogger.log("%s: Pegou uma bola do cesto! [Cesto: %d/%d]" % [data["name"], count_snap, basket_capacity])
			has_ball = true

	_set_status(data, "IDLE")
	SimLogger.log("%s: Thread encerrada." % data["name"])


func _busy_wait(ms: float) -> void:
	var start: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < ms:
		if not running:
			return
		OS.delay_usec(500)


func _set_status(data: Dictionary, status: String) -> void:
	ui_mutex.lock()
	data["status"] = status
	ui_mutex.unlock()
