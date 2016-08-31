
local myname, ns = ...


local ldb = LibStub:GetLibrary("LibDataBroker-1.1")

local EDGE = 8


local backdrop = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	edgeSize = 16,
	insets = {left = 5, right = 5, top = 5, bottom = 5},
	tile = true, tileSize = 16,
}


local function TextUpdate(self, event, name, key, value, dataobj)
	self.text:SetText(value)
	self:SetWidth(self.text:GetStringWidth() + 12 + (dataobj.icon and 24 or 0))
end


local function IconUpdate(self, event, name, key, value)
	local oldtexture = self.icon:GetTexture()
	self.icon:SetTexture(value)
	if value and value:match("Interface\\Icons") then self.icon:SetTexCoord(4/48, 44/48, 4/48, 44/48) else self.icon:SetTexCoord(0, 1, 0, 1) end
	if value and not oldtexture then
		self:SetWidth(self:GetWidth() + 24)
		self.text:SetPoint("CENTER", 12, 0)
	elseif not value then
		self:SetWidth(self:GetWidth() - 24)
		self.text:SetPoint("CENTER", 0, 0)
	end
end


local function SetDObjScript(self, event, name, key, value)
	self:SetScript(key, value)
end


-------------------------------------------
--      Namespace and all that shit      --
-------------------------------------------

local f = CreateFrame("frame")
f:SetFrameStrata('BACKGROUND')
f:SetHeight(24 + EDGE*2 - 5*2)
f:SetPoint("TOPLEFT", ns.anchor, -EDGE, 4)
f:SetBackdrop({
	bgFile = "Interface\\AddOns\\tekBlocks\\solid", tile = true, tileSize = 1,
	edgeFile = "Interface\\AddOns\\tekBlocks\\teksture", edgeSize = EDGE, insets = {left = EDGE, right = EDGE, top = EDGE, bottom = EDGE},
})


local function AnchorBlock(block, lastframe)
	if lastframe then
		block:SetPoint("TOPLEFT", lastframe, "TOPRIGHT")
	else
		block:SetPoint("TOPLEFT", ns.anchor)
	end
	f:SetPoint("RIGHT", block, EDGE, 0)

	return block
end


local blocks, order = {}, {"MakeRocketGoNow", "BlizzClock", "picoFriends", "picoGuild", "picoRep", "picoDPS", "picoEXP", "TomTom_Coords", "TourGuide", "DropTheCheapestThing", "picoFPS"}
local temp = {}
local function SetAnchors()
	for name,block in pairs(blocks) do temp[name] = block end

	local lastframe
	for _,name in ipairs(order) do
		local block = temp[name]
		if block then lastframe, temp[name] = AnchorBlock(block, lastframe), nil end
	end

	for name,block in pairs(temp) do lastframe = AnchorBlock(block, lastframe) end
end


local function GetQuadrant(frame)
	local x,y = frame:GetCenter()
	if not x or not y then return "BOTTOMLEFT", "BOTTOM", "LEFT" end
	local hhalf = (x > UIParent:GetWidth()/2) and "RIGHT" or "LEFT"
	local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
	return vhalf..hhalf, vhalf, hhalf
end


function f:NewDataobject(event, name, dataobj)
	if not dataobj.type then return print("Dataobject '"..name.."' has no type set!") end
	if dataobj.type ~= 'data source' then return end

	local frame = CreateFrame("Button", nil, UIParent)
	frame:SetHeight(24)

	frame:SetFrameStrata('LOW')

	frame:SetBackdrop(backdrop)
	frame:SetBackdropColor(0.09, 0.09, 0.19, 0.5)
	frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

	frame.dataobj = dataobj

	frame.icon = frame:CreateTexture()
	frame.icon:SetWidth(16) frame.icon:SetHeight(16)
	frame.icon:SetPoint("LEFT", 8, 0)
	frame.IconUpdate = IconUpdate
	ldb.RegisterCallback(frame, "LibDataBroker_AttributeChanged_"..name.."_icon", "IconUpdate")

	frame.text = frame:CreateFontString(nil, nil, "GameFontNormalSmall")
	frame.text:SetPoint("CENTER", dataobj.icon and 12 or 0, 0)
	frame.TextUpdate = TextUpdate
	ldb.RegisterCallback(frame, "LibDataBroker_AttributeChanged_"..name.."_text", "TextUpdate")

	IconUpdate(frame, nil, nil, "icon", dataobj.icon)
	TextUpdate(frame, nil, nil, "text", dataobj.text, dataobj)

	frame:RegisterForClicks("anyUp")

	frame.SetDObjScript = self.SetDObjScript
	frame:SetScript("OnEnter", function(self)
		if self.dataobj.OnEnter then return self.dataobj.OnEnter(self) end
		if self.dataobj.OnTooltipShow then
			GameTooltip:SetOwner(self, "ANCHOR_NONE")
			local quad, vhalf, hhalf = GetQuadrant(self)
			local anchpoint = (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
			GameTooltip:SetPoint(quad, self, anchpoint)

			self.dataobj.OnTooltipShow(GameTooltip)
			return GameTooltip:Show()
		end
	end)

	frame:SetScript("OnLeave", function(self) if dataobj.OnLeave then dataobj.OnLeave(self) else GameTooltip:Hide() end end)

	frame.SetDObjScript = SetDObjScript
	frame:SetScript("OnClick", dataobj.OnClick)
	ldb.RegisterCallback(frame, "LibDataBroker_AttributeChanged_"..name.."_OnClick", "SetDObjScript")

	blocks[name] = frame
	SetAnchors()
end


for name,dataobj in ldb:DataObjectIterator() do
	if dataobj.text then
		local success, err = pcall(f.NewDataobject, f, nil, name, dataobj)
		if not success then
			print("Error loading tekblock for dataobject", name)
		end
	end
end
ldb.RegisterCallback(f, "LibDataBroker_DataObjectCreated", "NewDataobject")
