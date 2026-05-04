extends TextureButton

var tween: Tween

func _ready() -> void:
    mouse_entered.connect(_on_hover)
    mouse_exited.connect(_on_exited)
    pressed.connect(_on_pressed)

func _on_hover() -> void:
    highlight()

func _on_exited() -> void:
    unhighlight()

func _on_pressed() -> void:
    reset_tween()
    await highlight()
    await unhighlight()

func highlight() -> Signal:
    reset_tween()
    tween = create_tween()
    tween.tween_property(material, "shader_parameter/color", Color("#d4d4d4"), 0.2).from(Color(0, 0, 0, 0))
    return tween.finished

func unhighlight() -> Signal:
    reset_tween()
    tween = create_tween()
    tween.tween_property(material, "shader_parameter/color", Color(0, 0, 0, 0), 0.2).from(Color("#d4d4d4"))
    return tween.finished

func reset_tween() -> void:
    if tween and tween.is_valid():
        tween.kill()