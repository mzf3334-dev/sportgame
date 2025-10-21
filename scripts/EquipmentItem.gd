class_name EquipmentItem
extends Resource
## Equipment item resource for player customization

enum EquipmentType { SHOES, JERSEY, ACCESSORY }

@export var item_id: String = ""
@export var item_name: String = ""
@export var equipment_type: EquipmentType = EquipmentType.SHOES
@export var stat_bonuses: Dictionary = {}
@export var icon_path: String = ""
@export var rarity: int = 1  # 1-5 rarity scale

func _init(id: String = "", name: String = "", type: EquipmentType = EquipmentType.SHOES) -> void:
	item_id = id
	item_name = name
	equipment_type = type
	stat_bonuses = {}

func get_stat_bonus(stat_name: String) -> int:
	return stat_bonuses.get(stat_name, 0)