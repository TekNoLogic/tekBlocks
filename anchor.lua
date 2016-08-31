
local myname, ns = ...


ns.anchor = CreateFrame("Frame", nil, UIParent)
ns.anchor:SetSize(1, 1)
ns.anchor:SetPoint("TOPLEFT")


local function ReAnchor()
	if OrderHallCommandBar and OrderHallCommandBar:IsShown() then
		ns.anchor:SetPoint("TOPLEFT", OrderHallCommandBar, "BOTTOMLEFT")
	else
		ns.anchor:SetPoint("TOPLEFT")
	end
end


ns.anchor:SetScript("OnEvent", function(self, event, addon)
	if OrderHallCommandBar then
		OrderHallCommandBar:HookScript("OnShow", ReAnchor)
		OrderHallCommandBar:HookScript("OnHide", ReAnchor)
		ReAnchor()
		self:SetScript("OnEvent", nil)
		self:UnregisterEvent("ADDON_LOADED")
	end
end)
ns.anchor:RegisterEvent("ADDON_LOADED")
