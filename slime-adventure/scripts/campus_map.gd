@tool
extends Node2D

@export_enum(
	"校园 G0",
	"教学楼前平台",
	"教学楼 F2",
	"教学楼 F3",
	"二层第一教室",
	"食堂内部",
	"白房内部",
	"男生宿舍内部",
	"男生宿舍 F2",
	"男生宿舍 F3",
	"宿舍尽头房间一",
	"宿舍尽头房间二"
)
var place: String = "校园 G0":
	set(value):
		place = value
		if is_node_ready():
			configure(place)

var map_size := Vector2(3072, 2240)
var points: Array[Dictionary] = []
var auto_transitions: Array[Dictionary] = []

var school := Rect2(160, 450, 1280, 700)
var platform := Rect2(160, 1150, 1280, 280)
var dorm := Rect2(1861, 670, 650, 450)
var white_house := Rect2(1490, 590, 160, 260)
var canteen := Rect2(1440, 1440, 1472, 650)
var playground := Rect2(1630, 80, 700, 470)
var noticeboard := Rect2(600, 1380, 400, 32)

@onready var walls: Node2D = $Walls


func _ready() -> void:
	configure(place)


func configure(next_place: String) -> void:
	if place != next_place:
		place = next_place
		return

	points.clear()
	auto_transitions.clear()

	for child in walls.get_children():
		child.free()

	var outside: bool = (
		place == "校园 G0"
		or place == "教学楼前平台"
	)

	if outside:
		map_size = Vector2(3072, 2240)

		_school_collision()
		_campus_barriers()
		_block(dorm)
		_block(white_house)
		_block(canteen)
		_block(noticeboard)

		if place == "校园 G0":
			_block(platform)
			_stair_rails()

			_point(Vector2(420, 1460), "左梯上到平台", "left_up", 32.0)
			_point(Vector2(1180, 1460), "右梯上到平台", "right_up", 32.0)
			_point(Vector2(1465, 1290), "侧楼梯上到平台", "side_up", 32.0)
			_point(Vector2(1690, 750), "进入白房", "white_house_enter", 45.0)
			_point(Vector2(1821, 1080), "女生宿舍入口", "dorm_female", 45.0)
			_point(Vector2(2551, 1080), "进入男生宿舍", "dorm_male_enter", 45.0)
			_point(Vector2(1400, 1780), "从左门进入食堂", "canteen_from_left", 55.0)
			_point(Vector2(1800, 1400), "从上门进入食堂", "canteen_from_upper", 55.0)

		else:
			_block(Rect2(0, 0, 160, 2240))
			_block(Rect2(1440, 0, 1632, 2240))
			_block(Rect2(160, 0, 920, 1150))
			_block(Rect2(1160, 0, 280, 1150))
			_block(Rect2(1080, 0, 80, 1068))
			_block(Rect2(160, 1430, 1280, 810))

			_point(Vector2(420, 1400), "左梯下到 G0", "left_down", 48.0)
			_point(Vector2(1180, 1400), "右梯下到 G0", "right_down", 48.0)
			_point(Vector2(1400, 1290), "侧楼梯下到右侧 G0", "side_down", 48.0)

			_classroom_points(1, 1180.0)
			_point(Vector2(800, 1335), "查看布告板", "noticeboard", 45.0)
			points[-1]["interaction_rect"] = Rect2(600, 1300, 400, 65)

			_point(
				Vector2(1120, 1090),
				"沿楼内楼梯上二层",
				"upstairs",
				20.0
			)

	elif place == "教学楼 F2" or place == "教学楼 F3":
		map_size = Vector2(1600, 820)

		var floor_number: int = 2 if place == "教学楼 F2" else 3
		var top: float = 100.0 + (3 - floor_number) * 180.0
		var walk_top: float = top + 104.0
		var rail_top: float = top + 164.0

		_block(Rect2(0, 0, 1080, walk_top))
		_block(Rect2(1160, 0, 440, walk_top))
		_block(Rect2(1080, 0, 80, top + 16))
		_block(Rect2(0, rail_top, 1600, 820 - rail_top))
		_block(Rect2(0, walk_top, 80, rail_top - walk_top))
		_block(Rect2(1520, walk_top, 80, rail_top - walk_top))

		if floor_number == 2:
			_point(Vector2(1120, top + 36), "上三层", "up_to_f3", 20.0)
			_point(Vector2(1120, top + 136), "下到一层平台", "downstairs", 24.0)
		else:
			_point(Vector2(1120, top + 36), "返回二层", "down_to_f2", 20.0)

		_classroom_points(floor_number, top + 130.0)

	elif place in ["男生宿舍内部", "男生宿舍 F2", "男生宿舍 F3"]:
		_configure_dorm_floor()

	elif place in ["宿舍尽头房间一", "宿舍尽头房间二"]:
		_configure_six_bed_room()

	elif place == "白房内部":
		map_size = Vector2(900, 700)
		_block(Rect2(0, 0, 900, 60))
		_block(Rect2(0, 640, 900, 60))
		_block(Rect2(0, 60, 60, 580))
		_block(Rect2(840, 60, 60, 580))
		_point(Vector2(800, 350), "离开白房", "white_house_exit", 45.0)
	elif place == "食堂内部":
		map_size = Vector2(1912, 900)

		_block(Rect2(0, 0, 1912, 80))
		_block(Rect2(0, 820, 1912, 80))
		_block(Rect2(0, 80, 80, 740))
		_block(Rect2(1832, 80, 80, 740))

		_point(Vector2(110, 500), "左门：返回校门广场", "canteen_exit_left", 45.0)
		_point(Vector2(700, 110), "上门：前往右上广场", "canteen_exit_upper", 45.0)

	else:
		# cb 教室：五排，每排四组课桌。
		map_size = Vector2(1280, 1320)

		_block(Rect2(0, 0, 1280, 80))
		_block(Rect2(0, 1240, 1280, 80))
		_block(Rect2(0, 80, 80, 1160))
		_block(Rect2(1200, 80, 80, 1160))

		for row in range(5):
			for column in range(4):
				_block(Rect2(
					260 + column * 200,
					340 + row * 170,
					100,
					55
				))

		_point(
			Vector2(1160, 280),
			"右侧前门：返回走廊",
			"exit_classroom_front",
			42.0
		)

		_point(
			Vector2(1160, 1100),
			"右侧后门：返回走廊",
			"exit_classroom_back",
			42.0
		)

	_block(Rect2(-32, -32, map_size.x + 64, 32))
	_block(Rect2(-32, map_size.y, map_size.x + 64, 32))
	_block(Rect2(-32, 0, 32, map_size.y))
	_block(Rect2(map_size.x, 0, 32, map_size.y))

	queue_redraw()


func _classroom_points(floor_number: int, y: float) -> void:
	# 从楼梯附近开始，由右往左数。
	# 第1门：独立房间。
	# 第2、3门：同一间房的前门、后门。
	# 第4、5门：另一间房的前门、后门。
	var positions: Array[int] = [990, 780, 630, 450, 240]
	var rooms: Array[int] = [1, 2, 2, 3, 3]

	for index in range(5):
		var title: String = "%d层 · 第%d间房" % [
			floor_number,
			rooms[index]
		]
		var action: String = "room_closed"

		if floor_number == 2 and index == 1:
			title = "cb 教室 · 前门"
			action = "classroom_front"

		elif floor_number == 2 and index == 2:
			title = "cb 教室 · 后门"
			action = "classroom_back"

		elif index > 0:
			title += " · " + (
				"前门" if index % 2 == 1 else "后门"
			)

		_point(Vector2(positions[index], y), title, action, 42.0)


func _point(
	pos: Vector2,
	title: String,
	action: String,
	radius: float = 80.0
) -> void:
	points.append({
		"pos": pos,
		"title": title,
		"action": action,
		"radius": radius
	})


func _block(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.get_center()

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()

	shape.size = rect.size
	collision.shape = shape

	body.add_child(collision)
	walls.add_child(body)


func _school_collision() -> void:
	_block(Rect2(160, 450, 1280, 618))
	_block(Rect2(160, 1068, 920, 82))
	_block(Rect2(1160, 1068, 280, 82))


func _campus_barriers() -> void:
	_block(Rect2(2912, 0, 160, 2240))
	_block(Rect2(0, 2090, 3072, 150))
	_block(Rect2(1440, 0, 20, 1150))


func _stair_rails() -> void:
	_block(Rect2(350, 1430, 20, 310))
	_block(Rect2(470, 1430, 20, 190))
	_block(Rect2(470, 1600, 260, 20))
	_block(Rect2(350, 1720, 380, 20))

	_block(Rect2(1230, 1430, 20, 310))
	_block(Rect2(1110, 1430, 20, 190))
	_block(Rect2(870, 1600, 260, 20))
	_block(Rect2(870, 1720, 380, 20))

	_block(Rect2(1440, 1130, 200, 20))
	_block(Rect2(1440, 1430, 200, 20))


func _text(pos: Vector2, value: String, size: int = 22) -> void:
	draw_string(
		ThemeDB.fallback_font,
		pos,
		value,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		size,
		Color.WHITE
	)


func _building(rect: Rect2, title: String, floors: int) -> void:
	draw_rect(rect, Color("#747e8c"))
	draw_rect(
		Rect2(rect.position, Vector2(rect.size.x, 50)),
		Color("#465468")
	)

	var band_height: float = (rect.size.y - 70.0) / floors

	for floor_index in range(floors):
		var y: float = rect.position.y + 65 + floor_index * band_height

		var window_count: int = int(rect.size.x / 100.0) - 1
		if rect == dorm:
			window_count = int((rect.size.x - 82.0) / 100.0) + 1
		for column in range(window_count):
			draw_rect(
				Rect2(rect.position.x + 30 + column * 100, y, 52, 38),
				Color("#b5dae5")
			)

		draw_line(
			Vector2(rect.position.x, y + band_height - 12),
			Vector2(rect.end.x, y + band_height - 12),
			Color("#d1d5d9"),
			5
		)

	_text(rect.position + Vector2(24, 35), title, 26)


func _stairs(rect: Rect2, horizontal: bool = false) -> void:
	draw_rect(rect, Color("#b8afa0"))

	for index in range(1, 10):
		var ratio: float = index / 10.0

		if horizontal:
			var x: float = rect.position.x + rect.size.x * ratio
			draw_line(
				Vector2(x, rect.position.y),
				Vector2(x, rect.end.y),
				Color("#655f59"),
				3
			)
		else:
			var y: float = rect.position.y + rect.size.y * ratio
			draw_line(
				Vector2(rect.position.x, y),
				Vector2(rect.end.x, y),
				Color("#655f59"),
				3
			)


func _draw_l_stairs() -> void:
	_stairs(Rect2(470, 1620, 260, 100), true)
	draw_rect(Rect2(370, 1620, 100, 100), Color("#b8afa0"))
	_stairs(Rect2(370, 1430, 100, 190))

	_stairs(Rect2(870, 1620, 260, 100), true)
	draw_rect(Rect2(1130, 1620, 100, 100), Color("#b8afa0"))
	_stairs(Rect2(1130, 1430, 100, 190))

	var rails: Array[Rect2] = [
		Rect2(350, 1430, 20, 310),
		Rect2(470, 1430, 20, 190),
		Rect2(470, 1600, 260, 20),
		Rect2(350, 1720, 380, 20),
		Rect2(1230, 1430, 20, 310),
		Rect2(1110, 1430, 20, 190),
		Rect2(870, 1600, 260, 20),
		Rect2(870, 1720, 380, 20)
	]

	for rail in rails:
		draw_rect(rail, Color("#626974"))

	_text(Vector2(530, 1780), "左梯入口", 20)
	_text(Vector2(930, 1780), "右梯入口", 20)


func _draw() -> void:
	if place == "校园 G0" or place == "教学楼前平台":
		_draw_campus()
	elif place == "教学楼 F2" or place == "教学楼 F3":
		_draw_corridor()
	elif place in ["男生宿舍内部", "男生宿舍 F2", "男生宿舍 F3"]:
		_draw_dorm_interior()
	elif place in ["宿舍尽头房间一", "宿舍尽头房间二"]:
		_draw_dorm_room()
	elif place == "白房内部":
		_draw_white_house_interior()
	elif place == "食堂内部":
		_draw_canteen_interior()
	else:
		_draw_classroom()

	for point in points:
		var pos: Vector2 = point["pos"]
		draw_arc(pos, 23, 0, TAU, 32, Color.GOLD, 3)


func _draw_campus() -> void:
	draw_rect(Rect2(Vector2.ZERO, map_size), Color("#557b50"))
	draw_rect(Rect2(240, 1440, 1240, 650), Color("#b3b1a4"))
	draw_rect(Rect2(1460, 570, 1452, 1520), Color("#b3b1a4"))

	_text(Vector2(650, 1870), "校门内广场 G0", 28)
	_text(Vector2(2350, 1320), "右侧广场 G0", 28)

	draw_rect(Rect2(160, 1430, 1280, 22), Color("#575a60"))
	draw_rect(platform, Color("#c6c1b4"))

	for x in range(160, 1441, 80):
		draw_line(
			Vector2(x, 1150), Vector2(x, 1430),
			Color("#aaa699"), 1
		)

	for y in range(1150, 1431, 70):
		draw_line(
			Vector2(160, y), Vector2(1440, y),
			Color("#aaa699"), 1
		)

	_text(Vector2(650, 1300), "教学楼一层开放平台", 28)

	draw_line(Vector2(160, 1430), Vector2(370, 1430), Color("#414a55"), 7)
	draw_line(Vector2(470, 1430), Vector2(1130, 1430), Color("#414a55"), 7)
	draw_line(Vector2(1230, 1430), Vector2(1440, 1430), Color("#414a55"), 7)

	_building(school, "教学楼：开放式外走廊 · 五层", 5)
	_building(dorm, "宿舍：五层", 5)

	_draw_white_house()
	_building(canteen, "食堂：两侧广场的通道", 1)

	draw_rect(Rect2(1440, 1730, 20, 100), Color("#584736"))
	draw_rect(Rect2(1443, 1734, 14, 92), Color("#b8d3d7"))
	draw_rect(Rect2(1760, 1440, 80, 24), Color("#584736"))
	draw_rect(Rect2(1765, 1443, 70, 18), Color("#b8d3d7"))

	_text(Vector2(1470, 1800), "左门", 20)
	_text(Vector2(1855, 1485), "上门", 20)

	draw_rect(Rect2(1440, 0, 20, 1150), Color("#50595b"))
	draw_line(Vector2(2912, 0), Vector2(2912, 2090), Color("#50595b"), 10)
	draw_line(Vector2(0, 0), Vector2(2912, 0), Color("#50595b"), 10)
	draw_line(Vector2(0, 0), Vector2(0, 2090), Color("#50595b"), 10)
	draw_line(Vector2(0, 2090), Vector2(570, 2090), Color("#50595b"), 10)
	draw_line(Vector2(1030, 2090), Vector2(2912, 2090), Color("#50595b"), 10)

	for door_x in [240, 450, 630, 780, 990]:
		draw_rect(Rect2(door_x - 33, 1052, 66, 98), Color("#444b55"))
		draw_rect(Rect2(door_x - 27, 1058, 54, 92), Color("#946741"))
		draw_rect(Rect2(door_x - 21, 1064, 42, 27), Color("#b4d1d8"))
		draw_circle(Vector2(door_x + 17, 1110), 3, Color("#e4d093"))

	draw_rect(Rect2(1076, 1062, 88, 114), Color("#444c4d"))
	draw_rect(Rect2(1080, 1068, 80, 108), Color("#687171"))
	_stairs(Rect2(1082, 1070, 76, 80))
	draw_rect(Rect2(1076, 1062, 6, 114), Color("#a7aba4"))
	draw_rect(Rect2(1158, 1062, 6, 114), Color("#909991"))
	_text(Vector2(1065, 1205), "上二层", 20)

	_draw_noticeboard()
	_draw_l_stairs()

	_stairs(Rect2(1440, 1150, 200, 280), true)
	draw_rect(Rect2(1440, 1130, 200, 20), Color("#626974"))
	draw_rect(Rect2(1440, 1430, 200, 20), Color("#626974"))
	_text(Vector2(1465, 1110), "平台 ↔ G0", 20)

	draw_rect(Rect2(20, 850, 120, 500), Color("#42664a"))
	_text(Vector2(25, 830), "休息区", 22)

	for y in [930, 1080, 1230]:
		draw_rect(Rect2(40, y, 75, 20), Color("#986845"))

	draw_rect(playground, Color("#bc6857"))

	var inner := playground.grow(-60)
	draw_rect(inner, Color("#638a59"))
	draw_rect(inner, Color.WHITE, false, 3)

	draw_line(
		Vector2(inner.get_center().x, inner.position.y),
		Vector2(inner.get_center().x, inner.end.y),
		Color.WHITE,
		3
	)

	draw_arc(inner.get_center(), 65, 0, TAU, 48, Color.WHITE, 3)
	_text(Vector2(1810, 300), "操场", 26)

	draw_rect(Rect2(570, 2090, 460, 35), Color("#48515f"))
	draw_rect(Rect2(570, 2060, 40, 100), Color("#767f8b"))
	draw_rect(Rect2(990, 2060, 40, 100), Color("#767f8b"))
	_text(Vector2(725, 2120), "校门", 28)


func _draw_corridor() -> void:
	draw_rect(Rect2(Vector2.ZERO, map_size), Color("#30343a"))
	draw_rect(Rect2(54, 96, 1492, 560), Color("#24272c"))
	draw_rect(Rect2(80, 564, 1440, 256), Color("#aaa9a0"))

	for y in range(590, 821, 38):
		draw_line(
			Vector2(80, y), Vector2(1520, y),
			Color("#a2a197"), 1
		)

	for x in range(80, 1521, 120):
		draw_line(
			Vector2(x, 564), Vector2(x, 820),
			Color("#a2a197"), 1
		)

	for floor_number in range(3, 0, -1):
		var top: float = 100.0 + (3 - floor_number) * 180.0
		_facade_floor(top, floor_number)

	draw_rect(Rect2(68, 88, 1464, 12), Color("#596066"))
	draw_rect(Rect2(68, 100, 12, 464), Color("#bbbcb4"))
	draw_rect(Rect2(1520, 100, 12, 464), Color("#9c9f99"))

	draw_line(
		Vector2(68, 100), Vector2(1532, 100),
		Color("#e6e3da"), 2
	)

	_text(Vector2(100, 790), "教学楼前广场", 20)


func _facade_floor(top: float, floor_number: int) -> void:
	var current_floor: int = 3 if place == "教学楼 F3" else 2
	var wall_color := Color("#c8c7bd")
	var floor_color := Color("#939690")

	if floor_number == current_floor:
		wall_color = Color("#d3d1c5")
		floor_color = Color("#aaa9a0")

	if floor_number == 1:
		floor_color = Color("#aaa9a0")

	draw_rect(Rect2(80, top, 1440, 104), wall_color)
	draw_rect(Rect2(80, top, 1440, 7), Color("#676d70"))
	draw_rect(Rect2(80, top + 7, 1440, 4), Color("#e2e1d8"))
	draw_rect(Rect2(80, top + 98, 1440, 6), Color("#5b615e"))

	for y_offset in [38, 70]:
		draw_line(
			Vector2(82, top + y_offset),
			Vector2(1518, top + y_offset),
			Color("#babbb2"),
			1
		)

	draw_rect(Rect2(1498, top + 11, 5, 93), Color("#969e9c"))

	var door_positions: Array[int] = [990, 780, 630, 450, 240]

	for door_x in door_positions:
		draw_rect(Rect2(door_x - 30, top + 22, 60, 82), Color("#5e5145"))
		draw_rect(Rect2(door_x - 26, top + 26, 52, 78), Color("#dddcd1"))
		draw_rect(Rect2(door_x - 22, top + 30, 44, 28), Color("#aac7cc"))
		draw_rect(Rect2(door_x - 26, top + 94, 52, 10), Color("#6c989e"))
		draw_circle(Vector2(door_x + 18, top + 76), 2, Color("#4b4b47"))

	for window_x in [330, 1210]:
		draw_rect(Rect2(window_x, top + 35, 46, 43), Color("#7a8a90"))
		draw_rect(Rect2(window_x + 3, top + 38, 40, 37), Color("#b9dce5"))
		draw_line(
			Vector2(window_x + 23, top + 38),
			Vector2(window_x + 23, top + 75),
			Color("#ecebe2"),
			2
		)

	draw_rect(Rect2(80, top + 104, 1440, 76), floor_color)
	draw_line(
		Vector2(80, top + 105), Vector2(1520, top + 105),
		Color("#737973"), 2
	)

	draw_rect(Rect2(1076, top + 10, 88, 122), Color("#444c4d"))
	draw_rect(Rect2(1080, top + 14, 80, 116), Color("#687171"))
	_stairs(Rect2(1082, top + 20, 76, 84))
	draw_rect(Rect2(1076, top + 10, 6, 122), Color("#a7aba4"))
	draw_rect(Rect2(1158, top + 10, 6, 122), Color("#909991"))

	if floor_number > 1:
		draw_rect(Rect2(80, top + 164, 1440, 16), Color("#bdb8a5"))
		draw_rect(Rect2(80, top + 164, 1440, 3), Color("#e5e0ce"))
		draw_rect(Rect2(80, top + 177, 1440, 3), Color("#636967"))

		for seam_x in range(100, 1520, 52):
			draw_line(
				Vector2(seam_x, top + 168),
				Vector2(seam_x, top + 176),
				Color("#a49f91"),
				1
			)

		draw_line(
			Vector2(80, top + 156),
			Vector2(1520, top + 156),
			Color("#343d40"),
			2
		)

		for post_x in range(88, 1520, 22):
			draw_line(
				Vector2(post_x, top + 156),
				Vector2(post_x, top + 164),
				Color("#434d4f"),
				1
			)

	_text(Vector2(100, top + 75), "%dF" % floor_number, 18)

	if floor_number == 2:
		draw_rect(Rect2(660, top + 3, 100, 18), Color("#566763"))
		_text(Vector2(675, top + 17), "cb 教室", 15)


func _draw_classroom() -> void:
	draw_rect(Rect2(Vector2.ZERO, map_size), Color("#d2c5a7"))
	draw_rect(Rect2(0, 0, 1280, 80), Color("#7e776d"))

	draw_rect(Rect2(390, 90, 500, 60), Color("#245347"))
	_text(Vector2(450, 130), "二层 · cb 所在教室", 28)
	draw_rect(Rect2(540, 170, 200, 35), Color("#906341"))

	for row in range(5):
		for column in range(4):
			var x: float = 260 + column * 200
			var y: float = 340 + row * 170

			draw_rect(Rect2(x, y, 100, 55), Color("#a77848"))
			draw_rect(Rect2(x + 25, y + 65, 50, 25), Color("#805c3b"))

	for y in [200, 400, 600, 800, 1000]:
		draw_rect(Rect2(90, y, 22, 100), Color("#a8d7e8"))

	# 黑板在上方；右墙上端是前门，下端是后门。
	draw_rect(Rect2(1186, 230, 32, 100), Color("#785139"))
	draw_rect(Rect2(1186, 1050, 32, 100), Color("#785139"))

	_text(Vector2(1035, 265), "前门 →", 20)
	_text(Vector2(1035, 1085), "后门 →", 20)


func _draw_canteen_interior() -> void:
	draw_rect(Rect2(Vector2.ZERO, map_size), Color("#64665f"))
	draw_rect(Rect2(80, 80, 1752, 740), Color("#c5c0b0"))
	draw_rect(Rect2(80, 80, 1752, 740), Color("#e5dfd0"), false, 4)

	draw_rect(Rect2(65, 455, 30, 90), Color("#72533d"))
	draw_rect(Rect2(665, 65, 70, 30), Color("#72533d"))

	_text(Vector2(145, 510), "左门 · 校门广场", 20)
	_text(Vector2(760, 120), "上门 · 右上广场", 20)

func _draw_white_house() -> void:
	draw_rect(white_house, Color("#727c7b"), false, 6)
	draw_rect(white_house, Color("#f0efea"))
	draw_rect(Rect2(1490, 590, 160, 26), Color("#d7dddc"))
	draw_rect(Rect2(1624, 720, 26, 60), Color("#65716c"))
	draw_rect(Rect2(1630, 726, 20, 48), Color("#a4bebc"))
	_text(Vector2(1510, 655), "白房", 22)


func _draw_white_house_interior() -> void:
	draw_rect(Rect2(Vector2.ZERO, map_size), Color("#e8e6df"))
	draw_rect(Rect2(60, 60, 780, 580), Color("#c9c5b8"))
	draw_rect(Rect2(60, 60, 780, 580), Color("#faf9f4"), false, 4)
	draw_rect(Rect2(840, 315, 18, 70), Color("#65716c"))
	_text(Vector2(755, 300), "出口 →", 20)
func _dorm_floor_number() -> int:
	if place == "男生宿舍 F3":
		return 3
	if place == "男生宿舍 F2":
		return 2
	return 1


func _configure_dorm_floor() -> void:
	map_size = Vector2(4800, 760)
	var floor_number: int = _dorm_floor_number()
	_block(Rect2(0, 0, 4800, 80))
	_block(Rect2(0, 700, 4800, 60))
	_block(Rect2(0, 80, 80, 620))
	_block(Rect2(4740, 80, 60, 620))
	if floor_number < 3:
		# 一、二楼只开放最右端的楼梯间。
		_block(Rect2(80, 80, 4300, 620))
	else:
		# 三楼长走廊，房间排列在下侧。
		_block(Rect2(80, 80, 4300, 180))
		_block(Rect2(80, 480, 4300, 220))
		for index in range(12):
			var door_x: float = 260.0 + index * 340.0
			var action: String = "dorm_room_closed"
			var title: String = "别人的宿舍"
			if index == 0:
				action = "dorm_room_one"
				title = "进入走廊尽头房间一"
			elif index == 1:
				action = "dorm_room_two"
				title = "进入走廊尽头房间二"
			_point(Vector2(door_x, 440), title, action, 45.0)

	if floor_number < 3:
		_block(Rect2(4480, 80, 20, 280))
		_block(Rect2(4600, 80, 20, 280))
		auto_transitions.append({"rect": Rect2(4500, 120, 100, 80), "step": 1})
	if floor_number > 1:
		_block(Rect2(4620, 80, 20, 280))
		auto_transitions.append({"rect": Rect2(4640, 120, 100, 80), "step": -1})
	if floor_number == 1:
		_point(Vector2(4690, 640), "离开宿舍，返回广场", "dorm_male_exit", 45.0)


func _draw_dorm_interior() -> void:
	var floor_number: int = _dorm_floor_number()
	draw_rect(Rect2(Vector2.ZERO, map_size), Color("#777c79"))
	if floor_number == 3:
		draw_rect(Rect2(80, 260, 4300, 220), Color("#c6c2b6"))
		for tile_x in range(80, 4380, 100):
			draw_line(Vector2(tile_x, 260), Vector2(tile_x, 480), Color("#b3afa3"), 1)
		draw_line(Vector2(80, 370), Vector2(4380, 370), Color("#b3afa3"), 1)
		draw_rect(Rect2(80, 480, 4300, 220), Color("#e0ddd1"))
		for index in range(12):
			var door_x: float = 260.0 + index * 340.0
			draw_rect(Rect2(door_x - 42, 480, 84, 14), Color("#4d5956"))
			_text(Vector2(door_x - 20, 530), str(301 + index), 20)
		_text(Vector2(120, 235), "男生宿舍三楼 · 长走廊", 26)
	else:
		_text(Vector2(4400, 470), "男生宿舍 %d 楼" % floor_number, 24)
		_text(Vector2(4400, 510), "走上楼梯自动换层", 20)
		draw_rect(Rect2(80, 80, 4300, 620), Color("#606663"))

	draw_rect(Rect2(4380, 80, 360, 620), Color("#c6c2b6"))
	_text(Vector2(4400, 510), "走上楼梯自动换层", 20)
	_text(Vector2(4400, 460), "%d 楼楼梯间" % floor_number, 24)
	if floor_number < 3:
		_stairs(Rect2(4500, 120, 100, 240))
		_text(Vector2(4490, 105), "上楼", 20)
		draw_rect(Rect2(4480, 80, 20, 280), Color("#626c68"))
		draw_rect(Rect2(4600, 80, 20, 280), Color("#626c68"))
	if floor_number > 1:
		_stairs(Rect2(4640, 120, 100, 240))
		_text(Vector2(4640, 105), "下楼", 20)
		draw_rect(Rect2(4620, 80, 20, 280), Color("#626c68"))


func _dorm_beds() -> Array[Rect2]:
	return [Rect2(140, 150, 180, 360), Rect2(140, 650, 180, 360), Rect2(780, 650, 180, 360)]


func _dorm_partitions() -> Array[Rect2]:
	return [
		# 两段横墙，中间保留 320 像素通道。
		Rect2(80, 1120, 310, 20), Rect2(710, 1120, 310, 20),
		# 洗澡间和厕所均向左开口，无门。
		Rect2(690, 1200, 330, 16), Rect2(1004, 1200, 16, 230), Rect2(690, 1414, 330, 16),
		Rect2(690, 1480, 330, 16), Rect2(1004, 1480, 16, 230), Rect2(690, 1694, 330, 16)
	]


func _configure_six_bed_room() -> void:
	map_size = Vector2(1100, 1800)
	_block(Rect2(0, 0, 1100, 80))
	_block(Rect2(0, 1720, 1100, 80))
	_block(Rect2(0, 80, 80, 1640))
	_block(Rect2(1020, 80, 80, 1640))
	for bed in _dorm_beds():
		_block(bed)
	for wall in _dorm_partitions():
		_block(wall)
	_block(Rect2(140, 1240, 180, 400))
	_block(Rect2(830, 1550, 80, 90))
	if place == "宿舍尽头房间一":
		_block(Rect2(744, 174, 32, 32))
	var exit_action: String = "dorm_room_one_exit" if place == "宿舍尽头房间一" else "dorm_room_two_exit"
	_point(Vector2(550, 120), "返回三楼走廊", exit_action, 45.0)


func _draw_bunk_bed(rect: Rect2, number: int) -> void:
	draw_rect(rect, Color("#465d68"))
	draw_rect(rect.grow(-8), Color("#d8d5c4"))
	# 两层床面和侧梯，用同一组上下铺表示两个床位。
	for bunk in range(2):
		var top: float = rect.position.y + 14 + bunk * 174
		draw_rect(Rect2(rect.position.x + 16, top, rect.size.x - 32, 150), Color("#a4c2c9"))
		draw_rect(Rect2(rect.position.x + 28, top + 10, rect.size.x - 56, 32), Color("#eeeee4"))
		draw_rect(Rect2(rect.position.x + 18, top + 65, rect.size.x - 36, 83), Color("#688f9d"))
		draw_line(Vector2(rect.position.x + 10, top + 155), Vector2(rect.end.x - 10, top + 155), Color("#344851"), 6)
	for rung in range(7):
		var y: float = rect.position.y + 45 + rung * 42
		draw_line(Vector2(rect.end.x - 28, y), Vector2(rect.end.x - 5, y), Color("#c1c6be"), 4)
	_text(rect.position + Vector2(22, -12), "%d号上下铺 · 2人" % number, 18)


func _draw_dorm_room() -> void:
	draw_rect(Rect2(Vector2.ZERO, map_size), Color("#e0ddd1"))
	draw_rect(Rect2(80, 80, 940, 1640), Color("#c6c2b6"))
	draw_rect(Rect2(80, 1140, 940, 580), Color("#bfc9c6"))
	for tile_y in range(1140, 1721, 80):
		draw_line(Vector2(80, tile_y), Vector2(1020, tile_y), Color("#a4b2af"), 1)
	for tile_x in range(80, 1021, 80):
		draw_line(Vector2(tile_x, 1140), Vector2(tile_x, 1720), Color("#a4b2af"), 1)
	# 顶部中央房门。
	draw_rect(Rect2(480, 62, 140, 18), Color("#4d5956"))
	_text(Vector2(640, 120), "返回走廊", 20)
	var beds: Array[Rect2] = _dorm_beds()
	for index in range(beds.size()):
		_draw_bunk_bed(beds[index], index + 1)
	for wall in _dorm_partitions():
		draw_rect(wall, Color("#747e7a"))
		draw_line(wall.position, Vector2(wall.end.x, wall.position.y), Color("#e8ebe3"), 3)
	# 左下方的洗漱台。
	draw_rect(Rect2(140, 1240, 180, 400), Color("#778c8e"))
	for sink_y in [1270, 1390, 1510]:
		draw_rect(Rect2(160, sink_y, 140, 90), Color("#eeeee5"))
		draw_rect(Rect2(176, sink_y + 16, 108, 58), Color("#aacbd0"))
		draw_line(Vector2(215, sink_y + 4), Vector2(238, sink_y + 20), Color("#667f86"), 6)
	_text(Vector2(145, 1215), "洗漱台", 22)
	# 上侧 U 形隔间：淋浴；下侧 U 形隔间：厕所。
	_text(Vector2(785, 1245), "洗澡间", 22)
	draw_line(Vector2(960, 1240), Vector2(920, 1260), Color("#637d88"), 7)
	draw_circle(Vector2(915, 1265), 12, Color("#8fabb2"))
	for drop in range(4):
		draw_line(Vector2(900 + drop * 12, 1288), Vector2(892 + drop * 12, 1314), Color("#8cb9ca"), 2)
	_text(Vector2(785, 1520), "WC · 厕所", 22)
	draw_rect(Rect2(830, 1550, 80, 90), Color("#eeeee9"))
	draw_circle(Vector2(870, 1595), 29, Color("#fafaf4"))
	draw_circle(Vector2(870, 1595), 17, Color("#a5bbb9"))
	if place == "宿舍尽头房间一":
		# 足球仅在当前这一间出现，不复制到其他宿舍。
		var ball := Vector2(760, 190)
		draw_circle(ball + Vector2(3, 5), 18, Color(0, 0, 0, 0.16))
		draw_circle(ball, 16, Color("#f3f0e4"))
		var patch := PackedVector2Array()
		for corner in range(5):
			var angle: float = -PI / 2.0 + corner * TAU / 5.0
			patch.append(ball + Vector2(cos(angle), sin(angle)) * 7.0)
		draw_colored_polygon(patch, Color("#303b40"))
		for seam in range(5):
			var angle: float = -PI / 2.0 + seam * TAU / 5.0
			draw_line(ball + Vector2(cos(angle), sin(angle)) * 7.0, ball + Vector2(cos(angle), sin(angle)) * 15.0, Color("#566263"), 1.5)
func _draw_noticeboard() -> void:
	# 空白展示面，内容由后续制作时补充。
	draw_rect(Rect2(608, 1386, 400, 32), Color(0, 0, 0, 0.16))
	draw_rect(noticeboard, Color("#675347"))
	draw_rect(noticeboard.grow(-5), Color("#d9d3bb"))
	draw_line(noticeboard.position, Vector2(noticeboard.end.x, noticeboard.position.y), Color("#9a8870"), 3)
