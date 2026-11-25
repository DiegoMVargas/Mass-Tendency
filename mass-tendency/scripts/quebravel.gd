extends Area3D


func _on_body_entered(body: Node3D) -> void:
	# Verifica se o corpo que entrou é o player 
	if body.grav_index == 0:
		body.velocity.y = 15.0 
		queue_free()
