class_name EquipmentItem
extends Resource
## Equipment item resource for player customization

enum EquipmentType { SHOES, JERSEY, SHORTS, ACCESSORY, GLOVES, HEADBAND }
enum Rarity { COMMON = 1, UNCOMMON = 2, RARE = 3, EPIC = 4, LEGENDARY = 5 }

@export var item_id: String = ""
@export var item_name: String = ""
@export var description: String = ""
@export var equipment_type: EquipmentType = EquipmentType.SHOES
@export var stat_bonuses: Dictionary = {}
@export var icon_path: String = ""
@export var rarity: Rarity = Rarity.COMMON
@export var cost: int = 0
@export var unlock_level: int = 1
@export var visual_data: Dictionary = {}  # Color, texture, etc.

func _init(id: String = "", name: String = "", type: EquipmentType = EquipmentType.SHOES) -> void:
	item_id = id
	item_name = name
	equipment_type = type
	stat_bonuses = {}
	visual_data = {}

func get_stat_bonus(stat_name: String) -> int:
	return stat_bonuses.get(stat_name, 0)

func get_total_stat_bonus() -> int:
	"""Get sum of all stat bonuses"""
	var total = 0
	for bonus in stat_bonuses.values():
		total += bonus
	return total

func get_rarity_color() -> Color:
	"""Get color associated with item rarity"""
	match rarity:
		Rarity.COMMON:
			return Color.WHITE
		Rarity.UNCOMMON:
			return Color.GREEN
		Rarity.RARE:
			return Color.BLUE
		Rarity.EPIC:
			return Color.PURPLE
		Rarity.LEGENDARY:
			return Color.ORANGE
		_:
			return Color.WHITE

func get_equipment_type_name() -> String:
	"""Get human-readable equipment type name"""
	match equipment_type:
		EquipmentType.SHOES:
			return "Shoes"
		EquipmentType.JERSEY:
			return "Jersey"
		EquipmentType.SHORTS:
			return "Shorts"
		EquipmentType.ACCESSORY:
			return "Accessory"
		EquipmentType.GLOVES:
			return "Gloves"
		EquipmentType.HEADBAND:
			return "Headband"
		_:
			return "Unknown"