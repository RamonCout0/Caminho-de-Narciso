using Godot;
using System;

public partial class Teleporter : Area2D
{
	[Export(PropertyHint.File, "*.tscn")]
	public string ProximaCena;

	public override void _Ready()
	{
		// Conectamos apenas o sinal de entrada
		BodyEntered += OnBodyEntered;
	}

	private void OnBodyEntered(Node2D body)
	{
		// Assim que algo entra, verificamos se é o player
		if (body.IsInGroup("player"))
		{
			FazerTeleporte();
		}
	}

	private void FazerTeleporte()
	{
		if (string.IsNullOrEmpty(ProximaCena))
		{
			GD.PrintErr("Erro: Nenhuma cena selecionada para o teleporte!");
			return;
		}

		// Muda a cena instantaneamente
		GetTree().ChangeSceneToFile(ProximaCena);
	}
}
