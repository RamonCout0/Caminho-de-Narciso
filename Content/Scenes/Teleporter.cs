using Godot;

public partial class Teleporter : Area2D
{
	[Export(PropertyHint.File, "*.tscn")]
	public string ProximaCena;

	public override void _Ready()
	{
		BodyEntered += OnBodyEntered;
	}

	private void OnBodyEntered(Node2D body)
	{
		if (body.IsInGroup("player"))
		{
			// Usa CallDeferred para não quebrar o callback de física
			CallDeferred(MethodName.FazerTeleporte);
		}
	}

	private void FazerTeleporte()
	{
		if (string.IsNullOrEmpty(ProximaCena))
		{
			GD.PrintErr("Erro: Nenhuma cena selecionada para o teleporte!");
			return;
		}

		GetTree().ChangeSceneToFile(ProximaCena);
	}
}
