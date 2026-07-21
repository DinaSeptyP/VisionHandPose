//
//  DeviceOrientation.swift
//  VisionHandPose
//
//  Created by Dylan Amadeus on 15/07/26.
//

import Foundation
import SwiftUI

var isLandscape = false
func forceLandscape() {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
    let preferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscape)
    windowScene.requestGeometryUpdate(preferences)
}

func updateOrientation() {
    let orientation = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first?
        .interfaceOrientation
    isLandscape = orientation?.isLandscape == true
}
