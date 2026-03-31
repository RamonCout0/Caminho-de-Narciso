using Godot;
using System;

public partial class Inimigo : CharacterBody2D
{
	[Export] public float Velocidade = 150.0f;
	
	private Node2D _alvo = null;
	private AudioStreamPlayer2D _somPerseguicao;
	private AudioStreamPlayer2D _somPassos; // Novo nó para passos
	private Area2D _areaDeteccao;
	private AnimatedSprite2D _anim;

	public override void _Ready()
	{
		// Referências dos nós
		_somPerseguicao = GetNode<AudioStreamPlayer2D>("AudioStreamPlayer2D");
		_somPassos = GetNode<AudioStreamPlayer2D>("SomPassos"); // Nome que você deu no Editor
		_areaDeteccao = GetNode<Area2D>("AreaDeteccao");
		_anim = GetNode<AnimatedSprite2D>("AnimatedSprite2D");

		_areaDeteccao.BodyEntered += OnBodyEntered;
		_areaDeteccao.BodyExited += OnBodyExited;
		
		_anim.Play("idle");
	}

	public override void _PhysicsProcess(double delta)
	{
		if (_alvo != null)
		{
			Vector2 direcao = (_alvo.GlobalPosition - GlobalPosition).Normalized();
			Velocity = direcao * Velocidade;

			if (direcao.X != 0)
			{
				_anim.FlipH = direcao.X < 0;
			}

			if (_anim.Animation != "run")
			{
				_anim.Play("run");
			}

			// --- LÓGICA DO SOM DE PERSEGUIÇÃO (SUSPENSE/ROSNADO) ---
			if (!_somPerseguicao.Playing)
			{
				_somPerseguicao.Play();
			}

			// --- LÓGICA DO SOM DE PASSOS ---
			// Toca se estiver se movendo e o som de passo anterior acabou
			if (Velocity.Length() > 10 && !_somPassos.Playing)
			{
				_somPassos.PitchScale = (float)GD.RandRange(0.8, 1.2);
				_somPassos.Play();
			}

			MoveAndSlide();
		}
		else
		{
			Velocity = Vector2.Zero;
			
			if (_anim.Animation != "idle")
			{
				_anim.Play("idle");
			}

			// Para ambos os sons quando perde o alvo
			if (_somPerseguicao.Playing) _somPerseguicao.Stop();
			if (_somPassos.Playing) _somPassos.Stop();
		}
	}

	private void OnBodyEntered(Node2D body)
	{
		if (body.IsInGroup("player"))
		{
			_alvo = body;
			GD.Print("Inimigo avistou o player! Iniciando perseguição.");
		}
	}

	private void OnBodyExited(Node2D body)
	{
		if (body == _alvo)
		{
			_alvo = null;
			GD.Print("Player escapou.");
		}
	}
}
