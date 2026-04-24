using Godot;
using System;

public partial class Inimigo : CharacterBody2D
{
	[Export] public float Velocidade = 150.0f;

	// --- SANIDADE ---
	// "Ele Sabe" é uma ameaça direta e persistente.
	[Export] public float TaxaSanidade = 5.0f; // Drenagem de sanidade por segundo (durante perseguição)
	private const string IdAmeaca = "ele_sabe";

	private Node2D _alvo = null;
	private Node _gameManager;
	private AudioStreamPlayer2D _somPerseguicao;
	private AudioStreamPlayer2D _somPassos;
	private Area2D _areaDeteccao;
	private AnimatedSprite2D _anim;

	public override void _Ready()
	{
		_gameManager = GetNode<Node>("/root/GameManager");

		_somPerseguicao = GetNode<AudioStreamPlayer2D>("AudioStreamPlayer2D");
		_somPassos = GetNode<AudioStreamPlayer2D>("SomPassos");
		_areaDeteccao = GetNode<Area2D>("AreaDeteccao");
		_anim = GetNode<AnimatedSprite2D>("AnimatedSprite2D");

		_areaDeteccao.BodyEntered += OnBodyEntered;
		_areaDeteccao.BodyExited += OnBodyExited;
		
		_anim.Play("idle");
	}

	public override void _ExitTree()
	{
		// Garante limpeza ao sair da cena
		_gameManager?.Call("remover_ameaca", IdAmeaca);
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

			// --- SANIDADE: Drena enquanto persegue ---
			_gameManager?.Call("registrar_ameaca", IdAmeaca, TaxaSanidade);

			// --- SOM DE PERSEGUIÇÃO ---
			if (!_somPerseguicao.Playing)
			{
				_somPerseguicao.Play();
			}

			// --- SOM DE PASSOS ---
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

			// --- SANIDADE: Para de drenar quando perde o player ---
			_gameManager?.Call("remover_ameaca", IdAmeaca);

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
