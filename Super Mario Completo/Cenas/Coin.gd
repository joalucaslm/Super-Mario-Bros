extends AnimatedSprite2D

#Create the animation for coin and give the instrutions to your position
func _ready():
	var coin_tween = get_tree().create_tween()
	coin_tween.tween_property(self, "position", position + Vector2(0, -40), .3)
	coin_tween.chain().tween_property(self, "position", position, .3)
	coin_tween.tween_callback(queue_free)
