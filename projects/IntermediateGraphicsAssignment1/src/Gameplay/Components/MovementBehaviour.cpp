#include "Gameplay/Components/MovementBehaviour.h"
#include <GLFW/glfw3.h>
#include "Gameplay/GameObject.h"
#include "Gameplay/Scene.h"
#include "Utils/ImGuiHelper.h"
#include "Gameplay/InputEngine.h"

void MovementBehaviour::Awake()
{
	_body = GetComponent<Gameplay::Physics::RigidBody>();
	if (_body == nullptr) {
		IsEnabled = false;
	}
}

void MovementBehaviour::RenderImGui() {
	LABEL_LEFT(ImGui::DragFloat, "Speed", &_speed, 1.0f);
}

nlohmann::json MovementBehaviour::ToJson() const {
	return {
		{ "speed", _speed }
	};
}

MovementBehaviour::MovementBehaviour() :
	IComponent(),
	_speed(0.05f)
{ }

MovementBehaviour::~MovementBehaviour() = default;

MovementBehaviour::Sptr MovementBehaviour::FromJson(const nlohmann::json & blob) {
	MovementBehaviour::Sptr result = std::make_shared<MovementBehaviour>();
	result->_speed = blob["speed"];
	return result;
}

void MovementBehaviour::Update(float deltaTime) {
	if (!InputEngine::IsMouseButtonDown(GLFW_MOUSE_BUTTON_LEFT)) {
		if (InputEngine::GetKeyState(GLFW_KEY_W) == ButtonState::Down) {
			_body->ApplyImpulse(glm::vec3(0.0f, _speed, 0.0f));
		}
		else if (InputEngine::GetKeyState(GLFW_KEY_A) == ButtonState::Down) {
			_body->ApplyImpulse(glm::vec3(-_speed, 0.0f, 0.0f));
		}
		else if (InputEngine::GetKeyState(GLFW_KEY_S) == ButtonState::Down) {
			_body->ApplyImpulse(glm::vec3(0.0f, -_speed, 0.0f));
		}
		else if (InputEngine::GetKeyState(GLFW_KEY_D) == ButtonState::Down) {
			_body->ApplyImpulse(glm::vec3(_speed, 0.0f, 0.0f));
		}
	}
}

