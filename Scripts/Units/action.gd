class_name Action
extends Resource

enum Category { ATTACK, DEFENSIVE, SKILL }
enum ScalingType { PHYSICAL, MAGICAL, ELEMENTAL }
enum DefensiveType { NONE, GUARD, COUNTER, REDIRECT }
enum Timing {
	# --- TURN FLOW ---
	TURN_START,          # Start of unit's turn
	TURN_END,            # End of unit's turn
	# --- ACTION DECLARATION ---
	ON_ACTION_SELECTED,  # When an action is chosen (UI, cards, costs)
	ON_ACTION_QUEUED,    # Added to action queue
	ON_ACTION_START,     # Just before resolution
	# --- TARGETING ---
	BEFORE_TARGETING,    # Modify targets
	ON_TARGET_SELECTED,  # Target locked in
	# --- CLASH / INTERACTION ---
	BEFORE_CLASH,        # Buffs, stances, reactions
	ON_CLASH_START,      # Clash begins
	ON_CLASH_WIN,        # Winner of clash
	ON_CLASH_LOSE,       # Loser of clash
	ON_CLASH_TIE,        # Equal outcome
	AFTER_CLASH,         # Cleanup after clash
	# --- DAMAGE PHASE ---
	BEFORE_DAMAGE,       # Shields, guards, reductions
	ON_DAMAGE_CALC,      # Modify damage number
	ON_HIT,              # Successful hit
	ON_CRIT,             # Critical hit
	ON_BLOCK,            # Damage blocked
	ON_PARRY,            # Perfect defense
	ON_MISS,             # Attack missed
	AFTER_DAMAGE,        # After damage is applied
	# --- DEFENSIVE REACTIONS ---
	ON_GUARD,            # Guard triggered
	ON_COUNTER,          # Counterattack triggered
	ON_REDIRECT,         # Target redirected
	# --- STATUS EFFECTS ---
	BEFORE_STATUS_APPLY, # Resist, immunity checks
	ON_STATUS_APPLY,     # Status applied
	ON_STATUS_TICK,      # Damage/heal over time
	ON_STATUS_EXPIRE,    # Status ends
	# --- RESOURCE MANAGEMENT ---
	ON_RESOURCE_GAIN,    # AP, mana, rage gained
	ON_RESOURCE_SPEND,   # Resource spent
	ON_COOLDOWN_START,   # Skill enters cooldown
	ON_COOLDOWN_END,     # Skill becomes usable
	# --- DEATH & CLEANUP ---
	ON_UNIT_DEFEATED,    # HP reaches zero
	ON_UNIT_REMOVED,     # Removed from field
	AFTER_ACTION,        # Final cleanup
}
# Core properties
@export var name: String
@export var category: Category
@export var scaling: ScalingType
@export var power: float
@export var texture: Texture
@export var cost: int = 1

# Defensive-specific
@export var defensive_type: DefensiveType = DefensiveType.NONE

# Skill-specific
@export var cooldown: int = 0
var current_cooldown: int = 0

# Optional properties
@export var status_effects: Array = []   # Array of Status instances
@export var timing: Timing         # e.g., "On Hit", "Before Clash"
@export var upgrade_unlock_lvl: int = 1
@export var effect_logic: ActionEffect # Or use ActionEffect if you defined that class_name

var owner: Object = null

#func get_scaled_power() -> float:
	#if owner == null:
		#return power  # fallback
#
	#match scaling:
		#ScalingType.PHYSICAL:
			#return power + owner.strength
		#ScalingType.MAGICAL:
			#return power * (1 + owner.intelligence / 100.0)
		#ScalingType.ELEMENTAL:
			## Typically base power; could add specific scaling later
			#return power
