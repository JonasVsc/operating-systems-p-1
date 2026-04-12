extends Node

var available_balls_semaphore: Semaphore;
var available_space_semaphore: Semaphore;
var basket_mutex: Mutex;

var basket_count: int = 0;
var basket_capacity: int = 1;
var children_data: Array = [];
var running: bool = true;

var ui_mutex: Mutex;


func _ready():
	ui_mutex = Mutex.new();
	basket_mutex = Mutex.new();
	
	print("Simulation is ready");


func initialize() -> void:
	print("Simulation initialized");
	
	available_balls_semaphore  = Semaphore.new();
	available_space_semaphore = Semaphore.new();
	
	for i in range(basket_capacity):
		available_space_semaphore.post();
		


func create_child(id, child_name: String, has_ball: bool, Tb_ms: float, Td_ms: float):
	var data = {
		"id": id, "name": child_name,
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


func _child_thread(data: Dictionary):
	if data.has_ball:
		_go_play(data)
	else:
		_go_wait_ball(data)


func _go_wait_ball(data):
	_set_status(data, "AG_CESTO")
	_log(data, "Aguardando bola no cesto...")

	available_space_semaphore.wait()

	basket_mutex.lock()
	basket_count -= 1
	basket_mutex.unlock()
	available_space_semaphore.post()

	_log(data, "Pegou uma bola!")
	_go_play(data)


func _go_play(data):
	_set_status(data, "BRINCANDO")
	_log(data, "Brincando com a bola (%dms)" % int(data.Tb))
	_busy_wait(data.Tb)
	_go_wait_space(data)


func _go_wait_space(data):
	_set_status(data, "AG_ESPACO")
	_log(data, "Aguardando espaço no cesto...")

	available_space_semaphore.wait()

	basket_mutex.lock()
	basket_count += 1
	basket_mutex.unlock()
	available_balls_semaphore.post() 

	_log(data, "Colocou a bola no cesto.")
	_go_rest(data)


func _go_rest(data):
	_set_status(data, "DESCANSANDO")
	_log(data, "Descansando (%dms)" % int(data.Td))
	_busy_wait(data.Td)
	
	if running:
		_go_wait_ball(data)


func _busy_wait(ms: float):
	var start = Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < ms:
		OS.delay_usec(500)


func _set_status(data: Dictionary, status: String):
	ui_mutex.lock()
	data.status = status
	ui_mutex.unlock()


func _log(data: Dictionary, msg: String):
	var entry = "[%s] %s: %s" % [
		Time.get_time_string_from_system(), data.name, msg
	]
	ui_mutex.lock()
	data.log.push_back(entry)
	if data.log.size() > 50:
		data.log.pop_front()
	ui_mutex.unlock()


func shutdown():
	running = false
	for i in range(children_data.size()):
		available_balls_semaphore.post()
		available_space_semaphore.post()
