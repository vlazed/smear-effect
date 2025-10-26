include("shared.lua")

---@class ent_smear: ENT
local ENT = ENT

local dummy_model = ClientsideModel("models/shadertest/vertexlit.mdl")
dummy_model:SetModelScale(0) -- make it invisible
---@param self ent_smear
local function vertexMetadata(self, flags)
	render.OverrideDepthEnable(true, true)
	render.SuppressEngineLighting(true)

	render.SetModelLighting(0, self.position.x, self.position.y, self.position.z)
	render.SetModelLighting(1, self.prevPosition.x, self.prevPosition.y, self.prevPosition.z)
	render.SetModelLighting(2, self:GetNoiseScale(), self:GetNoiseHeight(), CurTime())

	dummy_model:DrawModel()

	render.SuppressEngineLighting(false)
	render.OverrideDepthEnable(false, false)
end

local function getAncestor(ent)
	local root = ent
	local parent = ent:GetParent()
	while IsValid(parent) do
		root = parent
		parent = root:GetParent()
	end

	return root
end

function ENT:Think()
	self.parent = self.parent or getAncestor(self)
	if not IsValid(self.parent) then
		return
	end

	local time = CurTime()
	self.now = self.now or time
	if time > self.now + self:GetLag() then
		self.prevPosition = self.position
		self.now = time
	end
	self.position = self.parent:GetPos()
end

function ENT:Draw(flags)
	if not self.smearMaterial then
		self:InitializeRenderParams()
		return
	end

	local color = self:GetSmearColor()
	self.smearMaterial:SetFloat("$c0_x", color.x)
	self.smearMaterial:SetFloat("$c0_y", color.y)
	self.smearMaterial:SetFloat("$c0_z", color.z)
	self.smearMaterial:SetFloat("$c0_w", self:GetTransparency())
	self.smearMaterial:SetFloat("$c1_x", self:GetBrightness())
	self:SetMaterial("!" .. self.smearMaterial:GetName())
	-- render.SetMaterial(self.smearMaterial)
	vertexMetadata(self, flags)
	self:DrawModel(flags)
	-- render.DrawSphere(self.position, 20, 5, 5)
end

function ENT:DrawTranslucent(flags)
	self:Draw(flags)
end
