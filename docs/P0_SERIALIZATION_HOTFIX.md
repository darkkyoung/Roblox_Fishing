# FILAMENT Fishing 0.2 — P0 Studio 부팅 / 좌표 직렬화 핫픽스

2026-11-02 KST. 대상: `feature/fishing-functional-blockout`, [Draft PR #2](https://github.com/darkkyoung/Roblox_Fishing/pull/2). 기준 커밋 `16d0051ebba3fb935a072079bd4cfaf466b77664`를 fresh fetch하여 수정했습니다. main 및 Draft PR #1은 변경하지 않았습니다.

## 원인과 수정

사용자 Windows Studio에서 `ZoneService:10: Zone position differs: AquariumPlot12`로 서버 초기화가 중단되었고, 이후 생성되어야 하는 Remotes / CollectionVisuals를 클라이언트가 계속 기다렸습니다. 기존 XML을 직접 검사해 **75개 BasePart의 Position 75개, CFrame 0개**를 재현했습니다. 바이너리의 독립 역직렬화 결과에도 CFrame은 0개였습니다. 기존 구조 검사가 영속 변환 데이터를 확인하지 않은 검증 누락입니다.

- `generate_world.py`의 공통 Part 생성 함수에서 `Position`을 제거했습니다. SpawnLocation도 같은 함수를 쓰므로 빠짐없이 적용됩니다. Rojo 7의 `[x,y,z,1,0,0,0,1,0,0,0,1]` 형식을 사용합니다.
- `world.model.json`을 재생성하고 두 빌드를 다시 생성했습니다. 75개 모두 유효한 CoordinateFrame/CFrame이며 Position 저장 속성은 없습니다.
- 검증기는 생성된 JSON에만 의존하지 않고 `config/zones.json`과 별도 기하 계약으로 좌표·크기·회전을 검증합니다. Ground, 22개 Floor, Spawn 1개, 길 5개, 호수 안전 Box 3개, 경계 4개, Console 18개, 표지판 21개를 모두 포함합니다. 이름이 같은 Boundary 4개도 누락 없이 비교합니다.
- 실제 `.rbxl` 바이트를 **rbxmk 0.9.1 / rbxfile**로 독립 역직렬화하고 `.rbxlx`와 비교합니다. 좌표 오차 허용치는 float32 왕복을 고려한 **0.0001 stud**입니다. 두 형식의 내장 Luau 소스 22개도 현재 소스와 일치합니다. rbxmk의 XML 문자열 변환과 별개로 JSON 추출을 사용해 바이너리 내 한국어 UTF-8 소스까지 비교했습니다.
- `ZoneService.new()`는 누락된 월드 객체를 즉시 식별하고, 좌표/크기가 다른 모든 Zone의 전체 경로·기대값·실제값을 출력합니다. 검증을 무시하거나 잘못된 월드를 자동 보정하지 않습니다.
- 서버 전체 동기 초기화에 단계별 로그, traceback, `ReplicatedStorage`의 `FilamentBootStatus / FilamentBootStage / FilamentBootError`를 추가했습니다. 두 클라이언트는 해당 의존성이 15초 동안 생성되지 않으면 명시적 진단을 기록하고 종료합니다.

낚시·보상·경제·부화·펫·소유권·DataStore 처리와 밸런스는 변경하지 않았습니다. `Domain`, `FishingMachine`, `Catalog`, `Config`, `ProfileStore`, `Lease`, `FishingService`, `RewardService`, `WorldService`, `StudioTools`, `PlotRegistry`, `Zones`, `ZoneConfig`는 핫픽스 기준 커밋과 동일합니다. UI 디자인·월드 배치·기능 추가는 없습니다.

Rojo 형식 근거: [Rojo 7 CFrame 속성](https://rojo.space/docs/v7/properties/#cframe), [Roblox XML CFrame 형식](https://dom.rojo.space/xml.html).

## 결과 구분

| 검증 | 결과 | 근거와 한계 |
|---|---|---|
| 기존 자동 테스트 58개 | PASS | 기존 30 + 기능/Zone/UI 28, 테스트 본문 변경 없음 |
| 직렬화 회귀 7개 | PASS | Position-only 원래 결함, 누락/변형 CFrame, 좌표/회전/NaN 오류, 누락/중복 객체 거부 |
| 부팅 연결·진단 3개 | PASS — API 대체 객체 | 실제 Main/ZoneService/WorldService 코드 + 빌드 XML 좌표로 22 Zone 초기화, 7 Remotes·CollectionVisuals 생성 및 실패 진단 검사. **Studio 아님** |
| 정적 검사·컴파일 | PASS | Luau 0.743, 소스 22개. Roblox 전체 API 타입 검증은 아님 |
| Rojo 두 형식 재빌드 | PASS | Rojo 7.7.1 |
| XML/RBXL/JSON 좌표 | PASS | 75/75 CFrame, Position 0, 원본 좌표/크기/identity 회전 일치 |
| AquariumPlot12.Floor 저장 좌표 | PASS | `(76, 1.2, -113)` 양쪽 파일 확인, float32 허용 오차 적용 |
| 실제 Studio 로드 후 Floor.Position | 미실행 | Windows Roblox Studio 환경 없음 |
| 실제 ZoneService 부팅·Remotes·CollectionVisuals | 미실행 | 대체 객체 실행과 실제 엔진 동작을 구분 |
| 실제 코인·가방 HUD, Rod 지급/장착 | 미실행 | 아래 Play 검수 필요 |
| 실제 캐스팅·찌 착수·포획 | 미실행 | 서버 Raycast/물리/입력은 실제 엔진 검수 필요 |
| 실제 DataStore·멀티플레이 | 미실행 | 기존 모의 회귀만 통과. 실제 QA는 기존 문서 유지 |

검사 원문: `build/test-output-0.2-p0.txt`. **빌드/자동 검사 통과를 Studio Runtime PASS로 해석하지 마세요.**

## 실제 Studio QA — 미실행

각 파일 형식마다 독립적으로 아래 절차를 수행합니다. 이전 세션을 Stop하고 파일을 새로 열어야 합니다. 테스트 기록에는 파일명, SHA-256, Studio 버전, Output, 실제 결과를 남깁니다.

1. 아래 체크섬과 다운로드 파일을 비교합니다. PowerShell: `Get-FileHash .\FILAMENT-Fishing-0.2-P0-hotfix.rbxl -Algorithm SHA256` (XML은 확장자 rbxlx).
2. Studio → 파일 열기로 새 파일을 엽니다. **Play 전** Explorer에서 `Workspace.World.Zones.AquariumPlot12.Floor`를 선택합니다. Properties의 Position이 **76, 1.2, -113**이어야 합니다. 나머지 Zone이 원점에 겹치지 않아야 합니다.
3. Output 창을 열고 **Play(F5)**를 누릅니다. Server Output에서 다음 로그를 확인합니다.

```text
[FILAMENT BOOT] ZoneService ready: 22 zone floors match ZoneConfig
[FILAMENT BOOT] Starting WorldService / CollectionVisuals
[FILAMENT BOOT] Starting Remotes
[FILAMENT BOOT] READY: Remotes and CollectionVisuals created; player handlers connected
```

4. Play 중 **Server 컨텍스트 Command Bar**에서 아래 검사 코드를 실행합니다. 이는 실제 실행 후 검증용이며 파일을 고치는 코드가 아닙니다.

```lua
local rs = game:GetService("ReplicatedStorage")
local cfg = require(rs.Shared.ZoneConfig)
local checked = 0
for id, z in pairs(cfg.zones) do
    local floor = workspace.World.Zones[id].Floor
    assert((floor.Position - Vector3.new(unpack(z.position))).Magnitude < 0.01, id)
    assert((floor.Size - Vector3.new(unpack(z.size))).Magnitude < 0.01, id)
    checked += 1
end
assert(checked == 22)
assert((workspace.World.Zones.AquariumPlot12.Floor.Position - Vector3.new(76, 1.2, -113)).Magnitude < 0.01)
assert(rs:GetAttribute("FilamentBootStatus") == "Ready", rs:GetAttribute("FilamentBootError"))
assert(#rs.Remotes:GetChildren() == 7)
assert(workspace:FindFirstChild("CollectionVisuals"))
print("STUDIO boot / 22 zone positions / dependencies verified")
```

5. Client 화면에서 코인과 가방 버튼이 나타나는지, B로 가방이 열리는지 확인합니다. 대형 낚시 패널이 Idle에 나타나면 안 됩니다. 캐릭터 안에 Rod가 있고 장착되어 있어야 합니다. 리셋 후 재지급도 확인합니다.
6. 스폰 → 갈색 부두로 걷습니다. 부두 입구 통과, 연못 주변 안전 충돌, 회색 길, 상점/공방/16개 Plot 위치를 확인합니다.
7. F 유지 → 놓기로 캐스팅합니다. 찌가 파란 연못의 노출 수면에 착수하고 입질이 발생해야 합니다. F 유지 → 50%에서 4초 내 9회 → 다시 유지하여 포획하고, 가방 개체가 정확히 1개 증가하는지 확인합니다. 정상 낚시 검증에는 디버그 지급을 쓰지 않습니다.
8. 저항 시간 초과 실패 시 보상이 지급되지 않고 UI가 정리되는지도 확인합니다. Server/Client Output에 Zone mismatch, Remotes/CollectionVisuals Infinite yield 오류가 없어야 합니다.
9. Stop 후 다른 형식의 파일을 열어 2~8을 반복합니다. 그 뒤 [기존 7개 전체 루프 QA](QA_0.2.md)를 수행합니다.

진단 실패 경로를 검사하려면 별도 임시 복사본에서 **Play 전에** Plot12 Floor를 옮겨 실행합니다. `BootStatus=Failed`, `BootStage=ZoneService`, 전체 경로와 expected/loaded 값이 나와야 하며 클라이언트는 15초 뒤 명시적 경고로 종료되어야 합니다. 임시 수정본은 저장하지 않고 배포본을 다시 엽니다.

## 파일 식별

저장소의 파일명은 기존 `build/FILAMENT-Fishing-0.2.rbxl[x]`이며, 전달용 복사본은 `FILAMENT-Fishing-0.2-P0-hotfix.rbxl[x]`입니다. 내용은 동일합니다. 이전에 전달한 **CFrame 0개인 0.2 파일은 사용하지 마세요.**

| 새 파일 | SHA-256 |
|---|---|
| `FILAMENT-Fishing-0.2-P0-hotfix.rbxl` | `b28f39442ab7006e6215da974f49ab7146c41dd86f6a8c8654175ea5227c653a` |
| `FILAMENT-Fishing-0.2-P0-hotfix.rbxlx` | `a2058e8083e9fb00f117ca5c2d82db2654fd92ab73df9ea185845eec56dae023` |

이전 오류 파일 SHA-256: rbxl `369be9436d4cb0112716da91444acd6526ee8dfc983061ded90f1fce65356fbc`, rbxlx `bbc15f2949fca04d75a43616b4510b4e8fa11a870afadeba2c86dd85dfaeac6a`. 이 파일들은 새 전달 폴더/ZIP의 0.2 빌드에 포함하지 않습니다.

최종 커밋 SHA와 ZIP 체크섬은 전달 패키지의 `DELIVERY.md`에 기록됩니다.
