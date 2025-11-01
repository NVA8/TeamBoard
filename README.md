# TeamBoard — Enterprise Task Manager with Real-Time Collaboration

TeamBoard is a SwiftUI portfolio project that demonstrates how to build an enterprise-ready task manager for distributed teams. It combines Trello-like Kanban boards, a real-time chat, analytics dashboards powered by Swift Charts, and a robust offline-first data layer backed by Firebase and CoreData.

- **Live collaboration** powered by Firebase Auth, Firestore, and Storage
- **Offline-ready** thanks to a custom CoreData cache layer
- **Secure by design** with FaceID/TouchID gated access and push notifications
- **Modern SwiftUI** interface with matched geometry animations, drag & drop, and context menus
- **Actionable analytics** that visualise throughput, velocity, and completion KPIs

##  Features

- Kanban boards with drag & drop tasks, context menus, and matched geometry transitions
- Task lifecycle management: priorities, statuses, attachments, comments, due dates
- Real-time team chat with channel linking to boards
- Analytics dashboard highlighting team velocity and workload distribution
- Role-based access control (owner, admin, contributor, viewer)
- Biometric re-authentication for sensitive actions
- Push notifications for new tasks, mentions, and chat messages
- Offline bootstrap from CoreData cache with Firestore delta syncing

##  Architecture

Clean Architecture split into `Domain`, `Data`, and `Presentation` layers:

- **Domain**: Entities, value objects, and use cases that encode business rules via protocols.
- **Data**: Firebase repositories, CoreData cache actor, and mappers for DTO ↔︎ domain mapping.
- **Presentation**: SwiftUI scenes, view models, and the `AppCoordinator` for navigation.

 For diagrams and deeper notes, see `Docs/Architecture.md`.

##  Tech Stack

- SwiftUI 5 + Combine + async/await
- Firebase Auth, Firestore, and Storage
- CoreData (custom NSPersistentContainer) for offline caching
- Swift Charts for KPI visualisations
- LocalAuthentication for FaceID/TouchID
- UserNotifications + APNS push tokens
- MatchedGeometryEffect, `Transferable`, and `DropDestination` for fluid drag & drop

##  Installation

1. Clone the repository and open `Team board.xcodeproj` (Xcode 16 or newer recommended).
2. Add your Firebase configuration:
   - Create a Firebase project and add an iOS app.
   - Download `GoogleService-Info.plist` and drop it into the `Team board` target.
   - Enable Email/Password, Apple Sign-In, and (optionally) Google Sign-In providers.
   - Configure Firestore and Storage rules for your development environment.
3. Install Firebase frameworks (SPM or CocoaPods). SPM example:
   - In Xcode, open **Project Settings → Package Dependencies**.
   - Add `https://github.com/firebase/firebase-ios-sdk.git`.
   - Include `FirebaseAuth`, `FirebaseFirestore`, `FirebaseStorage`, `FirebaseMessaging`.
4. Update Push Notifications:
   - Enable Push Notifications and Background Modes (Remote notifications) in the target capabilities.
   - Upload the APNS key to Firebase Cloud Messaging if you plan to test notifications.
5. Run the app on a device or simulator with iOS 18.

##  Testing

- Unit tests target domain use cases with fake repositories (`Team boardTests`).
- UI tests cover critical flows like authentication, board interactions, drag & drop, and analytics (`Team boardUITests`).
- Extend with snapshot tests for animated layouts if desired.

## Portfolio Assets

To showcase the project on GitHub or your website:

1. Capture screens:
   - Authentication with FaceID prompt
   - Kanban board with drag gesture in motion
   - Chat with real-time message arrival
   - Analytics dashboard (Swift Charts)
2. Export short video/GIF demonstrating drag & drop and matched geometry transitions.
3. Place assets in `Docs/Assets/` and embed them in the README (placeholder folder ready to be created).

##  Roadmap Ideas

- Real push notification pipeline (Cloud Functions for Firestore triggers)
- Rich text editor for task descriptions and chat messages
- Slack/Jira integrations via webhooks
- Advanced analytics (burn-down, cumulative flow diagrams)
- macOS/iPadOS companion apps reusing the SwiftUI presentation layer

---

Built with ❤️ to highlight enterprise SwiftUI chops, Firebase mastery, and production-ready architecture.

