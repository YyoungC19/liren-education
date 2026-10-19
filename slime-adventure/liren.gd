extends Node2D

@export var cb_portrait: Texture2D

@onready var map = $Map
@onready var player = $Player
@onready var npc = $NPC
@onready var camera: Camera2D = $Player/Camera2D
@onready var hud: Label = $HUD/StatusLabel

var place: String = ""
var dorm_transition_cooldown: float = 0.0
var message: String = ""

var dialogue_lines: PackedStringArray = []
var dialogue_index: int = 0

var dialogue_box: PanelContainer
var dialogue_text: Label
var dialogue_footer: Label
var dialogue_height: float = 280.0

var noticeboard_view: Control
var portrait_frame: PanelContainer
var portrait_image: TextureRect


func _ready() -> void:
	_setup_dialogue()
	_setup_noticeboard()
	_load_place("校园 G0", Vector2(800, 2020))


func _process(_delta: float) -> void:
	dorm_transition_cooldown = maxf(dorm_transition_cooldown - _delta, 0.0)
	_update_dorm_stairs()
	_update_dialogue()

	if place in ["教学楼 F2", "教学楼 F3", "食堂内部", "白房内部", "二层第一教室"]:
		_frame_area()

	player.movement_enabled = message.is_empty() and not noticeboard_view.visible

	var hint := "靠近光圈，按 E 互动"
	if place in ["男生宿舍内部", "男生宿舍 F2", "男生宿舍 F3"]:
		hint = "走上右端楼梯自动换层，房门按 E 互动"
	var nearby := _nearest_point()

	if not nearby.is_empty():
		hint = "E：" + str(nearby["title"])

	if not message.is_empty():
		hint = "对话中，按 E 继续"

	if noticeboard_view.visible:
		hint = "查看布告板中，按 E 关闭"

	var area_name: String = place
	if place == "男生宿舍内部":
		area_name = "男生宿舍 F1 · 楼梯间"

	if place == "教学楼前平台":
		area_name = "教学楼 F1 · 开放平台"
	elif place == "二层第一教室":
		area_name = "二层 · cb 教室"

	hud.text = (
		player.display_name
		+ "  |  "
		+ area_name
		+ "\n方向键 / WASD 移动，E 互动\n"
		+ hint
	)


func _setup_dialogue() -> void:
	# 优先使用检查器指定的头像，否则读取默认文件。
	if cb_portrait == null:
		if ResourceLoader.exists("res://assets/portraits/cb.jpg"):
			cb_portrait = load(
				"res://assets/portraits/cb.jpg"
			) as Texture2D

	dialogue_box = PanelContainer.new()
	dialogue_box.name = "DialogueBox"
	$HUD.add_child(dialogue_box)

	dialogue_box.set_anchors_and_offsets_preset(
		Control.PRESET_BOTTOM_WIDE
	)
	dialogue_box.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.055, 0.075, 0.97)
	style.border_color = Color("#aebdb5")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	dialogue_box.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()

	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)

	dialogue_box.add_child(margin)

	# 左侧头像，右侧台词。
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	margin.add_child(row)

	portrait_frame = PanelContainer.new()
	portrait_frame.name = "Portrait"
	portrait_frame.custom_minimum_size = Vector2(200, 0)

	var portrait_style := StyleBoxFlat.new()
	portrait_style.bg_color = Color("#202a31")
	portrait_style.border_color = Color("#71857b")
	portrait_style.set_border_width_all(2)

	portrait_frame.add_theme_stylebox_override(
		"panel",
		portrait_style
	)
	row.add_child(portrait_frame)

	portrait_image = TextureRect.new()
	portrait_image.texture = cb_portrait
	portrait_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_frame.add_child(portrait_image)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 16)
	row.add_child(column)

	dialogue_text = Label.new()
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue_text.add_theme_font_size_override("font_size", 32)
	column.add_child(dialogue_text)

	dialogue_footer = Label.new()
	dialogue_footer.text = "E  关闭对话"
	dialogue_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dialogue_footer.add_theme_font_size_override("font_size", 22)
	dialogue_footer.add_theme_color_override(
		"font_color",
		Color("#b8c7be")
	)
	column.add_child(dialogue_footer)

	dialogue_box.hide()


func _update_dialogue() -> void:
	dialogue_height = clampf(
		get_viewport_rect().size.y * 0.23,
		180.0,
		340.0
	)

	dialogue_box.offset_left = 36.0
	dialogue_box.offset_right = -36.0
	dialogue_box.offset_top = -dialogue_height - 24.0
	dialogue_box.offset_bottom = -24.0

	dialogue_box.visible = not message.is_empty()
	dialogue_text.text = message

	portrait_image.texture = cb_portrait
	portrait_frame.custom_minimum_size.x = maxf(
		(dialogue_height - 48.0) * 0.75,
		90.0
	)

	portrait_frame.visible = (
		not message.is_empty()
		and message.begins_with(npc.display_name + "：")
		and cb_portrait != null
	)

	if dialogue_lines.is_empty():
		dialogue_footer.text = "E  关闭对话"
	elif dialogue_index + 1 < dialogue_lines.size():
		dialogue_footer.text = "E  继续  （%d / %d）" % [
			dialogue_index + 1,
			dialogue_lines.size()
		]
	else:
		dialogue_footer.text = "E  结束对话  （%d / %d）" % [
			dialogue_index + 1,
			dialogue_lines.size()
		]


func _start_cb_dialogue() -> void:
	dialogue_lines.clear()
	dialogue_index = 0

	# Dialogue 中每个实际换行代表下一段，空行会跳过。
	for line in npc.dialogue.split("\n"):
		var text: String = line.strip_edges()

		if not text.is_empty():
			dialogue_lines.append(text)

	if dialogue_lines.is_empty():
		dialogue_lines.append("……")

	message = npc.display_name + "：" + dialogue_lines[0]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_E:
			_interact()


func _nearest_point() -> Dictionary:
	var result: Dictionary = {}
	var best_distance: float = INF
	var candidates: Array[Dictionary] = map.points.duplicate()

	if npc.visible:
		candidates.append({
			"pos": npc.position,
			"title": "与 " + npc.display_name + " 对话",
			"action": "cb",
			"radius": 80.0
		})

	for point in candidates:
		var target: Vector2 = point["pos"]
		if point.has("interaction_rect"):
			var area: Rect2 = point["interaction_rect"]
			target = Vector2(clampf(player.position.x, area.position.x, area.end.x), clampf(player.position.y, area.position.y, area.end.y))
		var radius: float = float(point.get("radius", 80.0))
		var distance: float = player.position.distance_to(target)

		if distance <= radius and distance < best_distance:
			best_distance = distance
			result = point

	return result


func _interact() -> void:
	if noticeboard_view.visible:
		noticeboard_view.hide()
		player.movement_enabled = true
		return
	# 正在对话时，E 优先推进台词。
	if not message.is_empty():
		if (
			not dialogue_lines.is_empty()
			and dialogue_index + 1 < dialogue_lines.size()
		):
			dialogue_index += 1
			message = (
				npc.display_name
				+ "："
				+ dialogue_lines[dialogue_index]
			)
		else:
			message = ""
			dialogue_lines.clear()
			dialogue_index = 0

		player.movement_enabled = message.is_empty() and not noticeboard_view.visible
		_update_dialogue()
		return

	var point := _nearest_point()

	if point.is_empty():
		return

	var action: String = point["action"]

	match action:
		"noticeboard":
			noticeboard_view.show()

		"left_up":
			_load_place("教学楼前平台", Vector2(420, 1355))

		"right_up":
			_load_place("教学楼前平台", Vector2(1180, 1355))

		"left_down":
			_load_place("校园 G0", Vector2(420, 1515))

		"right_down":
			_load_place("校园 G0", Vector2(1180, 1515))

		"side_up":
			_load_place("教学楼前平台", Vector2(1360, 1290))

		"side_down":
			_load_place("校园 G0", Vector2(1690, 1290))

		"upstairs":
			_load_place("教学楼 F2", Vector2(1120, 416))

		"up_to_f3":
			_load_place("教学楼 F3", Vector2(1120, 236))

		"down_to_f2":
			_load_place("教学楼 F2", Vector2(1120, 416))

		"downstairs":
			_load_place("教学楼前平台", Vector2(1120, 1200))

		"classroom_front":
			_load_place("二层第一教室", Vector2(1120, 280))

		"classroom_back":
			_load_place("二层第一教室", Vector2(1120, 1100))

		"exit_classroom_front":
			_load_place("教学楼 F2", Vector2(780, 410))

		"exit_classroom_back":
			_load_place("教学楼 F2", Vector2(630, 410))

		"room_closed":
			message = str(point["title"]) + "暂未开放。"

		"cb":
			_start_cb_dialogue()

		"white_house_enter":
			_load_place("白房内部", Vector2(770, 350))

		"white_house_exit":
			_load_place("校园 G0", Vector2(1710, 750))

		"dorm_female":
			message = "此入口仅限女生进入，请从右侧男生宿舍入口进入。"

		"dorm_male_enter":
			_load_place("男生宿舍内部", Vector2(4690, 560))

		"dorm_male_exit":
			_load_place("校园 G0", Vector2(2571, 1080))

		"dorm_room_one":
			_load_place("宿舍尽头房间一", Vector2(550, 200))

		"dorm_room_two":
			_load_place("宿舍尽头房间二", Vector2(550, 200))

		"dorm_room_one_exit":
			_load_place("男生宿舍 F3", Vector2(260, 410))

		"dorm_room_two_exit":
			_load_place("男生宿舍 F3", Vector2(600, 410))

		"dorm_room_closed":
			message = "这是别人的宿舍，不能进入。"

		"canteen_from_left":
			_load_place("食堂内部", Vector2(180, 500))

		"canteen_from_upper":
			_load_place("食堂内部", Vector2(700, 180))

		"canteen_exit_left":
			_load_place("校园 G0", Vector2(1370, 1780))

		"canteen_exit_upper":
			_load_place("校园 G0", Vector2(1800, 1380))


	player.movement_enabled = message.is_empty() and not noticeboard_view.visible
	_update_dialogue()


func _load_place(next_place: String, spawn: Vector2) -> void:
	if next_place == "教学楼 F1":
		next_place = "教学楼前平台"

	noticeboard_view.hide()
	place = next_place
	dorm_transition_cooldown = 0.6
	message = ""
	dialogue_lines.clear()
	dialogue_index = 0

	map.configure(place)
	npc.set_active(place == "二层第一教室")

	player.position = spawn
	player.velocity = Vector2.ZERO
	player.movement_enabled = true

	var outside: bool = (
		place == "校园 G0"
		or place == "教学楼前平台"
	)

	camera.zoom = Vector2(0.75, 0.75) if outside else Vector2.ONE
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(map.map_size.x)
	camera.limit_bottom = int(map.map_size.y)
	camera.position = Vector2.ZERO

	_update_dialogue()

	if place in ["教学楼 F2", "教学楼 F3", "食堂内部", "白房内部", "二层第一教室"]:
		_frame_area()

	camera.reset_smoothing()
	camera.force_update_scroll()


func _frame_area() -> void:
	var view_size: Vector2 = get_viewport_rect().size

	var reserved: float = (
		dialogue_height + 60.0
		if not message.is_empty()
		else 0.0
	)

	var available_height: float = maxf(
		view_size.y - reserved,
		100.0
	)

	var fit: float = minf(
		view_size.x / map.map_size.x,
		available_height / map.map_size.y
	) * 0.94

	fit = maxf(fit, 0.1)

	camera.zoom = Vector2.ONE * fit
	camera.position = (
		map.map_size * 0.5
		- player.position
		+ Vector2(0, reserved / (2.0 * fit))
	)

	camera.limit_left = -100000
	camera.limit_top = -100000
	camera.limit_right = 100000
	camera.limit_bottom = 100000

func _update_dorm_stairs() -> void:
	if dorm_transition_cooldown > 0.0 or not message.is_empty() or noticeboard_view.visible:
		return
	if place not in ["男生宿舍内部", "男生宿舍 F2", "男生宿舍 F3"]:
		return
	for transition in map.auto_transitions:
		var trigger: Rect2 = transition["rect"]
		if trigger.has_point(player.position):
			var floor_number: int = map._dorm_floor_number() + int(transition["step"])
			var next_place: String = "男生宿舍内部" if floor_number == 1 else "男生宿舍 F%d" % floor_number
			var arrival_x: float = 4550.0 if int(transition["step"]) > 0 else 4690.0
			_load_place(next_place, Vector2(arrival_x, 410))
			return

func _setup_noticeboard() -> void:
	noticeboard_view = Control.new()
	noticeboard_view.name = "NoticeboardView"
	$HUD.add_child(noticeboard_view)
	noticeboard_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	noticeboard_view.mouse_filter = Control.MOUSE_FILTER_STOP
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.02, 0.03, 0.04, 0.82)
	noticeboard_view.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var board := Panel.new()
	board.name = "BlankBoard"
	noticeboard_view.add_child(board)
	board.anchor_left = 0.15
	board.anchor_top = 0.18
	board.anchor_right = 0.85
	board.anchor_bottom = 0.78
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#d9d3bb")
	style.border_color = Color("#675347")
	style.set_border_width_all(14)
	board.add_theme_stylebox_override("panel", style)
	# 只显示关闭操作，不添加任何布告内容。
	var close_hint := Label.new()
	close_hint.text = "E  关闭"
	close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_hint.add_theme_font_size_override("font_size", 26)
	noticeboard_view.add_child(close_hint)
	close_hint.anchor_left = 0.15
	close_hint.anchor_right = 0.85
	close_hint.anchor_top = 0.82
	close_hint.anchor_bottom = 0.9
	noticeboard_view.hide()
