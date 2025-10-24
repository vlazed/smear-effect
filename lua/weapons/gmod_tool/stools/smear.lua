TOOL.Category = "Render"
TOOL.Name = "#tool.smear.name"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar["noisescale"] = 15
TOOL.ClientConVar["noiseheight"] = 1.3
TOOL.ClientConVar["lag"] = 0.1
TOOL.ClientConVar["transparency"] = 0

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

		-- smearEnt:AddEffects(EF_BONEMERGE_FASTCULL)
		entity.smearEnt = smearEnt
	end
	smearEnt:SetNoiseScale(self:GetClientNumber("noisescale"))
	smearEnt:SetNoiseHeight(self:GetClientNumber("noiseheight"))
	smearEnt:SetLag(self:GetClientNumber("lag"))
	smearEnt:SetTransparency(self:GetClientNumber("transparency"))

	return true
end

---Copy an entity's smear parameters, if it has a smear entity
---@param tr table|TraceResult
---@return boolean
function TOOL:RightClick(tr)
	local entity = tr.Entity
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
		ply:ConCommand("smear_transparency" .. smearEnt:GetTransparency())
	end

	return true
end

if SERVER then
	return
end

TOOL:BuildConVarList()

---@param cPanel ControlPanel|DForm
function TOOL.BuildCPanel(cPanel)
	cPanel:NumSlider("#tool.smear.noisescale", "smear_noisescale", 0, 30, 3)
	cPanel:NumSlider("#tool.smear.noiseheight", "smear_noiseheight", 0, 10, 3)
	cPanel:NumSlider("#tool.smear.lag", "smear_lag", 0, 2, 5)
	cPanel:NumSlider("#tool.smear.transparency", "smear_transparency", 0, 1, 5)
end

TOOL.Information = {
	{ name = "left", stage = 0 },
	{ name = "left_1", stage = 1, op = 2 },
	{ name = "right", stage = 0 },
	{ name = "reload" },
}
