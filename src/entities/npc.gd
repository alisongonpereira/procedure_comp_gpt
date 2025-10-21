extends Node2D
class_name NPC

const TILE_SIZE := 32

var data: Dictionary
var _sprite: Sprite2D
var _label: Label

func setup(info: Dictionary) -> void:
    data = info
    if _sprite == null:
        _create_visuals()
    _label.text = info.get("name", "NPC")

func _create_visuals() -> void:
    _sprite = Sprite2D.new()
    _sprite.texture = _make_texture()
    _sprite.centered = true
    add_child(_sprite)
    _label = Label.new()
    _label.position = Vector2(-24, -28)
    add_child(_label)

func _make_texture() -> Texture2D:
    var img := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
    img.fill(Color(0.3, 0.8, 0.5))
    for y in range(0, TILE_SIZE):
        img.set_pixel(y % TILE_SIZE, y, Color(0.2, 0.5, 0.3))
    return ImageTexture.create_from_image(img)

func set_grid_position(pos: Vector2i) -> void:
    position = Vector2(pos * TILE_SIZE) + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
