extends Node

# Data structure for a unit template + its equipped cards
class EquippedUnit extends RefCounted:
	@export var template: UnitTemplate # The base unit blueprint
	@export var attack_card: Action = null
	@export var support_card: Action = null
	@export var control_card: Action = null
	@export var special_card: Action = null

# The Player's full collection (UnitTemplate is the key, EquippedUnit is the data)
var unit_collection: Dictionary = {} 

# The 3 units selected for the next battle
var current_squad: Array[EquippedUnit] = [] 

# Function called before combat loads
func prepare_combat_squad(selection_array): # selection_array contains 3 UnitTemplates
	# Logic to populate current_squad based on player's UI choices
	pass
