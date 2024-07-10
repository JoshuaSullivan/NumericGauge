import SwiftUI
import Combine

public struct NumericGaugeView: UIViewRepresentable {
    
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
        
        deinit {
            print("*** COORDINATOR DEINIT")
        }
    }
    
    @Binding public var value: Double
    
    private let minValue: Double
    private let maxValue: Double
    private let layout: NumericGaugeLayout
    private let theme: NumericGaugeTheme
    private let valuePreviewMode: NumericGauge.ValuePreviewMode
    
//    @State private var gauge: NumericGauge
    
    public init(value: Binding<Double>, minValue: Double, maxValue: Double, layout: NumericGaugeLayout = NumericGaugeLayout(), theme: NumericGaugeTheme = .default, valuePreviewMode: NumericGauge.ValuePreviewMode = .default) {
        self._value = value
        self.minValue = minValue
        self.maxValue = maxValue
        self.layout = layout
        self.theme = theme
        self.valuePreviewMode = valuePreviewMode
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    public func makeUIView(context: Context) -> some UIView {
        let gauge = NumericGauge(minValue: minValue, maxValue: maxValue, layout: layout, theme: theme, valuePreviewMode: valuePreviewMode)
        gauge.value = value
        context.coordinator.attach(to: gauge)
        return gauge
    }
    
    public func updateUIView(_ uiView: UIViewType, context: Context) {
        uiView.setNeedsLayout()
    }
    
    public func makeCoordinator() -> () {
        Coordinator(parent: self)
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
    
    NumericGaugeView(value: $vm.value, minValue: 0, maxValue: 100)
        .frame(height: 60)
}
