using Godot;
using System;

public partial class Inimigo : CharacterBody2D
{
	[Export] public float Velocidade = 150.0f;
	
	private Node2D _alvo = null;
	private AudioStreamPlayer2D _somPerseguicao;
	private Area2D _areaDeteccao;

	public override void _Ready()
	{
		_somPerseguicao = GetNode<AudioStreamPlayer2D>("AudioStreamPlayer2D");
		_areaDeteccao = GetNode<Area2D>("AreaDeteccao");

		// Conecta os sinais de detecção
		_areaDeteccao.BodyEntered += OnBodyEntered;
		_areaDeteccao.BodyExited += OnBodyExited;
	}

	public override void _PhysicsProcess(double delta)
	{
		if (_alvo != null)
		{
			// Calcula a direção para o jogador
			Vector2 direcao = ( _alvo.GlobalPosition - GlobalPosition ).Normalized();
			Velocity = direcao * Velocidade;

			// Toca o som se não estiver tocando
			if (!_somPerseguicao.Playing)
			{
				_somPerseguicao.Play();
			}

			MoveAndSlide();
		}
		else
		{
			// Para o som se o jogador fugir
			if (_somPerseguicao.Playing)
			{
				_somPerseguicao.Stop();
			}
		}
	}

	private void OnBodyEntered(Node2D body)
	{
		if (body.IsInGroup("player"))
		{
			_alvo = body;
			GD.Print("Jogador detectado! Iniciando perseguição.");
		}
	}

	private void OnBodyExited(Node2D body)
	{
		if (body == _alvo)
		{
			_alvo = null;
			GD.Print("O jogador escapou.");
		}
	}
}
