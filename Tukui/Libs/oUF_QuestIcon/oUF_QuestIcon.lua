local parent, ns = ...
local oUF = ns.oUF
local ScanTooltip = CreateFrame("GameTooltip", "oUF_QuestIconTooltip", UIParent, "GameTooltipTemplate")

local Cache = {
	-- Cache for NPCs
}

local DisplayQuestIcon = function(self)
	local QuestIcon = self.QuestIcon
	local GUID = UnitGUID(self.unit) or ""
	local ID = tonumber(strmatch(GUID, "%-(%d-)%-%x-$"), 10)
	
	if Cache[ID] == "QUEST" then
		if not QuestIcon:IsShown() then
			QuestIcon:Show()
		end
	else
		if QuestIcon:IsShown() then
			QuestIcon:Hide()
		end
	end
end

local FindPlateWithQuest = function(self, unit)
	local QuestIcon = self.QuestIcon
	
	if QuestIcon then
		local GUID = UnitGUID(unit) or ""
		local ID = tonumber(strmatch(GUID, "%-(%d-)%-%x-$"), 10)
		
		if not Cache[ID] then
			ScanTooltip:ClearLines()
			ScanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
			ScanTooltip:SetUnit(unit)
			ScanTooltip:Show()

			local NumLines = ScanTooltip:NumLines()
			local Name = UnitName(unit)
			
			Cache[ID] = "NOQUEST"

			if NumLines >= 3 then
				for i = 3, NumLines do
					local Line = _G[ScanTooltip:GetName().."TextLeft"..i]
					local r, g, b = Line:GetTextColor()

					if (r > 0.99 and r <= 1) and (g > 0.82 and g < 0.83) and (b >= 0 and b < 0.01) then
						Cache[ID] = "QUEST"
						
						break
					end
				end
			end
			
			ScanTooltip:Hide()
		end
	end
end

local Update = function(self, event)
	local InstanceType = select(2, IsInInstance())
	
	if InstanceType == "pvp" or InstanceType == "arena" then
		return
	end
	
	if event ~= "NAME_PLATE_UNIT_ADDED" then
		Cache = {}
	end
	
	local QuestIcon = self.QuestIcon
	local Unit = self.unit
	local NumPlates = C_NamePlate.GetNamePlates()
	
	if(QuestIcon.PreUpdate) then 
		QuestIcon:PreUpdate()
	end
	
	for i, Plate in pairs(NumPlates) do
		FindPlateWithQuest(self, Unit)
		
		DisplayQuestIcon(self)
	end

	if(QuestIcon.PostUpdate) then
		return QuestIcon:PostUpdate()
	end
end

local Path = function(self, ...)
	return (self.QuestIcon.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate')
end

local function Enable(self)
	local QuestIcon = self.QuestIcon
	
	if (QuestIcon) then
		QuestIcon.__owner = self
		QuestIcon.ForceUpdate = ForceUpdate

		if not QuestIcon:GetTexture() then
			QuestIcon:SetTexture([[Interface\QuestFrame\AutoQuest-Parts]])
			QuestIcon:SetTexCoord(0.13476563, 0.17187500, 0.01562500, 0.53125000)
		end
		
		QuestIcon:Hide()

		self:RegisterEvent("QUEST_ACCEPTED", Path, true)
		self:RegisterEvent("QUEST_REMOVED", Path, true)
		self:RegisterEvent("NAME_PLATE_UNIT_ADDED", Path, true)

		return true
	end
end

local function Disable(self)
	local QuestIcon = self.QuestIcon
	
	if (QuestIcon) then
		self:UnregisterEvent('QUEST_ACCEPTED', Path, true)
		self:UnregisterEvent('QUEST_REMOVED', Path, true)
		self:UnregisterEvent('NAME_PLATE_UNIT_ADDED', Path, true)
	end
end

oUF:AddElement('QuestIcon', Path, Enable, Disable)