import SwiftUI
import SplitView

struct CalculatorMainView: View {
    var body: some View {
        HSplit {
            CalculatorView()
        } right: {
            HistoryView()
        }
        .fraction(0.6)
        .constraints(minPFraction: 0.6, minSFraction: 0.4) // Theoretically locking the splitter
        .splitter { Splitter.invisible() }
    }
}

#Preview {
    CalculatorView()
}
