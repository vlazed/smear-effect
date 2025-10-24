VLAZED_SMEAR_GENERATOR = VLAZED_SMEAR_GENERATOR or {}

VLAZED_SMEAR_GENERATOR.count = VLAZED_SMEAR_GENERATOR.count or 0

---@param baseTexture string
---@return IMaterial
function VLAZED_SMEAR_GENERATOR:makeSmear(baseTexture)
	self.count = self.count + 1
	return CreateMaterial("smear_" .. self.count, "screenspace_general", {
		["$vertexshader"] = "vlazed_smear_vs30",
		["$pixshader"] = "vlazed_smear_ps30",
		["$basetexture"] = baseTexture,
		["$softwareskin"] = 1,
		["$nodecal"] = 1,
		["$translucent"] = 1,
		["$model"] = 1,
		["$ignorez"] = 0,
		["$vertexcolor"] = 0,
		["$vertexnormal"] = 1,
		["$vertextransform"] = 1,
		["$cull"] = 1,
		["$depthtest"] = 1,
		["$writedepth"] = 0,
		["$writealpha"] = 0,
		["$copyalpha"] = 0,
		["$alphablend"] = 1,
		["$alpha_blend"] = 1,
		["$c0_x"] = 0,
	})
end
