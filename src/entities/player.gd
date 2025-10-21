extends Node2D
class_name Player

const TILE_SIZE := 32

var grid_position: Vector2i = Vector2i.ZERO
var max_health := 100
var health := 100
var attack_power := 12
var inventory: Array = []

var _sprite: Sprite2D
var _label: Label

func _ready() -> void:
    _sprite = Sprite2D.new()
    _sprite.texture = _make_texture(Color(0.6, 0.8, 1.0), Color(0.1, 0.2, 0.5))
    _sprite.centered = true
    add_child(_sprite)
    _label = Label.new()
    _label.text = "Você"
    _label.position = Vector2(-20, -28)
    add_child(_label)

func _make_texture(color: Color, outline: Color) -> Texture2D:
    var img := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
    img.fill(outline)
    for y in range(4, TILE_SIZE - 4):
        for x in range(4, TILE_SIZE - 4):
            img.set_pixel(x, y, color)
    return ImageTexture.create_from_image(img)

func set_grid_position(pos: Vector2i) -> void:
    grid_position = pos
    position = Vector2(pos * TILE_SIZE) + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)

func take_damage(amount: int) -> void:
    health = max(0, health - amount)

func heal(amount: int) -> void:
    health = clamp(health + amount, 0, max_health)

func add_item(item: Dictionary) -> void:
    inventory.append(item)

func clear_inventory() -> void:
    inventory.clear()
