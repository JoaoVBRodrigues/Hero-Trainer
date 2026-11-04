class_name EconomyService
extends RefCounted

const ITEM_IDS: Array[StringName] = [
	&"training_notebook",
	&"recovery_kit",
	&"focus_aid",
]
const ITEM_CATALOG: Array[Dictionary] = [
	{
		"id": "training_notebook",
		"name": "Caderno de treino",
		"description": "Reduz em 2 o custo de energia dos treinos, até o mínimo de 8.",
		"price": 80,
	},
	{
		"id": "recovery_kit",
		"name": "Kit de recuperação",
		"description": "Descanso recupera 5 de energia adicional.",
		"price": 120,
	},
	{
		"id": "focus_aid",
		"name": "Auxílio de foco",
		"description": "Reduz em 1 o aumento de estresse dos treinos, até o mínimo de 0.",
		"price": 160,
	},
]

var _actions_per_week: int = 3


func set_actions_per_week(actions_per_week: int) -> void:
	if actions_per_week < 1:
		push_error("A quantidade de ações semanais precisa ser positiva.")
		return
	_actions_per_week = actions_per_week


func get_catalog() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item: Dictionary in ITEM_CATALOG:
		result.append(item.duplicate(true))
	return result


func get_item(item_id: StringName) -> Dictionary:
	for item: Dictionary in ITEM_CATALOG:
		if StringName(item["id"]) == item_id:
			return item.duplicate(true)
	return {}


func validate_state(state: TrainingState) -> String:
	if state == null:
		return "O estado da campanha não está disponível."
	if state.credits < 0:
		return "Os créditos não podem ser negativos."
	var seen: Dictionary[StringName, bool] = {}
	for item_id: StringName in state.inventory:
		if not ITEM_IDS.has(item_id):
			return "O inventário contém um item desconhecido: %s." % item_id
		if seen.has(item_id):
			return "O inventário contém o item duplicado: %s." % item_id
		seen[item_id] = true
	if (
		state.equipped_item_id != &""
		and (
			not ITEM_IDS.has(state.equipped_item_id)
			or not seen.has(state.equipped_item_id)
		)
	):
		return "O equipamento ativo precisa existir no inventário."
	return ""


func purchase_item(state: TrainingState, item_id: StringName) -> String:
	var validation_error: String = validate_state(state)
	if not validation_error.is_empty():
		return validation_error
	var item: Dictionary = get_item(item_id)
	if item.is_empty():
		return "Este item não pertence ao catálogo."
	if state.inventory.has(item_id):
		return "Este item já foi comprado nesta campanha."
	var price: int = int(item["price"])
	if state.credits < price:
		return "Créditos insuficientes: são necessários %d e há %d." % [
			price,
			state.credits,
		]

	var candidate: TrainingState = state.duplicate_state()
	candidate.credits -= price
	candidate.inventory.append(item_id)
	state.copy_from(candidate)
	return ""


func equip_item(state: TrainingState, item_id: StringName) -> String:
	var validation_error: String = validate_state(state)
	if not validation_error.is_empty():
		return validation_error
	if item_id != &"" and not ITEM_IDS.has(item_id):
		return "Este item não pertence ao catálogo."
	if item_id != &"" and not state.inventory.has(item_id):
		return "Compre o item antes de equipá-lo."
	if item_id == state.equipped_item_id:
		return ""
	if state.actions_remaining != _actions_per_week:
		return "O equipamento só pode ser trocado antes da primeira ação da semana."

	var candidate: TrainingState = state.duplicate_state()
	candidate.equipped_item_id = item_id
	state.copy_from(candidate)
	return ""
