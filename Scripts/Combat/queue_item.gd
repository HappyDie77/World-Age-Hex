extends RefCounted
class_name QueueItem

var unit_node: UnitNode # The CharacterBody3D node performing the action
var action: Action      # The cloned Action Resource instance
var target_node: UnitNode # The CharacterBody3D target of the action
var cost: int = 1       # Default action cost
