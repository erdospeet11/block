class_name Block
extends Resource

enum Type {
	AIR,
	GRASS,
	DIRT,
	STONE,
	WOOD,
	LEAVES
}

# Block properties
@export var block_type: Type = Type.AIR
@export var is_solid: bool = true
@export var texture_top: Vector2i = Vector2i(0, 0)
@export var texture_side: Vector2i = Vector2i(0, 0)
@export var texture_bottom: Vector2i = Vector2i(0, 0)

static func get_block_data(type: Type) -> Block:
	var block = Block.new()
	block.block_type = type
	
	match type:
		Type.AIR:
			block.is_solid = false
			block.texture_top = Vector2i(0, 0)
			block.texture_side = Vector2i(0, 0)
			block.texture_bottom = Vector2i(0, 0)
		Type.GRASS:
			block.is_solid = true
			block.texture_top = Vector2i(0, 0)    # Grass top
			block.texture_side = Vector2i(1, 0)   # Grass side
			block.texture_bottom = Vector2i(2, 0) # Dirt bottom
		Type.DIRT:
			block.is_solid = true
			block.texture_top = Vector2i(2, 0)
			block.texture_side = Vector2i(2, 0)
			block.texture_bottom = Vector2i(2, 0)
		Type.STONE:
			block.is_solid = true
			block.texture_top = Vector2i(3, 0)
			block.texture_side = Vector2i(3, 0)
			block.texture_bottom = Vector2i(3, 0)
		Type.WOOD:
			block.is_solid = true
			block.texture_top = Vector2i(4, 0)
			block.texture_side = Vector2i(5, 0)
			block.texture_bottom = Vector2i(4, 0)
		Type.LEAVES:
			block.is_solid = true
			block.texture_top = Vector2i(6, 0)
			block.texture_side = Vector2i(6, 0)
			block.texture_bottom = Vector2i(6, 0)
	
	return block
