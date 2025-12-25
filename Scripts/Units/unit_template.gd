extends Resource
class_name UnitTemplate

enum Faction {ALLY, ENEMY}

# Identity
@export var unit_name: String = "New Unit"
@export var faction_type: Faction = Faction.ALLY # Use the enum value or a String

# Core stats (base values)
@export var vitality: int = 10
@export var strength: int = 5
@export var intelligence: int = 5
@export var defence: int = 7
@export var agility: int = 3

# ... (Export all base stats)

# Default Action Resources (Preload the .tres files here)
@export var default_attacks: Array[Action] = []
@export var default_defensives: Array[Action] = []
@export var default_skills: Array[Action] = []
