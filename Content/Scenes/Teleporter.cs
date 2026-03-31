using Godot;
using System;

public partial class Teleporter : Area2D
{
	// O [Export] faz o mesmo que o @export do GDScript
	[Export(PropertyHint.File, "*.tscn")]
	public string ProximaCena;

	private bool _playerNaArea = false;

	public override void _Ready()
	{
		// Conectar os sinais via código (opcional, se não conectou pelo Editor)
		BodyEntered += OnBodyEntered;
		BodyExited += OnBodyExited;
	}

	public override void _Process(double delta)
	{
		// Verifica se o jogador está na área e pressionou a tecla
		if (_playerNaArea && Input.IsActionJustPressed("interagir"))
		{
			FazerTeleporte();
		}
	}

	private void OnBodyEntered(Node2D body)
	{
		if (body.IsInGroup("player"))
		{
			_playerNaArea = true;
			GD.Print("Pressione 'E' para entrar");
		}
	}

	private void OnBodyExited(Node2D body)
	{
		if (body.IsInGroup("player"))
		{
			_playerNaArea = false;
		}
	}

	private void FazerTeleporte()
	{
		if (string.IsNullOrEmpty(ProximaCena))
		{
			GD.Print("Erro: Nenhuma cena selecionada!");
			return;
		}

		// No C#, o GetTree() é um método
		GetTree().ChangeSceneToFile(ProximaCena);
	}
	
}
