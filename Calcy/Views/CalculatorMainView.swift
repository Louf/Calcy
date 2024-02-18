//
//  CalculatorView.swift
//  Calcy
//
//  Created by Louis Farmer on 2/16/24.
//

import SwiftUI
import SplitView

struct CalculatorView: View {
    var body: some View {
        HSplit {
            Text("Left")
        } right: {
            Text("Right")
        }
        .fraction(0.75)
        .constraints(minPFraction: 0.75, minSFraction: 0.25) // Theoretically locking the splitter
        .splitter { Splitter.invisible() }
    }
}

#Preview {
    CalculatorView()
}
