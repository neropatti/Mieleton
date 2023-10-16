extends Button
class_name state_cycling_button

enum states{neutral = 0, positive = 1, negative = 2}
var current_state : int = 0:
	set(value):
		current_state = value % 3
		self.icon = icons[value]

func _ready():
	self.pressed.connect(cycle_state)
	self.icon = icons[current_state]

var icons : Array [Texture2D] = [preload("res://neutral.png"), preload("res://plus.png"), preload("res://minus.png")]

signal state_cycled(new_state : int)

func cycle_state():
	current_state = (current_state + 1) % 3
	state_cycled.emit(current_state)
