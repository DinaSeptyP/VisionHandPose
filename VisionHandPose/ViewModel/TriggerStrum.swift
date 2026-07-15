//
//  TriggerStrum.swift
//  VisionHandPose
//
//  Created by Dylan Amadeus on 15/07/26.
//

import Foundation
import SwiftUI
var lastTriggeredStrings: [Bool] = [false, false, false, false, false, false]
var stringVibrations: [CGFloat] = [0, 0, 0, 0, 0, 0]

func triggerStrumAction(for stringIndex: Int) {
    let chord = HandPoseManager().activeChord
    guard stringIndex >= 0 && stringIndex < 6 else { return }
    
    let noteName = chord.guitarStrings[stringIndex]
    if !noteName.isEmpty {
        ChordPlayer().playNote(noteName)
    }
    
    withAnimation(.interactiveSpring(response: 0.12, dampingFraction: 0.12, blendDuration: 0)) {
        stringVibrations[stringIndex] = 14
        lastTriggeredStrings[stringIndex] = true
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
        withAnimation(.interactiveSpring(response: 0.22, dampingFraction: 0.18, blendDuration: 0)) {
            stringVibrations[stringIndex] = 0
        }
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
        lastTriggeredStrings[stringIndex] = false
    }
}
