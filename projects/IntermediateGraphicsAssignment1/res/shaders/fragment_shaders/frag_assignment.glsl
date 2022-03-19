#version 430

#include "../fragments/fs_common_inputs.glsl"
#include "../fragments/frame_uniforms.glsl"

// We output a single color to the color buffer
layout(location = 0) out vec4 frag_color;

////////////////////////////////////////////////////////////////
/////////////// Instance Level Uniforms ////////////////////////
////////////////////////////////////////////////////////////////

// Represents a collection of attributes that would define a material
// For instance, you can think of this like material settings in 
// Unity
struct Material {
	sampler2D Diffuse;
	float     Shininess;
};
// Create a uniform for the material
uniform Material u_Material;

uniform sampler1D s_ToonTerm;

uniform sampler1D s_SpecularRamp;

uniform sampler1D s_DiffuseRamp;

////////////////////////////////////////////////////////////////
///////////// Application Level Uniforms ///////////////////////
////////////////////////////////////////////////////////////////

#define MAX_LIGHTS 8

// Represents a single light source
struct Light {
	vec4  Position;
	// Stores color in RBG and attenuation in w
	vec4  ColorAttenuation;
};

// Our uniform buffer that will store all our lighting data
// so that it can be shared between shaders
layout (std140, binding = 2) uniform b_LightBlock {
	// Stores ambient light color in rgb, and number
	// of lights in w, allowing for easier struct packing
	// on the C++ side
	vec4  AmbientColAndNumLights;

	// Our array of all lights
	Light Lights[MAX_LIGHTS];

	// The rotation of the skybox/environment map
	mat3  EnvironmentRotation;
};

// Uniform for our environment map / skybox, bound to slot 0 by default
uniform layout(binding=15) samplerCube s_EnvironmentMap;

// Samples the environment map at a given direction. Will apply environment
// rotation to the input
// @param normal The direction to sample
// @returns The RGB color that was sampled from the environment map
vec3 SampleEnvironmentMap(vec3 normal) {
	vec3 transformed = EnvironmentRotation * normal;
	return texture(s_EnvironmentMap, transformed).rgb;
}

// Calculates the contribution the given point light has 
// for the current fragment
// @param worldPos  The fragment's position in world space
// @param normal    The fragment's normal (normalized)
// @param viewDir   Direction between camera and fragment
// @param Light     The light to caluclate the contribution for
// @param shininess The specular power for the fragment, between 0 and 1
vec3 CalcPointLightContribution(vec3 worldPos, vec3 normal, vec3 viewDir, Light light, float shininess) {

	
	// Get the direction to the light in world space
	vec3 toLight = light.Position.xyz - worldPos;
	// Get distance between fragment and light
	float dist = length(toLight);
	// Normalize toLight for other calculations
	toLight = normalize(toLight);

	// Halfway vector between light normal and direction to camera
	vec3 halfDir     = normalize(toLight + viewDir);

	
	// Calculate our specular power
	float specPower  = pow(max(dot(normal, halfDir), 0.0), pow(256, shininess));
	// Calculate specular color
	vec3 specularOut = specPower * light.ColorAttenuation.rgb;


	//Attempt using reference https://gamedev.stackexchange.com/questions/51063/what-is-ramp-shading-or-lighting
//	if(u_SpecularWarp == 1){ 
//		float rampCoords  = pow(dot(normal, halfDir) * 0.5 + 0.5, 0.0);
//		vec3 specularOut = texture(s_SpecularRamp,rampCoords).rgb;
//	}

	if(u_SpecularWarp == 1){
		specularOut.r = texture(s_SpecularRamp, specularOut.r).r;
		specularOut.g = texture(s_SpecularRamp, specularOut.g).g;
		specularOut.b = texture(s_SpecularRamp, specularOut.b).b;
	}

	// Calculate diffuse factor
	float diffuseFactor = max(dot(normal, toLight), 0);
	// Calculate diffuse color
	vec3  diffuseOut = diffuseFactor * light.ColorAttenuation.rgb;

	if(u_DiffuseWarp == 1){
		diffuseOut.r = texture(s_DiffuseRamp, diffuseOut.r).r;
		diffuseOut.g = texture(s_DiffuseRamp, diffuseOut.g).g;
		diffuseOut.b = texture(s_DiffuseRamp, diffuseOut.b).b;
	}

	// We'll use a modified distance squared attenuation factor to keep it simple
	// We add the one to prevent divide by zero errors
	float attenuation = clamp(1.0 / (1.0 + light.ColorAttenuation.w * pow(dist, 2)), 0, 1);


	if(u_Option == 3 || u_Option == 4 || u_Option == 5){
		return specularOut * attenuation;
	}
	else{
		return (diffuseOut + specularOut) * attenuation;
	}
//	else if(u_Option == 4 || u_Option == 5){
//		return (diffuseOut + specularOut) * attenuation;
//	}
	//return (diffuseOut + specularOut) * attenuation;
}

/*
 * Calculates the lighting contribution for all lights in the scene
 * for a given fragment
 * @param worldPos The fragment's position in world space
 * @param normal The normalized surface normal for the fragment
 * @param camPos The camera's position in world space
*/
vec3 CalcAllLightContribution(vec3 worldPos, vec3 normal, vec3 camPos, float shininess) {
	// Will accumulate the contributions of all lights on this fragment
	vec3 lightAccumulation = AmbientColAndNumLights.rgb;

	// Direction between camera and fragment will be shared for all lights
	vec3 viewDir  = normalize(camPos - worldPos);
	

	// Iterate over all lights
	for(int ix = 0; ix < AmbientColAndNumLights.w && ix < MAX_LIGHTS; ix++) {
		// Additive lighting model
		lightAccumulation += CalcPointLightContribution(worldPos, normal, viewDir, Lights[ix], shininess);
	}

	return lightAccumulation;
}


////////////////////////////////////////////////////////////////
/////////////// Frame Level Uniforms ///////////////////////////
////////////////////////////////////////////////////////////////

#include "../fragments/color_correction.glsl"

// https://learnopengl.com/Advanced-Lighting/Advanced-Lighting
void main() {


	// Normalize our input normal
	vec3 normal = normalize(inNormal);

	// Use the lighting calculation that we included from our partial file
	vec3 lightAccumulation = CalcAllLightContribution(inWorldPos, normal, u_CamPos.xyz, u_Material.Shininess);


	// Get the albedo from the diffuse / albedo map
	vec4 textureColor = texture(u_Material.Diffuse, inUV);

	// combine for the final result
	vec3 result = lightAccumulation  * inColor * textureColor.rgb;


	if(u_Option == 1){
		frag_color = textureColor;
	}
	else if(u_Option == 2){
		frag_color = vec4(ColorCorrect(AmbientColAndNumLights.rgb * textureColor.rgb), textureColor.a);
	}
//	else if(u_Option == 3){ //Showing Specular as a greyscale
//		frag_color = vec4(ColorCorrect(lightAccumulation), textureColor.a);
//	}
	else if(u_Option == 5 || u_Option == 8){ //Toon Shader State, 5 for Toon Shader + Ambient + Specular only
		result.r = texture(s_ToonTerm, result.r).r;
		result.g = texture(s_ToonTerm, result.g).g;
		result.b = texture(s_ToonTerm, result.b).b;
		frag_color = vec4(ColorCorrect(result), textureColor.a);
	}
	else{ //Otherwise just do the standard Tutorial Shading
		frag_color = vec4(ColorCorrect(result), textureColor.a);
	}
}