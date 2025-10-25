TOOL.Category = "Render"
TOOL.Name = "#tool.smear.name"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar["noisescale"] = 15
TOOL.ClientConVar["noiseheight"] = 130
TOOL.ClientConVar["lag"] = 0.1
TOOL.ClientConVar["color_r"] = 255
TOOL.ClientConVar["color_g"] = 255
TOOL.ClientConVar["color_b"] = 255
TOOL.ClientConVar["color_a"] = 255
TOOL.ClientConVar["brightness"] = 1

local firstReload = true
function TOOL:Think()
	if CLIENT and firstReload then
		self:RebuildControlPanel()
		firstReload = false
	end
end

---Remove the smear entity
---@param tr table|TraceResult
---@return boolean
function TOOL:Reload(tr)
	local entity = tr.Entity
	---@cast entity SmearEntity
	if not IsValid(entity) or entity:IsPlayer() then
		return false
	end

	local smearEnt = entity.smearEnt
	if IsValid(smearEnt) then
		smearEnt:Remove()
	end

	return true
end

function TOOL:Holster()
	self:ClearObjects()
end

---Add a smear entity, or update the entity's smear parameters
---@param tr table|TraceResult
---@return boolean
function TOOL:LeftClick(tr)
	local entity = tr.Entity
	---@cast entity SmearEntity
	if not IsValid(entity) or entity:IsPlayer() then
		return false
	end

	local smearEnt = entity.smearEnt
	if not IsValid(smearEnt) then
		---@diagnostic disable-next-line
		smearEnt = ents.Create("ent_smear")
		---@cast smearEnt ent_smear
		smearEnt:SetModel(entity:GetModel())
		smearEnt:SetSkin(entity:GetSkin())
		for i = 0, entity:GetNumBodyGroups() do
			smearEnt:SetBodygroup(i, entity:GetBodygroup(i))
		end
		smearEnt:Spawn()

		smearEnt:SetParent(entity, 0)

		smearEnt:SetMoveType(MOVETYPE_NONE)
		smearEnt:SetSolid(SOLID_NONE)
		smearEnt:SetLocalPos(vector_origin)
		smearEnt:SetLocalAngles(angle_zero)

		smearEnt:AddEffects(EF_BONEMERGE)
		smearEnt:AddEffects(EF_BONEMERGE_FASTCULL)
		for i = 0, entity:GetBoneCount() do
			if smearEnt:GetManipulateBoneScale(i) ~= entity:GetManipulateBoneScale(i) then
				entity:ManipulateBoneScale(i, smearEnt:GetManipulateBoneScale(i))
			end
			if smearEnt:GetManipulateBoneAngles(i) ~= entity:GetManipulateBoneAngles(i) then
				entity:ManipulateBoneAngles(i, smearEnt:GetManipulateBoneAngles(i))
			end
			if smearEnt:GetManipulateBonePosition(i) ~= entity:GetManipulateBonePosition(i) then
				entity:ManipulateBonePosition(i, smearEnt:GetManipulateBonePosition(i))
			end
			if smearEnt:GetManipulateBoneJiggle(i) ~= entity:GetManipulateBoneJiggle(i) then
				entity:ManipulateBoneJiggle(i, smearEnt:GetManipulateBoneJiggle(i))
			end
		end

		entity.smearEnt = smearEnt
	end
	smearEnt:SetSmearColor(
		Color(
			self:GetClientNumber("color_r", 255),
			self:GetClientNumber("color_g", 255),
			self:GetClientNumber("color_b", 255)
		):ToVector()
	)
	smearEnt:SetBrightness(self:GetClientNumber("brightness", 1))
	smearEnt:SetNoiseScale(self:GetClientNumber("noisescale"))
	smearEnt:SetNoiseHeight(self:GetClientNumber("noiseheight"))
	smearEnt:SetLag(self:GetClientNumber("lag"))
	smearEnt:SetTransparency(self:GetClientNumber("color_a", 255) / 255)

	return true
end

---Copy an entity's smear parameters, if it has a smear entity
---@param tr table|TraceResult
---@return boolean
function TOOL:RightClick(tr)
	local entity = tr.Entity
	---@cast entity SmearEntity
	if not IsValid(entity) then
		return false
	end

	if CLIENT then
		return true
	end

	local ply = self:GetOwner()

	if IsValid(entity.smearEnt) then
		---@type ent_smear
		local smearEnt = entity.smearEnt
		ply:ConCommand("smear_noisescale" .. smearEnt:GetNoiseScale())
		ply:ConCommand("smear_noiseheight" .. smearEnt:GetNoiseHeight())
		ply:ConCommand("smear_lag" .. smearEnt:GetLag())
		ply:ConCommand("smear_color_a" .. smearEnt:GetTransparency() * 255)

		local color = smearEnt:GetSmearColor() * 255
		ply:ConCommand("smear_color_r" .. color.x)
		ply:ConCommand("smear_color_g" .. color.y)
		ply:ConCommand("smear_color_b" .. color.z)
	end

	return true
end

if SERVER then
	return
end

local cvarList = TOOL:BuildConVarList()

---Helper for DForm
---@param cPanel ControlPanel|DForm
---@param name string
---@param type "ControlPanel"|"DForm"
---@return ControlPanel|DForm
local function makeCategory(cPanel, name, type)
	---@type DForm|ControlPanel
	local category = vgui.Create(type, cPanel)

	category:SetLabel(name)
	cPanel:AddItem(category)
	return category
end

---@param cPanel ControlPanel|DForm
function TOOL.BuildCPanel(cPanel)
	cPanel:ToolPresets("vlazed_smear", cvarList)

	local colorCategory = makeCategory(cPanel, "#tool.smear.color", "ControlPanel")
	colorCategory:SetExpanded(true)
	colorCategory:ColorPicker(
		"#tool.smear.colorpicker",
		"smear_color_r",
		"smear_color_g",
		"smear_color_b",
		"smear_color_a"
	)
	colorCategory
		:NumSlider("#tool.smear.brightness", "smear_brightness", 0, 10, 3)
		:SetTooltip("#tool.smear.brightness.tooltip")

	local smearShapeCategory = makeCategory(cPanel, "#tool.smear.shape", "ControlPanel")
	smearShapeCategory:SetExpanded(true)
	smearShapeCategory
		:NumSlider("#tool.smear.noisescale", "smear_noisescale", 0, 30, 3)
		:SetTooltip("#tool.smear.noisescale.tooltip")
	smearShapeCategory
		:NumSlider("#tool.smear.noiseheight", "smear_noiseheight", 0, 1000, 3)
		:SetTooltip("#tool.smear.noiseheight.tooltip")
	smearShapeCategory:NumSlider("#tool.smear.lag", "smear_lag", 0, 2, 5):SetTooltip("#tool.smear.lag.tooltip")
end

TOOL.Information = {
	{ name = "left", stage = 0 },
	{ name = "right", stage = 0 },
	{ name = "reload" },
}
