include("shared.lua")

---@class ent_smear: ENT
local ENT = ENT

local dummy_model = ClientsideModel("models/shadertest/vertexlit.mdl")
dummy_model:SetModelScale(0) -- make it invisible
---@param self ent_smear
local function vertexMetadata(self, flags)
	render.OverrideDepthEnable(true, true)
	render.SuppressEngineLighting(true)

	-- print(self:GetNoiseScale(), self:GetNoiseHeight())
	render.SetModelLighting(0, self.position.x, self.position.y, self.position.z)
	render.SetModelLighting(1, self.prevPosition.x, self.prevPosition.y, self.prevPosition.z)
	render.SetModelLighting(2, self:GetNoiseScale(), self:GetNoiseHeight(), CurTime())

	dummy_model:DrawModel()

	render.SuppressEngineLighting(false)
	render.OverrideDepthEnable(false, false)
end

function ENT:Think()
	local parent = self:GetParent()
	if not IsValid(parent) then
		return
	end

	local time = CurTime()
	self.now = self.now or time
	if time > self.now + self:GetLag() then
		self.prevPosition = self.position
		self.now = time
	end
	self.position = parent:GetPos()
end

function ENT:Draw(flags)
	if not self.smearMaterial then
		self:InitializeRenderParams()
		return
	end

	self:SetMaterial("!" .. self.smearMaterial:GetName())
	-- render.SetMaterial(self.smearMaterial)
	vertexMetadata(self, flags)
	self:DrawModel()
	-- render.DrawSphere(self.position, 20, 5, 5)
end

function ENT:DrawTranslucent(flags)
	self:Draw(flags)
end
