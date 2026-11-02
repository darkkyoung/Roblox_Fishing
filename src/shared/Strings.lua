-- All interface copy lives here. Add a locale table without rewriting UI logic.
local ko = {
    title="FILAMENT · FISHING", coins="코인", inventory="가방", fish="물고기", eggs="알", pets="펫", tank="수족관", help="도움말",
    silver="은빛 피라미",sunny="햇살 농어",azure="푸른 잉어",tideEgg="물결 알",otter="아기 수달",fox="구름 여우",dragon="별빛 드래곤",
    common="일반",uncommon="고급",rare="희귀",legendary="전설",basic="기본 사료",premium="고급 사료",none="사료 없음",
    dock="낚시터",aquarium="내 수족관",shop="판매 상점",craft="사료 공방",close="닫기",language="EN",rod="낚싯대 장착",
    idle="부두에서 낚시를 시작하세요",charge="놓으면 캐스팅!",flight="찌가 날아갑니다",waiting="입질을 기다리는 중…",reel="누르고 유지해서 끌어올리세요",resist="저항! 빠르게 여러 번 누르세요",success="포획 성공!",failed="물고기가 도망갔습니다",savingCatch="획득 정보를 저장하는 중…",
    castButton="길게 누르기 · 캐스팅",reelButton="길게 누르기 · 끌어올리기",tapButton="연타!",waitingButton="기다려 주세요",cancel="취소",power="캐스팅 파워",progress="포획 진행",resistance="저항 제거",keyHint="PC: F 또는 화면 버튼 / 모바일: 화면 버튼",
    place="수조 배치",retrieve="회수",sell="판매",craftBasic="기본 사료 제작",craftPremium="고급 사료 제작",equip="장착",unequip="해제",equippedLabel="장착 중",bag="가방",inTank="수조 안",incubating="부화 중",ready="부화 처리 중",empty="아직 개체가 없습니다. 낚시로 수집해 보세요.",
    upgrade="수족관 업그레이드",level="레벨",capacity="배치",maxLevel="최대 레벨입니다",feedChoice="알 배치 시 사용할 사료",lockedEgg="부화가 시작된 알은 회수할 수 없습니다",probabilities="부화 예상 확률",snapshotted="배치 시 사료·수조 레벨이 확정됩니다",buff="장착 버프",noPet="장착한 펫 없음",bite="입질 대기",efficiency="포획 효율",seconds="초",price="판매가",
    memory="임시 저장 · Stop 시 초기화",saved="클라우드 저장 완료",saving="저장 중…",error="저장 실패 · 세션 중지",loading="데이터 불러오는 중…",
    granted="아이템을 획득했습니다",placed="수족관에 배치했습니다",retrieved="가방으로 회수했습니다",sold="판매했습니다",crafted="사료를 만들었습니다",upgraded="수족관 레벨이 올랐습니다",equipped="펫을 장착했습니다",unequipped="펫을 해제했습니다",hatched="알이 부화했습니다! 펫 탭을 확인하세요",debugDone="Studio 테스트 데이터를 적용했습니다",
    full="가방이 가득 찼습니다 (최대 200개)",invalid="올바르지 않은 요청입니다",noCoins="코인이 부족합니다",notOwned="본인이 소유한 개체가 아닙니다",stateError="이 상태에서는 사용할 수 없습니다",tankFull="수족관이 가득 찼습니다. 회수하거나 업그레이드하세요",noFeed="선택한 사료가 부족합니다",eggLocked="부화 중인 알은 회수할 수 없습니다",retrieveFirst="수조의 물고기는 먼저 회수하세요",needBetterFish="이 물고기는 고급 사료로 만들 수 없습니다",notReady="아직 준비되지 않았습니다",busy="저장 작업 중입니다. 잠시 뒤 다시 눌러 주세요",serverError="처리 중 오류가 발생했습니다. Output을 확인해 주세요",saveError="저장에 실패했습니다",finishFishing="낚시를 마치거나 취소해 주세요",
    goDock="낚싯대를 장착하고 부두 위로 이동해 주세요",goAquarium="내 수족관으로 이동해 주세요",goShop="판매 상점으로 이동해 주세요",goCraft="사료 공방으로 이동해 주세요",
    helpBody="1. [낚시터]를 누르면 부두로 이동합니다.\n2. F키 또는 캐스팅 버튼을 누르다가 놓으세요.\n3. 입질 후 버튼을 유지해 게이지를 채우세요.\n4. 저항 구간에서는 버튼을 놓고 4초 안에 9번 연타하세요.\n5. 다시 유지하면 물고기나 희귀 알을 획득합니다.\n6. 가방을 열고 내 수족관·상점·공방으로 이동해 활용하세요.\n7. 알은 사료를 선택하고 수조에 배치하면 40~60초 뒤 부화합니다.\n8. 펫 탭에서 장착하면 대기시간과 포획 속도가 실제로 바뀝니다.\n\n물고기와 알에서 부화하는 동물 펫은 별개입니다.\nStudio 임시 모드에서는 Stop 시 모든 데이터가 초기화됩니다.\n클라우드 저장은 README의 비공개 저장 테스트 절차를 따라 주세요.",
    debugTitle="Studio 전용 테스트",debugPack="물고기 3종 + 알 + 재료 지급",debugHatch="배치된 알 즉시 부화",testNotice="라이브 서버에서는 이 기능이 서버에서 차단됩니다",emptyTank="배치한 물고기와 알이 여기에 표시됩니다",
}
local en = {
    title="FILAMENT · FISHING",coins="Coins",inventory="Bag",fish="Fish",eggs="Eggs",pets="Pets",tank="Aquarium",help="Help",
    silver="Silver Minnow",sunny="Sun Perch",azure="Azure Carp",tideEgg="Tide Egg",otter="Baby Otter",fox="Cloud Fox",dragon="Starlight Dragon",
    common="Common",uncommon="Uncommon",rare="Rare",legendary="Legendary",basic="Basic feed",premium="Premium feed",none="No feed",dock="Fishing pier",aquarium="My aquarium",shop="Fish market",craft="Feed workshop",close="Close",language="한국어",rod="Equip rod",
    idle="Start fishing on the pier",charge="Release to cast!",flight="Casting…",waiting="Waiting for a bite…",reel="Hold to reel in",resist="Resistance! Tap rapidly!",success="Caught!",failed="The fish escaped",savingCatch="Saving your catch…",castButton="HOLD · CAST",reelButton="HOLD · REEL",tapButton="TAP!",waitingButton="Please wait",cancel="Cancel",power="Casting power",progress="Catch progress",resistance="Clear resistance",keyHint="PC: F or button / Mobile: touch button",
    place="Place",retrieve="Retrieve",sell="Sell",craftBasic="Basic feed",craftPremium="Premium feed",equip="Equip",unequip="Unequip",equippedLabel="Equipped",bag="Bag",inTank="In tank",incubating="Hatching",ready="Finishing hatch",empty="No items yet. Go fishing!",upgrade="Upgrade aquarium",level="Level",capacity="Capacity",maxLevel="Maximum level",feedChoice="Feed used when placing an egg",lockedEgg="Incubating eggs cannot be retrieved",probabilities="Hatch odds",snapshotted="Feed and tank level are locked when placed",buff="Equipped bonus",noPet="No pet equipped",bite="Bite wait",efficiency="Reel speed",seconds="s",price="Price",
    memory="Temporary · resets on Stop",saved="Cloud saved",saving="Saving…",error="Save failed · session stopped",loading="Loading profile…",granted="Item acquired",placed="Placed in aquarium",retrieved="Returned to bag",sold="Fish sold",crafted="Feed crafted",upgraded="Aquarium upgraded",equipped="Pet equipped",unequipped="Pet unequipped",hatched="Egg hatched! Check the Pets tab",debugDone="Studio test data applied",
    full="Inventory full (200 max)",invalid="Invalid request",noCoins="Not enough coins",notOwned="You do not own this item",stateError="Invalid item state",tankFull="Tank full: retrieve items or upgrade",noFeed="Not enough feed",eggLocked="Incubating eggs are locked",retrieveFirst="Retrieve this fish first",needBetterFish="This fish cannot make premium feed",notReady="Not ready yet",busy="Save in progress. Please try again shortly",serverError="Server error. Check Output",saveError="Save failed",finishFishing="Finish or cancel fishing first",goDock="Equip your rod and stand on the pier",goAquarium="Go to your aquarium",goShop="Go to the fish market",goCraft="Go to the feed workshop",
    helpBody="1. Tap Fishing pier to travel there.\n2. Hold F or the cast button, then release.\n3. After a bite, hold to fill the catch meter.\n4. At resistance, release and tap 9 times in 4 seconds.\n5. Hold again to catch a fish or a rare egg.\n6. Open Bag, then travel to your tank, market or workshop.\n7. Select feed and place an egg; it hatches in 40–60 seconds.\n8. Equip a pet for real bite-time and reel-speed bonuses.\n\nPets are separate animals born from eggs, not evolved fish.\nStudio temporary mode resets all data on Stop.\nFor private cloud-save testing, follow README.",debugTitle="Studio test tools",debugPack="Grant 3 fish + egg + materials",debugHatch="Hatch placed eggs now",testNotice="Server rejects debug tools outside Studio",emptyTank="Placed fish and eggs appear here",
}
ko.backList = "목록으로"
en.backList = "Back to list"
ko.placedState = "수족관 배치 중"
en.placedState = "Placed in aquarium"
ko.bagState = "가방 보관"
en.bagState = "In bag"
ko.itemSource = "획득 경로"
en.itemSource = "Source"
ko.fishing = "정상 낚시"
en.fishing = "Normal fishing"
ko.studioDebug = "Studio 테스트 지급/즉시 부화"
en.studioDebug = "Studio debug grant/instant hatch"
ko.legacy = "이전 저장 개체"
en.legacy = "Previous save"
ko.feedTitle = "배치 시 사용할 사료 선택"
en.feedTitle = "Choose feed before confirming placement"
ko.saveLabel = "저장 상태"
en.saveLabel = "Save status"
ko.sessionChecks = "이번 접속 정상 포획 / 디버그 작업"
en.sessionChecks = "Session catches / debug operations"
ko.rodHelp = "Rod 장착 · R / 핫바"
en.rodHelp = "Equip Rod · R / hotbar"
ko.debugToggle = "Studio 도구 펼치기 / 접기"
en.debugToggle = "Expand / collapse Studio tools"
ko.debugFish = "DEBUG 물고기 3종 지급"
en.debugFish = "DEBUG Grant 3 fish"
ko.debugEgg = "DEBUG 물결 알 지급"
en.debugEgg = "DEBUG Grant tide egg"
ko.debugFeed = "DEBUG 사료 각 3개 지급"
en.debugFeed = "DEBUG Grant 3 of each feed"
ko.debugCoins = "DEBUG 500 코인 지급"
en.debugCoins = "DEBUG Grant 500 coins"
ko.debugHatch = "DEBUG 배치된 알 즉시 부화"
en.debugHatch = "DEBUG Hatch placed eggs now"
ko.travelLabel = "DEBUG 이동"
en.travelLabel = "DEBUG Travel"
ko.exploring = "이동 중"
en.exploring = "Exploring"
ko.zoneHint = "물고기·알을 선택하세요. 배치는 내 수족관, 판매는 상점, 제작은 공방에서만 가능합니다."
en.zoneHint = "Select a fish or egg. Place at your plot, sell at the market, craft at the workshop."
ko.idleHint = "부두: F 유지 → 놓기 · 터치/마우스 버튼"
en.idleHint = "Dock: Hold F then release · touch/mouse button"
ko.releaseHint = "F / 버튼을 놓아 던지세요"
en.releaseHint = "Release F / button to cast"
ko.holdHint = "F / 버튼 유지로 포획"
en.holdHint = "Hold F / button to reel"
ko.holdShort = "유지"
en.holdShort = "HOLD"
ko.tapShort = "연타"
en.tapShort = "TAP"
ko.castShort = "캐스팅"
en.castShort = "CAST"
ko.tapHint = "놓고 다시 9번 누르세요 · 4초"
en.tapHint = "Release and tap 9 times · 4 seconds"
ko.biteNow = "입질! F / 버튼을 유지하세요"
en.biteNow = "Bite! Hold F / button"
ko.resistCleared = "저항 해제! 다시 유지하세요"
en.resistCleared = "Resistance cleared! Hold again"
ko.helpBody = "Phase 0.2 기능 테스트\n남쪽 스폰 → 앞 부두에서 F 유지/놓기 → 입질 후 유지 → 50% 저항에서 4초 안에 9번 연타 → 다시 유지. 모바일은 오른쪽 버튼입니다.\n왼쪽 아래 주황 바닥은 상점, 왼쪽 위 보라 바닥은 공방, 연못 뒤 청록 구역은 16개 개인 수족관입니다. 길을 따라 이동하고 E/터치 프롬프트를 사용하세요. 가방은 B 또는 버튼입니다.\n내 수족관의 알 배치 확정 시 사료를 선택합니다. 40~60초 뒤 별개의 동물 펫으로 부화합니다. 펫 탭에서 장착하면 서버 낚시에 실제 버프가 적용됩니다.\n기본 Studio 저장은 임시 모드입니다. Stop하면 초기화됩니다. 영속/오프라인 검증은 README를 따르세요."
en.helpBody = "Phase 0.2 functional test\nWalk from the south spawn onto the dock. Hold/release F; after a bite hold to reel; at 50% release and tap 9 times in 4 seconds, then hold again. Mobile uses the right-hand button.\nOrange southwest: market. Purple northwest: workshop. Teal north: 16 personal plots. Follow paths and use E/touch prompts. B or the Bag button opens inventory.\nChoose feed when confirming egg placement at your plot. After 40–60 seconds it becomes a separate animal pet. Equip it for real server fishing buffs.\nStudio defaults to temporary storage. Stop resets data. Follow README for persistence/offline tests."
return {ko=ko,en=en}
