extends Node2D

func _ready():
	# 1. Espera um frame para garantir que tudo carregou
	await get_tree().process_frame
	
	# 2. Busca o nó de forma segura
	var luz_da_fase = find_child("CanvasModulate", true, false)
	
	# 3. Verifica se o nó existe ANTES de tentar mudar a cor
	if luz_da_fase:
		# Verifica se a variável existe no GameManager para não travar
		if "cor_da_luz" in GameManager:
			luz_da_fase.color = GameManager.cor_da_luz
		else:
			print("ERRO: A variável 'cor_da_luz' não foi criada no GameManager.gd!")
	else:
		print("AVISO: CanvasModulate não encontrado nesta cena. Adicione um para o efeito funcionar.")
