import CoreGraphics

// Accidental type based on vertical position
enum Accidental {
    case sharp   // Top of frame (y < 0.33)
    case natural // Middle of frame (0.33 <= y <= 0.66)
    case flat    // Bottom of frame (y > 0.66)

    var suffix: String {
        switch self {
        case .sharp:   return "#"
        case .natural: return ""
        case .flat:    return "♭"
        }
    }

    static func from(y: CGFloat) -> Accidental {
        if y < 0.33 {
            return .sharp
        } else if y > 0.66 {
            return .flat
        } else {
            return .natural
        }
    }
}

// Strum chord type based on hand pose
enum StrumChordType: String {
    case major7 = "Maj7"
    case major = "Maj"
    case minor7 = "Min7"
    case minor = "Min"

    var icon: String {
        switch self {
        case .major7:  return "hand.raised.fingers.spread.fill"
        case .major:   return "hand.point.up.fill"
        case .minor7:  return "rock"
        case .minor:   return "hand.point.down.fill"
        }
    }

    var fingerPattern: String {
        switch self {
        case .major7:  return "Thumb + Index — loose pose"
        case .major:   return "Index pointing"
        case .minor7:  return "Thumb + Index + Pinky — rock n roll"
        case .minor:   return "Pinky extended"
        }
    }
}
