extends Node2D
class_name Enemy

const TILE_SIZE := 32

var data: Dictionary
var health := 20
var base_attack := 6
var _sprite: Sprite2D
var _label: Label

func setup(info: Dictionary) -> void:
    data = info
    health = info.get("power", 20)
    base_attack = int(ceil(health / 4.0))
    if _sprite == null:
        _create_visuals()
    _label.text = info.get("title", info.get("name", "Inimigo"))

func _create_visuals() -> void:
    _sprite = Sprite2D.new()
    var color := Color(0.8, 0.3, 0.3)
    if data.get("id", "") == "boss":
        color = Color(0.6, 0.0, 0.8)
    _sprite.texture = _make_texture(color)
    _sprite.centered = true
    add_child(_sprite)
    _label = Label.new()
    _label.position = Vector2(-30, -28)
    add_child(_label)

func _make_texture(color: Color) -> Texture2D:
    var img := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
    img.fill(color)
    return ImageTexture.create_from_image(img)

func set_grid_position(pos: Vector2i) -> void:
    position = Vector2(pos * TILE_SIZE) + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)

func take_damage(amount: int) -> void:
    health = max(0, health - amount)
