#pragma once
#include "IComponent.h"
#include "Gameplay/Physics/RigidBody.h"

/// <summary>
/// A simple behaviour that applies an impulse along the Z axis to the 
/// rigidbody of the parent when the space key is pressed
/// </summary>
class MovementBehaviour : public Gameplay::IComponent {
public:
	typedef std::shared_ptr<MovementBehaviour> Sptr;

	std::weak_ptr<Gameplay::IComponent> Panel;

	MovementBehaviour();
	virtual ~MovementBehaviour();

	virtual void Awake() override;
	virtual void Update(float deltaTime) override;

public:
	virtual void RenderImGui() override;
	MAKE_TYPENAME(MovementBehaviour);
	virtual nlohmann::json ToJson() const override;
	static MovementBehaviour::Sptr FromJson(const nlohmann::json& blob);

protected:
	float _speed;

	bool _isPressed = false;
	Gameplay::Physics::RigidBody::Sptr _body;
};