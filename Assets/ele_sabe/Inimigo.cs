using Godot;
using System;

public partial class Inimigo : CharacterBody2D
{
	[Export] public float Velocidade = 150.0f;
	
	private Node2D _alvo = null;
	private AudioStreamPlayer2D _somPerseguicao;
	private Area2D _areaDeteccao;
	private AnimatedSprite2D _anim;

	public override void _Ready()
	{
		// Pegando as referências dos nós
		_somPerseguicao = GetNode<AudioStreamPlayer2D>("AudioStreamPlayer2D");
		_areaDeteccao = GetNode<Area2D>("AreaDeteccao"); // Verifique se o nome no Editor está igual!
		_anim = GetNode<AnimatedSprite2D>("AnimatedSprite2D");

		// Conectando os sinais
		_areaDeteccao.BodyEntered += OnBodyEntered;
		_areaDeteccao.BodyExited += OnBodyExited;
		
		// Começa com a animação de parado
		_anim.Play("idle");
	}

	public override void _PhysicsProcess(double delta)
	{
		if (_alvo != null)
		{
			// Movimentação
			Vector2 direcao = (_alvo.GlobalPosition - GlobalPosition).Normalized();
			Velocity = direcao * Velocidade;

			// Inverter o sprite baseado na direção (olhar para esquerda ou direita)
			if (direcao.X != 0)
			{
				_anim.FlipH = direcao.X < 0;
			}

			// Tocar animação de correr (apenas se já não estiver tocando)
			if (_anim.Animation != "run")
			{
				_anim.Play("run");
			}

			// Tocar som de perseguição
			if (!_somPerseguicao.Playing)
			{
				_somPerseguicao.Play();
			}

			MoveAndSlide();
		}
		else
		{
			// Parar o inimigo e trocar animação para idle
			Velocity = Vector2.Zero;
			
			if (_anim.Animation != "idle")
			{
				_anim.Play("idle");
			}

			// Parar o som se o jogador sair da área
			if (_somPerseguicao.Playing)
			{
				_somPerseguicao.Stop();
			}
		}
	}

	private void OnBodyEntered(Node2D body)
	{
		// Certifique-se que seu Player está no grupo "player"
		if (body.IsInGroup("player"))
		{
			_alvo = body;
			GD.Print("Alvo travado!");
		}
	}

	private void OnBodyExited(Node2D body)
	{
		if (body == _alvo)
		{
			_alvo = null;
			GD.Print("Alvo perdido.");
		}
	}
}
