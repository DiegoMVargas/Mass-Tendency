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


# ------------- FUNÇOES -----------------------
func _ready() -> void:
	# Garante que a gravidade correta é aplicada assim que a cena entra na árvore
	_gravity = grav_list[grav_index]

func _input(event: InputEvent) -> void:
	# mouse sendo capturado pela janela
	if event.is_action_pressed("mouse_esq"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# F e E, troca de gravidade
	if event.is_action_pressed("mais_peso") and grav_index > 0:
		grav_index -= 1
		_gravity = grav_list[grav_index]
	if event.is_action_pressed("menos_peso") and grav_index < grav_list.size() - 1:
		grav_index += 1
		_gravity = grav_list[grav_index]

func _unhandled_input(event: InputEvent) -> void:
	
	# ------------ input da camera ------
	var is_camera_motion := (
		event is InputEventMouseMotion and
		Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if is_camera_motion:
		_camera_input_direction = event.screen_relative * mouse_sense


func _physics_process(delta):
	# camera
	_camera_pivot.rotation.x -= _camera_input_direction.y * delta
	_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, min_vert_angle, max_vert_angle)
	_camera_pivot.rotation.y -= _camera_input_direction.x * delta
	_camera_input_direction = Vector2.ZERO
	

	# inputs para o movimento
	var input_dir := Input.get_vector("andar_esq", "andar_dir", "andar_frente", "andar_tras")
	var forward := _camera.global_basis.z
	var right := _camera.global_basis.x
	var move_direction := forward * input_dir.y + right * input_dir.x
	move_direction.y = 0.0
	move_direction = move_direction.normalized()
	
	# faz uma var separada pra que o codigo de movimento não afetar o axis Y
	var y_velocity := velocity.y
	#var x_velocity := velocity.x
	#var z_velocity := velocity.z
	velocity.y = 0.0
	# aqui é onde o movimento realmente acontece
	velocity = velocity.move_toward(move_direction * move_speed, acceleration * delta)
	# aplica a gravidade no axis y (o tempo todo! não é aplicado só quando tu sai do chão)
	
	velocity.y = y_velocity + _gravity * delta
	# estabelece a ação do pulo (pro isonfloor funcionar tu precisa de gravidade constante)
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
	
	
	
