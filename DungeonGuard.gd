extends Sprite2D

var health = 30
var health_dirty = true

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if health_dirty:
		health_dirty = false
		var hp_label = find_child("GuardHPLabel")
		if hp_label == null:
			hp_label = Label.new()
			hp_label.set_name(&"GuardHPLabel")
			add_child(hp_label, true)
			hp_label.set_owner(self)
			hp_label.position.y += 20.0
			hp_label.position.x -= 20.0
		hp_label.text = "%d HP" % health
