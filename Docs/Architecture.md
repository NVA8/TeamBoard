# TeamBoard Architecture Overview

TeamBoard is organised with a Clean Architecture mindset, separating the project into independent layers that communicate via protocols. The goal is to keep the UI reactive, the business rules testable, and the data access easily replaceable.

```
┌──────────────┐
│  Presentation│  SwiftUI, async/await, Combine
└──────┬───────┘
       │  interacts through ViewModels & Coordinators
┌──────▼───────┐
│    Domain    │  Entities, Value Objects, Use Cases, Repositories (protocols)
└──────┬───────┘
       │  invert dependency via protocol conformances
┌──────▼───────┐
│     Data     │  Firebase Auth/Firestore/Storage, CoreData cache, Push, Biometrics
└──────────────┘
```

## Layer Responsibilities

- **Presentation**: SwiftUI views, navigation, state handling, animations (`matchedGeometryEffect`, drag and drop, context menus), Swift Charts dashboards, and view models. Files live under `Team board/Presentation`.
- **Domain**: Pure business logic with no Apple or Firebase imports. Defines entities (`Task`, `Board`, `TeamMember`), value objects, and use cases (`ObserveBoardsUseCase`, `UpdateTaskStatusUseCase`, etc.). Protocol-oriented to enable mocks in tests.
- **Data**: Concrete services for Firebase, CoreData, Push Notifications, and biometric protection. Uses mappers to translate DTOs to domain entities and repositories that satisfy the domain contracts.

## Asynchronous Data Flow

Firestore real-time listeners feed async `AsyncThrowingStream` publishers that are bridged into the domain use cases. View models consume those use cases via `for await` loops or Combine publishers and update `@Published` state.

CoreData provides offline-first storage via background contexts. The repository writes snapshots of Firestore collections into CoreData and serves cached data when offline.

```
Firestore -> DTO -> Mapper -> Domain Entity -> ViewModel -> SwiftUI View
                  ↘ CoreData Cache (background) ↗
```

## Navigation and Coordination

Navigation is centralised through `AppFlowCoordinator`, which holds the high-level navigation state (authentication, onboarding, main app). Each screen exposes a `ViewModel` that interacts only with use cases, not with concrete services.

## Security

- Firebase Auth handles email/password and SSO (Apple, Google) flows.
- Biometric guard wraps the authenticated session; on launch we prompt FaceID/TouchID before exposing sensitive data.
- Push notification tokens are synchronised with Firestore for targeted alerts on new tasks or chat messages.

## Offline Strategy

1. Initial sync loads data from Firestore, persists into CoreData.
2. Subsequent launches bootstrap from CoreData snapshots instantly.
3. Firestore listeners merge incoming updates and reconcile conflicts via server timestamps.
4. Write operations queue locally if offline and retry when connectivity returns.

## Testing Strategy

- Unit tests in `Team boardTests` focus on use cases and repository behaviour with fake services.
- UI tests in `Team boardUITests` cover onboarding, board interactions, drag-and-drop, chat, and analytics visualisations.
- Snapshot tests (optional) validate complex animations and matched geometry transitions.

## Extensibility

- Additional integrations (e.g., JIRA import, Slack webhooks) should plug into the data layer via new repository implementations.
- Domain layer remains untouched when swapping Firebase for another backend.
- Presentation layer can be shared with macOS/iPadOS targets due to SwiftUI.

