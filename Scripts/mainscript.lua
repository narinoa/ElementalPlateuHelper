local Params =  {
	["ActivateAddon"] = true,
	}
local wtMainPanel = nil
local wtIcon = nil	
local wtChat = nil
local valuedText = common.CreateValuedText()
local wtMainPanel =  mainForm:GetChildChecked( "MainPanel", false )
wtMainPanel:Show(false)
--------------------------------------------------------------------------------------------------------
local MESSAGE_FADE_IN_TIME = 350
local MESSAGE_FADE_SOLID_TIME = 4000
local MESSAGE_FADE_OUT_TIME = 1000
local WIDGET_FADE_TRANSPARENT = 1
local WIDGET_FADE_IN = 2
local WIDGET_FADE_SOLID = 3
local WIDGET_FADE_OUT = 4
local wtMessage = nil
local fadeStatus = WIDGET_FADE_TRANSPARENT
local wtMessage = mainForm:GetChildChecked( "Announce", false )
wtMessage:Show( false )
---------------------------------------------------------------------------------------------------------
function AddBuff(params)
	if userMods.FromWString(params.buffName)=="Повезло" then
	wtMessage:SetVal( "value", "Можно искать хрусталь" )
	wtMessage:SetClassVal("class", "tip_green" )
	wtMessage:Show( true )
	wtMessage:PlayFadeEffect( 0.0, 1.0, MESSAGE_FADE_IN_TIME, EA_MONOTONOUS_INCREASE )
	fadeStatus = WIDGET_FADE_IN
	end 
end 

function OnEventEffectFinished ( params )
	if params.wtOwner:IsEqual( wtMessage ) then
		if fadeStatus == WIDGET_FADE_IN then
			wtMessage:PlayFadeEffect( 1.0, 1.0, MESSAGE_FADE_SOLID_TIME, EA_MONOTONOUS_INCREASE )
			fadeStatus = WIDGET_FADE_SOLID		
		elseif fadeStatus == WIDGET_FADE_SOLID then
			wtMessage:PlayFadeEffect( 1.0, 0.0, MESSAGE_FADE_OUT_TIME, EA_MONOTONOUS_INCREASE )
			fadeStatus = WIDGET_FADE_OUT		
		elseif fadeStatus == WIDGET_FADE_OUT then
			fadeStatus = WIDGET_FADE_TRANSPARENT
			wtMessage:Show( false )
		end
	end
end
---------------------------------------------------------------------------------------------------------
local ListButton = mainForm:GetChildChecked( "ListButton", false )
local ButtonText = mainForm:GetChildChecked( "ButtonText", false )

ButtonText:SetVal("name", userMods.ToWString(Params.ActivateAddon and "EPH ON" or "EPH OFF")) 
ButtonText:SetClassVal("class", "tip_green")
ListButton:AddChild(ButtonText)
ButtonText:Show(true)

local IsAOPanelEnabled = GetConfig( "EnableAOPanel" ) or GetConfig( "EnableAOPanel" ) == nil

function onAOPanelStart( params )
	if IsAOPanelEnabled then
	local stringName
	local class
		if Params.ActivateAddon then
			stringName = "   ON"
			class = "LogColorGreen"
		elseif not Params.active then
			stringName = "   OFF"
			class = "LogColorRed"
		end
		local SetVal = { val1 = userMods.ToWString(stringName), class1 = class }
		local params = { header = SetVal, ptype = "button", size = 55, icon = wtIcon }
		userMods.SendEvent( "AOPANEL_SEND_ADDON", { name = common.GetAddonName(), sysName = common.GetAddonName(), param = params } )
		ListButton:Show( false )
	end 
end

function OnAOPanelButtonLeftClick( params ) -- aopanel
if params.sender ~= "EPHelper" then return end
local stringName
local class
	if Params.ActivateAddon then 
		Params.ActivateAddon = false 
		stringName = "   OFF"
		class = "LogColorRed"
		userMods.SetGlobalConfigSection ("EPH_Params", Params)
	elseif not Params.ActivateAddon 
		then Params.ActivateAddon = true
		stringName = "   ON"
		class = "LogColorGreen"
		userMods.SetGlobalConfigSection ("EPH_Params", Params)
	end
	local SetVal = { val1 = userMods.ToWString(stringName), class1 = class }
	userMods.SendEvent( "AOPANEL_UPDATE_ADDON", { sysName = "EPHelper", header = SetVal } )
	if not Params.ActivateAddon then
	Params.ActivateAddon = false	
	LogToChat("EPHelper off")
	elseif Params.ActivateAddon then 
	Params.ActivateAddon = true
	LogToChat("EPHelper on")
	end 
end

function LeftClick(params)
if DnD:IsDragging() then return end
	ButtonText:SetVal("name", userMods.ToWString( Params.ActivateAddon and "EPH OFF" or "EPH ON" )) 
	Params.ActivateAddon = not Params.ActivateAddon
	if not Params.ActivateAddon then
	Params.ActivateAddon = false	
	LogToChat("EPHelper off")
	ButtonText:SetClassVal("class", "tip_red" )
	ButtonText:Show(true)
	elseif Params.ActivateAddon then 
	Params.ActivateAddon = true
	LogToChat("EPHelper on")
	ButtonText:SetClassVal("class", "tip_green" )
		end 
end 

function onAOPanelChange( params )
	if params.unloading and params.name == "UserAddon/AOPanelMod" then
		ListButton:Show( true )
	end
end

function enableAOPanelIntegration( enable )
	IsAOPanelEnabled = enable
	SetConfig( "EnableAOPanel", enable )
	if enable then
		onAOPanelStart()
	else
		ListButton:Show( true )
	end
end
---------------------------------------------------------------------------------------------------------

function LogToChat(text) -- message to chat
	if not wtChat then ---- 2.0.06.13 [26.05.2011]
		wtChat = stateMainForm:GetChildUnchecked("ChatLog", false)
		wtChat = wtChat:GetChildUnchecked("Container", true)
		local formatVT = "<html fontname='AllodsFantasy' fontsize='14' shadow='1'><rs class='color'><r name='addon'/><r name='text'/></rs></html>"
		valuedText:SetFormat(userMods.ToWString(formatVT))
	end
	if wtChat and wtChat.PushFrontValuedText then
		if not common.IsWString(text) then text = userMods.ToWString(text) end
		valuedText:ClearValues()
		valuedText:SetClassVal( "color", "LogColorYellow" )
		valuedText:SetVal( "text", text )
		valuedText:SetVal( "addon", userMods.ToWString("") )
		wtChat:PushFrontValuedText( valuedText )
	end
end
-------------------------------------------------------
--ASD API&Helps
-------------------------------------------------------
local GetContextActionShortInfo = avatar.GetContextActionShortInfo or avatar.GetContextActionInfo
local IsNavigateToPoint = avatar.IsNavigateToPoint or function() return false end
local ExtractWStringFromValuedText = function(str) return common.IsWString(str) and str or common.ExtractWStringFromValuedText(str) end
-------------------------------------------------------
local acceptedOnce
local cached
-------------------------------------------------------
--AUTOSELECTQUESTS
-------------------------------------------------------
function FinishQuest(interactorId) -- завершить квест
local flag = false
	local actions = autoSelectQuests and autoSelectQuests[userMods.FromWString(object.GetName(interactorId))]
	if actions then
		if not cached then
			cached = {}
			local quests = avatar.GetReturnableQuests()
			local imax = quests and GetTableSize(quests) or -1
			for i = 0, imax do
				if quests[i] then
					local progress = avatar.GetQuestProgress(quests[i])
					local reward = avatar.GetQuestReward(quests[i])
					local cantReturn = not progress or progress.state ~= QUEST_READY_TO_RETURN or GetTableSize(reward and reward.alternativeItems or {}) > 1
					if not cantReturn then
						local info = avatar.GetQuestInfo(quests[i])
						local name = userMods.FromWString(ExtractWStringFromValuedText(info.name))
						cached[name] = quests[i]
					end
				end
			end
		end
		for j = 1, GetTableSize(actions) do
			local name = actions[j]
			if cached[name] then
				if flag then return flag end
				acceptedOnce[name] = true
				if Params.ActivateAddon then
				local map = cartographer.GetCurrentMapInfo()
				if map then
				if userMods.FromWString(map.name) == "Царство Стихий" then
				local activeBuffs = object.GetBuffs( avatar.GetId() )
					for i, k in pairs(activeBuffs) do
						local buffInfo = object.GetBuffInfo( k )
						if buffInfo then
						if userMods.FromWString(buffInfo.name) == "Богатство" and buffInfo.stackCount == 6 then
							avatar.ReturnQuest(cached[name], nil)
							cached[name] = nil
							flag = true
						elseif userMods.FromWString(buffInfo.name) == "Богатство" and buffInfo.stackCount ~= 6 then
							LogToChat("Нехватает богатства! В наличии: "..buffInfo.stackCount.."/6")
							wtMessage:SetVal( "value", "Мало богатства: "..buffInfo.stackCount.."/6" )
							wtMessage:SetClassVal("class", "tip_red" )
							wtMessage:Show( true )
							wtMessage:PlayFadeEffect( 0.0, 1.0, MESSAGE_FADE_IN_TIME, EA_MONOTONOUS_INCREASE )
							fadeStatus = WIDGET_FADE_IN
							return
								end
							end
						end
					end
				end
			end
		end
	end
	cached = nil
	return flag
	end
end 


function AcceptQuest(interactorId) -- принЯть квест
	local actions = autoSelectQuests and autoSelectQuests[userMods.FromWString(object.GetName(interactorId))]
	if actions then
		local quests = avatar.GetAvailableQuests()
		local imax = quests and GetTableSize(quests) or -1
		if imax > 0 then
			local name = {}
			for j = 1, GetTableSize(actions) do
				if not acceptedOnce[ actions[j] ] then
					for i = 0, imax do
						if quests[i] then
							if not name[i] then
								local info = avatar.GetQuestInfo(quests[i])
								name[i] = userMods.FromWString(ExtractWStringFromValuedText(info.name))
							end
							if name[i] == actions[j] then
								acceptedOnce[ name[i] ] = true
								if Params.ActivateAddon then
								avatar.AcceptQuest(quests[i])
								return true
							end
						end
					end
				end
			end
		end
	end
end
end 

local lastCue
local inProgress = false

local retries
local maxRetries = 20

function OnTalkStarted() 
	inProgress = true
	acceptedOnce = {}
	retries = nil
	lastCue = nil
end 

function OnInteractionStarted()
	if not inProgress then return end
	local info = avatar.GetInteractorInfo()
	if info and info.hasInteraction then -- always true?
		inProgress = AcceptQuest(info.interactorId) or FinishQuest(info.interactorId) or false
	else
		inProgress = false
end
	if not inProgress then
		acceptedOnce = nil
		end
	end 

local activeNPC

function OnTalkStopped()
	if activeNPC then
		local target = avatar.GetTarget() -- or avatar.GetSecondaryTarget() ?
		local name = target and object.IsExist(target) and userMods.FromWString(object.GetName(target))
		if name and activeNPC == name then
			avatar.UnselectTarget()
		end
	end
	activeNPC = nil
	inProgress = false
	acceptedOnce = nil
end

-- Only checking new context actions
local knownNPCs = {}

function OnActionFailed( params )
	if activeNPC and params.sysId == "ENUM_ActionFailCause_TooFar" and not params.isInNotPredicate then
		if not retries then retries = maxRetries end
		if retries > 0 then
			retries = retries - 1
			-- Try again
			knownNPCs = {}
			activeNPC = nil
			OnContextActionsChanged()
		else
			-- It's enough
			retries = nil
			activeNPC = nil
		end
	end
end

function OnContextActionsChanged()
	local current = {}
	local flag = false
	local actions = avatar.GetContextActions()
	for _,action in pairs(actions) do
		local info = GetContextActionShortInfo(action)
		if info and info.objectId and info.enabled and info.sysType == "ENUM_CONTEXT_ACTION_TYPE_NPC_TALK" then
			local name = userMods.FromWString(object.GetName(info.objectId))
			if not knownNPCs[name] then
				flag = true
			end
			current[name] = info.objectId
		end
	end
	-- Not starting interaction if:
	--  1. already talking with another NPC
	--  2. automoving to NPC (not to point --- TODO)
	if avatar.IsTalking() or IsNavigateToPoint() then
		flag = false
	end
	if flag then
		for j = 1, GetTableSize(autoStartDialog) do
			local name = autoStartDialog[j]
			if current[name] and not knownNPCs[name] then
			if Params.ActivateAddon then
				avatar.StartInteract(current[name])
				activeNPC = name
				break
			end
		end
	end
	end 
	knownNPCs = current
end

function LoadSettings()
	if userMods.GetGlobalConfigSection("EPH_Params") then
		Params = userMods.GetGlobalConfigSection("EPH_Params")
	else userMods.SetGlobalConfigSection("EPH_Params", Params) end
end
-----------------------------------------------------------
function AvatarInit() -- avatar init
    if not avatar.IsExist() then
        return false
    end
    if not avatar.GetId() then    
        return false
    end
 common.UnRegisterEventHandler( AvatarInit, "EVENT_SECOND_TIMER" )
end

function Init() -- init
	common.RegisterEventHandler(AddBuff, "EVENT_OBJECT_BUFF_ADDED",{objectId = avatar.GetId() })
	common.RegisterEventHandler( OnEventEffectFinished, "EVENT_EFFECT_FINISHED" )
	common.RegisterEventHandler(OnTalkStarted, "EVENT_TALK_STARTED")
	common.RegisterEventHandler(OnTalkStopped, "EVENT_TALK_STOPPED")
	common.RegisterEventHandler(OnInteractionStarted, "EVENT_INTERACTION_STARTED")
	-- Let users disable this feature by removing everything from autoStartDialog
	if GetTableSize(autoStartDialog or {}) > 0 then
		common.RegisterEventHandler(OnActionFailed, "EVENT_ACTION_FAILED_OTHER")
		common.RegisterEventHandler(OnContextActionsChanged, "EVENT_CONTEXT_ACTIONS_CHANGED")
	else
		OnActionFailed = nil
		OnContextActionsChanged = nil
	end
	Init = nil
	common.RegisterEventHandler( AvatarInit, "EVENT_SECOND_TIMER" )
	common.RegisterEventHandler( onAOPanelStart, "AOPANEL_START" )
    common.RegisterEventHandler( OnAOPanelButtonLeftClick, "AOPANEL_BUTTON_LEFT_CLICK" )   
	common.RegisterEventHandler( onAOPanelChange, "EVENT_ADDON_LOAD_STATE_CHANGED" )
	common.RegisterReactionHandler( LeftClick, "LEFT_CLICK" )
	DnD:Init( 527, ListButton, ListButton, true )
	DnD:Init( 528, ButtonText, ListButton, true )
	wtIcon = mainForm:GetChildChecked( "IconPanel", false )
	LoadSettings()
end

if (avatar.IsExist()) then Init()
else common.RegisterEventHandler(Init, "EVENT_AVATAR_CREATED")	
end
