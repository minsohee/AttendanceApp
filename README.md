# 출석체크 앱 (AttendanceApp)

학원·과외 선생님을 위한 **iOS 출석 관리 앱**입니다.
수업별로 학생을 등록하고, 출석을 체크하면서 학부모에게 바로 출석·수업 종료 문자를 보낼 수 있습니다.
SwiftUI로 만들었고, 별도 서버 없이 기기 안에만 데이터를 저장합니다.

## 주요 기능

### 수업 관리
- 수업 이름과 시간표를 입력해 수업을 추가/삭제
- 수업 목록에서 수업별 학생 수 확인

### 학생 관리
- 이름·전화번호·메모로 학생 등록 (메모는 동명이인 구분이나 특이사항 기록용)
- **연락처에서 불러오기**: 휴대폰 연락처를 검색해 이름과 전화번호를 바로 가져옴
- 학생 정보 수정, 왼쪽으로 밀어서 삭제

### 출석 체크
- 학생을 탭해서 오늘 출석 처리, 출석 인원(`출석 n / 전체 m명`) 실시간 표시
- 출석 중인 상태는 저장되어 앱을 껐다 켜도 **당일**에는 유지 (다음 날이 되면 자동 초기화)
- "오늘 출석 완료"를 누르면 그날의 출석 상태 초기화

### 문자 발송 (iOS 기본 메시지 작성 화면 사용)
| 대상 | 내용 예시 |
| --- | --- |
| 출석한 학생(학부모) | `[수학반] 홍길동 학생 오후 3시 05분에 출석하였습니다.` |
| 코디 선생님 | `[수학반] 전체 10명 중 8명 출석하였습니다.` |
| 출석한 학생 전체 | `[수학반] 오후 5시 00분에 수업이 종료되었습니다.` (순서대로 연속 발송) |

- 수업마다 **코디 선생님** 번호를 등록해 출석 요약을 보낼 수 있습니다.

### 출석 기록
- 수업별 출석 이력을 시간순으로 확인
- 각 기록마다 문자 발송 여부 표시

## 기술 스택

- **언어/UI**: Swift, SwiftUI
- **프레임워크**: Contacts / ContactsUI (연락처 불러오기), MessageUI (문자 발송)
- **데이터 저장**: `UserDefaults` + `Codable` (JSON 인코딩)
- **최소 지원 버전**: iOS 26.5

## 프로젝트 구조

```
AttendanceApp/
├── AttendanceApp.xcodeproj        # Xcode 프로젝트
└── AttendanceApp/
    ├── AttendanceAppApp.swift     # 앱 진입점
    ├── ContentView.swift          # 탭 구성 (수업 / 출석 기록)
    ├── Models.swift               # 데이터 모델 + DataStore (저장/불러오기)
    ├── ClassListView.swift        # 수업 목록
    ├── AddClassView.swift         # 수업 추가
    ├── ClassDetailView.swift      # 수업 상세: 출석 체크, 학생/코디 선생님 관리, 문자 발송
    ├── AddStudentView.swift       # 학생 추가 (연락처 불러오기)
    ├── AttendanceCheckView.swift  # 출석 체크 화면
    ├── AttendanceHistoryView.swift# 출석 기록
    └── Assets.xcassets            # 앱 아이콘, 색상
```

## 실행 방법

### 준비물
- macOS + **Xcode 26.5 이상** (iOS 26.5 SDK 포함)
- (실기기 실행 시) Apple ID와 iPhone

### 1. 소스 받기
```bash
git clone https://github.com/minsoyee/AttendanceApp.git
cd AttendanceApp
open AttendanceApp.xcodeproj
```

### 2. 시뮬레이터에서 실행
1. Xcode 상단의 실행 대상(Destination)에서 원하는 iPhone 시뮬레이터를 선택합니다.
2. `⌘ + R` (또는 ▶︎ Run 버튼)을 누르면 빌드 후 시뮬레이터에서 앱이 실행됩니다.

> ⚠️ 시뮬레이터에서는 **문자 발송이 동작하지 않습니다** (`MFMessageComposeViewController`는 실제 기기에서만 사용 가능). 수업·학생 관리와 출석 체크는 시뮬레이터에서도 확인할 수 있습니다.

### 3. 실제 iPhone에서 실행
1. iPhone을 Mac에 연결하고 Xcode 실행 대상에서 기기를 선택합니다.
2. 프로젝트 설정 → **Signing & Capabilities** 탭에서
   - **Team**을 본인 Apple ID 팀으로 변경
   - 필요하면 **Bundle Identifier**를 고유한 값으로 변경 (예: `com.yourname.AttendanceApp`)
3. `⌘ + R`로 실행합니다.
4. 처음 설치한 경우 iPhone에서 **설정 → 일반 → VPN 및 기기 관리**에서 개발자 앱을 신뢰해 주세요.
5. 학생 추가 시 연락처 접근 권한을 요청하면 **허용**을 눌러야 연락처 불러오기를 쓸 수 있습니다.

### 터미널에서 빌드만 해보기 (선택)
```bash
xcodebuild -project AttendanceApp.xcodeproj -scheme AttendanceApp -destination 'generic/platform=iOS Simulator' build
```

## 데이터 및 개인정보

- 모든 데이터(수업, 학생 연락처, 출석 기록)는 **기기 내부(UserDefaults)에만 저장**되며 외부 서버로 전송되지 않습니다.
- 문자는 iOS 기본 메시지 작성 화면을 통해 사용자가 직접 확인 후 전송합니다.
- 앱을 삭제하면 저장된 데이터도 함께 삭제됩니다.
