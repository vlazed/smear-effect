TOOL.Category = "Render"
TOOL.Name = "#tool.smear_trail.name"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar["key"] = 0
TOOL.ClientConVar["toggle"] = 1
TOOL.ClientConVar["starton"] = 1

TOOL.ClientConVar["lag"] = 0.1
TOOL.ClientConVar["color_r"] = 255
TOOL.ClientConVar["color_g"] = 255
TOOL.ClientConVar["color_b"] = 255
TOOL.ClientConVar["color_a"] = 255
TOOL.ClientConVar["material"] = 1
TOOL.ClientConVar["segments"] = 1
TOOL.ClientConVar["types"] = 1

---@class SmearTrailParams
---@field lag number
---@field color Color
---@field key integer
---@field toggle boolean
---@field starton boolean
---@field segments integer
---@field type SmearTrailType
---@field material string
---@field attachment1 SmearTrailPhysicsAttachment
---@field attachment2 SmearTrailPhysicsAttachment

function TOOL:GetSmearEntity()
	return self:GetWeapon():GetNWEntity("smear_trail_selection")
end

function TOOL:SetSmearEntity(ent)
	return self:GetWeapon():SetNWEntity("smear_trail_selection", ent)
end

local firstReload = true
local lastEntity = NULL
local lastValidEntity = false
function TOOL:Think()
	if CLIENT and firstReload then
		self:RebuildControlPanel()
		firstReload = false
	end

	if CLIENT then
		local currentEnt = self:GetSmearEntity()
		if currentEnt == lastEntity and IsValid(currentEnt) == lastValidEntity then
			return
		end

		lastEntity = currentEnt
		lastValidEntity = IsValid(lastEntity)
		self:RebuildControlPanel(currentEnt)
	end
end

---Remove the smear entity
---@param tr table|TraceResult
---@return boolean
function TOOL:Reload(tr)
	local entity = tr.Entity
	---@cast entity SmearEntity
	if not IsValid(entity) or entity:IsPlayer() or entity:IsWorld() then
		return false
	end

	for _, e in ipairs(ents.FindByClass("info_target")) do
		local tab = e:GetTable()
		if tab.Type == "vlazed_smear_trail" and (tab.Ent1 == entity or tab.Ent2 == entity) then
			e:Remove()
		end
	end

	return true
end

function TOOL:Holster()
	self:ClearObjects()
end

---
---@param ent Entity
---@param physBone integer
---@param pos Vector worldspace vector
---@return SmearTrailPhysicsAttachment
local function createPhysicsAttachment(ent, physBone, pos)
	local physObj = ent:GetPhysicsObjectNum(physBone)
	---@type SmearTrailPhysicsAttachment
	return {
		pos = physObj and physObj:WorldToLocal(pos) or vector_origin,
		boneName = ent:GetBoneName(ent:TranslatePhysBoneToBone(physBone)),
	}
end

local COLOR = FindMetaTable("Color")

---@param trail ent_smear_trail
---@param owner Player
---@param smearParams SmearTrailParams
local function setSmearTrailParameters(trail, owner, smearParams)
	setmetatable(smearParams.color, COLOR)

	trail:SetSmearType(smearParams.type)
	trail:SetSegments(smearParams.segments)
	trail:SetLag(smearParams.lag)
	trail:SetSmearMaterial(smearParams.material)
	trail:SetSmearColor(smearParams.color:ToVector())
	trail:SetActive(Either(smearParams.starton ~= nil, smearParams.starton, true))

	if IsValid(owner) then
		trail:SetNumpadKey(smearParams.key)
		trail:SetToggle(smearParams.toggle)

		numpad.OnDown(owner, smearParams.key, "smear_trail_press", trail)
		numpad.OnUp(owner, smearParams.key, "smear_trail_release", trail)
	end
end

local function updateView(trail, ent1, ent2, smearParams)
	net.Start("smear_trail_update")
	net.WriteEntity(trail)
	net.WriteEntity(ent1)
	net.WriteEntity(ent2)
	net.WriteTable(smearParams.attachment1)
	net.WriteTable(smearParams.attachment2)
	net.Broadcast()
end

---@param ent1 Entity
---@param ent2 Entity
---@param owner Player
---@param smearParams SmearTrailParams
---@return ent_smear_trail?
local function addSmearTrail(ent1, ent2, smearParams, owner)
	if not IsValid(ent1) then
		return
	end
	if not IsValid(ent2) then
		return
	end

	local trail = ents.Create("ent_smear_trail")
	---@cast trail ent_smear_trail
	trail:Spawn()

	local const = ents.Create("info_target")
	const:Spawn()
	const:Activate()

	setSmearTrailParameters(trail, owner, smearParams)

	constraint.AddConstraintTable(ent1, const, ent2, trail)

	const:SetTable({
		Type = "vlazed_smear_trail",
		Ent1 = ent1,
		Ent2 = ent2,
		SmearParams = smearParams,
		Owner = owner,
	})

	trail.Ent1 = ent1
	trail.Ent2 = ent2
	trail.constraint = const

	const:DeleteOnRemove(trail)
	ent1:DeleteOnRemove(const)
	ent2:DeleteOnRemove(const)

	updateView(trail, ent1, ent2, smearParams)

	return trail
end

duplicator.RegisterConstraint("vlazed_smear_trail", addSmearTrail, "Ent1", "Ent2", "SmearParams", "Owner")

---Add a smear entity, or update the entity's smear parameters
---@param tr table|TraceResult
---@return boolean
function TOOL:LeftClick(tr)
	local entity = tr.Entity
	---@cast entity SmearEntity
	if not IsValid(entity) or entity:IsPlayer() then
		return false
	end

	local ply = self:GetOwner()

	local stage = self:GetStage()
	if stage == 0 then
		self:SetStage(1)
		local po = entity:GetPhysicsObjectNum(tr.PhysicsBone)
		self:SetObject(0, entity, tr.HitPos, po, tr.PhysicsBone, tr.HitNormal)
		return true
	elseif stage == 1 then
		self:SetStage(0)

		---@type SmearTrailParams
		local smearParams = {
			color = Color(
				self:GetClientNumber("color_r", 255),
				self:GetClientNumber("color_g", 255),
				self:GetClientNumber("color_b", 255)
			),
			lag = self:GetClientNumber("lag"),
			key = self:GetClientNumber("key", 0),
			toggle = tobool(self:GetClientBool("toggle", true)),
			starton = tobool(self:GetClientBool("starton", true)),
			persist = tobool(self:GetClientBool("persist", false)),
			segments = self:GetClientNumber("segments", 3),
			material = self:GetClientInfo("material"),
			attachment1 = createPhysicsAttachment(self:GetEnt(0), self:GetBone(0), self:GetPos(0)),
			attachment2 = createPhysicsAttachment(entity, tr.PhysicsBone, tr.HitPos),
			type = self:GetClientNumber("types"),
		}

		local trail = addSmearTrail(self:GetEnt(0), entity, smearParams, ply)

		if trail then
			undo.Create("Smear Trail")
			undo.AddEntity(trail)
			undo.SetPlayer(ply)
			undo.Finish()
		end
	end

	return true
end

---Select an entity to view its smear trails
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

	self:SetSmearEntity(entity)

	local ply = self:GetOwner()

	return true
end

if SERVER then
	util.AddNetworkString("smear_trail_update")
	net.Receive("smear_trail_update", function(len, ply)
		local trail = net.ReadEntity()
		---@cast trail ent_smear_trail
		local smearParams = net.ReadTable()

		local ent1 = trail.Ent1
		local ent2 = trail.Ent2
		local const = trail.constraint

		local owner = ply

		const:SetTable({
			Type = "vlazed_smear_trail",
			Ent1 = ent1,
			Ent2 = ent2,
			SmearParams = smearParams,
			Owner = owner,
		})

		setSmearTrailParameters(trail, owner, smearParams)
		updateView(trail, ent1, ent2, smearParams)
	end)

	util.AddNetworkString("smear_trail_reset")
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

---@param cPanel DForm|ControlPanel
---@param entity Entity
local function trailList(cPanel, entity)
	---@class SmearTrailList: DTree
	local tree = vgui.Create("DTree", cPanel)
	tree:SetPaintBackground(false)
	tree:Dock(TOP)
	tree:SetSize(cPanel:GetWide(), 400)

	---@class SmearTrailList_Node: DTree_Node
	local root = tree:AddNode(tostring(entity))

	tree.root = root

	for _, trail in ipairs(ents.FindByClass("ent_smear_trail")) do
		---@cast trail ent_smear_trail
		local tab = trail:GetTable()
		if tab.Ent1 == entity or tab.Ent2 == entity then
			---@class SmearTrailList_Node
			local trailNode = root:AddNode(tostring(trail))

			trailNode.entity = trail
			function trailNode:OnNodeSelected()
				tree:OnTrailSelected(self)
			end

			trail:CallOnRemove("smear_trail_RemoveLine", function(ent, ...)
				if IsValid(ent) and IsValid(trailNode) then
					trailNode:Remove()
				end
			end)
		end
	end

	---@param node SmearTrailList_Node
	function tree:OnTrailSelected(node) end

	return tree
end

local smearChoice = {
	[VLAZED_SMEAR_GENERATOR.SmearTrailShape.quad] = "Quad",
	[VLAZED_SMEAR_GENERATOR.SmearTrailShape.tri] = "Triangle",
}

---@param cPanel ControlPanel|DForm
---@param entity Entity
function TOOL.BuildCPanel(cPanel, entity)
	cPanel:ToolPresets("vlazed_smear_trail", cvarList)

	---@type ent_smear_trail
	local trailEntity = NULL

	local listCategory = makeCategory(cPanel, "#tool.smear_trail.trails", "ControlPanel")
	listCategory:SetExpanded(true)
	local trailList = trailList(listCategory, entity)

	local colorCategory = makeCategory(cPanel, "#tool.smear.color", "ControlPanel")
	colorCategory:SetExpanded(true)
	local color = colorCategory:ColorPicker(
		"#tool.smear.colorpicker",
		"smear_trail_color_r",
		"smear_trail_color_g",
		"smear_trail_color_b",
		"smear_trail_color_a"
	)

	local smearShapeCategory = makeCategory(cPanel, "#tool.smear.shape", "ControlPanel")
	smearShapeCategory:SetExpanded(true)
	-- smearShapeCategory
	-- 	:NumSlider("#tool.smear.noiseheight", "smear_noiseheight", 0, 1000, 3)
	-- 	:SetTooltip("#tool.smear.noiseheight.tooltip")
	local smearType = smearShapeCategory:ComboBox("#tool.smear_trail.type", "smear_trail_types")
	---@cast smearType DComboBox
	smearType:AddChoice("Quad", 1)
	smearType:AddChoice("Triangle", 2)

	local lag = smearShapeCategory:NumSlider("#tool.smear.lag", "smear_trail_lag", 0, 2, 5)
	---@cast lag DNumSlider
	lag:SetTooltip("#tool.smear.lag.tooltip")
	local segments = smearShapeCategory:NumSlider("#tool.smear_trail.segments", "smear_trail_segments", 1, 20, 0)
	---@cast segments DNumSlider
	segments:SetTooltip("#tool.smear_trail.segments.tooltip")

	local materialCategory = makeCategory(cPanel, "#tool.smear.material", "ControlPanel")
	local material = materialCategory:TextEntry("#tool.smear.material.material", "smear_trail_material")
	---@cast material DTextEntry

	---https://github.com/Facepunch/garrysmod/blob/e47ac049d026f922867ee3adb2c4746fb1244300/garrysmod/gamemodes/sandbox/entities/weapons/gmod_tool/stools/material.lua#L136
	local materials = {}
	for id, str in ipairs(list.Get("OverrideMaterials")) do
		if not table.HasValue(materials, str) then
			table.insert(materials, str)
		end
	end

	materialCategory:MatSelect("smear_trail_material", materials, true, 0.25, 0.25)

	local controlCategory = makeCategory(cPanel, "#tool.smear.control", "ControlPanel")
	local key = controlCategory:KeyBinder("#tool.smear.key", "smear_trail_key")
	local toggle = controlCategory:CheckBox("#tool.smear.toggle", "smear_trail_toggle")
	---@cast toggle DCheckBoxLabel
	local starton = controlCategory:CheckBox("#tool.smear.starton", "smear_trail_starton")
	---@cast starton DCheckBoxLabel
	-- local persist = controlCategory:CheckBox("#tool.smear.persist", "smear_trail_persist"):SetTooltip("#tool.smear.persist.tooltip")

	---@class SmearTrailUpdate: DButton
	local update = cPanel:Button("#tool.smear_trail.update", "")
	function update:DoClick()
		if not IsValid(trailEntity) then
			return
		end

		---@diagnostic disable
		---@type Color
		local color = color.Mixer:GetColor()
		---@type integer
		local key = key:GetValue1()
		---@diagnostic enable

		local name, type = smearType:GetSelected()
		---@type SmearTrailParams
		local smearParams = {
			color = color,
			lag = lag:GetValue(),
			key = key,
			starton = starton:GetChecked(),
			toggle = toggle:GetChecked(),
			material = material:GetValue(),
			segments = segments:GetValue(),
			attachment1 = trailEntity.physicsAttachments[1],
			attachment2 = trailEntity.physicsAttachments[2],
			type = type,
		}

		net.Start("smear_trail_update")
		net.WriteEntity(trailEntity)
		net.WriteTable(smearParams)
		net.SendToServer()
	end

	---@param ent ent_smear_trail
	local function updateConVars(ent)
		local color = ent:GetSmearColor():ToColor()
		lag:SetValue(ent:GetLag())
		RunConsoleCommand("smear_trail_material", ent:GetSmearMaterial())
		RunConsoleCommand("smear_trail_key", ent:GetNumpadKey())
		RunConsoleCommand("smear_trail_color_r", color.r)
		RunConsoleCommand("smear_trail_color_g", color.g)
		RunConsoleCommand("smear_trail_color_b", color.b)
		RunConsoleCommand("smear_trail_types", ent:GetSmearType())
		smearType:ChooseOption(smearChoice[ent:GetSmearType()], ent:GetSmearType())
	end

	function trailList:OnTrailSelected(node)
		trailEntity = node.entity
		updateConVars(trailEntity)
	end
end

TOOL.Information = {
	{ name = "left", stage = 0 },
	{ name = "left_1", stage = 1 },
	{ name = "right", stage = 0 },
	{ name = "reload" },
}
