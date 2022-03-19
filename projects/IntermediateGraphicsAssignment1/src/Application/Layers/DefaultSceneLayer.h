#pragma once
#include "Application/ApplicationLayer.h"
#include "json.hpp"
#include "Gameplay/Scene.h"

/**
 * This example layer handles creating a default test scene, which we will use 
 * as an entry point for creating a sample scene
 */
class DefaultSceneLayer final : public ApplicationLayer {
public:
	MAKE_PTRS(DefaultSceneLayer)

	DefaultSceneLayer();
	virtual ~DefaultSceneLayer();

	// Inherited from ApplicationLayer

	virtual void OnAppLoad(const nlohmann::json& config) override;
	virtual void OnUpdate() override;

protected:
	void _CreateScene();

	Gameplay::Scene::Sptr _scene;

	Texture3D::Sptr coolLUT;
	Texture3D::Sptr warmLUT;
	Texture3D::Sptr customLUT;

	bool warmEnabled = false;
	bool coolEnabled = false;
	bool customEnabled = false;

	bool diffuseWrapEnabled = false;
	bool specularWrapEnabled = false;
};