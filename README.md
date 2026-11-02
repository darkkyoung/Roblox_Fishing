# FILAMENT Fishing — Functional Blockout 0.2

낚시 → 수집 → 보관/판매/사료, 알 → 부화 → 펫 장착/버프를 연결한 **기능 검수용 Roblox 프로젝트**입니다. 월드는 색상 Flat Part와 번호 슬롯만으로 새로 만들었습니다. 건축물·장식·복잡한 물·3D 인벤토리 미리보기가 없습니다.

**현재 판정: 구현·자동 검사·빌드 완료 / 실제 Roblox Studio 실행 승인 전.** 이 작업 환경에는 Studio가 없어 실제 조작·물리·렌더링·실기기·클라우드 저장·실제 2인 플레이는 미검증입니다. 자동 테스트를 실제 플레이 성공으로 간주하지 않습니다.

## P0 직렬화 핫픽스 (2026-11-02)

초기 0.2 파일은 `Position`만 저장해 Windows Studio에서 Zone 배치 검증이 실패했습니다. **이 브랜치의 최신 빌드에는 75개 Part/SpawnLocation 모두 Rojo 7의 12성분 `CFrame`으로 저장됩니다.** 이전에 받은 0.2 파일 대신 새 `0.2-P0-hotfix` 배포 파일을 사용하세요. 게임 버전/밸런스/저장 스키마는 변경하지 않았습니다.

수정 범위·파일 체크섬·정확한 Studio 부팅 QA는 [P0 핫픽스 보고서](docs/P0_SERIALIZATION_HOTFIX.md)에 있습니다. 실제 Studio 재실행은 이 작업 환경에서 **미실행**입니다. 기존 58개 테스트와 별개로 직렬화 7개·부팅 API 대체 객체 검사 3개가 통과했습니다.

## 바로 실행

1. `build/FILAMENT-Fishing-0.2.rbxl` 또는 `build/FILAMENT-Fishing-0.2.rbxlx`를 내려받아 **Roblox Studio → 파일 열기**로 엽니다.
2. **Play(F5)**를 누릅니다. `Run`이 아니라 플레이어가 생성되는 Play를 사용하세요.
3. 스폰 앞의 갈색 부두로 걸어갑니다. `Rod`는 자동 장착되며, 필요하면 **R / 기본 핫바**로 재장착합니다.
4. **F 길게 누르기 → 놓기**로 던집니다. 입질 후 F 유지, 50% 저항에서 놓고 **4초 안에 9번 누르기/놓기**, 다시 유지하면 포획합니다. PC는 화면 버튼, 모바일은 오른쪽 버튼도 지원합니다.
5. **B 또는 가방 버튼**을 눌러 획득물을 확인합니다. 상점·공방·자기 수족관에 걸어가 **E / 터치 프롬프트**를 누르면 해당 작업을 할 수 있습니다.

Rojo 설치·플러그인·외부 모델·수동 오브젝트 배치가 필요하지 않습니다. 기본 Studio는 **임시 저장 모드**이며 Stop 시 데이터가 사라집니다. 첫 안내 및 가방 → ? 도움말의 저장 상태를 확인하세요.

## 공간과 장소별 기능

북쪽은 Roblox 좌표의 **−Z**, 왼쪽은 **−X**입니다. 콘셉트 아트는 구역 관계만 참고했습니다.

| 구역 | 위치 / 표시 | 기능 |
|---|---|---|
| SpawnPlaza | 남쪽, 베이지 | 캐릭터 스폰, 정면에 부두와 연못 |
| FishingLake | 중앙, 파란 평면 | 서버가 찌 착수를 검사하는 수면 |
| FishingDock | 스폰과 연못 사이, 갈색 평면 | 낚시 시작·유지 가능 구역 |
| FishMarket | 왼쪽 아래, 주황 바닥·표지 | 물고기 판매 |
| FeedWorkshop | 왼쪽 위, 보라 바닥·표지 | 기본/고급 사료 제작 |
| AquariumGarden | 연못 북쪽 뒤편, 청록 바닥 | 16개 개인 Plot |
| AquariumPlot01~16 | 정원 안 번호·소유자 표식 | 배치·회수·알 부화·업그레이드 |
| Paths | 회색 평면 | 입구→부두, 왼쪽 시설→북쪽 정원 연결 |

연못에는 단순한 파란 충돌 바닥과 **투명 안전 충돌 Box**가 있어 일반 보행/점프로 연못에 들어가지 않도록 구성했습니다. 부두의 입구는 열려 있습니다. 낚시 보상은 부두 검증, 서버 계산 목표점, 실제 찌 위치와 연못 Part 레이캐스트를 모두 통과한 세션에서만 지급합니다. 실제 충돌·레이캐스트 동작은 Studio QA에 포함되어 있습니다.

## 연결된 플레이 루프

- **보관:** 내 Plot 옆에서 가방 → 물고기 → 개체 선택 → 배치. 단순 3D 물고기가 나타납니다. 수족관 탭에서 선택해 회수하면 표시 모델이 제거됩니다.
- **판매:** 주황 상점에서 물고기 선택 → 판매. 코인 증가와 개체 삭제가 하나의 서버 저장 트랜잭션으로 처리됩니다.
- **사료:** 보라 공방에서 물고기 선택 → 기본/고급 사료 제작. 개체 1마리를 소비합니다. 피라미에는 고급 제작 버튼이 없습니다.
- **부화:** 내 Plot에서 알 선택 → 사료 선택 → 배치 확정. **사료 소비·배치·부화 시각은 동시에 확정**됩니다. 40~60초 뒤 같은 ID의 알이 별개의 동물 펫으로 바뀝니다. 부화 중 알은 회수할 수 없습니다.
- **펫:** 펫 탭 → 장착/해제. 1마리만 추종하며, 버프는 다음 캐스팅 시작 시 서버 계산에 적용됩니다.
- **업그레이드:** 내 Plot에서 수족관 탭 → 업그레이드. 이후 배치하는 알부터 새 레벨 확률이 적용됩니다.

배치 중인 물고기는 먼저 회수해야 판매·제작할 수 있습니다. 다른 플레이어의 Plot과 개체는 조작할 수 없습니다. 평상시 낚시 게이지는 숨겨지며, 가방과 낚시 조작은 동시에 활성화되지 않습니다.

## 유지한 테스트 수치

| 항목 | 값 |
|---|---|
| 포획 보상 | 은빛 피라미 55%, 햇살 농어 28%, 푸른 잉어 12%, 물결 알 5% |
| 충전 / 입질 | 최대 파워까지 1.8초 / 기본 3~7초 |
| 포획 / 저항 | 초당 17% / 50%에서 4초 내 9회 |
| 부화 | 사료 없음 60초, 기본 50초, 고급 40초 |
| 수족관 | Lv.1~3, 4/7/10개, 업그레이드 100/250코인 |
| 판매 | 피라미/농어/잉어 20/40/80코인 |
| 기본 사료 | 피라미/농어/잉어 1/2/3개 |
| 고급 사료 | 피라미 불가, 농어/잉어 1/2개 |
| 펫 | 수달: 입질 −10%, 포획 +5%; 여우: −20%, +12%; 드래곤: −35%, +25% |
| 시작 코인 / 가방 한도 | 100 / 200개 |

사료·레벨·예정 부화 시간이 확률에 영향을 줍니다. Lv.1/기본 사료에서도 전설 확률은 0보다 큽니다. 배치 전 확률을 가방에서 확인할 수 있습니다. 펫은 **물고기 진화체가 아니라 알에서 태어나는 별도의 동물**입니다.

## Studio 테스트 메뉴

**가방 → ? → Studio 도구 펼치기**에만 있습니다.

- 물고기 3종 지급 / 물결 알 지급 / 기본·고급 사료 각 3개 / 500코인
- Lv.1~3 직접 변경: 현재 배치 수를 수용할 수 없는 레벨로 낮추기는 거부
- 배치된 알 즉시 부화: 기존 확률 계산용 예정 기간 길이는 보존
- 스폰·부두·상점·공방·정원·내 수족관 이동

서버에서 `RunService:IsStudio()`와 `Config.StudioDebug`를 모두 검사합니다. 일반 서버에서는 원격 호출을 위조해도 사용할 수 없습니다. 지급/즉시 부화 개체는 **[DEBUG]** 표시와 획득 경로가 저장됩니다. 도움말에는 이번 접속 정상 포획 수와 디버그 작업 수가 분리됩니다. 디버그를 쓴 빠른 기능 점검을 정상 획득 시나리오 통과로 기록하지 마세요.

## 저장·불러오기와 오프라인 부화

기본 `StudioPersistence=false`는 클라우드 API 없이 실행됩니다. 실제 저장 확인은 다음처럼 별도 비공개 Experience에서 합니다.

1. 파일을 **새 비공개 테스트 Experience**에 저장합니다. 다른 게임을 덮어쓰거나 공개하지 않습니다.
2. Explorer → ReplicatedStorage → Shared → Config에서 `StudioPersistence=true`로 설정합니다. 해당 Experience의 보안 설정에서 **Enable Studio Access to API Services**를 켭니다.
3. Play 후 가방 → ?의 저장 상태가 **클라우드 저장 완료**인지 확인합니다. 실패하면 Output의 `[FILAMENT]` 오류를 확인합니다. 영속 모드가 임시 모드로 조용히 대체되지 않습니다.
4. 코인·물고기·사료·레벨·배치·장착을 변경하고 저장 완료를 확인한 뒤 Stop/Play하여 복구를 확인합니다.
5. 알을 사료 없이 배치하고 저장 완료 후 Stop합니다. 60초 이상 지난 뒤 같은 계정/Experience로 Play합니다. 펫 1마리로 변해야 하며 다시 접속해도 재추첨·추가 지급되면 안 됩니다.

데이터 키는 `player_<UserId>`, 네임스페이스는 기존 `FILAMENT_Fishing_v1_Studio` / `_Live`를 유지합니다. **Plot 번호는 접속별 할당**입니다. 재접속 시 번호가 바뀌어도 개인 프로필의 수족관 배치가 새 할당 Plot에 복구됩니다. 개체 소유권은 프로필 키로 관리하고 3D 모델은 저장 데이터에서 재생성합니다.

저장 재시도 3회, 세션 잠금 180초, 갱신 간격 40초입니다. 실패/잠금 상실 시 저장되지 않은 후보 상태를 보여주지 않고 오류를 알린 뒤 세션을 중지합니다. 실제 API·비정상 종료 검수는 QA 문서를 따르세요.

## 개발 구조

| 경로 | 역할 |
|---|---|
| `config/zones.json` | 위치·크기·타입·색·상호작용 거리의 단일 원본 |
| `scripts/generate_world.py` | Flat 월드와 `ZoneConfig.lua`를 함께 생성 |
| `src/shared/Zones.lua` | Zone 경계·높이·거리·착수 좌표·액션 권한의 순수 규칙 |
| `src/server/ZoneService.lua` | 실제 캐릭터 위치와 연못 Raycast 연결 |
| `Domain / FishingMachine / Catalog` | 기존 수집·소비·확률·부화·버프 / 낚시 상태 / 콘텐츠 정의 |
| `ProfileStore / Lease` | 기존 DataStore 트랜잭션·재시도·잠금 |
| `RewardService` | 서버 보상 추첨·고정 ID 지급, 획득 경로 유지 |
| `PlotRegistry / WorldService` | 16개 소유권 할당과 표시 모델 생성·제거 |
| `StudioTools` | 서버 전용 테스트 작업 |
| `src/client/Main.client.lua` | 새 목록형 가방·게이지·PC/터치 입력 |
| `src/client/Effects.client.lua` | 기본 추종/유영·자기 Prompt 표시·초기 카메라 |

서버 실행 진입점은 `Main.server.lua` **1개**, 클라이언트 LocalScript는 **2개**입니다. 이전 UI·월드 실행 스크립트와 병행하지 않습니다. 기존 0.1 빌드 파일은 기록용이며 새 Rojo 트리에 로드되지 않습니다.

최종 아트로 교체할 때 Zone의 논리 좌표와 Floor/Console 계약을 유지하면 수집·부화·저장 로직을 고칠 필요가 없습니다. 좌표를 옮길 때는 `zones.json`을 수정해 재빌드하세요. 임의로 Floor만 이동해 서버와 설정이 어긋나면 시작 시 명시적 오류가 발생합니다. V2 낚시는 `FishingMachine` 및 입력 어댑터를 교체하고 `RewardService` 이후를 재사용할 수 있습니다.

## 빌드·테스트

바로 플레이에는 개발 도구가 필요 없습니다. 개발용 고정 버전은 **Rojo 7.7.1 / Luau 0.743 / Python 3 / [rbxmk 0.9.1](https://github.com/Anaminus/rbxmk/releases/tag/v0.9.1)**입니다.

```bash
bash scripts/build.sh
bash scripts/check.sh
```

Windows PowerShell:

```powershell
./scripts/build.ps1
python scripts/run_tests.py
luau tests/functional.spec.luau
python tests/serialization.spec.py
python scripts/test_boot.py
python scripts/validate_place.py
```

Luau 정적 검사: `luau-analyze src/shared/*.lua src/server/*.lua src/client/*.lua`. `scripts/check.sh`는 소스 컴파일도 수행합니다. `LUAU_BIN` 환경 변수로 규칙 테스트 실행 파일 경로를 지정할 수 있습니다. `rbxmk`를 PATH에 추가하거나 `RBXMK_BIN`으로 지정하세요. `validate_place.py`는 실제 `.rbxl`을 rbxmk로 독립 역직렬화하여 `.rbxlx` 및 원본 설정과 대조합니다. 도구가 없으면 검증은 실패하며 바이너리 검사를 생략하지 않습니다.

검증: **기존 30개 + 새 28개 = 58개 자동 테스트 통과**, Luau 분석·컴파일 및 Rojo 두 형식 빌드 통과. P0 수정 후 재검증 원문은 `build/test-output-0.2-p0.txt`, 기능별 구분은 [결과 보고서](docs/PHASE_0.2_REPORT.md), 실제 시나리오는 [Studio QA](docs/QA_0.2.md)입니다. 기존 테스트 중 레이아웃 1개만 새 UI 구조에 맞춰 수정했습니다. 테스트의 저장 어댑터는 모의 구현이며 실제 Roblox API 호출이 아닙니다.

## 버전·GitHub 보존

- Canonical: https://github.com/darkkyoung/Roblox_Fishing
- fresh fetch한 기준 main: `857fa5c95357908fa022e6f61417b6e773432765`
- 작업 브랜치: `feature/fishing-functional-blockout` / [Draft PR #2](https://github.com/darkkyoung/Roblox_Fishing/pull/2)
- 0.1.1 브랜치와 [Draft PR #1](https://github.com/darkkyoung/Roblox_Fishing/pull/1)은 변경하지 않았습니다. 0.1.1의 UI 전용 14개 테스트도 해당 브랜치에 보존됩니다.
- `Domain`, `FishingMachine`, `Catalog`, `ProfileStore`, `Lease`는 기준 main과 동일합니다. Config의 밸런스는 유지하고 지리 정보만 Zone 설정으로 분리했습니다.
- 이번 최종 커밋·새 PR·체크섬은 전달 ZIP의 `DELIVERY.md`에 있습니다. main 병합이나 Roblox 공개 배포는 하지 않습니다.

`docs/TEST_RESULTS.md`, `docs/STUDIO_TEST_PLAN.md`, `docs/ARCHITECTURE.md`는 이전 0.1 기록입니다. **0.2 실행 기준은 이 README와 0.2 문서**입니다.
