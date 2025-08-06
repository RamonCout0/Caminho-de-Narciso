using Godot;
using System;

public partial class movimento : CharacterBody2D
{
	[Export]
	private int speed = 300;

	public override void _PhysicsProcess(double delta)
	{
		// A ordem das chamadas é importante.
		// Primeiro, pegue a entrada e calcule a velocidade.
		handleInput();
		
		// Depois, use a velocidade para mover o personagem.
		MoveAndSlide();
	}
	
	private void handleInput()
	{
		// Obtém um vetor 2D baseado nas entradas do usuário (teclado, controle, etc.).
		Vector2 inputVector = Input.GetVector("mv_esquerdo", "mv_direito", "mv_cima", "mv_baixo");

		// Atribui o vetor de entrada, multiplicado pela velocidade, 
		// à propriedade 'Velocity' do CharacterBody2D.
		Velocity = inputVector * speed;
	}
}
