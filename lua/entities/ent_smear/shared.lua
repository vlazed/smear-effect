---@class ent_smear: ENT
local ENT = ENT

ENT.Type = "anim"
ENT.Base = "base_anim"

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "NoiseScale")
	self:NetworkVar("Float", 1, "NoiseHeight")
	self:NetworkVar("Float", 2, "Lag")
end

function ENT:Initialize()
	if CLIENT then
		self:SetLOD(0)
		self:SetupBones()
		self:InvalidateBoneCache()
	end
end

function ENT:InitializeRenderParams()
	local parent = self:GetParent()
	self.baseTexture = Material(parent:GetMaterials()[1]):GetTexture("$basetexture")
	self.smearMaterial = VLAZED_SMEAR_GENERATOR:makeSmear(self.baseTexture:GetName())
	self.position = parent:GetPos()
	self.prevPosition = parent:GetPos()
end
