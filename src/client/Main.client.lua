local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UserInputService=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local GuiService=game:GetService("GuiService")
local TweenService=game:GetService("TweenService")
local player=Players.LocalPlayer
local Shared=ReplicatedStorage:WaitForChild("Shared")
local Config=require(Shared.Config)
local Visual=require(Shared.VisualConfig)
local Catalog=require(Shared.Catalog)
local Strings=require(Shared.Strings)
local Layout=require(Shared.Layout)
local Presentation=require(Shared.Presentation)
local Domain=require(Shared.Domain).new(Config,Catalog,require(Shared.Util))
local W=require(script.Parent.Widgets)
local C=W.colors
local remotes=ReplicatedStorage:WaitForChild("Remotes")
local Action=remotes:WaitForChild("Action")
local FishingInput=remotes:WaitForChild("FishingInput")
local world=workspace:WaitForChild("World")
local locale=string.sub(player.LocaleId,1,2)=="ko" and "ko" or "en"
local data,snapshotAt=nil,0
local phase={phase="Idle",progress=0}
local context,tab,selectedId="bag","fish",nil
local feedQuality,page,debugOpen="none",1,false
local held,castPressed,pointer=false,false,nil
local pendingUntil=0
local timers={}
local detailModel=nil
local portraitDetail=false
local coreMenu=false
local touch=UserInputService.TouchEnabled
local resultDeadline=0
local t=function(key) return Strings[locale][key] or Strings.en[key] or tostring(key) end
local function serverNow() return data and data.serverTime+os.clock()-snapshotAt or os.time() end
local gui=W.new("ScreenGui",player:WaitForChild("PlayerGui"),{Name="FilamentUI",ResetOnSpawn=false,ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets,ClipToDeviceSafeArea=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=10})
local topGui=W.new("ScreenGui",player.PlayerGui,{Name="FilamentTopbar",ResetOnSpawn=false,ScreenInsets=Enum.ScreenInsets.TopbarSafeInsets,ClipToDeviceSafeArea=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=10})
local top=W.frame(topGui,{AnchorPoint=Vector2.new(0,.5),Position=UDim2.fromScale(0,.5),Size=UDim2.new(1,0,0,44),BackgroundTransparency=1})
local brand=W.label(top,"FILAMENT",UDim2.fromOffset(12,0),UDim2.fromOffset(120,44),16,C.dark,true)
local petLabel=W.label(top,"",UDim2.fromOffset(145,0),UDim2.new(1,-340,0,44),12,C.muted)
local wallet=W.frame(top,{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-62,0,1),Size=UDim2.fromOffset(116,42),BackgroundColor3=C.panel})
W.round(wallet,14);W.stroke(wallet)
W.icon(wallet,"coin",UDim2.fromOffset(9,10),22,C.accent)
local coins=W.label(wallet,"—",UDim2.fromOffset(37,0),UDim2.new(1,-44,1,0),14,C.ink,true)
local bag=W.button(top,"",UDim2.new(1,-52,0,0),UDim2.fromOffset(48,44),nil,true)
W.icon(bag,"bag",UDim2.fromOffset(11,8),27,C.ink)
local saveDot=W.frame(wallet,{Position=UDim2.new(1,-9,0,4),Size=UDim2.fromOffset(5,5),BackgroundColor3=C.accent});W.round(saveDot,5)
local modal=W.frame(gui,{Name="BagOverlay",Size=UDim2.fromScale(1,1),BackgroundColor3=C.dark,BackgroundTransparency=.42,Visible=false,Active=true,ZIndex=20})
local panel=W.frame(modal,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5)});W.round(panel,20);W.stroke(panel)
local panelTitle=W.label(panel,"",UDim2.fromOffset(18,9),UDim2.new(1,-128,0,30),22,C.ink,true)
local locationLabel=W.label(panel,"",UDim2.fromOffset(18,39),UDim2.new(1,-38,0,20),12,C.muted)
local close=W.button(panel,"×",UDim2.new(1,-56,0,10),UDim2.fromOffset(44,44))
local help=W.button(panel,"?",UDim2.new(1,-106,0,10),UDim2.fromOffset(44,44))
local tabs=W.frame(panel,{Position=UDim2.fromOffset(12,66),Size=UDim2.new(1,-24,0,44),BackgroundTransparency=1})
local tabButtons={}
local gridPane=W.frame(panel,{Position=UDim2.fromOffset(12,122),BackgroundTransparency=1})
local grid=W.scroll(gridPane,{Size=UDim2.fromScale(1,1)})
local gridLayout=W.new("UIGridLayout",grid,{CellPadding=UDim2.fromOffset(10,10),SortOrder=Enum.SortOrder.LayoutOrder})
local detail=W.scroll(panel,{Position=UDim2.fromOffset(0,122)})
local detailStack=W.stack(detail,10)
local fullPage=W.scroll(panel,{Position=UDim2.fromOffset(16,122),Size=UDim2.new(1,-32,1,-138),Visible=false})
local fullStack=W.stack(fullPage,12)
local footer=W.frame(panel,{Position=UDim2.new(0,12,1,-52),Size=UDim2.fromOffset(400,44),BackgroundTransparency=1})
local prev=W.button(footer,"‹",UDim2.new(),UDim2.fromOffset(44,44))
local nextPage=W.button(footer,"›",UDim2.new(1,-44,0,0),UDim2.fromOffset(44,44))
local pageLabel=W.label(footer,"",UDim2.fromOffset(52,0),UDim2.new(1,-104,1,0),12,C.muted)
pageLabel.TextXAlignment=Enum.TextXAlignment.Center
local back=W.button(panel,"",UDim2.fromOffset(12,66),UDim2.fromOffset(140,44));back.Visible=false
local gauge=W.frame(gui,{Name="FishingGauge",AnchorPoint=Vector2.new(.5,0),BackgroundColor3=C.panel,Visible=false});W.round(gauge,16);W.stroke(gauge)
local gaugeTitle=W.label(gauge,"",UDim2.fromOffset(14,8),UDim2.new(1,-60,0,24),15,C.ink,true)
local gaugeNumber=W.label(gauge,"",UDim2.new(1,-76,0,8),UDim2.fromOffset(62,24),14,C.water,true);gaugeNumber.TextXAlignment=Enum.TextXAlignment.Right
local track=W.frame(gauge,{Position=UDim2.fromOffset(14,38),Size=UDim2.new(1,-28,0,10),BackgroundColor3=C.line});W.round(track,5)
local fill=W.frame(track,{Size=UDim2.fromScale(0,1),BackgroundColor3=C.water});W.round(fill,5)
local marker=W.frame(track,{Position=UDim2.fromScale(Config.Fishing.ResistanceAt,0),Size=UDim2.new(0,2,1,0),BackgroundColor3=C.accent})
local gaugeNote=W.label(gauge,"",UDim2.fromOffset(14,52),UDim2.new(1,-28,0,23),12,C.muted)
local hint=W.button(gui,"",UDim2.new(),UDim2.fromOffset(290,32));hint.BackgroundTransparency=.12;hint.TextSize=12;hint.Visible=false
local actionButton=W.button(gui,"",UDim2.new(),UDim2.fromOffset(64,64),nil,true);W.round(actionButton,32);actionButton.Visible=false
local waiting=W.label(gui,"",UDim2.new(),UDim2.fromOffset(280,28),13,C.ink,true);waiting.BackgroundColor3=C.panel;waiting.BackgroundTransparency=.1;waiting.TextXAlignment=Enum.TextXAlignment.Center;waiting.Visible=false;W.round(waiting,14)
local cancel=W.button(gui,"×",UDim2.new(),UDim2.fromOffset(44,44));cancel.Visible=false
local toast=W.frame(gui,{AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,12),Size=UDim2.fromOffset(350,54),BackgroundColor3=C.dark,Visible=false,ZIndex=30});W.round(toast,16)
local toastText=W.label(toast,"",UDim2.fromOffset(14,5),UDim2.new(1,-28,1,-10),13,C.panel);toastText.TextXAlignment=Enum.TextXAlignment.Center
local result=W.frame(gui,{AnchorPoint=Vector2.new(.5,0),Size=UDim2.fromOffset(300,94),Visible=false});W.round(result,18);W.stroke(result)
local metrics=Layout.metrics(800,600,touch)
local render,renderDetail,resize,updateFishing
local notifySequence=0
local function notify(key)
    notifySequence+=1
    local sequence=notifySequence
    toastText.Text=t(key);toast.Visible=not coreMenu
    task.delay(Visual.UI.ToastSeconds,function() if sequence==notifySequence then toast.Visible=false end end)
end
local function release()
    held=false;pointer=nil
    if castPressed then FishingInput:FireServer("release");castPressed=false end
    FishingInput:FireServer("stopHold")
end
local function finishInput()
    release()
    if phase.phase~="Idle" and phase.phase~="Success" and phase.phase~="Failed" then FishingInput:FireServer("cancel") end
end
local function send(action,id,option)
    if os.clock()<pendingUntil then return end
    pendingUntil=os.clock()+.55
    Action:FireServer(action,id,option)
end
local function clear(frame,keep)
    for _,child in ipairs(frame:GetChildren()) do if child~=keep then child:Destroy() end end
end
local function block(parent,height,color)
    local f=W.frame(parent,{Size=UDim2.new(1,-4,0,height),BackgroundColor3=color or C.card});W.round(f,12);return f
end
local function copyBlock(parent,text,color)
    local f=block(parent,0)
    f.AutomaticSize=Enum.AutomaticSize.Y
    W.new("UIPadding",f,{PaddingTop=UDim.new(0,12),PaddingBottom=UDim.new(0,12),PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12)})
    local l=W.label(f,text,UDim2.new(),UDim2.new(1,0,0,0),13,color or C.muted)
    l.AutomaticSize=Enum.AutomaticSize.Y
    return f
end
local function timeLabel(parent,item)
    local l=W.label(parent,"",UDim2.fromOffset(10,8),UDim2.new(1,-20,1,-16),14,C.water,true)
    table.insert(timers,{label=l,readyAt=item.readyAt})
end
local function location()
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return "bag" end
    local plot=data and world.Aquariums:FindFirstChild(data.plotName or "")
    return Presentation.context((root.Position-world.Shop.Position).Magnitude,(root.Position-world.Craft.Position).Magnitude,plot and (root.Position-plot.Anchor.Position).Magnitude or math.huge,Config.StationRadius)
end
local function closeBag()
    modal.Visible=false;detailModel=nil;result.Visible=false
    if updateFishing then updateFishing() end
end
local function openBag(which)
    finishInput();resultDeadline=0;result.Visible=false
    tab=which or tab;portraitDetail=false;modal.Visible=true
    context=location();render();updateFishing()
end
local function showResult(species,kind)
    clear(result)
    W.round(result,18);W.stroke(result)
    resultDeadline=os.clock()+Visual.UI.ResultSeconds
    if species then
        local def=Catalog[species]
        W.viewport(result,species,UDim2.fromOffset(4,3),UDim2.fromOffset(88,86))
        W.label(result,t(kind or "caughtLabel"),UDim2.fromOffset(98,10),UDim2.new(1,-110,0,21),11,C.muted)
        W.label(result,t(species),UDim2.fromOffset(98,32),UDim2.new(1,-110,0,27),17,C.ink,true)
        W.label(result,t(def.rarity),UDim2.fromOffset(98,64),UDim2.new(1,-110,0,20),12,C[def.rarity],true)
    else
        W.label(result,t("failed"),UDim2.fromOffset(18,12),UDim2.new(1,-36,0,28),17,C.ink,true)
        W.label(result,t("failedShort"),UDim2.fromOffset(18,43),UDim2.new(1,-36,0,35),13,C.muted)
    end
    result.Visible=not modal.Visible and not coreMenu
end
renderDetail=function()
    clear(detail,detailStack);timers={};detailModel=nil
    if selectedId=="__tank" and data then
        local lv=data.aquariumLevel
        copyBlock(detail,t("tankSummary").."\nLv."..lv.." · "..Domain.occupied(data).." / "..Config.Aquarium[lv].capacity)
        local cost=Config.Aquarium[lv].nextCost
        copyBlock(detail,cost==0 and t("maxLevel") or (t("upgrade").." · "..cost.." "..t("coins")))
        if context=="aquarium" and cost>0 then
            W.button(detail,t("upgrade"),UDim2.new(),UDim2.new(1,-4,0,46),function() send("upgrade") end,true)
        elseif context~="aquarium" then copyBlock(detail,t("whereTank")) end
        return
    end
    local item=data and data.items[selectedId]
    if not item then copyBlock(detail,t("selectItem"));return end
    local def=Catalog[item.species]
    local showcase=block(detail,metrics.previewHeight+58)
    local stripe=W.frame(showcase,{Size=UDim2.new(1,0,0,4),BackgroundColor3=C[def.rarity]});W.round(stripe,4)
    local _,model=W.viewport(showcase,item.species,UDim2.fromOffset(6,6),UDim2.new(1,-12,0,metrics.previewHeight))
    detailModel=model
    W.label(showcase,t(item.species),UDim2.fromOffset(14,metrics.previewHeight+4),UDim2.new(1,-28,0,24),18,C.ink,true)
    W.label(showcase,t(def.rarity).."  ·  "..t(item.location=="aquarium" and "inTank" or "bag"),UDim2.fromOffset(14,metrics.previewHeight+29),UDim2.new(1,-28,0,22),12,C[def.rarity])
    if item.kind=="fish" then
        copyBlock(detail,t("price").." "..def.value.."  ·  "..t("basic").." ×"..def.basicYield.."\n"..t("premium").." ×"..def.premiumYield)
    elseif item.kind=="pet" then
        copyBlock(detail,t("bite").." −"..math.floor((1-def.biteMultiplier)*100+.5).."%\n"..t("efficiency").." +"..math.floor((def.reelMultiplier-1)*100+.5).."%",C.water)
    elseif item.location=="aquarium" then
        timeLabel(block(detail,50),item)
        copyBlock(detail,t(item.feedQuality).." · Lv."..item.incubationLevel.."\n"..t("lockedEgg"))
    else
        copyBlock(detail,t("feedTitle").."\n"..t("basic").." ×"..data.feed.basic.." · "..t("premium").." ×"..data.feed.premium)
        for _,quality in ipairs({"none","basic","premium"}) do
            local b=W.button(detail,(quality==feedQuality and "• " or "")..t(quality).." · "..Config.Feed[quality].duration..t("seconds"),UDim2.new(),UDim2.new(1,-4,0,44),function() feedQuality=quality;renderDetail() end,quality==feedQuality)
            b.LayoutOrder=0
        end
        local weights=Domain.weights(data.aquariumLevel,feedQuality,Config.Feed[feedQuality].duration)
        local sum=0;for _,v in ipairs(weights) do sum+=v.weight end
        local lines={t("probabilities")}
        for _,v in ipairs(weights) do table.insert(lines,t(Catalog[v.id].rarity).."  "..string.format("%.2f%%",v.weight/sum*100)) end
        copyBlock(detail,table.concat(lines,"\n"),C.water)
        copyBlock(detail,t("snapshotted"))
    end
    local actions=Presentation.actions(item,context,data.equippedPet)
    for _,key in ipairs(actions) do
        local titleKey=key
        if key=="unequip" then titleKey="unequip" end
        W.button(detail,t(titleKey),UDim2.new(),UDim2.new(1,-4,0,46),function()
            if key=="craftBasic" then send("craft",item.id,"basic")
            elseif key=="craftPremium" then send("craft",item.id,"premium")
            else send(key,item.id,item.kind=="egg" and feedQuality or nil) end
        end,true)
    end
    if #actions==0 and item.kind~="pet" and not (item.kind=="egg" and item.location=="aquarium") then
        copyBlock(detail,t(item.location=="aquarium" and "whereTank" or (item.kind=="egg" and "whereEgg" or "whereFish")))
    end
end
local function renderHelp()
    clear(fullPage,fullStack)
    copyBlock(fullPage,t("helpBody"))
    copyBlock(fullPage,t("rodHelp").."\n"..t("saveInfo")..": "..t(data and data.saveStatus or "loading").."\n"..t("versionLabel"))
    W.button(fullPage,t("language"),UDim2.new(),UDim2.new(1,-4,0,46),function() locale=locale=="ko" and "en" or "ko";render() end)
    if data and data.debugEnabled then
        W.button(fullPage,t("debugToggle"),UDim2.new(),UDim2.new(1,-4,0,46),function() debugOpen=not debugOpen;render() end)
        if debugOpen then
            copyBlock(fullPage,t("testNotice"))
            for _,destination in ipairs({"dock","aquarium","shop","craft"}) do
                W.button(fullPage,t(destination),UDim2.new(),UDim2.new(1,-4,0,44),function() Action:FireServer("travel",destination);closeBag() end)
            end
            W.button(fullPage,t("debugPack"),UDim2.new(),UDim2.new(1,-4,0,46),function() send("debugPack") end,true)
            W.button(fullPage,t("debugHatch"),UDim2.new(),UDim2.new(1,-4,0,46),function() send("debugHatch") end)
        end
    end
end
render=function()
    if not modal.Visible then return end
    panelTitle.Text=t(tab=="help" and "controls" or "bagTitle")
    locationLabel.Text=t(({shop="nearShop",craft="nearCraft",aquarium="nearAquarium",bag="nearBag"})[context])
    back.Text="‹  "..t("back")
    for key,b in pairs(tabButtons) do b.Text=t(key);b.BackgroundColor3=tab==key and C.accent or C.card end
    local helpMode=tab=="help"
    tabs.Visible=not helpMode and not (portraitDetail and not metrics.split)
    back.Visible=helpMode or (portraitDetail and not metrics.split)
    gridPane.Visible=not helpMode and (metrics.split or not portraitDetail)
    footer.Visible=gridPane.Visible
    detail.Visible=not helpMode and (metrics.split or portraitDetail)
    fullPage.Visible=helpMode
    if helpMode then detailModel=nil;renderHelp();return end
    clear(grid,gridLayout)
    local items={}
    if data then
        for _,item in pairs(data.items) do
            if (tab=="fish" and item.kind=="fish") or (tab=="eggs" and item.kind=="egg") or (tab=="pets" and item.kind=="pet") or (tab=="tank" and item.location=="aquarium") then table.insert(items,item) end
        end
    end
    table.sort(items,function(a,b) if a.obtainedAt==b.obtainedAt then return a.id<b.id end;return a.obtainedAt>b.obtainedAt end)
    local maxPage=math.max(1,math.ceil(#items/Visual.UI.CardPageSize))
    page=math.clamp(page,1,maxPage)
    pageLabel.Text=page.." / "..maxPage.."  ·  "..#items
    prev.Active=page>1;prev.AutoButtonColor=prev.Active;nextPage.Active=page<maxPage;nextPage.AutoButtonColor=nextPage.Active
    if tab=="tank" and data then
        local summary=W.button(grid,t("level").." "..data.aquariumLevel.."\n"..Domain.occupied(data).." / "..Config.Aquarium[data.aquariumLevel].capacity.."\n"..t("upgrade"),UDim2.new(),UDim2.fromOffset(metrics.cardWidth,metrics.cardHeight),function()
            selectedId="__tank";portraitDetail=true;render()
        end)
        summary.LayoutOrder=0
    end
    for index=(page-1)*Visual.UI.CardPageSize+1,math.min(#items,page*Visual.UI.CardPageSize) do
        local item=items[index];local def=Catalog[item.species]
        local card=W.button(grid,"",UDim2.new(),UDim2.fromOffset(metrics.cardWidth,metrics.cardHeight),function() selectedId=item.id;portraitDetail=true;render() end)
        card.LayoutOrder=index
        if selectedId==item.id then card.BackgroundColor3=Color3.fromRGB(230,237,211);card:FindFirstChildOfClass("UIStroke").Color=C.water end
        W.frame(card,{Position=UDim2.fromOffset(8,8),Size=UDim2.fromOffset(6,6),BackgroundColor3=C[def.rarity]})
        W.viewport(card,item.species,UDim2.fromOffset(5,8),UDim2.new(1,-10,1,-63))
        local name=W.label(card,t(item.species),UDim2.new(0,8,1,-51),UDim2.new(1,-16,0,24),13,C.ink,true);name.TextXAlignment=Enum.TextXAlignment.Center
        local state=item.id==data.equippedPet and t("equippedLabel") or (item.location=="aquarium" and t("inTank") or t(def.rarity))
        local rarity=W.label(card,state,UDim2.new(0,8,1,-27),UDim2.new(1,-16,0,20),11,C[def.rarity]);rarity.TextXAlignment=Enum.TextXAlignment.Center
    end
    if #items==0 and tab~="tank" then
        local empty=W.label(grid,t(data and "bagEmpty" or "loading"),UDim2.new(),UDim2.fromOffset(metrics.listWidth-8,170),14,C.muted)
        empty.LayoutOrder=1
    end
    renderDetail()
end
for index,key in ipairs({"fish","eggs","pets","tank"}) do
    local b=W.button(tabs,t(key),UDim2.new((index-1)/4,3,0,0),UDim2.new(.25,-6,1,0),function() tab=key;page=1;selectedId=nil;portraitDetail=false;grid.CanvasPosition=Vector2.zero;render() end)
    tabButtons[key]=b
end
bag.Activated:Connect(function() if modal.Visible then closeBag() else openBag() end end)
close.Activated:Connect(closeBag)
help.Activated:Connect(function() tab="help";portraitDetail=false;render() end)
back.Activated:Connect(function() if tab=="help" then tab="fish" end;portraitDetail=false;selectedId=nil;render() end)
prev.Activated:Connect(function() if page>1 then page-=1;render();grid.CanvasPosition=Vector2.zero end end)
nextPage.Activated:Connect(function() page+=1;render();grid.CanvasPosition=Vector2.zero end)
cancel.Activated:Connect(function() finishInput() end)
resize=function()
    local size=gui.AbsoluteSize
    metrics=Layout.metrics(size.X,size.Y,touch)
    panel.Size=UDim2.fromOffset(metrics.panelWidth,metrics.panelHeight)
    gridPane.Size=UDim2.fromOffset(metrics.listWidth,metrics.panelHeight-184)
    footer.Size=UDim2.fromOffset(metrics.listWidth,44)
    detail.Position=UDim2.fromOffset(metrics.split and metrics.listWidth+28 or 12,122)
    detail.Size=UDim2.fromOffset(metrics.detailWidth,metrics.panelHeight-138)
    gridLayout.CellSize=UDim2.fromOffset(metrics.cardWidth,metrics.cardHeight)
    gridLayout.FillDirectionMaxCells=metrics.columns
    gauge.Position=UDim2.new(.5,0,0,metrics.gaugeY)
    gauge.Size=UDim2.fromOffset(metrics.gaugeWidth,metrics.gaugeHeight)
    gaugeNote.Visible=not metrics.compact
    hint.AnchorPoint=Vector2.new(.5,0)
    hint.Position=UDim2.new(.5,0,0,touch and metrics.portrait and size.Y-250 or size.Y-102)
    hint.Size=UDim2.fromOffset(math.min(310,size.X-40),32)
    actionButton.Position=UDim2.fromOffset(metrics.actionX,metrics.actionY)
    waiting.AnchorPoint=Vector2.new(.5,0);waiting.Position=UDim2.new(.5,0,0,metrics.gaugeY+20)
    waiting.Size=UDim2.fromOffset(math.min(270,size.X-80),28)
    cancel.Position=UDim2.fromOffset(touch and metrics.actionX-56 or (size.X+metrics.gaugeWidth)/2+8,touch and metrics.actionY or metrics.gaugeY)
    if not touch and size.X<500 then cancel.Position=UDim2.new(1,-54,0,metrics.gaugeY-48) end
    result.Position=UDim2.new(.5,0,0,math.max(16,metrics.gaugeY-12));result.Size=UDim2.fromOffset(math.min(310,size.X-32),94)
    toast.Size=UDim2.fromOffset(math.min(370,size.X-32),54)
    if modal.Visible then render() end
end
local function hudResize()
    local h=Layout.hud(topGui.AbsoluteSize.X)
    brand.Visible=h.title;wallet.Visible=h.coins;petLabel.Visible=topGui.AbsoluteSize.X>=620
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
topGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(hudResize)
local function equipped()
    return player.Character and player.Character:FindFirstChild(Visual.RodName)~=nil
end
local function atPier()
    local r=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not r then return false end
    local f=Config.Fishing
    return math.abs(r.Position.X-f.DockX)<=f.DockHalfX and math.abs(r.Position.Z-f.DockZ)<=f.DockHalfZ and r.Position.Y>1 and r.Position.Y<12
end
local function press(input)
    if modal.Visible or coreMenu or not data or not equipped() then return end
    if pointer then return end
    local action=Presentation.press(phase.phase,held)
    if not action then return end
    held=true;pointer=input
    if action=="start" then castPressed=true end
    FishingInput:FireServer(action)
end
for _,control in ipairs({hint,actionButton}) do
    control.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then press(input) end
    end)
end
UserInputService.InputBegan:Connect(function(input,processed)
    if processed or UserInputService:GetFocusedTextBox() or coreMenu then return end
    if input.KeyCode==Enum.KeyCode.F then press(input)
    elseif input.KeyCode==Enum.KeyCode.B then if modal.Visible then closeBag() else openBag() end
    elseif input.KeyCode==Enum.KeyCode.R then Action:FireServer("rod") end
end)
UserInputService.InputEnded:Connect(function(input)
    if input==pointer or (input.KeyCode==Enum.KeyCode.F and pointer and pointer.KeyCode==Enum.KeyCode.F)
        or (input.UserInputType==Enum.UserInputType.MouseButton1 and pointer and pointer.UserInputType==Enum.UserInputType.MouseButton1) then release() end
end)
UserInputService.WindowFocusReleased:Connect(finishInput)
GuiService.MenuOpened:Connect(function() coreMenu=true;finishInput();modal.Visible=false;toast.Visible=false;updateFishing() end)
GuiService.MenuClosed:Connect(function() coreMenu=false;updateFishing() end)
updateFishing=function()
    local state=phase.phase
    local v=Presentation.view(state,equipped(),atPier(),modal.Visible,coreMenu)
    gauge.Visible=v.gauge
    hint.Visible=v.hint or (v.gauge and not touch)
    hint.Text=t(atPier() and (touch and "touchHint" or "idleHint") or "walkPier")
    if state=="Reel" then hint.Text=t("holdHint") elseif state=="Resist" then hint.Text=t("tapHint") end
    actionButton.Visible=v.action and touch
    actionButton.Text=t(state=="Reel" and "reelShort" or (state=="Resist" and "tapShort" or "castShort"))
    waiting.Visible=v.waiting
    waiting.Text=t(state=="Saving" and "savingCatch" or (state=="Flight" and "flight" or "waiting"))
    cancel.Visible=v.cancel
    local value=phase.progress or 0
    gaugeTitle.Text=t("progress");gaugeNumber.Text=math.floor(value*100).."%";gaugeNote.Text=t("holdHint")
    fill.BackgroundColor3=C.water;marker.Visible=state=="Reel"
    if state=="Charge" then
        value=phase.power or 0;gaugeTitle.Text=t("power");gaugeNumber.Text=math.floor(value*100).."%";gaugeNote.Text=t("charge")
    elseif state=="Resist" then
        value=(phase.taps or 0)/Config.Fishing.ResistanceTaps
        gaugeTitle.Text=t("resistance").."  "..(phase.taps or 0).."/"..Config.Fishing.ResistanceTaps
        gaugeNumber.Text=string.format("%.1f",phase.remaining or 0)..t("seconds");gaugeNote.Text=t("tapHint");fill.BackgroundColor3=C.accent
    end
    fill.Size=UDim2.fromScale(math.clamp(value,0,1),1)
    result.Visible=os.clock()<resultDeadline and not modal.Visible and not coreMenu and (state=="Idle" or state=="Success" or state=="Failed")
end
remotes.FishingState.OnClientEvent:Connect(function(state)
    local previous=phase.phase
    phase=state
    if state.phase=="Reel" and previous=="Waiting" then notify("biteNow")
    elseif state.phase=="Reel" and previous=="Resist" then notify("resistCleared");TweenService:Create(gauge,TweenInfo.new(.35),{BackgroundColor3=C.panel}):Play() end
    if state.phase=="Success" then showResult(state.species,"caughtLabel")
    elseif state.phase=="Failed" then showResult(nil) end
    if state.phase=="Failed" or state.phase=="Success" or state.phase=="Idle" then held=false;castPressed=false;pointer=nil end
    if state.phase=="Success" or state.phase=="Failed" then
        task.delay(Visual.UI.ResultSeconds,function() if phase==state then phase={phase="Idle"};updateFishing() end end)
    end
    updateFishing()
end)
remotes.Snapshot.OnClientEvent:Connect(function(snapshot)
    local previous=data
    data=snapshot;snapshotAt=os.clock();pendingUntil=0
    coins.Text=tostring(data.coins)
    local pet=data.items[data.equippedPet]
    petLabel.Text=pet and (t(pet.species).." · "..t("equippedLabel")) or ""
    saveDot.BackgroundColor3=data.saveStatus=="memory" and C.accent or C.good
    if previous then
        for id,item in pairs(data.items) do
            if item.kind=="pet" and previous.items[id] and previous.items[id].kind=="egg" then showResult(item.species,"hatchLabel");break end
        end
    elseif data.saveStatus=="memory" then notify("memory") end
    context=location()
    if selectedId and selectedId~="__tank" and not data.items[selectedId] then selectedId=nil;portraitDetail=false end
    if modal.Visible then render() end
end)
remotes.SaveStatus.OnClientEvent:Connect(function(status)
    if data then data.saveStatus=status end
    saveDot.BackgroundColor3=status=="error" and C.bad or (status=="memory" and C.accent or C.good)
    if status=="error" then notify("error") end
end)
remotes.Notice.OnClientEvent:Connect(function(key) pendingUntil=0;notify(key) end)
remotes.OpenPanel.OnClientEvent:Connect(function(which) selectedId=nil;page=1;openBag(which) end)
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
    elapsed+=dt
    if elapsed<Visual.UI.HoldInterval then return end
    elapsed=0
    if held and phase.phase=="Reel" and not modal.Visible and not coreMenu then FishingInput:FireServer("hold") end
    for _,entry in ipairs(timers) do
        if entry.label.Parent then local remaining=math.max(0,math.ceil(entry.readyAt-serverNow()));entry.label.Text=remaining==0 and t("ready") or (t("incubating").." · "..remaining..t("seconds")) end
    end
    local nextContext=location()
    if nextContext~=context then context=nextContext;if modal.Visible then render() end end
    updateFishing()
end)
RunService.RenderStepped:Connect(function(dt)
    if modal.Visible and detail.Visible and detailModel and detailModel.Parent then detailModel:PivotTo(detailModel:GetPivot()*CFrame.Angles(0,dt*.35,0)) end
end)
player.CharacterAdded:Connect(function() release();phase={phase="Idle"};modal.Visible=false;resultDeadline=0 end)
resize();hudResize();updateFishing()
task.spawn(function()
    for _=1,12 do Action:FireServer("sync");if data then return end;task.wait(2) end
end)
