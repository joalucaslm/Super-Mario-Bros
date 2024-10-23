extends Enemy

func die():
	super.die()
	set_collision_layer_value(3, false)
	set_collision_mask_value(3, false)
	get_tree().create_timer(0.5).timeout.connect(queue_free)
