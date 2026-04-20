# plugin.gd
# Tile Polygon Generator – EditorPlugin
#
# Injects two buttons into the TileSet editor's own toolbar
# (the row with "Configuration | Select | Paint"):
#   • "Gen Collision"  – generates physics-layer collision polygons
#   • "Gen Occlusion"  – generates occlusion-layer polygons
#
# Generation runs in a background thread so the editor stays responsive.
# Before generation a settings dialog lets you adjust:
#   • Alpha threshold (which pixels count as solid)
#   • Whether to overwrite existing polygons
#   • Whether to auto-create missing layers

@tool
extends EditorPlugin

const _PolygonBuilderScript = preload("res://addons/tile_polygon_gen/PolygonBuilder.gd")

# Injected UI nodes (owned by the TileSetEditor toolbar)
var _sep: VSeparator = null
var _btn_col: Button = null
var _btn_occ: Button = null

# Timer used to retry finding TileSetEditor if it isn't ready yet
var _retry_timer: Timer = null

# Background thread for polygon computation
var _thread: Thread = null

# ──────────────────────────────────────────────────────────────
# Lifecycle
# ──────────────────────────────────────────────────────────────

func _enter_tree() -> void:
	# Defer so all built-in plugins (including TilesEditorPlugin) finish setup first
	call_deferred("_inject_buttons")

func _exit_tree() -> void:
	_stop_retry_timer()
	_remove_buttons()
	if _thread != null and _thread.is_started():
		_thread.wait_to_finish()
	_thread = null

# ──────────────────────────────────────────────────────────────
# Button injection into TileSetEditor toolbar
# ──────────────────────────────────────────────────────────────

func _inject_buttons() -> void:
	var toolbar := _find_tileset_toolbar()
	if toolbar == null:
		# TileSetEditor not in tree yet – retry every 0.5 s
		if _retry_timer == null:
			_retry_timer = Timer.new()
			_retry_timer.wait_time = 0.5
			_retry_timer.one_shot = false
			_retry_timer.timeout.connect(_inject_buttons)
			EditorInterface.get_base_control().add_child(_retry_timer)
			_retry_timer.start()
		return

	_stop_retry_timer()
	_remove_buttons()  # avoid duplicates if called again

	_sep = VSeparator.new()
	toolbar.add_child(_sep)

	_btn_col = Button.new()
	_btn_col.text = "Gen Collision"
	_btn_col.tooltip_text = "Generate collision polygons for every tile in the active TileSet"
	_btn_col.pressed.connect(_on_gen_collision_pressed)
	toolbar.add_child(_btn_col)

	_btn_occ = Button.new()
	_btn_occ.text = "Gen Occlusion"
	_btn_occ.tooltip_text = "Generate occlusion polygons for every tile in the active TileSet"
	_btn_occ.pressed.connect(_on_gen_occlusion_pressed)
	toolbar.add_child(_btn_occ)

func _remove_buttons() -> void:
	if is_instance_valid(_sep):     _sep.queue_free()
	if is_instance_valid(_btn_col): _btn_col.queue_free()
	if is_instance_valid(_btn_occ): _btn_occ.queue_free()
	_sep = null
	_btn_col = null
	_btn_occ = null

func _stop_retry_timer() -> void:
	if is_instance_valid(_retry_timer):
		_retry_timer.stop()
		_retry_timer.queue_free()
	_retry_timer = null

# Walk the editor UI tree to find the TileSetEditor's toolbar HBoxContainer.
# TileSetEditor (C++ class) is the root of the TileSet bottom panel.
func _find_tileset_toolbar() -> HBoxContainer:
	var ts_editor := _find_node_by_class(EditorInterface.get_base_control(), "TileSetEditor")
	if ts_editor == null:
		return null
	# The toolbar is the first HBoxContainer child of TileSetEditor
	for child in ts_editor.get_children():
		if child is HBoxContainer:
			return child as HBoxContainer
	# Some Godot builds nest it one level deeper
	for child in ts_editor.get_children():
		for grandchild in child.get_children():
			if grandchild is HBoxContainer:
				return grandchild as HBoxContainer
	return null

func _find_node_by_class(node: Node, target_class: String) -> Node:
	if node.get_class() == target_class:
		return node
	for child in node.get_children():
		var found := _find_node_by_class(child, target_class)
		if found != null:
			return found
	return null

# ──────────────────────────────────────────────────────────────
# Button handlers
# ──────────────────────────────────────────────────────────────

func _on_gen_collision_pressed() -> void:
	_show_settings_dialog(false)

func _on_gen_occlusion_pressed() -> void:
	_show_settings_dialog(true)

func _set_buttons_enabled(enabled: bool) -> void:
	if is_instance_valid(_btn_col): _btn_col.disabled = not enabled
	if is_instance_valid(_btn_occ): _btn_occ.disabled = not enabled

# ──────────────────────────────────────────────────────────────
# Settings dialog
# ──────────────────────────────────────────────────────────────

func _show_settings_dialog(occlusion_mode: bool) -> void:
	var tile_set := _get_active_tileset()
	if tile_set == null:
		_error_popup("No TileSet is open in the inspector.\nSelect a TileSet resource first.")
		return

	var dialog := AcceptDialog.new()
	dialog.title = "Gen Occlusion Settings" if occlusion_mode else "Gen Collision Settings"
	dialog.ok_button_text = "Generate"

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(340, 0)
	dialog.add_child(vbox)

	# Alpha threshold row
	var alpha_row := HBoxContainer.new()
	vbox.add_child(alpha_row)
	var alpha_label := Label.new()
	alpha_label.text = "Alpha threshold (0 – 1):"
	alpha_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	alpha_row.add_child(alpha_label)
	var alpha_spin := SpinBox.new()
	alpha_spin.min_value = 0.0
	alpha_spin.max_value = 1.0
	alpha_spin.step = 0.01
	alpha_spin.value = 0.4
	alpha_spin.custom_minimum_size = Vector2(90, 0)
	alpha_row.add_child(alpha_spin)

	# Overwrite checkbox
	var overwrite_check := CheckBox.new()
	overwrite_check.text = "Overwrite existing polygons"
	overwrite_check.button_pressed = true
	vbox.add_child(overwrite_check)

	# Auto-create layer checkbox
	var layer_check := CheckBox.new()
	layer_check.text = "Auto-create occlusion layer if missing" if occlusion_mode \
		else "Auto-create physics layer if missing"
	layer_check.button_pressed = true
	vbox.add_child(layer_check)

	EditorInterface.get_base_control().add_child(dialog)
	dialog.popup_centered()

	dialog.confirmed.connect(func():
		_generate(tile_set, occlusion_mode, alpha_spin.value,
			overwrite_check.button_pressed, layer_check.button_pressed)
		dialog.queue_free()
	)
	dialog.canceled.connect(func(): dialog.queue_free())

# ──────────────────────────────────────────────────────────────
# Generation  (image processing runs in a background thread)
# ──────────────────────────────────────────────────────────────

func _generate(
	tile_set: TileSet,
	occlusion_mode: bool,
	alpha: float,
	overwrite: bool,
	auto_create_layer: bool
) -> void:

	if occlusion_mode:
		if tile_set.get_occlusion_layers_count() == 0:
			if auto_create_layer:
				tile_set.add_occlusion_layer(0)
			else:
				_error_popup("The TileSet has no occlusion layer. Add one first.")
				return
	else:
		if tile_set.get_physics_layers_count() == 0:
			if auto_create_layer:
				tile_set.add_physics_layer(0)
			else:
				_error_popup("The TileSet has no physics layer. Add one first.")
				return

	# --- Collect work items on the main thread (texture access must be main-thread) ---
	var work_items: Array = []
	for src_idx in tile_set.get_source_count():
		var source_id := tile_set.get_source_id(src_idx)
		var source := tile_set.get_source(source_id)
		if not source is TileSetAtlasSource:
			continue
		var atlas := source as TileSetAtlasSource
		if atlas.texture == null:
			continue
		var full_image: Image = atlas.texture.get_image()
		if full_image == null:
			continue
		# Convert once per atlas – PolygonBuilder expects FORMAT_RGBA8
		if full_image.get_format() != Image.FORMAT_RGBA8:
			full_image.convert(Image.FORMAT_RGBA8)

		for tile_idx in atlas.get_tiles_count():
			var tile_id: Vector2i = atlas.get_tile_id(tile_idx)
			var tile_data: TileData = atlas.get_tile_data(tile_id, 0)
			if tile_data == null:
				continue
			var region: Rect2i = atlas.get_tile_texture_region(tile_id, 0)
			work_items.append({
				tile_data = tile_data,
				tile_image = full_image.get_region(region)
			})

	if work_items.is_empty():
		return

	_set_buttons_enabled(false)

	# --- Run heavy polygon computation in a background thread ---
	_thread = Thread.new()
	_thread.start(func():
		var builder = _PolygonBuilderScript.new()
		var results: Array = []
		for item in work_items:
			results.append({
				tile_data = item.tile_data,
				polygons  = builder.build_from_image(item.tile_image, alpha)
			})
		# Hand results back to the main thread
		call_deferred("_apply_results", results, occlusion_mode, overwrite, tile_set)
	)

# Called on the main thread once the background thread finishes computing.
func _apply_results(
	results: Array,
	occlusion_mode: bool,
	overwrite: bool,
	tile_set: TileSet
) -> void:
	for r in results:
		if occlusion_mode:
			_apply_occlusion(r.tile_data, r.polygons, overwrite)
		else:
			_apply_collision(r.tile_data, r.polygons, overwrite)

	# Signal the editor that the resource changed so the panel refreshes
	tile_set.emit_changed()

	if _thread != null:
		_thread.wait_to_finish()
		_thread = null

	_set_buttons_enabled(true)
	print("[TilePolygonGen] Done. Tiles processed: ", results.size())

# ──────────────────────────────────────────────────────────────
# Apply helpers
# ──────────────────────────────────────────────────────────────

func _apply_collision(tile_data: TileData, polygons: Array, overwrite: bool) -> void:
	if not overwrite and tile_data.get_collision_polygons_count(0) > 0:
		return
	while tile_data.get_collision_polygons_count(0) > 0:
		tile_data.remove_collision_polygon(0, 0)
	for poly in polygons:
		var idx := tile_data.get_collision_polygons_count(0)
		tile_data.add_collision_polygon(0)
		tile_data.set_collision_polygon_points(0, idx, poly)

func _apply_occlusion(tile_data: TileData, polygons: Array, overwrite: bool) -> void:
	if not overwrite and tile_data.get_occluder(0) != null:
		return
	if polygons.is_empty():
		return
	var occ := OccluderPolygon2D.new()
	occ.polygon = polygons[0]
	tile_data.set_occluder(0, occ)

# ──────────────────────────────────────────────────────────────
# Utilities
# ──────────────────────────────────────────────────────────────

func _get_active_tileset() -> TileSet:
	var obj := EditorInterface.get_inspector().get_edited_object()
	if obj is TileSet:
		return obj as TileSet
	return null

func _error_popup(msg: String) -> void:
	var d := AcceptDialog.new()
	d.title = "Tile Polygon Generator"
	d.dialog_text = msg
	EditorInterface.get_base_control().add_child(d)
	d.popup_centered()
	d.confirmed.connect(func(): d.queue_free())
