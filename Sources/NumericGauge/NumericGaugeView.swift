import SwiftUI
import Combine

public struct NumericGaugeView: UIViewRepresentable {
    
    @MainActor
    public class Coordinator: NSObject {
        private var parent: NumericGaugeView

        init(parent: NumericGaugeView) {
            self.parent = parent
            super.init()
        }

        public func attach(to gauge: NumericGauge) {
            gauge.addTarget(self, action: #selector(handleValue(sender:)), for: .valueChanged)
        }

        @objc private func handleValue(sender: NumericGauge) {
            parent.value = sender.value
        }
    }
    
    @Binding public var value: Double
    
    private let minValue: Double
    private let maxValue: Double
    private let layout: NumericGaugeLayout
    private let theme: NumericGaugeTheme
    private let valuePreviewMode: NumericGauge.ValuePreviewMode
    private let accessibilityLabelText: String?
    private let accessibilityStep: Double?
    
//    @State private var gauge: NumericGauge
    
    /// Creates a new NumericGaugeView.
    ///
    /// - Parameters:
    ///   - value: A binding to the current value of the gauge.
    ///   - minValue: The minimum value of the gauge range.
    ///   - maxValue: The maximum value of the gauge range.
    ///   - layout: The layout configuration for the gauge bar.
    ///   - theme: The color theme for the gauge.
    ///   - valuePreviewMode: Controls whether and how a value preview is displayed.
    ///   - accessibilityLabel: The accessibility label announced by VoiceOver.
    ///   - accessibilityStep: The step size for VoiceOver swipe adjustments. Defaults to one major tick division.
    ///
    public init(
        value: Binding<Double>,
        minValue: Double,
        maxValue: Double,
        layout: NumericGaugeLayout = NumericGaugeLayout(),
        theme: NumericGaugeTheme = .default,
        valuePreviewMode: NumericGauge.ValuePreviewMode = .default,
        accessibilityLabel: String? = nil,
        accessibilityStep: Double? = nil
    ) {
        self._value = value
        self.minValue = minValue
        self.maxValue = maxValue
        self.layout = layout
        self.theme = theme
        self.valuePreviewMode = valuePreviewMode
        self.accessibilityLabelText = accessibilityLabel
        self.accessibilityStep = accessibilityStep
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    public func makeUIView(context: Context) -> some UIView {
        let gauge = NumericGauge(minValue: minValue, maxValue: maxValue, layout: layout, theme: theme, valuePreviewMode: valuePreviewMode)
        gauge.value = value
        gauge.accessibilityLabel = accessibilityLabelText
        gauge.accessibilityStep = accessibilityStep
        context.coordinator.attach(to: gauge)
        return gauge
    }
    
    public func updateUIView(_ uiView: UIViewType, context: Context) {
        guard let gauge = uiView as? NumericGauge else { return }
        if gauge.value != value {
            gauge.value = value
        }
    }
}

private class PreviewViewModel: ObservableObject {
    @Published public var value: Double = 50 {
        didSet {
            print("value: \(value)")
        }
    }
}

#Preview {
    @ObservedObject var vm = PreviewViewModel()
    
    return NumericGaugeView(value: $vm.value, minValue: 0, maxValue: 100)
        .frame(height: 60)
}
