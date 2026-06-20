import UIKit

enum HapticEvent {
    case pouchLogged
    case milestoneReached
    case shieldUsed
    case relapseLogged
    case schedulerUnlocked
}

final class HapticService {
    static func fire(_ event: HapticEvent) {
        switch event {
        case .pouchLogged, .schedulerUnlocked:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .shieldUsed:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .relapseLogged:
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        case .milestoneReached:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}
