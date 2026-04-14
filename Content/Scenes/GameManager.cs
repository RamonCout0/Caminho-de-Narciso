using Godot;

public partial class GameManager : Node
{
	// Armazena a posição para onde o player deve ir na próxima cena
	public Vector2 ProximaPosicaoPlayer { get; set; }
	
	// Flag para saber se o player deve ser movido (evita mover no início do jogo)
	public bool UsarPosicaoSalva { get; set; } = false;
}
