---@class SmearEntity: Entity
---@field smearEnt ent_smear
---@field Draw fun(self: SmearEntity, flags: number)
---@field smear_oldDraw fun(self: SmearEntity, flags: number)

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
---@field SetNumpadKey fun(self: ent_smear, numpadKey: integer)
---@field SetStartOn fun(self: ent_smear, startOn: boolean)
---@field SetToggle fun(self: ent_smear, toggle: boolean)
---@field GetNumpadKey fun(self: ent_smear): numpadKey: integer
---@field GetStartOn fun(self: ent_smear): startOn: boolean
---@field GetToggle fun(self: ent_smear): toggle: boolean
---@field GetActive fun(self: ent_smear): active: boolean
---@field SetActive fun(self: ent_smear, active: boolean)
local ENT = ENT

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.DoNotDuplicate = true

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "NoiseScale")
	self:NetworkVar("Float", 1, "NoiseHeight")
	self:NetworkVar("Float", 2, "Lag")
	self:NetworkVar("Float", 3, "Transparency")
	self:NetworkVar("Float", 4, "Brightness")

	self:NetworkVar("Int", 0, "NumpadKey")

	self:NetworkVar("Bool", 0, "Toggle")
	self:NetworkVar("Bool", 1, "Active")

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

---@param ent Entity
---@return IMaterial
local function getMaterial(ent)
	---TODO: Remove the diagnostic once the new skin argument is added in main branch
	---INFO: GetSkin argument only works in x86_64 branch
	---@diagnostic disable-next-line
	local meshData = util.GetModelMeshes(ent:GetModel(), 0, nil, ent:GetSkin())
	local material = Material(meshData[1].material)
	return material
end

function ENT:InitializeRenderParams()
	local parent = self:GetParent()
	local targetMaterial = #parent:GetMaterial() > 0 and Material(parent:GetMaterial()) or getMaterial(parent)
	self.baseTexture = targetMaterial:GetTexture("$basetexture")
	self.smearMaterial = VLAZED_SMEAR_GENERATOR:makeSmear(self.baseTexture:GetName())

	self.position = parent:GetPos()
	self.prevPosition = parent:GetPos()
end
