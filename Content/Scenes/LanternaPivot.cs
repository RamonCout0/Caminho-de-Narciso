using Godot;
using System;

public partial class LanternaPivot : Node2D
{
	public override void _Process(double delta)
	{
		// Apenas gira o braço para o mouse
		LookAt(GetGlobalMousePosition());
	}
}
