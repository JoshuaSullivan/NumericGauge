import SwiftUI
import Combine

public struct NumericGaugeView: UIViewRepresentable {
        
    private let gauge: NumericGauge
    @State private var sub: AnyCancellable?
    public var valuePublisher: AnyPublisher<Double, Never> {
        gauge.valuePublisher
    }
    
    public init(minValue: Double, maxValue: Double, layout: NumericGaugeLayout = NumericGaugeLayout(), theme: NumericGaugeTheme = .default, formatter: NumberFormatter? = nil) {
        gauge = NumericGauge(minValue: minValue, maxValue: maxValue, layout: layout, theme: theme, formatter: formatter)
    }
    
    public func makeUIView(context: Context) -> some UIView {
        gauge
    }
    
    public func updateUIView(_ uiView: UIViewType, context: Context) {
        uiView.setNeedsLayout()
    }
}

#Preview {
    NumericGaugeView(minValue: 0, maxValue: 100)
        .frame(height: 60)
}
