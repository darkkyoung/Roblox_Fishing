-- Phase 0.2: one plain bag panel and one contextual fishing meter. No previews.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local Shared=ReplicatedStorage:WaitForChild("Shared")
local Config=require(Shared.Config)
local ZoneConfig=require(Shared.ZoneConfig)
local Zones=require(Shared.Zones).new(ZoneConfig)
local Catalog=require(Shared.Catalog)
local Domain=require(Shared.Domain).new(Config,Catalog,require(Shared.Util))
local Presentation=require(Shared.Presentation)
local Layout=require(Shared.Layout)
local Strings=require(Shared.Strings)
local remotes=ReplicatedStorage:WaitForChild("Remotes")
local Action=remotes:WaitForChild("Action");local Input=remotes:WaitForChild("FishingInput")
local locale=string.sub(player.LocaleId,1,2)=="ko" and "ko" or "en"
local function t(key) return Strings[locale][key] or Strings.en[key] or tostring(key) end
local data,snapshotAt=nil,0
local phase={phase="Idle"}
local tab,selected,quality,context="fish",nil,"none","bag"
local debugOpen,coreMenu=false,false
local held,pointer,charging=false,nil,false
local timers={};local noticeVersion=0;local nextAction=0
local touch=UIS.TouchEnabled
local C={panel=Color3.fromRGB(242,243,245),text=Color3.fromRGB(30,35,43),muted=Color3.fromRGB(84,92,104),button=Color3.fromRGB(214,221,231),accent=Color3.fromRGB(236,161,74),disabled=Color3.fromRGB(202,204,209)}
local function make(class,parent,props)
    local object=Instance.new(class);for k,v in pairs(props or {}) do object[k]=v end;object.Parent=parent;return object
end
local function frame(parent,props)
    props.BorderSizePixel=0;props.BackgroundColor3=props.BackgroundColor3 or C.panel;return make("Frame",parent,props)
end
local function text(parent,value,pos,size,fontSize)
    return make("TextLabel",parent,{Text=value,Position=pos,Size=size,TextSize=fontSize or 15,TextColor3=C.text,BackgroundTransparency=1,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.Gotham})
end
local function button(parent,value,pos,size,callback,enabled)
    local b=make("TextButton",parent,{Text=value,Position=pos,Size=size,TextSize=15,TextColor3=C.text,Font=Enum.Font.Gotham,TextWrapped=true,BorderSizePixel=0,
        BackgroundColor3=enabled==false and C.disabled or C.button,Active=enabled~=false,AutoButtonColor=enabled~=false})
    if callback then b.Activated:Connect(function() if b.Active then callback() end end) end
    return b
end
local playerGui=player:WaitForChild("PlayerGui")
assert(not playerGui:FindFirstChild("FilamentBlockout"),"Duplicate FILAMENT client")
local gui=make("ScreenGui",playerGui,{Name="FilamentBlockout",ResetOnSpawn=false,ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets,ClipToDeviceSafeArea=true,DisplayOrder=10,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
local hud=make("ScreenGui",playerGui,{Name="FilamentBlockoutHUD",ResetOnSpawn=false,ScreenInsets=Enum.ScreenInsets.TopbarSafeInsets,ClipToDeviceSafeArea=true,DisplayOrder=10})
local coins=text(hud,"—",UDim2.new(1,-238,0,10),UDim2.fromOffset(136,44),16);coins.BackgroundTransparency=.05;coins.BackgroundColor3=C.panel;coins.TextXAlignment=Enum.TextXAlignment.Center
local bag=button(hud,t("bag"),UDim2.new(1,-94,0,10),UDim2.fromOffset(84,44))
local modal=frame(gui,{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(35,40,48),BackgroundTransparency=.4,Visible=false,Active=true,ZIndex=10})
local panel=frame(modal,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5)})
local title=text(panel,t("bag"),UDim2.fromOffset(12,4),UDim2.new(1,-120,0,44),18)
local close=button(panel,"×",UDim2.new(1,-52,0,4),UDim2.fromOffset(44,44))
local help=button(panel,"?",UDim2.new(1,-102,0,4),UDim2.fromOffset(44,44))
local tabs=frame(panel,{Position=UDim2.fromOffset(8,54),Size=UDim2.new(1,-16,0,44),BackgroundTransparency=1})
local tabButtons={}
local meta=text(panel,"",UDim2.fromOffset(12,102),UDim2.new(1,-24,0,56),14)
local body=make("ScrollingFrame",panel,{Position=UDim2.fromOffset(12,164),Size=UDim2.new(1,-24,1,-176),BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=4,ScrollingDirection=Enum.ScrollingDirection.Y})
local stack=make("UIListLayout",body,{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})
local meter=frame(gui,{AnchorPoint=Vector2.new(.5,0),Position=UDim2.fromScale(.5,.5),Visible=false})
local meterTitle=text(meter,"",UDim2.fromOffset(10,4),UDim2.new(1,-20,0,26),15)
local track=frame(meter,{Position=UDim2.fromOffset(10,34),Size=UDim2.new(1,-20,0,14),BackgroundColor3=C.button})
local fill=frame(track,{Size=UDim2.fromScale(0,1),BackgroundColor3=Color3.fromRGB(60,142,202)})
local meterHelp=text(meter,"",UDim2.fromOffset(10,52),UDim2.new(1,-20,0,34),14)
local hint=button(gui,"",UDim2.new(),UDim2.fromOffset(300,34));hint.AnchorPoint=Vector2.new(.5,0);hint.Visible=false
local control=button(gui,"",UDim2.new(),UDim2.fromOffset(64,64));control.BackgroundColor3=C.accent;control.Visible=false
local cancel=button(gui,"×",UDim2.new(),UDim2.fromOffset(44,44));cancel.Visible=false
local waiting=text(gui,"",UDim2.new(),UDim2.fromOffset(270,36),15);waiting.AnchorPoint=Vector2.new(.5,0);waiting.BackgroundColor3=C.panel;waiting.BackgroundTransparency=.05;waiting.TextXAlignment=Enum.TextXAlignment.Center;waiting.Visible=false
local toast=text(gui,"",UDim2.new(.5,0,0,64),UDim2.fromOffset(360,58),15);toast.AnchorPoint=Vector2.new(.5,0);toast.BackgroundTransparency=0;toast.BackgroundColor3=C.panel;toast.TextXAlignment=Enum.TextXAlignment.Center;toast.Visible=false;toast.ZIndex=20
local metrics=Layout.metrics(800,600,touch)
local render,updateFishing
local function notify(value)
    noticeVersion+=1;local version=noticeVersion
    toast.Text=value;toast.Visible=not coreMenu
    task.delay(3,function() if version==noticeVersion then toast.Visible=false end end)
end
local function release()
    held=false;pointer=nil
    if charging then Input:FireServer("release");charging=false end
    Input:FireServer("stopHold")
end
local function stopInput()
    release()
    if phase.phase~="Idle" and phase.phase~="Success" and phase.phase~="Failed" and phase.phase~="Saving" then Input:FireServer("cancel") end
end
local function position()
    local r=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    return r and {r.Position.X,r.Position.Y,r.Position.Z} or nil
end
local function equipped() return player.Character and player.Character:FindFirstChild(ZoneConfig.rodName)~=nil end
local function send(action,id,option)
    if os.clock()<nextAction then return end;nextAction=os.clock()+.45
    Action:FireServer(action,id,option)
end
local function row(value,height)
    local l=text(body,value,UDim2.new(),UDim2.new(1,-8,0,height or 0),15)
    if not height then l.AutomaticSize=Enum.AutomaticSize.Y end
    return l
end
local function rowButton(value,callback,enabled,height) return button(body,value,UDim2.new(),UDim2.new(1,-8,0,height or 46),callback,enabled) end
local function closeBag() modal.Visible=false;updateFishing() end
local function openBag(which)
    stopInput();tab=which or tab;selected=nil;modal.Visible=true;context=Zones.context(position(),data and data.plotId)
    body.CanvasPosition=Vector2.zero;render();updateFishing()
end
local function back() selected=nil;body.CanvasPosition=Vector2.zero;render() end
local function selectedItem(item)
    rowButton("‹ "..t("backList"),back)
    local d=Catalog[item.species]
    row(t(item.species).." · "..t(d.rarity).."\n"..t(item.location=="aquarium" and "placedState" or "bagState"))
    row(t("itemSource")..": "..t(item.source or "legacy").." · ID "..string.sub(item.id,1,8))
    if item.kind=="fish" then
        row(t("price")..": "..d.value.." · "..t("basic").." ×"..d.basicYield.." / "..t("premium").." ×"..d.premiumYield)
    elseif item.kind=="pet" then
        row(t("bite").." −"..math.floor((1-d.biteMultiplier)*100+.5).."%\n"..t("efficiency").." +"..math.floor((d.reelMultiplier-1)*100+.5).."%")
    elseif item.location=="aquarium" then
        local label=row("",48);table.insert(timers,{label=label,at=item.readyAt})
        row(t(item.feedQuality).." · Lv."..item.incubationLevel.."\n"..t("lockedEgg"))
    elseif context=="aquarium" then
        row(t("feedTitle"))
        for _,q in ipairs({"none","basic","premium"}) do
            rowButton((quality==q and "✓ " or "")..t(q).." · "..Config.Feed[q].duration..t("seconds"),function() quality=q;render() end,q=="none" or data.feed[q]>0)
        end
        local weights=Domain.weights(data.aquariumLevel,quality,Config.Feed[quality].duration);local sum=0;local lines={}
        for _,w in ipairs(weights) do sum+=w.weight end
        for _,w in ipairs(weights) do table.insert(lines,t(w.id).." "..string.format("%.2f%%",w.weight/sum*100)) end
        row(table.concat(lines,"\n"));row(t("snapshotted"))
    end
    local actions=Presentation.actions(item,context,data.equippedPet,Catalog)
    for _,key in ipairs(actions) do
        local enabled=key~="place" or Domain.occupied(data)<Config.Aquarium[data.aquariumLevel].capacity
        rowButton(t(key),function()
            if key=="craftBasic" then send("craft",item.id,"basic")
            elseif key=="craftPremium" then send("craft",item.id,"premium")
            else send(key,item.id,item.kind=="egg" and quality or nil) end
        end,enabled)
    end
    if #actions==0 then row(t(item.kind=="egg" and item.location=="aquarium" and "lockedEgg" or "zoneHint")) end
end
local function helpPage()
    row(t("helpBody"));row(t("saveLabel")..": "..t(data and data.saveStatus or "loading"))
    if data then row(t("sessionChecks")..": "..data.sessionStats.catches.." / DEBUG "..data.sessionStats.debug) end
    rowButton(t("language"),function() locale=locale=="ko" and "en" or "ko";render();bag.Text=t("bag") end)
    rowButton(t("rodHelp"),function() send("rod") end)
    if data and data.debugEnabled then
        rowButton(t("debugToggle"),function() debugOpen=not debugOpen;render() end)
        if debugOpen then
            row(t("testNotice"))
            for _,key in ipairs({"debugFish","debugEgg","debugFeed","debugCoins","debugHatch"}) do rowButton(t(key),function() send(key) end) end
            for level=1,3 do rowButton("DEBUG Lv."..level,function() send("debugLevel",nil,tostring(level)) end) end
            for _,id in ipairs({"SpawnPlaza","FishingDock","FishMarket","FeedWorkshop","AquariumGarden","aquarium"}) do
                local titleText=id=="aquarium" and t("aquarium") or ZoneConfig.zones[id].label[locale]
                rowButton(t("travelLabel").." · "..titleText,function() send("travel",id);closeBag() end)
            end
        end
    end
end
render=function()
    if not modal.Visible then return end
    for _,child in ipairs(body:GetChildren()) do if child~=stack then child:Destroy() end end
    timers={};title.Text=t(tab=="help" and "help" or "bag")
    for key,b in pairs(tabButtons) do b.Text=t(key);b.BackgroundColor3=key==tab and C.accent or C.button end
    if not data then meta.Text=t("loading");return end
    title.Text=t(tab=="help" and "help" or "bag").." · "..data.coins.." "..t("coins")
    local zoneLabel=t(({shop="shop",craft="craft",aquarium="aquarium",bag="exploring"})[context])
    meta.Text=zoneLabel.." · "..(data.plotId or "").."\n"..t("basic").." "..data.feed.basic.." / "..t("premium").." "..data.feed.premium.." · Lv."..data.aquariumLevel
    if tab=="help" then helpPage();return end
    if selected and data.items[selected] then selectedItem(data.items[selected]);return end
    if tab=="tank" then
        local count=Domain.occupied(data);local lv=data.aquariumLevel;local cost=Config.Aquarium[lv].nextCost
        row(t("capacity")..": "..count.." / "..Config.Aquarium[lv].capacity.." · "..t("zoneHint"))
        if cost>0 then rowButton(t("upgrade").." · "..cost.." "..t("coins"),function() send("upgrade") end,context=="aquarium" and data.coins>=cost)
        else row(t("maxLevel")) end
    end
    local items={}
    for _,item in pairs(data.items) do
        if (tab=="fish" and item.kind=="fish") or (tab=="eggs" and item.kind=="egg") or (tab=="pets" and item.kind=="pet") or (tab=="tank" and item.location=="aquarium") then table.insert(items,item) end
    end
    table.sort(items,function(a,b) if a.obtainedAt==b.obtainedAt then return a.id<b.id end;return a.obtainedAt>b.obtainedAt end)
    if #items==0 then row(t("empty")) end
    for _,item in ipairs(items) do
        local state=item.id==data.equippedPet and t("equippedLabel") or t(item.location=="aquarium" and "placedState" or "bagState")
        local prefix=item.source=="studioDebug" and "[DEBUG] " or ""
        rowButton(prefix..t(item.species).." · "..t(Catalog[item.species].rarity).."\n"..state.." · "..string.sub(item.id,1,8),function() selected=item.id;body.CanvasPosition=Vector2.zero;render() end,true,66)
    end
end
for i,key in ipairs({"fish","eggs","pets","tank"}) do
    tabButtons[key]=button(tabs,t(key),UDim2.new((i-1)/4,2,0,0),UDim2.new(.25,-4,1,0),function() tab=key;back() end)
end
bag.Activated:Connect(function() if modal.Visible then closeBag() else openBag() end end)
close.Activated:Connect(closeBag);help.Activated:Connect(function() tab="help";selected=nil;render() end)
cancel.Activated:Connect(stopInput)
local function press(input)
    if modal.Visible or coreMenu or not data or not equipped() or pointer then return end
    if phase.phase=="Idle" and not Zones.canFish(position()) then notify(t("goDock"));return end
    local intent=Presentation.intent(phase.phase,held);if not intent then return end
    held=true;pointer=input;charging=intent=="start";Input:FireServer(intent)
end
for _,b in ipairs({hint,control}) do b.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then press(input) end
end) end
UIS.InputBegan:Connect(function(input,processed)
    if processed or UIS:GetFocusedTextBox() or coreMenu then return end
    if input.KeyCode==Enum.KeyCode.F then press(input)
    elseif input.KeyCode==Enum.KeyCode.B then if modal.Visible then closeBag() else openBag() end
    elseif input.KeyCode==Enum.KeyCode.R then send("rod") end
end)
UIS.InputEnded:Connect(function(input)
    if input==pointer or (pointer and input.KeyCode==Enum.KeyCode.F and pointer.KeyCode==Enum.KeyCode.F)
        or (pointer and input.UserInputType==Enum.UserInputType.MouseButton1 and pointer.UserInputType==Enum.UserInputType.MouseButton1) then release() end
end)
UIS.WindowFocusReleased:Connect(stopInput)
updateFishing=function()
    local state=phase.phase
    local v=Presentation.view(state,equipped(),Zones.canFish(position()),modal.Visible or coreMenu)
    meter.Visible=v.meter;hint.Visible=v.hint;control.Visible=v.action and (touch or state~="Idle");cancel.Visible=v.cancel;waiting.Visible=v.waiting
    hint.Text=t(Zones.canFish(position()) and "idleHint" or "goDock")
    control.Text=t(state=="Reel" and "holdShort" or (state=="Resist" and "tapShort" or "castShort"))
    waiting.Text=t(state=="Saving" and "savingCatch" or (state=="Flight" and "flight" or "waiting"))
    local value=phase.progress or 0
    if state=="Charge" then value=phase.power or 0;meterTitle.Text=t("power").." "..math.floor(value*100).."%";meterHelp.Text=t("releaseHint")
    elseif state=="Resist" then value=(phase.taps or 0)/Config.Fishing.ResistanceTaps;meterTitle.Text=t("resistance").." "..(phase.taps or 0).."/9 · "..string.format("%.1f",phase.remaining or 0)..t("seconds");meterHelp.Text=t("tapHint")
    else meterTitle.Text=t("progress").." "..math.floor(value*100).."%";meterHelp.Text=t("holdHint") end
    fill.Size=UDim2.fromScale(math.clamp(value,0,1),1);fill.BackgroundColor3=state=="Resist" and C.accent or Color3.fromRGB(60,142,202)
end
local function resize()
    local size=gui.AbsoluteSize;metrics=Layout.metrics(size.X,size.Y,touch)
    panel.Size=UDim2.fromOffset(metrics.panelWidth,metrics.panelHeight)
    meter.Position=UDim2.new(.5,0,0,metrics.meterY);meter.Size=UDim2.fromOffset(metrics.meterWidth,90)
    control.Position=UDim2.fromOffset(metrics.actionX,metrics.actionY);control.Size=UDim2.fromOffset(metrics.actionW,metrics.actionH)
    cancel.Position=UDim2.fromOffset(metrics.cancelX,metrics.actionY)
    hint.Position=UDim2.new(.5,0,0,metrics.hintY);hint.Size=UDim2.fromOffset(math.min(350,size.X-24),34)
    waiting.Position=UDim2.new(.5,0,0,metrics.meterY+20);waiting.Size=UDim2.fromOffset(math.min(270,size.X-24),36)
    toast.Size=UDim2.fromOffset(math.min(370,size.X-24),size.Y<430 and 32 or 58)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
local function hudResize()
    local h=Layout.hud(hud.AbsoluteSize.X)
    coins.Visible=h.showCoins;coins.Position=UDim2.new(0,h.coinX,.5,-22);coins.Size=UDim2.fromOffset(h.coinWidth,44)
    bag.Position=UDim2.new(0,h.bagX,.5,-22);bag.Size=UDim2.fromOffset(h.bagWidth,44)
end
hud:GetPropertyChangedSignal("AbsoluteSize"):Connect(hudResize)
GuiService.MenuOpened:Connect(function() coreMenu=true;stopInput();modal.Visible=false;toast.Visible=false;updateFishing() end)
GuiService.MenuClosed:Connect(function() coreMenu=false;updateFishing() end)
remotes:WaitForChild("FishingState").OnClientEvent:Connect(function(state)
    local previous=phase.phase;phase=state
    if state.phase=="Reel" and previous=="Waiting" then notify(t("biteNow")) end
    if state.phase=="Reel" and previous=="Resist" then notify(t("resistCleared")) end
    if state.phase=="Success" then notify(t("success").." · "..t(state.species)) elseif state.phase=="Failed" then notify(t("failed")) end
    if state.phase=="Success" or state.phase=="Failed" or state.phase=="Idle" then held=false;pointer=nil;charging=false end
    if state.phase=="Success" or state.phase=="Failed" then task.delay(2,function() if phase==state then phase={phase="Idle"};updateFishing() end end) end
    updateFishing()
end)
remotes:WaitForChild("Snapshot").OnClientEvent:Connect(function(snapshot)
    local initial=data==nil
    data=snapshot;snapshotAt=os.clock();nextAction=0
    if initial and data.saveStatus=="memory" then notify(t("memory")) end
    coins.Text=t("coins").." "..data.coins
    if quality~="none" and data.feed[quality]<1 then quality="none" end
    if selected and not data.items[selected] then selected=nil end
    context=Zones.context(position(),data.plotId);render()
end)
remotes:WaitForChild("SaveStatus").OnClientEvent:Connect(function(status)
    if data then data.saveStatus=status end
    if status=="error" then notify(t("error")) end
    if modal.Visible and tab=="help" then render() end
end)
remotes:WaitForChild("Notice").OnClientEvent:Connect(function(key) nextAction=0;notify(t(key)) end)
remotes:WaitForChild("OpenPanel").OnClientEvent:Connect(function(which) openBag(which) end)
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
    elapsed+=dt;if elapsed<.15 then return end;elapsed=0
    if held and phase.phase=="Reel" and not modal.Visible and not coreMenu then Input:FireServer("hold") end
    local nextContext=Zones.context(position(),data and data.plotId)
    if nextContext~=context then context=nextContext;render() end
    local now=data and data.serverTime+os.clock()-snapshotAt or os.time()
    for _,entry in ipairs(timers) do if entry.label.Parent then entry.label.Text=t("incubating").." · "..math.max(0,math.ceil(entry.at-now))..t("seconds") end end
    updateFishing()
end)
player.CharacterAdded:Connect(function() release();phase={phase="Idle"};modal.Visible=false end)
resize();hudResize();updateFishing()
task.spawn(function() for _=1,12 do Action:FireServer("sync");if data then return end;task.wait(2) end end)
