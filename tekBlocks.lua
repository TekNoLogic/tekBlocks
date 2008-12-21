
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
	self:SetWidth(self.text:GetStringWidth() + 8 + (dataobj.icon and 24 or 0))
end


local function IconUpdate(self, event, name, key, value)
	local oldtexture = self.icon:GetTexture()
	self.icon:SetTexture(value)
	if value and value:match("Interface\\Icons") then self.icon:SetTexCoord(4/48, 44/48, 4/48, 44/48) else self.icon:SetTexCoord(0, 1, 0, 1) end
	if not oldtexture then
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
f:SetHeight(24 + EDGE*2 - 5*2)
f:SetBackdrop({
	bgFile = "Interface\\AddOns\\tekBlocks\\solid", tile = true, tileSize = 1,
	edgeFile = "Interface\\AddOns\\tekBlocks\\teksture", edgeSize = EDGE, insets = {left = EDGE, right = EDGE, top = EDGE, bottom = EDGE},
})


local function AnchorBlock(block, lastframe)
	block:SetPoint("TOPLEFT", lastframe or UIParent, lastframe and "TOPRIGHT" or "TOPLEFT")

	if not lastframe then f:SetPoint("LEFT", block, -EDGE, 0) end
	f:SetPoint("RIGHT", block, EDGE, 0)

	return block
end


local blocks, order = {}, {"MakeRocketGoNow", "BlizzClock", "picoFriends", "picoGuild", "picoRep", "picoDPS", "picoEXP", "TomTom_Coords", "TourGuide", "picoFPS"}
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


function f:NewDataobject(event, name, dataobj)
	if not dataobj.text then return end

	local frame = CreateFrame("Button", nil, UIParent)
	frame:SetHeight(24)

	frame:SetBackdrop(backdrop)
	frame:SetBackdropColor(0.09, 0.09, 0.19, 0.5)
	frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

	frame.icon = frame:CreateTexture()
	frame.icon:SetWidth(16) frame.icon:SetHeight(16)
	frame.icon:SetPoint("LEFT", 8, 0)
	frame.icon:SetTexture(dataobj.icon)
	if dataobj.icon and dataobj.icon:match("Interface\\Icons") then frame.icon:SetTexCoord(4/48, 44/48, 4/48, 44/48) end
	frame.IconUpdate = IconUpdate
	ldb.RegisterCallback(frame, "LibDataBroker_AttributeChanged_"..name.."_icon", "IconUpdate")

	frame.text = frame:CreateFontString(nil, nil, "GameFontNormalSmall")
	frame.text:SetPoint("CENTER", dataobj.icon and 12 or 0, 0)
	frame.text:SetText(dataobj.text)
	frame:SetWidth(frame.text:GetStringWidth() + 8 + (dataobj.icon and 24 or 0))
	frame.TextUpdate = TextUpdate
	ldb.RegisterCallback(frame, "LibDataBroker_AttributeChanged_"..name.."_text", "TextUpdate")

	frame:RegisterForClicks("anyUp")

	frame.SetDObjScript = SetDObjScript
	frame:SetScript("OnEnter", dataobj.OnEnter)
	ldb.RegisterCallback(frame, "LibDataBroker_AttributeChanged_"..name.."_OnEnter", "SetDObjScript")

	frame:SetScript("OnLeave", dataobj.OnLeave)
	ldb.RegisterCallback(frame, "LibDataBroker_AttributeChanged_"..name.."_OnLeave", "SetDObjScript")

	frame:SetScript("OnClick", dataobj.OnClick)
	ldb.RegisterCallback(frame, "LibDataBroker_AttributeChanged_"..name.."_OnClick", "SetDObjScript")

	blocks[name] = frame
	SetAnchors()
end


for name,dataobj in ldb:DataObjectIterator() do if dataobj.text then f:NewDataobject(nil, name, dataobj) end end
ldb.RegisterCallback(f, "LibDataBroker_DataObjectCreated", "NewDataobject")

