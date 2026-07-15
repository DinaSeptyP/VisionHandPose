//
//  DeviceOrientation.swift
//  VisionHandPose
//
//  Created by Dylan Amadeus on 15/07/26.
//

import Foundation
import SwiftUI

// DeviceOrientation.swift
import Foundation
import SwiftUI

func forceLandscape() {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
    let preferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscape)
    windowScene.requestGeometryUpdate(preferences)
}

func currentInterfaceIsLandscape() -> Bool {
    let orientation = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first?
        .interfaceOrientation
    return orientation?.isLandscape == true
}
