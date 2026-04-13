AddCSLuaFile()

---@class SmearTrailPhysicsAttachment
---@field pos Vector local position with respect to the bone
---@field boneName string name of the bone that we're attached to

---@class ent_smear_trail: ENT
---@field SetSmearType fun(self: ent_smear_trail, smearType: SmearTrailType)
---@field GetSmearType fun(self: ent_smear_trail): smearType: SmearTrailType
---@field SetSegments fun(self: ent_smear_trail, segments: integer)
---@field GetSegments fun(self: ent_smear_trail): segments: integer
---@field SetSmearMaterial fun(self: ent_smear_trail, material: string)
---@field GetSmearMaterial fun(self: ent_smear_trail): material: string
---@field SetUpdateInterval fun(self: ent_smear_trail, updateInterval: number)
---@field GetUpdateInterval fun(self: ent_smear_trail): updateInterval: number
---@field SetLag fun(self: ent_smear_trail, lag: number)
---@field GetLag fun(self: ent_smear_trail): lag: number
---@field SetActive fun(self: ent_smear_trail, active: boolean)
---@field GetActive fun(self: ent_smear_trail): active: boolean
---@field SetToggle fun(self: ent_smear_trail, toggle: boolean)
---@field GetToggle fun(self: ent_smear_trail): toggle: boolean
---@field SetStartOn fun(self: ent_smear_trail, StartOn: boolean)
---@field GetStartOn fun(self: ent_smear_trail): StartOn: boolean
---@field SetNumpadKey fun(self: ent_smear_trail, numpadKey: integer)
---@field GetNumpadKey fun(self: ent_smear_trail): numpadKey: integer
---@field SetSmearColor fun(self: ent_smear_trail, smearColor: Vector)
---@field GetSmearColor fun(self: ent_smear_trail): smearColor: Vector
---@field SetMaxVerts fun(self: ent_smear_trail, maxVerts: integer)
---@field GetMaxVerts fun(self: ent_smear_trail): maxVerts: integer
local ENT = ENT

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "Smear Trail"
ENT.Author = "vlazed"

ENT.Purpose = ""
ENT.Instructions = ""

---@param slot integer?
---@return fun(): integer
local function orderer(slot)
	slot = slot or 32
	local i = -1
	return function()
		i = i + 1
		if i < slot then
			return i
		else
			error("Went beyond slot")
		end
	end
end

function ENT:ValidateMaterial(materialString)
	local newMaterial = Material(tostring(materialString))
	if newMaterial and not newMaterial:IsError() then
		self.material:SetTexture("$basetexture", newMaterial:GetTexture("$basetexture"))
	end
end

function ENT:SetupDataTables()
	local intOrder = orderer()
	local floatOrder = orderer()
	local stringOrder = orderer()
	local vectorOrder = orderer()
	local booleanOrder = orderer()

	self:NetworkVar("Int", intOrder(), "Segments")
	self:NetworkVar("Int", intOrder(), "SmearType")
	self:NetworkVar("Int", intOrder(), "MaxVerts")
	self:NetworkVar("String", stringOrder(), "SmearMaterial")
	self:NetworkVar("Float", floatOrder(), "Lag")
	self:NetworkVar("Vector", vectorOrder(), "SmearColor")

	self:NetworkVar("Int", intOrder(), "NumpadKey")

	self:NetworkVar("Bool", booleanOrder(), "Toggle")
	self:NetworkVar("Bool", booleanOrder(), "Active")

	self:NetworkVarNotify("Segments", function(entity, _, _, newSegments)
		---@cast newSegments number
		if self:GetSmearType() == VLAZED_SMEAR_GENERATOR.SmearTrailShape.quad then
			self:SetMaxVerts(newSegments * 4)
		elseif self:GetSmearType() == VLAZED_SMEAR_GENERATOR.SmearTrailShape.tri then
			self:SetMaxVerts(newSegments * 4 - 1)
		end
		if SERVER then
			net.Start("smear_trail_reset")
			net.WriteEntity(entity)
			net.Broadcast()
		else
			self.verts = {}
		end
	end)
end

function ENT:Initialize()
	self:SetRenderMode(RENDERMODE_TRANSCOLOR)
	self.material = Material("")

	---@type Vector[]
	self.verts = {}
	---@type number[]
	self.us = {}
	---@type number[]
	self.vs = {}
	---@type SmearTrailPhysicsAttachment[]
	self.physicsAttachments = {}

	self:SetRenderMode(RENDERMODE_TRANSCOLOR)

	self:AddEFlags(EFL_FORCE_CHECK_TRANSMIT)
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

if CLIENT then
	function ENT:Dequeue()
		table.remove(self.verts, 1)
		table.remove(self.us, 1)
		table.remove(self.vs, 1)
	end

	---@param x Vector
	---@param v number
	function ENT:Queue(x, v)
		table.insert(self.vs, v)
		table.insert(self.verts, x)
	end

	---@param attachmentProps SmearTrailPhysicsAttachment
	function ENT:MakeAttachment(attachmentProps)
		table.insert(self.physicsAttachments, attachmentProps)
	end

	function ENT:QueueVertex()
		local ents = {
			self.Ent1,
			self.Ent2,
		}
		local maxVerts = self:GetMaxVerts()

		for i, attachment in ipairs(self.physicsAttachments) do
			local ent = ents[i]
			local boneIndex = ent:LookupBone(attachment.boneName)
			if ent:GetBoneCount() == 1 then
				boneIndex = 0
			end
			local matrix = ent:GetBoneMatrix(boneIndex)
			self:Queue(
				LocalToWorld(attachment.pos, angle_zero, matrix:GetTranslation(), matrix:GetAngles()),
				(i + 1) % 2
			)
		end

		local count = #self.verts

		if count - 1 == maxVerts and self:GetSmearType() == VLAZED_SMEAR_GENERATOR.tri then
			local a1, a2 = self.verts[2], self.verts[1]
			a1:Add(a2)
			a1:Div(2)
			self.verts[2] = a1
			self:Dequeue()
		elseif count > maxVerts then
			self:Dequeue()
			self:Dequeue()
		end

		local count = #self.verts

		for i = 1, count, 2 do
			self.us[i] = 1 - i / count
			self.us[i + 1] = 1 - i / count
		end
	end

	function ENT:Think()
		self:QueueVertex()

		self:SetNextClientThink(CurTime() + self:GetLag())
		self:SetPos(LocalPlayer():GetPos())
	end

	function ENT:InitializeMaterial()
		self.material = VLAZED_SMEAR_GENERATOR:makeSmearTrail("color/white")
	end

	function ENT:Draw(flags)
		if not self:GetActive() then
			return
		end

		local verts = self.verts
		local us = self.us
		local vs = self.vs

		if not verts[1] then
			return
		end

		if not self.material then
			self:InitializeMaterial()
		end
		self:ValidateMaterial(self:GetSmearMaterial())

		local count = #self.verts
		if count - 2 == 0 then
			return
		end

		self.material:SetVector("$color2", self:GetSmearColor())
		render.CullMode(2)
		render.SetMaterial(self.material)
		mesh.Begin(MATERIAL_TRIANGLE_STRIP, count - 2)
		local success, err = pcall(function()
			for i = count, 1, -1 do
				mesh.Position(verts[i]) -- Set the position
				mesh.TexCoord(0, us[i], vs[i]) -- Set the texture UV coordinates
				mesh.AdvanceVertex() -- Write the vertex
			end
		end)
		if not success and err then
			ErrorNoHalt(err)
		end
		mesh.End()
	end

	function ENT:DrawTranslucent(flags)
		self:Draw(flags)
	end

	net.Receive("smear_trail_update", function(len, ply)
		---@class ent_smear_trail
		local trail = net.ReadEntity()
		local ent1 = net.ReadEntity()
		local ent2 = net.ReadEntity()

		local attachment1 = net.ReadTable()
		local attachment2 = net.ReadTable()

		trail.Ent1 = ent1
		trail.Ent2 = ent2

		trail.physicsAttachments = {}
		trail:MakeAttachment(attachment1)
		trail:MakeAttachment(attachment2)
	end)

	net.Receive("smear_trail_reset", function(len, ply)
		local entity = net.ReadEntity()
		---@cast entity ent_smear_trail

		entity.verts = {}
	end)
end

if SERVER then
	local function press(pl, ent)
		if not ent or not IsValid(ent) then
			return
		end

		if ent:GetToggle() then
			if not ent:GetActive() then
				ent:SetActive(true)
			else
				ent:SetActive(false)
			end
		else
			ent:SetActive(true)
		end
	end

	local function release(pl, ent)
		if not ent or not IsValid(ent) then
			return
		end

		if ent:GetToggle() then
			return
		end

		ent:SetActive(false)
	end

	numpad.Register("smear_trail_press", press)
	numpad.Register("smear_trail_release", release)
end
