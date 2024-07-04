import SwiftUI
import Combine

public struct NumericGaugeView: UIViewRepresentable {
    
    private class ValueProxy {
        private var parent: NumericGaugeView
        private var sub: AnyCancellable?
        
        init(parent: NumericGaugeView, gauge: NumericGauge) {
            self.parent = parent
            sub = gauge.valuePublisher.assign(to: \.value.wrappedValue, on: parent)
        }
    }
        
    private let gauge: NumericGauge
    private let value: Binding<Double>
    private var proxy: ValueProxy?
    
    public init(value: Binding<Double>, minValue: Double, maxValue: Double, layout: NumericGaugeLayout = NumericGaugeLayout(), theme: NumericGaugeTheme = .default, valuePreviewMode: NumericGauge.ValuePreviewMode = .default) {
        gauge = NumericGauge(minValue: minValue, maxValue: maxValue, layout: layout, theme: theme, valuePreviewMode: valuePreviewMode)
        self.value = value
        gauge.set(value: value.wrappedValue)
        proxy = ValueProxy(parent: self, gauge: gauge)
    }
    
    public func makeUIView(context: Context) -> some UIView {
        gauge
    }
    
    public func updateUIView(_ uiView: UIViewType, context: Context) {
        uiView.setNeedsLayout()
    }
}

#Preview {
    var value = Binding<Double>(get: { 1.0 }, set: { _ in })
    
    NumericGaugeView(value: value, minValue: 0, maxValue: 100)
        .frame(height: 60)
}
