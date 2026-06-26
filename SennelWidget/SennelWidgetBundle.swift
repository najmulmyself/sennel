//
//  SennelWidgetBundle.swift
//  SennelWidget
//
//  Created by Najmul Huda on 6/27/26.
//

import WidgetKit
import SwiftUI

@main
struct SennelWidgetBundle: WidgetBundle {
    var body: some Widget {
        SennelWidget()
        SennelWidgetControl()
        SennelWidgetLiveActivity()
    }
}
