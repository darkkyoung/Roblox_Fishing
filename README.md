# FILAMENT Fishing — Playable Prototype 0.1

Roblox용 낚시·수집·개인 수족관·희귀 펫 프로토타입입니다. **소스 구현과 Rojo 빌드·자동 검사는 완료했으며, 실제 Roblox Studio 실행·멀티플레이 승인은 아직 수행하지 않았습니다.** 정식 출시용이 아닌 비공개 검수용 빌드입니다.

## 가장 빠르게 실행하기

1. Roblox Studio를 실행합니다.
2. **파일 → 파일 열기(Ctrl+O)**에서 `build/FILAMENT-Fishing-0.1.rbxl` 또는 `.rbxlx`를 엽니다. 별도로 받은 게임 파일도 그대로 열 수 있습니다.
3. **Play(F5)**를 누릅니다. `Run`은 플레이어 캐릭터를 만들지 않으므로 사용하지 마세요.
4. 화면 위 **낚시터** 버튼을 누릅니다. 낚싯대는 자동으로 장착됩니다. 해제했다면 위의 **낚싯대 장착**, 키보드 **R** 또는 기본 단축바를 사용하세요.
5. **F키 또는 화면의 캐스팅 버튼을 누르다가 놓으세요.** 입질 뒤 다시 유지하고, 저항 구간에서는 놓았다가 **4초 안에 9번 연타**하세요. 저항을 제거한 뒤 다시 유지하면 잡힙니다.

**Rojo 플러그인, 개발 도구, 외부 모델 설치, 수동 오브젝트 배치가 필요하지 않습니다.** 지형·연못·부두·상점·공방·수족관은 게임 파일에 포함되어 있고, 낚싯대·물고기·알·펫·UI는 실행 시 생성됩니다.

기본 파일은 **Studio 임시 저장 모드**입니다. 게시하지 않은 파일도 바로 실행할 수 있고, 상단에 `임시 저장 · Stop 시 초기화`가 표시됩니다. **Stop하면 저장 데이터는 사라집니다.** 이것은 클라우드 저장 성공 표시가 아닙니다. 실제 저장·재접속 검증은 아래 절차를 따르세요.

## 핵심 플레이 흐름

| 획득물 | 할 수 있는 일 |
|---|---|
| 은빛 피라미 / 햇살 농어 / 푸른 잉어 | 내 수족관에서 배치·회수, 판매 상점에서 코인으로 판매, 사료 공방에서 기본·고급 사료로 제작 |
| 물결 알 | 가방의 알 탭에서 사료 선택 → 내 수족관으로 이동 → 알 배치 → 부화 |
| 아기 수달 / 구름 여우 / 별빛 드래곤 | 가방의 펫 탭에서 한 마리 장착 → 실제 입질 대기시간 감소·포획 속도 증가 |

상단 이동 버튼은 빠른 테스트를 위한 무료 이동입니다. 좁은 화면에서는 가로로 밀어 나머지 버튼을 볼 수 있습니다. **B키**로 가방을 열거나 닫을 수 있습니다. 상점·공방·본인 수족관의 콘솔에도 상호작용 프롬프트가 있습니다.

가방에서 물고기를 선택한 뒤 원하는 장소로 이동하고 다시 가방을 열어 사용하세요. 상점·공방·수족관 작업은 **서버가 해당 장소까지의 거리를 확인**합니다. 수족관의 물고기는 먼저 회수해야 판매·제작할 수 있습니다.

펫은 **알에서 태어나는 별도의 동물**입니다. 물고기의 진화체가 아닙니다. 일반 물고기의 성장·진화는 이번 빌드에 구현하지 않았고 `growth` 데이터만 확장용으로 마련했습니다.

## 테스트용 기본 수치

| 설정 | 값 |
|---|---|
| 낚시 보상 | 피라미 55%, 농어 28%, 잉어 12%, 물결 알 5% |
| 캐스팅 파워 충전 | 최대 1.8초, 설정 거리 8~38 studs, 연못 내부로 보정 |
| 입질 대기 | 기본 3~7초 |
| 포획 게이지 | 초당 17%, 50% 지점에서 저항 1회 |
| 저항 | 4초 안에 9회, 서버 최대 인정 빈도 약 13회/초 |
| 부화 | 사료 없음 60초 / 기본 사료 50초 / 고급 사료 40초 |
| 수족관 레벨 | 1~3, 수용량 4 / 7 / 10개 |
| 업그레이드 비용 | 100 / 250 코인 |
| 물고기 판매 | 20 / 40 / 80 코인 |
| 기본 사료 제작 | 피라미 1 / 농어 2 / 잉어 3개 |
| 고급 사료 제작 | 피라미 불가 / 농어 1 / 잉어 2개 |
| 시작 코인·가방 한도 | 100 코인 / 전체 개체 200개 |

부화에는 **배치할 때 선택한 사료·수족관 레벨·예정 부화 시간**이 적용됩니다. 사료는 알 배치 시 1개 소비되며, 도중에 추가로 넣거나 알을 회수할 수 없습니다. 업그레이드는 이후에 배치하는 알부터 반영됩니다. 더 긴 부화 시간에도 작은 상위 등급 보너스가 있으며, 좋은 사료는 시간을 단축하면서 그보다 큰 품질 보너스를 줍니다. 기본 사료·레벨 1에서도 전설 확률이 양수입니다. 구체적인 확률은 알 탭에 표시됩니다.

| 장착 펫 | 입질 대기 | 포획 속도 |
|---|---:|---:|
| 아기 수달 | 10% 감소 | 5% 증가 |
| 구름 여우 | 20% 감소 | 12% 증가 |
| 별빛 드래곤 | 35% 감소 | 25% 증가 |

버프는 캐스팅 시작 시 서버에서 읽어 낚시 세션에 적용합니다. 저항 난도는 펫에 따라 바뀌지 않습니다.

## Studio 디버그 도구

Play 중 **가방 → 도움말 → Studio 전용 테스트**를 사용하세요.

- **물고기 3종 + 알 + 재료 지급**: 물고기 각 1마리, 물결 알 1개, 500코인, 사료 각 3개를 지급합니다.
- **배치된 알 즉시 부화**: 이미 배치한 알의 시간을 앞으로 당깁니다. 예정 부화 기간의 길이는 유지하여 확률 수치를 바꾸지 않습니다.

서버의 `RunService:IsStudio()`와 `Config.StudioDebug`가 모두 참이어야 동작합니다. 라이브 플레이어가 같은 RemoteEvent를 직접 호출해도 차단됩니다. 도구를 숨기려면 `StudioDebug=false`로 설정하세요.

## 실제 저장·오프라인 부화 검증

1. 이 파일을 **새로운 비공개 테스트 Experience**로 저장합니다. 공개 액세스로 전환하지 마세요. 기존 다른 게임을 덮어쓰지 마세요.
2. Studio에서 Explorer의 `ReplicatedStorage → Shared → Config`를 열고 `StudioPersistence = true`로 바꿉니다. 파일을 저장합니다.
3. 해당 테스트 Experience 설정의 보안 항목에서 **Enable Studio Access to API Services**를 켭니다.
4. Play 후 상단이 **클라우드 저장 완료**인지 확인합니다. 오류가 나면 Output의 `[FILAMENT]` 메시지를 확인하세요. 영속 모드는 오류를 임시 저장 모드로 몰래 바꾸지 않습니다.
5. 테스트 팩을 지급하고 물고기를 배치·판매·제작합니다. 알을 사료 없이 배치하고 완료까지 남은 시간을 확인합니다.
6. **클라우드 저장 완료** 표시 후 Stop합니다. 60초 이상 기다렸다가 같은 계정·같은 Experience에서 다시 Play합니다.
7. 코인·사료·수족관 배치·레벨이 유지되고, 알은 펫 1마리로 바뀌어야 합니다. 다시 Stop/Play해도 같은 펫이며 추가 지급되지 않아야 합니다.

네임스페이스는 `FILAMENT_Fishing_v1_Studio`와 `FILAMENT_Fishing_v1_Live`로 분리됩니다. Studio 테스트 데이터는 게시된 Roblox 서버의 데이터와 공유되지 않습니다. 라이브 서버는 항상 영속 저장을 사용합니다. 실제 API 저장 실패·잠금 충돌은 최대 3회 재시도 또는 접속 거부·세션 중지로 명시적으로 처리합니다.

프로필 잠금은 180초, 갱신 간격은 40초입니다. 비정상 종료 직후 잠겨 있으면 약 3분 뒤 다시 시도하세요. 저장 성공 여부가 불확실한 경우에는 보상을 먼저 보여주지 않고 세션을 중지합니다. 사용자 기기 강제 종료나 플랫폼 장애 자체를 완전히 제거할 수는 없습니다.

## 소스 구조와 수정 방법

```text
src/shared/Config.lua          게임 밸런스·저장 모드
src/shared/Catalog.lua         물고기·알·펫 정의
src/shared/Domain.lua          보상·소비·배치·부화·버프 순수 규칙
src/shared/FishingMachine.lua  낚시 V1 상태 전환
src/shared/Strings.lua         한국어·영어 UI 문구
src/shared/Models.lua          기본 Part 모델
src/shared/Layout.lua          반응형 크기 계산
src/server/Main.server.lua     서버 초기화·검증·Remote 연결
src/server/FishingService.lua  낚시 위치·장비·입력·보상 연결
src/server/ProfileStore.lua    영속 트랜잭션·재시도·세션 관리
src/server/Lease.lua           UpdateAsync 잠금 규칙
src/server/WorldService.lua    수족관 할당·표시·낚싯대
src/client/Main.client.lua     UI·PC/터치 입력
src/client/Effects.client.lua  수영·펫 추종 표시
src/world.model.json           빌드에 포함되는 전체 맵
tests/spec.luau                실제 Luau 모듈 자동 테스트
scripts/                      빌드·검사·맵 생성
docs/                         검증표·실제 테스트 절차·설계
```

바로 플레이할 때는 아래 도구가 필요 없습니다. 소스를 수정하는 개발자에게만 해당합니다.

- 고정 도구 버전: **Rojo 7.7.1**, **Luau 0.743**, Python 3.
- Windows 재빌드: PowerShell에서 `./scripts/build.ps1` 실행.
- macOS/Linux 재빌드: `bash scripts/build.sh` 실행.
- Luau 검사: `luau-analyze src/shared/*.lua src/server/*.lua src/client/*.lua`
- 규칙·저장 테스트: `python scripts/run_tests.py` (필요하면 `LUAU_BIN`에 실행 파일 경로 지정).
- 개발 중 Studio 동기화: `rojo serve`와 Rojo Studio 플러그인 사용.
- 맵 생성기를 다시 실행하면 `src/world.model.json`을 재생성합니다. 지속적인 맵 변경은 생성기에 반영하세요.
- `rojo build`는 스크립트를 실행하는 것이 아닙니다. 빌드 통과만으로 실제 플레이 성공을 확정할 수 없습니다.

GitHub 새 Private Repository를 만드는 연결 기능과 인증된 GitHub CLI가 이 작업 환경에 없어 원격 저장소 생성·푸시는 수행하지 않았습니다. 독립된 로컬 Git 저장소로 커밋했으며 최종 ZIP의 `SOURCE_COMMIT.txt`와 `build/FILAMENT-source.bundle`에 버전 정보를 포함합니다. 다른 프로젝트는 변경하지 않았습니다.

## 검증과 다음 단계

자세한 완료 구분은 [docs/TEST_RESULTS.md](docs/TEST_RESULTS.md), 실제 Studio 승인 절차는 [docs/STUDIO_TEST_PLAN.md](docs/STUDIO_TEST_PLAN.md), 구조·한계·향후 개발은 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)를 참조하세요.

현재 공개 배포·Robux 결제·플레이어 거래·도둑질·물고기 진화·낚시 V2는 포함하지 않습니다. 실제 Studio 체크리스트를 통과한 뒤 다음 단계로 넘어가세요.

참고한 공식 문서: [Rojo 프로젝트 형식](https://rojo.space/docs/v7/project-format/), [Roblox DataStore](https://create.roblox.com/docs/cloud-services/data-stores), [플레이어 데이터와 세션 잠금](https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing), [서버 경계 검증](https://create.roblox.com/docs/scripting/security/client-server-boundary).
