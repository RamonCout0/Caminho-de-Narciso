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
		currentVelocity = Input.GetVector("mv_left", "mv_right", "mv_up", "mv_down");
		currentVelocity *= speed;
	}
}
