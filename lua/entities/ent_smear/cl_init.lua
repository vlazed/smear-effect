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

function ENT:Think()
	local parent = self:GetParent()
	if IsValid(parent) then
		self:SetColor(parent:GetColor())
	end

	local time = CurTime()
	self.now = self.now or time
	if time > self.now + self:GetLag() then
		self.prevPosition = LerpVector(self:GetLagFactor(), self.prevPosition, self.position)
		self.now = time
	end
	self.position = self:GetBoneMatrix(0):GetTranslation()
end

function ENT:Draw(flags)
	if not self.smearMaterial then
		self:InitializeRenderParams()
		return
	end

	if not self:GetActive() then
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
