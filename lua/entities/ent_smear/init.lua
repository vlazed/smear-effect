AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

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

numpad.Register("smear_press", press)
numpad.Register("smear_release", release)

---@diagnostic disable
duplicator.RegisterEntityClass("ent_smear", function(ply, data) end, "Data")
