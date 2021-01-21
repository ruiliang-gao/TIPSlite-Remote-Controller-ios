//
//  HapticsController.swift
//  TipsController
//
//  Created by Prasan Dhareshwar on 1/15/21.
//
//
import UIKit

final class HapticsManager {
    static let shared = HapticsManager()


//    private init() {}

    public func selectionVibrate() {
        DispatchQueue.main.async {
            let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
            selectionFeedbackGenerator.prepare()
            selectionFeedbackGenerator.selectionChanged()
        }
    }

    public func impactVibrate() {
        DispatchQueue.main.async {
            let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .light)
            impactFeedbackgenerator.prepare()
            impactFeedbackgenerator.impactOccurred()
        }
    }

    public func vibrate(for type: UINotificationFeedbackGenerator.FeedbackType) {
        DispatchQueue.main.async {
            let notificationGenerator = UINotificationFeedbackGenerator()
            notificationGenerator.prepare()
            notificationGenerator.notificationOccurred(type)
        }

    }
}
