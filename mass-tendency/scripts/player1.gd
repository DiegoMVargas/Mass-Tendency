extends CharacterBody3D

# -------------	 SETUP CAMERA
@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sense := 0.25
@export_range(-90.0, 0.0, 0.1, "radians_as_degrees") var min_vert_angle := -PI/2
@export_range(0.0, 90.0, 0.1, "radians_as_degrees") var max_vert_angle := PI/4
var _camera_input_direction := Vector2.ZERO
@onready var _camera_pivot: Node3D = %CameraPivot
@onready var _camera: Camera3D = %Camera3D

# ------------	SETUP MOVIMENTO
@export_group("Movimento")
@export var move_speed := 5.0
@export var jump_impulse := 10.0
@export var acceleration := 15.0
var grav_list := [-45.0, -30.0, -15.0]
var grav_index := 1
var _gravity := 0.0
var _last_movement_direction := Vector3.BACK
@onready var _skin: MeshInstance3D = %HookSkin
@export var rotation_speed := 12.0

# ------------ SETUP GANCHO ZELDA (HOOKSHOT RETO)
@export_group("Gancho Zelda")
@export var ray: RayCast3D
@export var max_hook_range := 25.0  # Alcance máximo do gancho
@export var pull_speed := 30.0    # Velocidade com que o player é puxado até o alvo

var is_pulling := false
var hook_target_pos := Vector3.ZERO


# ------------- FUNÇOES -----------------------
func _ready() -> void:
	_gravity = grav_list[grav_index]

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("mouse_esq"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
	# Troca de gravidade (E e F)
	if event.is_action_pressed("mais_peso") and grav_index > 0:
		grav_index -= 1
		_gravity = grav_list[grav_index]
	if event.is_action_pressed("menos_peso") and grav_index < grav_list.size() - 1:
		grav_index += 1
		_gravity = grav_list[grav_index]

	# Botão de atirar o gancho
	if event.is_action_pressed("atirar"):
		if not is_pulling:
			try_start_hookshot()
		else:
			stop_hookshot()

func _unhandled_input(event: InputEvent) -> void:
	var is_camera_motion := (
		event is InputEventMouseMotion and
		Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if is_camera_motion:
		_camera_input_direction = event.screen_relative * mouse_sense


func _physics_process(delta):
	# Camera
	_camera_pivot.rotation.x -= _camera_input_direction.y * delta
	_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, min_vert_angle, max_vert_angle)
	_camera_pivot.rotation.y -= _camera_input_direction.x * delta
	_camera_input_direction = Vector2.ZERO
	

	# --- SE ESTIVER SENDO PUXADO (ESTILO ZELDA) ---
	if is_pulling:
		# Desliga a gravidade enquanto é puxado em linha reta
		velocity = Vector3.ZERO
		
		# Move o player em linha reta na direção do ponto de impacto
		var direction = global_position.direction_to(hook_target_pos)
		var distance = global_position.distance_to(hook_target_pos)
		
		if distance > 1.0:
			# Puxa o player em direção ao alvo
			global_position += direction * pull_speed * delta
		else:
			# Chegou próximo ao alvo, solta o gancho e dá um pequeno impulso para cima
			stop_hookshot()
			velocity.y = jump_impulse * 0.7
			
		# Se o jogador apertar pulo durante o puxão, cancela o gancho e pula
		if Input.is_action_just_pressed("pulo"):
			stop_hookshot()
			velocity.y = jump_impulse
			
		return # Ignora o movimento normal enquanto o hookshot estiver ativo


	# --- MOVIMENTO NORMAL ---
	var input_dir := Input.get_vector("andar_esq", "andar_dir", "andar_frente", "andar_tras")
	var forward := _camera.global_basis.z
	var right := _camera.global_basis.x
	var move_direction := forward * input_dir.y + right * input_dir.x
	move_direction.y = 0.0
	move_direction = move_direction.normalized()
	
	var y_velocity := velocity.y
	velocity.y = 0.0
	velocity = velocity.move_toward(move_direction * move_speed, acceleration * delta)
	
	velocity.y = y_velocity + _gravity * delta
	
	var jump_start := Input.is_action_just_pressed("pulo") and is_on_floor()
	if jump_start:
		velocity.y += jump_impulse
		move_speed = 2.0
	
	if is_on_floor():
		move_speed = 5.0

	move_and_slide()
	
	if move_direction.length() > 0.2:
		_last_movement_direction = move_direction
	var target_angle := Vector3.BACK.signed_angle_to(_last_movement_direction, Vector3.UP)
	_skin.global_rotation.y = lerp_angle(_skin.rotation.y, target_angle, rotation_speed * delta)

# --- FUNÇÕES DO HOOKSHOT (ZELDA) ---
func try_start_hookshot() -> void:
	if ray and ray.is_colliding():
		var hit_point = ray.get_collision_point()
		var distance = global_position.distance_to(hit_point)
		
		if distance <= max_hook_range:
			hook_target_pos = hit_point
			is_pulling = true

func stop_hookshot() -> void:
	is_pulling = false
