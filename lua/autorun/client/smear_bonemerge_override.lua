---This script attempts to fix smears for some bonemerged entities
---The fix relies on checking if the Draw function's `flags` argument equals zero
---The Advanced Bonemerger reports this as preventing `EF_BONEMERGE` from rendering
---multiple times (https://github.com/NO-LOAFING/AdvBonemerge/blob/a8b5739e35be73144191ed43bfeb4f39d6c1ec7a/lua/entities/ent_advbonemerge.lua#L1069)
---
---I think the detour fix is pretty hacky, but then again most fixes in GMod are hacky

---This function removes the fix from `detourBonemergeDraw`.
local function removeDetourBonemergeDraw()
	local ent = net.ReadEntity()
	---@cast ent SmearEntity
	if not IsValid(ent) then
		return
	end

	if ent.smear_oldDraw then
		ent.Draw = ent.smear_oldDraw
	end
end

---This function detours the bonemerge classes listed in `badBonemergeClasses`
---To only draw once if it has a child with `EF_BONEMERGE`. This fixes smears
---not working on bonemerged entities, but may introduce problems.
local function detourBonemergeDraw()
	local ent = net.ReadEntity()
	---@cast ent SmearEntity

	if not IsValid(ent) then
		return
	end

	if not ent.smear_oldDraw then
		---@diagnostic disable-next-line
		ent.smear_oldDraw = ent.Draw
	end

	function ent:Draw(flags)
		if flags == 0 then
			return
		end

		return ent:smear_oldDraw(flags)
	end
end

net.Receive("smear_add_bonemerge", detourBonemergeDraw)
net.Receive("smear_remove_bonemerge", removeDetourBonemergeDraw)
