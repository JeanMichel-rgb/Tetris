extends Node

var speed_boost : float = 5
var Score : int = 0
var SpawnPlace : Vector2 = Vector2(4, 2)
var current_piece : StaticBody2D
var NextPiece : StaticBody2D
var current_shape : Array
var NextShape : Array
var current_collision : Array
var NextCollision : Array
var GameSpeed : float = .5
const BlockScale : float = 40
var time : float = 0.0
var time2 : float = 0.0
var UpLeft_GameCorner : Vector2 = Vector2(7, 1)
var BoardWidth : int = 10
var BoardHeight : int = 20
var Game : bool = false
var Xdir : int
var Ydir : int
var rotate : int
var Board : StaticBody2D
var BoardGame : Array
var LineArray : Array
var current_position : Vector2i = Vector2i.ZERO

func _process(delta: float) -> void:
	time += delta
	time2 += delta
	if Game:
		GameSpeed = pow(clamp(Score/1000, 1, 5), -1)
		if Input.is_action_pressed("ui_accept") : GameSpeed /= speed_boost
		#Make a GameBoard Array
		BoardGame.clear()
		for x in BoardWidth+2 :
			for y in BoardHeight+1 :
				BoardGame.append(0)
		for line in BoardHeight+1:
			BoardGame[line*(BoardWidth+2)] = 1
		for line in BoardHeight+1:
			BoardGame[line*(BoardWidth+2)+BoardWidth+1] = 1
		for x in BoardWidth+2:
			BoardGame[BoardHeight*(BoardWidth+2)+x] = 1
		for line in LineArray:
			for child in line.get_children():
				BoardGame[line.name.to_int()*(BoardWidth+2)+(child.position.x-UpLeft_GameCorner.x*BlockScale)/BlockScale] = 1
		#current_piece_state
		var current_piece_state : Array = PiecePlace()
		#Game Logic
		Xdir = Input.get_axis("ui_left", "ui_right")
		rotate = Input.get_axis("ui_up", "ui_down")*90
		if current_piece.move_and_collide(Vector2(Xdir*BlockScale, 0), true) : Xdir = 0
		Ydir = 1-abs(Xdir)
		if time2 >= .1:
			time2 = 0.0
			current_piece.position.x += Xdir*BlockScale
			RotatePiece(rotate)
		$HUD/Score.text = "Score : " + str(Score)
	else :
		start_game()

func PiecePlace():
	var current_piece_state : Array
	var blocs_place : Array
	for bloc in 4:
		current_piece_state.append(current_piece.position/BlockScale-UpLeft_GameCorner+current_piece.get_child(bloc).position/BlockScale)
	for bloc in current_piece_state:
		var x = bloc.x
		var y = bloc.y
		blocs_place.append((y * (BoardWidth+2)) + (x+1))
	return [current_piece_state, blocs_place]

func RotatePiece(rotation):
	var pos = current_piece.position
	var ro = current_piece.rotation
	rotation = deg_to_rad(rotation)
	current_piece.rotate(rotation)
	if current_piece.move_and_collide(Vector2.ZERO, false) : current_piece.position = pos ; current_piece.rotation = ro ;
	elif rotation != 0 : Ydir = 0
	if time >= GameSpeed:
		time = 0.0
		MovePiece(Ydir*BlockScale)

func MovePiece(velocityY):
	var velocity = Vector2(0, 0)
	var is_colliding_Y = current_piece.move_and_collide(Vector2(0, velocityY), true)
	if is_colliding_Y :
		for child in current_piece.get_children():
			var child_position : Vector2i = Vector2i(round(child.global_position.x/float(BlockScale)), round(child.global_position.y/float(BlockScale)) - UpLeft_GameCorner.y)
			child.position.x = child_position.x * BlockScale
			child.position.y = 0
			child.rotation = 0
			child.reparent(get_node(str(child_position.y)), false)
		remove_child(current_piece)
		for line in BoardHeight :
			if is_line_full(line) : clear_line(line)
		spawn_piece(SpawnPlace*BlockScale)
	else :
		velocity.y = velocityY
		current_piece.position += velocity

func is_line_full(line):
	if get_node(str(line)).get_child_count() == BoardWidth*2 :
		return true
	return false

func clear_line(line):
	var lineID = get_node(str(line))
	for child in lineID.get_children():
		lineID.remove_child(child)
	Score += BoardWidth*10
	DownGrade_lines_over(line)

func DownGrade_lines_over(line):
	var lines : Array
	for linees in line :
		lines.append([])
		for child in get_node(str(linees)).get_children() :
			lines[linees].append(child)
	for linees in lines.size():
		for child in lines[linees]:
			child.reparent(get_node(str(linees+1)), false)

func start_game():
	Score = 0
	DestroyPreviousGame()
	MakeBoard()
	CreateNextPiece()
	spawn_piece(SpawnPlace*BlockScale)
	Game = true

func DestroyPreviousGame():
	while get_child(0) != get_child(-1):
		remove_child(get_child(-1))

func MakeBoard():
	$HUD.position = (UpLeft_GameCorner+Vector2(BoardWidth+2, 0))*BlockScale
	$HUD/NextPieceMenu/NextPieceBackGround.size = Vector2(8, 8)*BlockScale
	$HUD/NextPieceMenu/NextPieceBackGround.color = Color.BLACK
	var Static = StaticBody2D.new()
	Static.position = $HUD/NextPieceMenu.global_position+Vector2(BlockScale, BlockScale)/2
	add_child(Static)
	var block
	for x in 8:
		block = CreateBlock(Vector2(x, 0), Color.GRAY)
		Static.add_child(block[0])
	for x in 8:
		block = CreateBlock(Vector2(x, 7), Color.GRAY)
		Static.add_child(block[0])
	for y in 6:
		block = CreateBlock(Vector2(0, y+1), Color.GRAY)
		Static.add_child(block[0])
	for y in 6:
		block = CreateBlock(Vector2(7, y+1), Color.GRAY)
		Static.add_child(block[0])
	MakeBaseLines()
	var BlockPosition = UpLeft_GameCorner
	BlockPosition -= Vector2(1,1)
	Board = StaticBody2D.new()
	add_child(Board)
	for i in BoardHeight+1:
		BlockPosition.y += 1
		block = CreateBlock(BlockPosition, Color.BLACK)
		Board.add_child(block[0])
		Board.add_child(block[1])
	for i in BoardWidth+1:
		BlockPosition.x += 1
		block = CreateBlock(BlockPosition, Color.BLACK)
		Board.add_child(block[0])
		Board.add_child(block[1])
	for i in BoardHeight:
		BlockPosition.y -= 1
		block = CreateBlock(BlockPosition, Color.BLACK)
		Board.add_child(block[0])
		Board.add_child(block[1])

func MakeBaseLines():
	LineArray.clear()
	for line in BoardHeight :
		var BaseLine = StaticBody2D.new()
		LineArray.append(BaseLine)
		BaseLine.position = Vector2(0, (UpLeft_GameCorner.y + line) * BlockScale)
		BaseLine.name = str(line)
		add_child(BaseLine)

func CreateNextPiece():
	var pos = $HUD/NextPieceMenu.global_position+Vector2(7,7)*BlockScale/2
	NextPiece = generate_new_piece()
	generate_random_shape()
	NextPiece.position = pos
	add_child(NextPiece)
	for block in NextShape :
		NextPiece.add_child(block)
	for collision in NextCollision :
		NextPiece.add_child(collision)

func spawn_piece(pos : Vector2):
	current_piece = NextPiece
	current_shape = NextShape
	current_collision = NextCollision
	pos += UpLeft_GameCorner*BlockScale
	current_piece.position = pos
	if current_piece.move_and_collide(Vector2.ZERO) :
		Game = false
	CreateNextPiece()

func generate_new_piece() :
	return StaticBody2D.new()

func generate_random_shape():
	var shapes = [
		[[0, 0], [1, 0], [0, 1], [1, 1], Color.WHITE],  # O
		[[0, 0], [0, -1], [0, 1], [1, 1], Color.BLUE],  # L
		[[0, 0], [0, -1], [0, 1], [-1, 1], Color.GOLD], # J
		[[0, 0], [-1, 0], [1, 0], [0, 1], Color.DARK_RED],  # T
		[[0, 0], [1, 0], [0, -1], [-1, -1], Color.BLUE_VIOLET],  # S
		[[0, 0], [-1, 0], [0, -1], [1, -1], Color.HOT_PINK], # Z
		[[0, 0], [0, -1], [0, 1], [0, 2], Color.CYAN]   # I
	]
	
	var shape = shapes[randi() % shapes.size()]
	var color = shape[-1]
	NextShape.clear()
	NextCollision.clear()
	for BlockPosition in shape :
		if BlockPosition is Array:
			var block = CreateBlock(Vector2(BlockPosition[0], BlockPosition[1]), color)
			NextShape.append(block[0])
			NextCollision.append(block[1])

func CreateBlock(BlockPosition : Vector2, color : Color):
	var block = MeshInstance2D.new()
	var mesh = QuadMesh.new()
	var CollisionShape = CollisionShape2D.new()
	var Collision = RectangleShape2D.new()
	mesh.size = Vector2(BlockScale, BlockScale)
	Collision.size = Vector2(BlockScale-5, BlockScale-5)
	block.mesh = mesh
	CollisionShape.shape = Collision
	block.position = BlockPosition*BlockScale
	CollisionShape.position = block.position
	block.modulate = color
	return [block, CollisionShape]
