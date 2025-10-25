---@class SmearEntity: Entity
---@field smearEnt ent_smear

---@class ent_smear: ENT
---@field GetNoiseScale fun(self: ent_smear): noiseScale: number
---@field GetNoiseHeight fun(self: ent_smear): noiseHeight: number
---@field GetLag fun(self: ent_smear): lag: number
---@field GetTransparency fun(self: ent_smear): transparency: number
---@field GetBrightness fun(self: ent_smear): brightness: number
---@field SetNoiseScale fun(self: ent_smear, noiseScale: number)
---@field SetNoiseHeight fun(self: ent_smear, noiseHeight: number)
---@field SetLag fun(self: ent_smear, lag: number)
---@field SetTransparency fun(self: ent_smear, transparency: number)
---@field SetBrightness fun(self: ent_smear, brightness: number)
---@field GetSmearColor fun(self: ent_smear): smearColor: Vector
---@field SetSmearColor fun(self: ent_smear, smearColor: Vector)
local ENT = ENT

ENT.Type = "anim"
ENT.Base = "base_anim"

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "NoiseScale")
	self:NetworkVar("Float", 1, "NoiseHeight")
	self:NetworkVar("Float", 2, "Lag")
	self:NetworkVar("Float", 3, "Transparency")
	self:NetworkVar("Float", 4, "Brightness")

	self:NetworkVar("Vector", 0, "SmearColor")
end

function ENT:Initialize()
	if CLIENT then
		self:SetLOD(0)
		self:SetupBones()
		self:InvalidateBoneCache()
	end

	self:SetRenderMode(RENDERMODE_TRANSCOLOR)
end

function ENT:InitializeRenderParams()
	local parent = self:GetParent()
	self.baseTexture = Material(parent:GetMaterials()[1]):GetTexture("$basetexture")
	self.smearMaterial = VLAZED_SMEAR_GENERATOR:makeSmear(self.baseTexture:GetName())
	self.position = parent:GetPos()
	self.prevPosition = parent:GetPos()
end
