# ActionEffect.gd

extends Resource
class_name ActionEffect

## --- EFFECT PROPERTIES ---
@export var effect_name: String = "Effect"
@export var amount: int = 0
@export var duration: int = 0
@export var target_stat: String = ""

## --- CONDITION CHECK ---
func check_condition(source_unit: Unit, target_unit: Unit, target_outcome: String) -> bool:
	# Default condition: Always apply if clash is won or a free hit.
	if target_outcome == "WIN" or target_outcome == "FREE_HIT":
		return true
	
	# Add a specific check for a "LastStand" buff effect, for example
	if effect_name == "HealSelfLowHP" and source_unit.current_hp < source_unit.max_hp * 0.3:
		return true
		
	return false

## --- EFFECT APPLICATION ---
func apply_effect(source_unit: Unit, target_unit: Unit):
	print(">>> Applying Effect: ", effect_name, " from ", source_unit.name, " to ", target_unit.name)
	
	match effect_name:
		"Burn", "Poison":
			# Calls the new Unit function to add a Status Effect.
			target_unit.add_status_effect(effect_name, amount, duration)
			print("    -> Applied ", effect_name, " (DoT: ", amount, ") for ", duration, " turns.")
			
		"BuffStat": # <--- RENAMED to be generic
			# Calls the new Unit function to apply a temporary stat buff.
			# Passes the target_stat property from the resource
			target_unit.apply_temporary_buff(target_stat, amount, duration)
			print("    -> Applied ", target_stat, " Buff (+", amount, ") for ", duration, " turns.")
			##In your ActionEffect resource files (the .tres files), 
			#ensure you set effect_name to BuffStat and set target_stat 
			#to a valid stat name like strength, intelligence, or defense.
		
		
		"HealSelfLowHP":
			# Healing effect on the source unit (caster)
			source_unit.heal(amount)
			print("    -> Caster healed for ", amount, " HP.")

		"InstaDamage":
			# Apply bonus damage directly.
			target_unit.take_damage(amount)
			print("    -> Applied ", amount, " bonus damage.")
			
		_:
			push_error("Action Effect '", effect_name, "' has no defined logic in apply_effect.")
