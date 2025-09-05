extends Node3D

const Block = preload("res://Block.gd")

const CHUNK_SIZE = 16*5
const CHUNK_HEIGHT = 16*5


var chunks = {}
var chunk_meshes = {}
var block_material: StandardMaterial3D

func _ready():
	setup_materials()
	generate_chunk(Vector3i(0, 0, 0))

func setup_materials():
	block_material = StandardMaterial3D.new()
	block_material.albedo_color = Color.WHITE
	block_material.metallic = 0.0
	block_material.roughness = 0.8
	
	#TODO: load a texture atlas here, instead of simple colors

func generate_chunk(chunk_pos: Vector3i):
	var chunk_data = []
	
	# Initialize 3D array for chunk blocks
	for x in range(CHUNK_SIZE):
		chunk_data.append([])
		for y in range(CHUNK_HEIGHT):
			chunk_data[x].append([])
			for z in range(CHUNK_SIZE):
				chunk_data[x][y].append(Block.Type.AIR)
	
	# Generate terrain (simple heightmap)
	for x in range(CHUNK_SIZE):
		for z in range(CHUNK_SIZE):
			var height = get_terrain_height(x + chunk_pos.x * CHUNK_SIZE, z + chunk_pos.z * CHUNK_SIZE)
			
			for y in range(min(height + 1, CHUNK_HEIGHT)):
				if y == height and height > 0:
					chunk_data[x][y][z] = Block.Type.GRASS
				elif y > height - 4 and y < height:
					chunk_data[x][y][z] = Block.Type.DIRT
				elif y < height:
					chunk_data[x][y][z] = Block.Type.STONE
	
	# Store chunk data
	chunks[chunk_pos] = chunk_data
	
	# Generate mesh
	generate_chunk_mesh(chunk_pos, chunk_data)

func get_terrain_height(world_x: int, world_z: int) -> int:
	# Simple noise-based terrain generation
	var noise_value = sin(world_x * 0.1) * cos(world_z * 0.1) + sin(world_x * 0.05) * sin(world_z * 0.05)
	var height = int((noise_value + 2) * 2) + 5  # Height between 1 and 9
	return clamp(height, 1, CHUNK_HEIGHT - 1)

func generate_chunk_mesh(chunk_pos: Vector3i, chunk_data: Array):
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Generate faces for each block
	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_HEIGHT):
			for z in range(CHUNK_SIZE):
				var block_type = chunk_data[x][y][z]
				if block_type != Block.Type.AIR:
					add_block_faces(surface_tool, Vector3i(x, y, z), block_type, chunk_data)
	
	# Generate normals and create mesh
	surface_tool.generate_normals()
	var mesh = surface_tool.commit()
	
	# Create MeshInstance3D node
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = block_material
	mesh_instance.position = Vector3(chunk_pos.x * CHUNK_SIZE, chunk_pos.y * CHUNK_HEIGHT, chunk_pos.z * CHUNK_SIZE)
	
	# Add collision
	var static_body = StaticBody3D.new()
	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = mesh.create_trimesh_shape()
	static_body.add_child(collision_shape)
	mesh_instance.add_child(static_body)
	
	add_child(mesh_instance)
	chunk_meshes[chunk_pos] = mesh_instance

func add_block_faces(surface_tool: SurfaceTool, pos: Vector3i, block_type: Block.Type, chunk_data: Array):
	var block_pos = Vector3(pos.x, pos.y, pos.z)
	
	# Define face vertices (relative to block position)
	var faces = [
		# Top face (+Y)
		[Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(1, 1, 1), Vector3(0, 1, 1)],
		# Bottom face (-Y)
		[Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, 0, 0), Vector3(0, 0, 0)],
		# Front face (+Z)
		[Vector3(0, 0, 1), Vector3(0, 1, 1), Vector3(1, 1, 1), Vector3(1, 0, 1)],
		# Back face (-Z)
		[Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(0, 1, 0), Vector3(0, 0, 0)],
		# Right face (+X)
		[Vector3(1, 0, 1), Vector3(1, 1, 1), Vector3(1, 1, 0), Vector3(1, 0, 0)],
		# Left face (-X)
		[Vector3(0, 0, 0), Vector3(0, 1, 0), Vector3(0, 1, 1), Vector3(0, 0, 1)]
	]
	
	# Face directions for culling check
	var face_directions = [
		Vector3i(0, 1, 0),   # Top
		Vector3i(0, -1, 0),  # Bottom
		Vector3i(0, 0, 1),   # Front
		Vector3i(0, 0, -1),  # Back
		Vector3i(1, 0, 0),   # Right
		Vector3i(-1, 0, 0)   # Left
	]
	
	# UV coordinates for each face
	var face_uvs = [
		[Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)],  # Top
		[Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)],  # Bottom
		[Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)],  # Front
		[Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)],  # Back
		[Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)],  # Right
		[Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]   # Left
	]
	
	# Colors for different block types (since we're not using textures yet)
	var block_colors = {
		Block.Type.GRASS: Color.GREEN,
		Block.Type.DIRT: Color(0.6, 0.4, 0.2),
		Block.Type.STONE: Color.GRAY,
		Block.Type.WOOD: Color(0.6, 0.3, 0.1),
		Block.Type.LEAVES: Color(0.2, 0.8, 0.2)
	}
	
	var color = block_colors.get(block_type, Color.WHITE)
	
	for face_index in range(6):
		var face_dir = face_directions[face_index]
		var neighbor_pos = pos + face_dir
		
		# Check if we should render this face (face culling)
		if should_render_face(neighbor_pos, chunk_data):
			var vertices = faces[face_index]
			var uvs = face_uvs[face_index]
			
			# Add vertices in triangular order
			# Triangle 1
			surface_tool.set_uv(uvs[0])
			surface_tool.set_color(color)
			surface_tool.add_vertex(block_pos + vertices[0])
			
			surface_tool.set_uv(uvs[1])
			surface_tool.set_color(color)
			surface_tool.add_vertex(block_pos + vertices[1])
			
			surface_tool.set_uv(uvs[2])
			surface_tool.set_color(color)
			surface_tool.add_vertex(block_pos + vertices[2])
			
			# Triangle 2
			surface_tool.set_uv(uvs[0])
			surface_tool.set_color(color)
			surface_tool.add_vertex(block_pos + vertices[0])
			
			surface_tool.set_uv(uvs[2])
			surface_tool.set_color(color)
			surface_tool.add_vertex(block_pos + vertices[2])
			
			surface_tool.set_uv(uvs[3])
			surface_tool.set_color(color)
			surface_tool.add_vertex(block_pos + vertices[3])

func should_render_face(neighbor_pos: Vector3i, chunk_data: Array) -> bool:
	# Check if neighbor position is outside chunk bounds
	if neighbor_pos.x < 0 or neighbor_pos.x >= CHUNK_SIZE or \
	   neighbor_pos.y < 0 or neighbor_pos.y >= CHUNK_HEIGHT or \
	   neighbor_pos.z < 0 or neighbor_pos.z >= CHUNK_SIZE:
		return true  # Render face if neighbor is outside chunk
	
	# Check if neighbor block is air (transparent)
	var neighbor_type = chunk_data[neighbor_pos.x][neighbor_pos.y][neighbor_pos.z]
	return neighbor_type == Block.Type.AIR

func get_block_at(world_pos: Vector3i) -> Block.Type:
	var chunk_pos = Vector3i(
		int(world_pos.x / CHUNK_SIZE),
		0,  # We only have one chunk layer for now
		int(world_pos.z / CHUNK_SIZE)
	)
	
	if not chunks.has(chunk_pos):
		return Block.Type.AIR
	
	var local_pos = Vector3i(
		world_pos.x % CHUNK_SIZE,
		world_pos.y,
		world_pos.z % CHUNK_SIZE
	)
	
	if local_pos.y < 0 or local_pos.y >= CHUNK_HEIGHT:
		return Block.Type.AIR
	
	return chunks[chunk_pos][local_pos.x][local_pos.y][local_pos.z]
