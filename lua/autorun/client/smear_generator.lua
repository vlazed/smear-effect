VLAZED_SMEAR_GENERATOR = VLAZED_SMEAR_GENERATOR or {}

VLAZED_SMEAR_GENERATOR.count = VLAZED_SMEAR_GENERATOR.count or 0
VLAZED_SMEAR_GENERATOR.trailCount = VLAZED_SMEAR_GENERATOR.trailCount or 0

---@param baseTexture string
---@return IMaterial
function VLAZED_SMEAR_GENERATOR:makeSmear(baseTexture)
	self.count = self.count + 1
	return CreateMaterial("smear_" .. self.count, "screenspace_general", {
		["$vertexshader"] = "vlazed_smear_vs30",
		["$pixshader"] = "vlazed_smear_ps30",
		["$basetexture"] = baseTexture,
		["$model"] = 1,
		["$cull"] = 1,
		-- ["$vertextransform"] = 1,
		["$depthtest"] = 1,
		["$alphablend"] = 1,
		["$alpha_blend"] = 1,
		["$vertexnormal"] = 1,
		["$c0_x"] = 1,
		["$c0_y"] = 1,
		["$c0_z"] = 1,
		["$c0_w"] = 1,
		["$c1_x"] = 1,
	})
end

---@param baseTexture string
---@return IMaterial
function VLAZED_SMEAR_GENERATOR:makeSmearTrail(baseTexture)
	self.trailCount = self.trailCount + 1
	return CreateMaterial("smear_trail_" .. self.trailCount, "UnlitGeneric", {
		["$basetexture"] = "color/white",
		["$model"] = 1,
		["$alphatest"] = 1,
		["$translucent"] = 1,
		["$color2"] = "{255 255 255}",
		["$blendtintbybasealpha"] = 1,
		["$blendtintcoloroverbase"] = 0,
		["Proxies"] = {
			["invis"] = {},

			["ItemTintColor"] = {
				["resultVar"] = "$colortint_tmp",
			},
			["SelectFirstIfNonZero"] = {
				["srcVar1"] = "$colortint_tmp",
				["srcVar2"] = "$colortint_base",
				["resultVar"] = "$color2",
			},
		},
	})
end
