TOOL.Category = "Render"
TOOL.Name = "#tool.smear.name"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar["key"] = 0
TOOL.ClientConVar["toggle"] = 1
TOOL.ClientConVar["starton"] = 1

TOOL.ClientConVar["persist"] = 0

TOOL.ClientConVar["noisescale"] = 15
TOOL.ClientConVar["noiseheight"] = 130
TOOL.ClientConVar["lag"] = 0.1
TOOL.ClientConVar["color_r"] = 255
TOOL.ClientConVar["color_g"] = 255
TOOL.ClientConVar["color_b"] = 255
TOOL.ClientConVar["color_a"] = 255
TOOL.ClientConVar["brightness"] = 1
TOOL.ClientConVar["model"] = ""
TOOL.ClientConVar["skin"] = 0
TOOL.ClientConVar["bodygroup"] = ""

---@class SmearParams
---@field color Vector
---@field brightness number
---@field noiseScale number
---@field noiseHeight number
---@field lag number
---@field transparency number
---@field key integer
---@field toggle boolean
---@field startOn boolean
---@field persist boolean
---@field model string
---@field skin integer
---@field bodygroup string

local firstReload = true
function TOOL:Think()
	if CLIENT and firstReload then
		self:RebuildControlPanel()
		firstReload = false
	end
end

---Remove smears from an entity's hierarchy
---@param tool TOOL
---@param root SmearEntity
local function removeSmearFromHierarchy(tool, root)
	if IsValid(root.smearEnt) then
		duplicator.ClearEntityModifier(root, "smear_persist")
		root.smearEnt:Remove()
	end

	net.Start("smear_remove_bonemerge")
	net.WriteEntity(root)
	net.Broadcast()

	local children = root:GetChildren() or {}
	for _, entity in ipairs(children) do
		---@cast entity SmearEntity
		removeSmearFromHierarchy(tool, entity)
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

	removeSmearFromHierarchy(self, entity)

	return true
end

function TOOL:Holster()
	self:ClearObjects()
end

---Add smears to an entity's hierarchy
---@param root SmearEntity
---@param smearParams SmearParams
---@param ply Player
local function addSmearToHierarchy(root, smearParams, ply)
	AddSmear(ply, root, smearParams)
	local children = root:GetChildren() or {}
	for _, entity in ipairs(children) do
		---@cast entity SmearEntity
		addSmearToHierarchy(entity, smearParams, ply)
	end
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

	---@type SmearParams
	local smearParams = {
		color = Color(
			self:GetClientNumber("color_r", 255),
			self:GetClientNumber("color_g", 255),
			self:GetClientNumber("color_b", 255)
		):ToVector(),
		brightness = self:GetClientNumber("brightness", 1),
		noiseScale = self:GetClientNumber("noisescale"),
		noiseHeight = self:GetClientNumber("noiseheight"),
		lag = self:GetClientNumber("lag"),
		transparency = self:GetClientNumber("color_a", 255) / 255,
		key = self:GetClientNumber("key", 0),
		toggle = tobool(self:GetClientBool("toggle", true)),
		startOn = tobool(self:GetClientBool("starton", true)),
		persist = tobool(self:GetClientBool("persist", false)),
		model = self:GetClientInfo("model"),
		bodygroup = self:GetClientInfo("bodygroup"),
		skin = self:GetClientNumber("skin", 0),
	}
	local ply = self:GetOwner()

	addSmearToHierarchy(entity, smearParams, ply)

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
		ply:ConCommand("smear_noisescale " .. smearEnt:GetNoiseScale())
		ply:ConCommand("smear_noiseheight " .. smearEnt:GetNoiseHeight())
		ply:ConCommand("smear_lag " .. smearEnt:GetLag())
		ply:ConCommand("smear_color_a " .. smearEnt:GetTransparency() * 255)

		local color = smearEnt:GetSmearColor() * 255
		ply:ConCommand("smear_color_r " .. color.x)
		ply:ConCommand("smear_color_g " .. color.y)
		ply:ConCommand("smear_color_b " .. color.z)
	end

	return true
end

if SERVER then
	util.AddNetworkString("smear_add_bonemerge")
	util.AddNetworkString("smear_remove_bonemerge")

	-- Filter entities that shouldn't be smeared
	local smearFilter = {
		["ent_smear"] = true, -- Don't smear entities like ourselves
		["manipulate_flex"] = true, -- Don't smear flex entities
		["prop_replacementeffect"] = true, -- TF2 Hat Painter & Crit Glow
		["proxyent_tf2critglow"] = true, -- TF2 Hat Painter & Crit Glow
		["proxyent_tf2cloakeffect"] = true, -- TF2 Cloak Effect
		["particle_player"] = true, -- 3D Particle Effects Player
		["particlecontroller_normal"] = true, -- 3D Particle Effects Player
		["particlecontroller_proj"] = true, -- Advanced Particle Controller
		["particlecontroller_tracer"] = true, -- Advanced Particle Controller
		["parctrl_dummyent"] = true, -- Advanced Particle Controller
		["prop_effect"] = true,
	}

	local enableBonemergeFix = CreateConVar(
		"sv_smear_enable_bonemerge_fix",
		"1",
		FCVAR_ARCHIVE + FCVAR_REPLICATED,
		"Fix smears not working on some bonemerged objects",
		0,
		1
	)

	local badBonemergeClasses = {
		["ent_bonemerged"] = true,
		["ent_composite"] = true,
	}

	---Add a smear to the entity.
	---
	---If the `parent` is in the `smearFilter` or if it doesn't have a valid model, then this will return NULL
	---
	---```
	---local smearFilter = {
	---["ent_smear"] = true, -- Don't smear entities like ourselves
	---["manipulate_flex"] = true, -- Don't smear flex entities
	---["prop_replacementeffect"] = true, -- TF2 Hat Painter & Crit Glow
	---["proxyent_tf2critglow"] = true, -- TF2 Hat Painter & Crit Glow
	---["proxyent_tf2cloakeffect"] = true, -- TF2 Cloak Effect
	---["particle_player"] = true, -- 3D Particle Effects Player
	---["particlecontroller_normal"] = true, -- 3D Particle Effects Player
	---["particlecontroller_proj"] = true, -- Advanced Particle Controller
	---["particlecontroller_tracer"] = true, -- Advanced Particle Controller
	---["parctrl_dummyent"] = true, -- Advanced Particle Controller
	---["prop_effect"] = true,
	---}
	---
	---```
	---
	---If the entity is a bonemerged entity and fits one of the `badBonemergeClasses`, and `sv_smear_enable_bonemerge_fix 1`,
	---then it will detour the entity's current `Draw` function to force support (see `smear_bonemerge_override.lua`)
	---
	---@param parent SmearEntity
	---@param smearParams SmearParams
	---@return ent_smear
	function AddSmear(ply, parent, smearParams)
		if smearFilter[parent:GetClass()] then
			return NULL
		end

		if parent.GetModel and not parent:GetModel() or not util.IsValidModel(parent:GetModel()) then
			return NULL
		end

		if enableBonemergeFix:GetBool() and badBonemergeClasses[parent:GetClass()] then
			net.Start("smear_add_bonemerge")
			net.WriteEntity(parent)
			net.Broadcast()
		end

		local smearEnt = parent.smearEnt
		if not IsValid(smearEnt) then
			---@diagnostic disable-next-line
			smearEnt = ents.Create("ent_smear")
			---@cast smearEnt ent_smear
			smearEnt:SetModel(parent:GetModel())
			smearEnt:SetSkin(parent:GetSkin())
			for i = 0, parent:GetNumBodyGroups() do
				smearEnt:SetBodygroup(i, parent:GetBodygroup(i))
			end
			smearEnt:Spawn()

			smearEnt:SetParent(parent, 0)

			smearEnt:SetMoveType(MOVETYPE_NONE)
			smearEnt:SetSolid(SOLID_NONE)
			smearEnt:SetLocalPos(vector_origin)
			smearEnt:SetLocalAngles(angle_zero)

			smearEnt:AddEffects(EF_BONEMERGE)
			if parent:GetClass() == "prop_ragdoll" then
				smearEnt:AddEffects(EF_BONEMERGE_FASTCULL)
			end
			smearEnt:SetModelScale(parent:GetModelScale())
			for i = 0, parent:GetBoneCount() do
				smearEnt:ManipulateBoneScale(i, parent:GetManipulateBoneScale(i))
				smearEnt:ManipulateBoneAngles(i, parent:GetManipulateBoneAngles(i))
				smearEnt:ManipulateBonePosition(i, parent:GetManipulateBonePosition(i))
			end

			parent.smearEnt = smearEnt
		end

		if smearParams.model[1] and util.IsValidModel(smearParams.model) then
			smearEnt:SetModel(smearParams.model)
			smearEnt:SetSkin(smearParams.skin)
			smearEnt:SetBodyGroups(smearParams.bodygroup)
			smearEnt:SetDifferentModel(true)
		end
		smearEnt:SetSmearColor(smearParams.color)
		smearEnt:SetBrightness(smearParams.brightness)
		smearEnt:SetNoiseScale(smearParams.noiseScale)
		smearEnt:SetNoiseHeight(smearParams.noiseHeight)
		smearEnt:SetLag(smearParams.lag)
		smearEnt:SetTransparency(smearParams.transparency)
		smearEnt:SetActive(Either(smearParams.startOn ~= nil, smearParams.startOn, true))

		if IsValid(ply) then
			smearEnt:SetNumpadKey(smearParams.key)
			smearEnt:SetToggle(smearParams.toggle)

			numpad.OnDown(ply, smearParams.key, "smear_press", smearEnt)
			numpad.OnUp(ply, smearParams.key, "smear_release", smearEnt)
		end

		duplicator.ClearEntityModifier(parent, "smear_persist")
		if smearParams.persist then
			duplicator.StoreEntityModifier(parent, "smear_persist", smearParams)
		end

		return smearEnt
	end

	duplicator.RegisterEntityModifier("smear_persist", AddSmear)

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

	local modelCategory = makeCategory(smearShapeCategory, "#tool.smear.model", "ControlPanel")
	modelCategory:SetExpanded(true)
	---@class SmearModelEntry: DTextEntry
	local modelEntry = modelCategory:TextEntry("#tool.smear.model.entry", "smear_model")
	modelEntry:SetTooltip("#tool.smear.model.entry.tooltip")
	local skin = modelCategory:NumSlider("#tool.smear.model.skin", "smear_skin", 0, 10, 0)
	---@cast skin DNumSlider
	skin:SetEnabled(false)
	---@class SmearBodygroupCategory: ControlPanel
	---@field Items Panel[]
	local bodygroupCategory = makeCategory(modelCategory, "#tool.smear.model.bodygroup", "ControlPanel")

	local bodygroupCVar = GetConVar("smear_bodygroup")

	---@param val integer
	local function parseValue(val)
		if val > 9 then
			return tostring(97 + val - 10)
		end
		return tostring(val)
	end

	local function getBodygroupString()
		local bodygroupStr = ""
		for _, panel in ipairs(bodygroupCategory.Items) do
			local slider = panel:GetChildren()[1]
			---@cast slider DNumSlider
			bodygroupStr = bodygroupStr .. parseValue(math.Round(slider:GetValue()))
		end
		return bodygroupStr
	end

	---@param name string
	---@param count integer
	local function makeBodygroupSlider(name, count, initialValue)
		---@class SmearBodygroupSlider: DNumSlider
		local slider = bodygroupCategory:NumSlider(string.NiceName(name), "", 0, count, 0)
		slider:SetValue(initialValue)

		if count == 0 then
			slider:SetVisible(false)
			function slider:GetValue()
				return 0
			end
		end
		function slider:OnValueChanged(_)
			bodygroupCVar:SetString(getBodygroupString())
		end
	end

	function modelEntry:OnValueChange(model)
		bodygroupCategory:Clear()
		skin:SetEnabled(false)

		if not model then
			return
		end

		local ent = ClientsideModel(model)
		---@cast ent CSEnt
		local ok, result = pcall(function()
			if not IsValid(ent) then
				return
			end

			ent:SetModelScale(0)
			skin:SetEnabled(true)
			skin:SetDark(true)
			skin:SetMax(ent:SkinCount() - 1)
			for _, bodygroup in ipairs(ent:GetBodyGroups()) do
				---@cast bodygroup BodyGroupData
				makeBodygroupSlider(bodygroup.name, bodygroup.num - 1, bodygroupCVar:GetString()[bodygroup.id + 1])
			end
		end)
		if not ok and result then
			ErrorNoHalt(result, "\n")
		end
		if IsValid(ent) then
			ent:Remove()
		end
	end

	local controlCategory = makeCategory(cPanel, "#tool.smear.control", "ControlPanel")
	controlCategory:KeyBinder("#tool.smear.key", "smear_key")
	controlCategory:CheckBox("#tool.smear.toggle", "smear_toggle")
	controlCategory:CheckBox("#tool.smear.starton", "smear_starton")
	controlCategory:CheckBox("#tool.smear.persist", "smear_persist"):SetTooltip("#tool.smear.persist.tooltip")
end

TOOL.Information = {
	{ name = "left", stage = 0 },
	{ name = "right", stage = 0 },
	{ name = "reload" },
}
