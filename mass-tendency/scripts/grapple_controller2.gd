extends Node

@export var ray: RayCast3D

@export var stiffness = 10.0
@export var damping = 1.0
@export_range(1, 10) var rest_length_center_fraction: int = 3
@export var thrust_mult = 15.0

@onready var player: CharacterBody3D = get_parent()

var target: Vector3
var rest_length: float = 2.0
var launched = false

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("atirar"):
		if not launched:
			launch()
		else:
			retract()
	
	if launched:
		handle_grapple(delta)

func launch():
	if ray.is_colliding():
		target = ray.get_collision_point()
		launched = true
		
		# 1. Calcula o rest_length dinamicamente com base na distância do disparo
		var initial_dist = player.global_position.distance_to(target)
		var rest_length_center = initial_dist / float(rest_length_center_fraction)
		rest_length = initial_dist - rest_length_center

func retract():
	launched = false

func handle_grapple(delta: float):
	var target_dir = player.global_position.direction_to(target)
	var target_dist = player.global_position.distance_to(target)
	
	var displacement = target_dist - rest_length
	var spring_force_magnitude = stiffness * displacement
	
	# 2. Impede o efeito "cama elástica exagerada" quando o gancho está abaixo de você
	if spring_force_magnitude > 0:
		spring_force_magnitude *= 2.0
	else:
		spring_force_magnitude = 0.0
		
	var spring_force = target_dir * spring_force_magnitude
	
	# Amortecimento (Damping)
	var vel_dot = player.velocity.dot(target_dir)
	var damping_force = -damping * vel_dot * target_dir
	
	var total_force = spring_force + damping_force
	
	# 3. Opcional: Encurtar ou esticar a corda com o scroll do mouse (se tiver mapeado)
	if Input.is_action_just_pressed("mw_down"): 
		rest_length -= 1.0
	elif Input.is_action_just_pressed("mw_up"):
		rest_length += 1.0
		
	# 4. Impulso adicional (Thrust) ao segurar o pulo enquanto fisgado
	if Input.is_action_pressed("action_jump"):
		player.velocity += target_dir * thrust_mult * delta * 60.0
		
	player.velocity += total_force * delta
