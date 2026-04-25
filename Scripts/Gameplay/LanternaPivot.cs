using Godot;

public partial class LanternaPivot : Node2D
{
	public override void _Process(double delta)
	{
		// Converte posição do mouse na tela para coordenadas do mundo
		Vector2 mouseScreen = GetViewport().GetMousePosition();
		Vector2 mouseWorld = GetCanvasTransform().AffineInverse() * mouseScreen;
		
		LookAt(mouseWorld);
		Rotation -= Mathf.Pi / 2f;
	}
}
