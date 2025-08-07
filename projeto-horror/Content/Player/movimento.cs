using Godot;
using System;

public partial class movimento : CharacterBody2D
{
	[Export]
	private int speed = 300;
	private Vector2 currentVelocity;

	public override void _PhysicsProcess(double delta)
	{
		base._PhysicsProcess(delta);
		handleInput();
		MoveAndSlide();
		Velocity = currentVelocity;

	}
	private void handleInput()
	{
		currentVelocity = Input.GetVector("mv_esquerdo", "mv_direito", "mv_cima", "mv_baixo");
		currentVelocity *= speed;
	}
}
