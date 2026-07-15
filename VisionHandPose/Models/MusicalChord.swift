import SwiftUI

enum MusicalChord: String {
    case none = "—"
    case c = "C"
    case d = "D"
    case e = "E"
    case f = "F"
    case g = "G"
    case a = "A"
    case b = "B"

    var accidentalSuffix: String {
        ""
    }

    var icon: String {
        switch self {
        case .none: return "hand.raised.slash"
        case .c:    return "hand.point.up.left.fill"
        case .d:    return "hand.victory.fill"
        case .e:    return "hand.raised.fill"
        case .f:    return "hand.raised.fill"
        case .g:    return "hand.raised.fill"
        case .a:    return "hand.fist.fill"
        case .b:    return "hands.sparkles.fill"
        }
    }

    // Finger pattern used to trigger this chord
    var fingerPattern: String {
        switch self {
        case .none: return "No chord detected"
        case .c:    return "Index finger only"
        case .d:    return "Index + middle — peace sign"
        case .e:    return "Index + middle + ring + little"
        case .f:    return "Index + middle + ring + little — all except thumb"
        case .g:    return "All five fingers — open hand"
        case .a:    return "Thumb only — thumbs up"
        case .b:    return "Thumb + index — L-shape"
        }
    }

    // Notes (as ChordPlayer note names) that make up the chord for this pose
    var notes: [String] {
        switch self {
        case .none: return []
        case .c:    return ["C", "E", "G"]
        case .d:    return ["D", "F#", "A"]
        case .e:    return ["E", "G", "B"]
        case .f:    return ["F", "A", "C2"]
        case .g:    return ["G", "B", "D"]
        case .a:    return ["A", "C#", "E"]
        case .b:    return ["B", "D", "F#"]
        }
    }

    // The 6-string voicing mapped to the string indices (0 = string 6, 5 = string 1)
    var guitarStrings: [String] {
        switch self {
        case .none:
            return ["", "", "", "", "", ""]
        case .c:
            return ["E3", "C", "E", "G", "C5", "E5"]
        case .d:
            return ["D3", "A3", "D", "F#", "A", "D5"]
        case .e:
            return ["E3", "B3", "E", "G", "B", "E5"]
        case .f:
            return ["F3", "C", "F", "A", "C5", "F5"]
        case .g:
            return ["G3", "B3", "D", "G", "B", "G5"]
        case .a:
            return ["E3", "A3", "E", "A", "C#5", "E5"]
        case .b:
            return ["F#3", "B3", "F#", "B", "D#5", "F#5"]
        }
    }
}
