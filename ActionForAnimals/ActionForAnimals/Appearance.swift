//
//  Appearance.swift
//  ActionForAnimals
//
//  Created by Ben Scheirman on 2/22/17.
//  Copyright © 2017 5calls. All rights reserved.
//

import UIKit

enum Appearance {
    static func swiftUISetup() {
        let pageControlAppearance = UIPageControl.appearance()
        pageControlAppearance.pageIndicatorTintColor = R.color.afaLightBlue()
        pageControlAppearance.currentPageIndicatorTintColor = R.color.afaDarkBlue()
        UINavigationBar.appearance().backIndicatorImage = UIImage(systemName: "chevron.backward.circle.fill")
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = UIImage(systemName: "chevron.backward.circle.fill")
        UIDatePicker.appearance().minuteInterval = 10
        UIDatePicker.appearance().roundsToMinuteInterval = true
    }
}
