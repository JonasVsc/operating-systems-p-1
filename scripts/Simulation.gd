extends Node

var available_balls: Semaphore;
var available_space: Semaphore;
var basket_mutex: Mutex;

var basket_count: int = 0
var basket_capacity: int = 3       # K — configurável pela UI
var children_data: Array = []
var running: bool = true

var ui_mutex: Mutex;
