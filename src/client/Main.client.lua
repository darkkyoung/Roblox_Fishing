local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UserInputService=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local Shared=ReplicatedStorage:WaitForChild("Shared")
local Config=require(Shared.Config)
local Catalog=require(Shared.Catalog)
local Strings=require(Shared.Strings)
local Layout=require(Shared.Layout)
local Domain=require(Shared.Domain).new(Config,Catalog,require(Shared.Util))
local remotes=ReplicatedStorage:WaitForChild("Remotes")
local Action=remotes:WaitForChild("Action")
local FishingInput=remotes:WaitForChild("FishingInput")
local palette={bg=Color3.fromRGB(17,39,48),card=Color3.fromRGB(29,58,67),line=Color3.fromRGB(65,104,111),text=Color3.fromRGB(244,239,219),muted=Color3.fromRGB(170,199,199),accent=Color3.fromRGB(255,174,89),mint=Color3.fromRGB(111,218,191),red=Color3.fromRGB(255,126,116)}
local locale=string.sub(player.LocaleId,1,2)=="ko" and "ko" or "en"
local data=nil
local snapshotAt=0
local selectedTab="fish"
local feedQuality="none"
local fishState={phase="Idle",progress=0,power=0,taps=0,remaining=0}
local held=false
local castPressed=false
local pointer=nil
local actionPendingUntil=0
local timers={}
local function t(key) return Strings[locale][key] or Strings.en[key] or tostring(key) end
local function new(class,parent,props)
    local obj=Instance.new(class)
    for k,v in pairs(props or {}) do obj[k]=v end
    obj.Parent=parent
    return obj
end
local function corner(obj,radius) new("UICorner",obj,{CornerRadius=UDim.new(0,radius or 10)}) end
local function label(parent,text,pos,size,textSize,color)
    return new("TextLabel",parent,{Text=text,Position=pos,Size=size,BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=textSize or 14,TextColor3=color or palette.text,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true})
end
local function button(parent,text,pos,size,callback,color)
    local b=new("TextButton",parent,{Text=text,Position=pos,Size=size,BackgroundColor3=color or palette.line,TextColor3=palette.text,Font=Enum.Font.GothamBold,TextSize=13,TextWrapped=true,AutoButtonColor=true})
    corner(b,8)
    if callback then b.Activated:Connect(callback) end
    return b
end
local gui=new("ScreenGui",player:WaitForChild("PlayerGui"),{Name="FilamentUI",ResetOnSpawn=false,IgnoreGuiInset=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=10})
local hud=new("Frame",gui,{Position=UDim2.fromOffset(12,6),Size=UDim2.new(1,-24,0,48),BackgroundColor3=palette.bg})
corner(hud)
local title=label(hud,t("title"),UDim2.fromOffset(12,3),UDim2.new(.6,-12,0,21),13)
title.Font=Enum.Font.GothamBold
local money=label(hud,"—",UDim2.new(.6,0,0,3),UDim2.new(.4,-12,0,21),15,palette.accent)
money.TextXAlignment=Enum.TextXAlignment.Right
local saveLabel=label(hud,t("loading"),UDim2.fromOffset(12,26),UDim2.new(1,-24,0,16),11,palette.muted)
local nav=new("ScrollingFrame",gui,{Position=UDim2.fromOffset(12,60),Size=UDim2.new(1,-24,0,36),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=0,ScrollingDirection=Enum.ScrollingDirection.X,AutomaticCanvasSize=Enum.AutomaticSize.X,CanvasSize=UDim2.new()})
new("UIListLayout",nav,{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder})
local fishing=new("Frame",gui,{AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,108),Size=UDim2.fromOffset(430,194),BackgroundColor3=palette.bg,BackgroundTransparency=.06})
corner(fishing,14)
local fishTitle=label(fishing,t("idle"),UDim2.fromOffset(14,8),UDim2.new(1,-65,0,28),16)
fishTitle.Font=Enum.Font.GothamBold
local cancelButton=button(fishing,"×",UDim2.new(1,-44,0,7),UDim2.fromOffset(32,30),function() FishingInput:FireServer("cancel");held=false;castPressed=false end)
local gaugeText=label(fishing,t("power"),UDim2.fromOffset(14,43),UDim2.new(1,-28,0,20),12,palette.muted)
local track=new("Frame",fishing,{Position=UDim2.fromOffset(14,68),Size=UDim2.new(1,-28,0,14),BackgroundColor3=palette.line,BorderSizePixel=0})
corner(track,7)
local fill=new("Frame",track,{Size=UDim2.fromScale(0,1),BackgroundColor3=palette.mint,BorderSizePixel=0})
corner(fill,7)
local resistanceMark=new("Frame",track,{Position=UDim2.fromScale(Config.Fishing.ResistanceAt,0),Size=UDim2.new(0,3,1,0),BackgroundColor3=palette.accent,BorderSizePixel=0})
local resistanceText=label(fishing,"",UDim2.fromOffset(14,85),UDim2.new(1,-28,0,20),12,palette.accent)
local actionButton=button(fishing,t("castButton"),UDim2.fromOffset(14,112),UDim2.new(1,-28,0,48),nil,palette.accent)
actionButton.TextColor3=palette.bg
local keyHint=label(fishing,t("keyHint"),UDim2.fromOffset(14,166),UDim2.new(1,-28,0,18),11,palette.muted)
keyHint.TextXAlignment=Enum.TextXAlignment.Center
local toast=label(gui,"",UDim2.new(.5,0,0,310),UDim2.new(1,-30,0,44),14,palette.text)
toast.AnchorPoint=Vector2.new(.5,0);toast.BackgroundColor3=palette.bg;toast.BackgroundTransparency=.08;toast.TextXAlignment=Enum.TextXAlignment.Center;toast.Visible=false;toast.ZIndex=30;corner(toast)
local toastSequence=0
local function notify(key)
    toastSequence+=1
    local sequence=toastSequence
    toast.Text=t(key);toast.Visible=true
    task.delay(3.5,function() if toastSequence==sequence then toast.Visible=false end end)
end
local overlay=new("Frame",gui,{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.35,Visible=false,ZIndex=20,Active=true})
local panel=new("Frame",overlay,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(760,560),BackgroundColor3=palette.bg})
corner(panel,14)
local panelTitle=label(panel,t("inventory"),UDim2.fromOffset(16,8),UDim2.new(1,-130,0,30),21)
panelTitle.Font=Enum.Font.GothamBold
local close=button(panel,t("close"),UDim2.new(1,-90,0,8),UDim2.fromOffset(74,32),function() overlay.Visible=false end)
local tabs=new("ScrollingFrame",panel,{Position=UDim2.fromOffset(12,48),Size=UDim2.new(1,-24,0,38),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,ScrollingDirection=Enum.ScrollingDirection.X,AutomaticCanvasSize=Enum.AutomaticSize.X,CanvasSize=UDim2.new()})
new("UIListLayout",tabs,{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder})
local content=new("ScrollingFrame",panel,{Position=UDim2.fromOffset(12,94),Size=UDim2.new(1,-24,1,-108),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ScrollingDirection=Enum.ScrollingDirection.Y})
local list=new("UIListLayout",content,{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder})
local navButtons={}
local tabButtons={}
local render
local function send(action,id,option)
    if os.clock()<actionPendingUntil then return end
    actionPendingUntil=os.clock()+.55
    Action:FireServer(action,id,option)
end
local function release()
    held=false;pointer=nil
    if castPressed then FishingInput:FireServer("release");castPressed=false end
    FishingInput:FireServer("stopHold")
end
local function open(tab)
    release()
    if fishState.phase~="Idle" then FishingInput:FireServer("cancel") end
    selectedTab=tab or selectedTab
    overlay.Visible=true
    render()
end
local function travel(destination)
    release();overlay.Visible=false
    Action:FireServer("travel",destination)
end
local function row(height)
    local f=new("Frame",content,{Size=UDim2.new(1,-6,0,height),BackgroundColor3=palette.card,BorderSizePixel=0})
    corner(f,10);return f
end
local function itemCard(item)
    local def=Catalog[item.species]
    local egg=item.kind=="egg"
    local inTank=item.location=="aquarium"
    local f=row(egg and 142 or (item.kind=="fish" and 148 or 126))
    local dot=new("Frame",f,{Position=UDim2.fromOffset(12,14),Size=UDim2.fromOffset(12,12),BackgroundColor3=Color3.fromRGB(def.color[1],def.color[2],def.color[3]),BorderSizePixel=0})
    corner(dot,6)
    label(f,t(def.nameKey).." · "..t(def.rarity),UDim2.fromOffset(32,7),UDim2.new(1,-42,0,27),15)
    label(f,(inTank and t("inTank") or t("bag")).." · #"..string.sub(item.id,1,7),UDim2.fromOffset(12,36),UDim2.new(1,-24,0,18),11,palette.muted)
    local function action(text,index,count,callback,y)
        return button(f,text,UDim2.new((index-1)/count,8,0,y or 96),UDim2.new(1/count,-16,0,40),callback)
    end
    if item.kind=="fish" then
        label(f,t("price").." "..def.value.." · "..t("basic").." ×"..def.basicYield.." · "..t("premium").." ×"..def.premiumYield,UDim2.fromOffset(12,59),UDim2.new(1,-24,0,28),12)
        if inTank then action(t("retrieve"),1,1,function() send("retrieve",item.id) end)
        else
            action(t("place"),1,4,function() send("place",item.id) end)
            action(t("sell"),2,4,function() send("sell",item.id) end)
            action(t("craftBasic"),3,4,function() send("craft",item.id,"basic") end)
            action(t("craftPremium"),4,4,function() send("craft",item.id,"premium") end)
        end
    elseif egg then
        if inTank then
            local timer=label(f,"",UDim2.fromOffset(12,60),UDim2.new(1,-24,0,24),15,palette.accent)
            table.insert(timers,{label=timer,readyAt=item.readyAt})
            label(f,t(item.feedQuality).." · Lv."..item.incubationLevel.."\n"..t("lockedEgg"),UDim2.fromOffset(12,88),UDim2.new(1,-24,0,44),12,palette.muted)
        else
            label(f,t(feedQuality).." · "..Config.Feed[feedQuality].duration..t("seconds"),UDim2.fromOffset(12,61),UDim2.new(1,-24,0,22),13,palette.accent)
            action(t("place"),1,1,function() send("place",item.id,feedQuality) end,92)
        end
    else
        label(f,t("bite").." -"..math.floor((1-def.biteMultiplier)*100+.5).."%  ·  "..t("efficiency").." +"..math.floor((def.reelMultiplier-1)*100+.5).."%",UDim2.fromOffset(12,58),UDim2.new(1,-24,0,20),12,palette.mint)
        local equipped=data.equippedPet==item.id
        action(equipped and (t("equippedLabel").." · "..t("unequip")) or t("equip"),1,1,function() send(equipped and "unequip" or "equip",item.id) end,82)
    end
end
render=function()
    if not overlay.Visible then return end
    local previousScroll=content.CanvasPosition
    for _,child in ipairs(content:GetChildren()) do if child~=list then child:Destroy() end end
    timers={}
    for key,b in pairs(tabButtons) do b.Text=t(key);b.BackgroundColor3=selectedTab==key and palette.accent or palette.line;b.TextColor3=selectedTab==key and palette.bg or palette.text end
    panelTitle.Text=t(selectedTab);close.Text=t("close")
    if not data then local f=row(60);label(f,t("loading"),UDim2.fromOffset(12,5),UDim2.new(1,-24,1,-10));return end
    if selectedTab=="help" then
        local f=row(0)
        f.AutomaticSize=Enum.AutomaticSize.Y
        new("UIPadding",f,{PaddingTop=UDim.new(0,12),PaddingBottom=UDim.new(0,12),PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12)})
        local helpText=label(f,t("helpBody"),UDim2.new(),UDim2.new(1,0,0,0),13)
        helpText.AutomaticSize=Enum.AutomaticSize.Y
        helpText.TextYAlignment=Enum.TextYAlignment.Top
        local languageRow=row(52)
        button(languageRow,t("language"),UDim2.fromOffset(8,6),UDim2.new(1,-16,0,40),function() locale=locale=="ko" and "en" or "ko";render() end)
        if data.debugEnabled then
            local d=row(164)
            label(d,t("debugTitle"),UDim2.fromOffset(12,5),UDim2.new(1,-24,0,26),16,palette.accent)
            button(d,t("debugPack"),UDim2.fromOffset(10,40),UDim2.new(1,-20,0,40),function() send("debugPack") end)
            button(d,t("debugHatch"),UDim2.fromOffset(10,86),UDim2.new(1,-20,0,40),function() send("debugHatch") end)
            label(d,t("testNotice"),UDim2.fromOffset(12,130),UDim2.new(1,-24,0,26),11,palette.muted)
        end
        return
    end
    local shortcuts=row(48)
    for index,key in ipairs({"aquarium","shop","craft"}) do
        button(shortcuts,t(key),UDim2.new((index-1)/3,5,0,5),UDim2.new(1/3,-10,0,38),function() travel(key) end)
    end
    if selectedTab=="tank" then
        local f=row(106)
        local lv=data.aquariumLevel
        label(f,t("level").." "..lv.." · "..t("capacity").." "..Domain.occupied(data).."/"..Config.Aquarium[lv].capacity,UDim2.fromOffset(12,8),UDim2.new(1,-24,0,24),16)
        button(f,lv<3 and (t("upgrade").." · "..Config.Aquarium[lv].nextCost.." "..t("coins")) or t("maxLevel"),UDim2.fromOffset(10,51),UDim2.new(1,-20,0,42),function() send("upgrade") end)
    elseif selectedTab=="eggs" then
        local f=row(180)
        label(f,t("feedChoice"),UDim2.fromOffset(12,4),UDim2.new(1,-24,0,25),14)
        for index,key in ipairs({"none","basic","premium"}) do
            local count=key=="none" and "" or " ×"..data.feed[key]
            button(f,(feedQuality==key and "✓ " or "")..t(key)..count,UDim2.new((index-1)/3,6,0,36),UDim2.new(1/3,-12,0,42),function() feedQuality=key;render() end,feedQuality==key and palette.line or palette.bg)
        end
        local entries=Domain.weights(data.aquariumLevel,feedQuality,Config.Feed[feedQuality].duration)
        local total=0
        for _,entry in ipairs(entries) do total+=entry.weight end
        local parts={}
        for _,entry in ipairs(entries) do table.insert(parts,t(Catalog[entry.id].rarity).." "..string.format("%.2f%%",100*entry.weight/total)) end
        label(f,t("probabilities").."\n"..table.concat(parts," · "),UDim2.fromOffset(12,86),UDim2.new(1,-24,0,48),12,palette.mint)
        label(f,t("snapshotted"),UDim2.fromOffset(12,139),UDim2.new(1,-24,0,32),11,palette.muted)
    elseif selectedTab=="fish" then
        local f=row(50)
        label(f,t("basic").." ×"..data.feed.basic.."  ·  "..t("premium").." ×"..data.feed.premium,UDim2.fromOffset(12,5),UDim2.new(1,-24,1,-10),13,palette.mint)
    elseif selectedTab=="pets" then
        local f=row(60)
        local pet=data.items[data.equippedPet]
        label(f,t("buff")..": "..(pet and t(pet.species) or t("noPet")),UDim2.fromOffset(12,5),UDim2.new(1,-24,1,-10),14,palette.mint)
    end
    local items={}
    for _,item in pairs(data.items) do
        if (selectedTab=="fish" and item.kind=="fish") or (selectedTab=="eggs" and item.kind=="egg") or (selectedTab=="pets" and item.kind=="pet") or (selectedTab=="tank" and item.location=="aquarium") then table.insert(items,item) end
    end
    table.sort(items,function(a,b) if a.obtainedAt==b.obtainedAt then return a.id<b.id end;return a.obtainedAt>b.obtainedAt end)
    for _,item in ipairs(items) do itemCard(item) end
    if #items==0 then local f=row(90);label(f,t(selectedTab=="tank" and "emptyTank" or "empty"),UDim2.fromOffset(12,8),UDim2.new(1,-24,1,-16),14,palette.muted) end
    task.defer(function() content.CanvasPosition=previousScroll end)
end
for index,key in ipairs({"fish","eggs","pets","tank","help"}) do
    local b=button(tabs,t(key),UDim2.new(),UDim2.fromOffset(92,34),function() selectedTab=key;content.CanvasPosition=Vector2.zero;render() end)
    b.LayoutOrder=index;tabButtons[key]=b
end
for index,key in ipairs({"inventory","dock","aquarium","shop","craft","rod","help"}) do
    local b=button(nav,t(key),UDim2.new(),UDim2.fromOffset(key=="inventory" and 78 or 102,36),function()
        if key=="inventory" then open(selectedTab)
        elseif key=="help" then open("help")
        elseif key=="rod" then Action:FireServer("rod")
        else travel(key) end
    end,key=="inventory" and palette.accent or palette.bg)
    if key=="inventory" then b.TextColor3=palette.bg end
    b.LayoutOrder=index;navButtons[key]=b
end
local function resize()
    local size=gui.AbsoluteSize
    local metrics=Layout.metrics(size.X,size.Y)
    panel.Size=UDim2.fromOffset(metrics.panelWidth,metrics.panelHeight)
    fishing.Size=UDim2.fromOffset(metrics.fishWidth,194)
    fishing.Position=UDim2.new(.5,0,0,metrics.fishY)
    toast.Position=UDim2.new(.5,0,0,metrics.fishY+200)
    if size.Y<390 then toast.Position=UDim2.new(.5,0,0,6) end
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
resize()
local function press()
    if overlay.Visible or not data then return end
    if held then return end
    held=true
    local phase=fishState.phase
    if phase=="Idle" or phase=="Success" or phase=="Failed" then
        castPressed=true;FishingInput:FireServer("start")
    elseif phase=="Resist" then FishingInput:FireServer("tap")
    elseif phase=="Reel" then FishingInput:FireServer("hold") end
end
actionButton.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
        if not pointer then pointer=input;press() end
    end
end)
UserInputService.InputBegan:Connect(function(input,processed)
    if processed or UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode==Enum.KeyCode.F then press()
    elseif input.KeyCode==Enum.KeyCode.B then if overlay.Visible then overlay.Visible=false else open() end
    elseif input.KeyCode==Enum.KeyCode.R then Action:FireServer("rod") end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode==Enum.KeyCode.F or input==pointer or (input.UserInputType==Enum.UserInputType.MouseButton1 and pointer and pointer.UserInputType==Enum.UserInputType.MouseButton1) then release() end
end)
UserInputService.WindowFocusReleased:Connect(release)
local phaseKeys={Idle="idle",Charge="charge",Flight="flight",Waiting="waiting",Reel="reel",Resist="resist",Success="success",Failed="failed",Saving="savingCatch"}
local function updateFishing()
    local phase=fishState.phase
    fishTitle.Text=t(phaseKeys[phase] or "idle")..(fishState.species and (" · "..t(fishState.species)) or "")
    keyHint.Text=t("keyHint")
    resistanceMark.Visible=phase=="Reel" or phase=="Resist"
    local value=fishState.progress or 0
    gaugeText.Text=t("progress").." · "..math.floor(value*100).."%"
    fill.BackgroundColor3=palette.mint
    resistanceText.Text=""
    if phase=="Idle" or phase=="Charge" then
        value=fishState.power or 0
        gaugeText.Text=t("power").." · "..math.floor(value*100).."%"
        actionButton.Text=t("castButton")
    elseif phase=="Reel" then actionButton.Text=t("reelButton")
    elseif phase=="Resist" then
        value=(fishState.taps or 0)/Config.Fishing.ResistanceTaps
        gaugeText.Text=t("resistance").." · "..(fishState.taps or 0).."/"..Config.Fishing.ResistanceTaps
        fill.BackgroundColor3=palette.accent
        resistanceText.Text=string.format("%.1f",fishState.remaining or 0)..t("seconds")
        actionButton.Text=t("tapButton")
    elseif phase=="Success" or phase=="Failed" then actionButton.Text=t("castButton")
    else actionButton.Text=t("waitingButton") end
    fill.Size=UDim2.fromScale(math.clamp(value,0,1),1)
    cancelButton.Visible=phase~="Idle" and phase~="Success" and phase~="Failed"
end
remotes.FishingState.OnClientEvent:Connect(function(state)
    fishState=state
    if state.phase=="Failed" or state.phase=="Success" or state.phase=="Idle" then held=false;castPressed=false end
    updateFishing()
    if state.phase=="Success" or state.phase=="Failed" then
        local exact=state
        task.delay(2.5,function() if fishState==exact then fishState={phase="Idle"};updateFishing() end end)
    end
end)
remotes.Snapshot.OnClientEvent:Connect(function(snapshot)
    data=snapshot;snapshotAt=os.clock();actionPendingUntil=0
    money.Text=t("coins").." "..data.coins
    saveLabel.Text=t(data.saveStatus)
    saveLabel.TextColor3=data.saveStatus=="memory" and palette.accent or palette.mint
    render()
end)
remotes.SaveStatus.OnClientEvent:Connect(function(status)
    saveLabel.Text=t(status);saveLabel.TextColor3=status=="error" and palette.red or (status=="memory" and palette.accent or palette.mint)
    if data then data.saveStatus=status end
end)
remotes.Notice.OnClientEvent:Connect(function(key) actionPendingUntil=0;notify(key) end)
remotes.OpenPanel.OnClientEvent:Connect(open)
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
    elapsed+=dt
    if elapsed<.15 then return end
    elapsed=0
    if held and fishState.phase=="Reel" and not overlay.Visible then FishingInput:FireServer("hold") end
    if data then
        local now=data.serverTime+os.clock()-snapshotAt
        for _,entry in ipairs(timers) do
            if entry.label.Parent then
                local remaining=math.max(0,math.ceil(entry.readyAt-now))
                entry.label.Text=remaining==0 and t("ready") or (t("incubating").." · "..remaining..t("seconds"))
            end
        end
        money.Text=t("coins").." "..data.coins
        saveLabel.Text=t(data.saveStatus)
    end
    title.Text=t("title")
    for key,b in pairs(navButtons) do b.Text=t(key) end
    updateFishing()
end)
player.CharacterAdded:Connect(function() held=false;castPressed=false;fishState={phase="Idle"};updateFishing() end)
task.spawn(function()
    for _=1,12 do
        Action:FireServer("sync")
        if data then return end
        task.wait(2)
    end
end)
