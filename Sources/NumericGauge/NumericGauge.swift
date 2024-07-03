import UIKit
import Combine

/// A control that functions similarly to a Slider, but uses a fixed reference point with a sliding gauge under it.
///
/// The NumericGauge control allows much more precise selection of values that the standard slider. It was inspired
/// by the color editing controls in the Photos app, with more of a classic analog gauge style.
///
public final class NumericGauge: UIView {
    
    /// The minimum value of the gauge.
    public let minValue: Double
    
    /// The maximum value of the gauge.
    public let maxValue: Double
    
    /// The color theme of the bar.
    public let theme: NumericGaugeTheme
    
    /// Number formatter for live value preview.
    public let formatter: NumberFormatter
    
    /// The size of the guage bar.
    public let layout: NumericGaugeLayout
    
    /// The current value of the gauge.
    public var value: Double {
        valueSubject.value
    }
    
    /// A publisher which emits the changing gauge values.
    public var valuePublisher: AnyPublisher<Double, Never> {
        valueSubject.eraseToAnyPublisher()
    }
    
    private lazy var valueSubject: CurrentValueSubject<Double, Never> = {
        CurrentValueSubject(minValue)
    }()
    
    private lazy var gaugeBar: UIImage = {
        createGaugeBar()
    }()
    
    private let scrollView: UIScrollView
    
    /// Create a new instance of NumericGauge.
    public init(minValue: Double, maxValue: Double, layout: NumericGaugeLayout = NumericGaugeLayout(), theme: NumericGaugeTheme = .default, formatter: NumberFormatter? = nil) {
        self.minValue = minValue
        self.maxValue = maxValue
        self.theme = theme
        self.layout = layout
        if let formatter {
            self.formatter = formatter
        } else {
            let nf = NumberFormatter()
            nf.numberStyle = .decimal
            nf.usesGroupingSeparator = false
            let range = log10(maxValue - minValue)
            if range < 1 {
                nf.maximumFractionDigits = 3
                nf.minimumFractionDigits = 3
            } else if range < 2 {
                nf.maximumFractionDigits = 2
                nf.minimumFractionDigits = 2
            } else if range < 3 {
                nf.maximumFractionDigits = 1
                nf.minimumFractionDigits = 1
            } else {
                nf.maximumFractionDigits = 0
            }
            self.formatter = nf
        }
        
        scrollView = UIScrollView(frame: .zero)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.maximumZoomScale = 1.0
        scrollView.minimumZoomScale = 1.0
        scrollView.decelerationRate = .fast
        
        super.init(frame: .zero)
        
        scrollView.delegate = self
        self.backgroundColor = theme.background
    }
    
    public override func layoutSubviews() {
        addSubview(scrollView)
        
        let w = floor(self.bounds.width * 0.5)
        
        let imageView = UIImageView(image: gaugeBar)
        scrollView.addSubview(imageView)
        scrollView.contentInset = UIEdgeInsets(top: 0, left: w, bottom: 0, right: w)
        scrollView.contentOffset = CGPoint(x: -w, y: 0.0)
        
        let indicatorView = UIView(frame: .zero)
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.backgroundColor = theme.indicator
        addSubview(indicatorView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            
            indicatorView.topAnchor.constraint(equalTo: topAnchor),
            indicatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            indicatorView.widthAnchor.constraint(equalToConstant: 1),
            indicatorView.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }
    
    /// Create the gauge bar image.
    private func createGaugeBar() -> UIImage {
        let w = layout.barWidth
        let h = frame.height
        let bounds = CGRect(origin: .zero, size: CGSize(width: w + 1, height: h))
        let tickWidth: CGFloat = 1
        let majorHeight: CGFloat = round(h * layout.majorTickHeightRatio)
        let minorHeight: CGFloat = round(h * layout.minorTickHeightRatio)
        let majorSpacing = w / CGFloat(layout.majorTickCount)
        let minorSpacing = w / CGFloat(layout.minorTickCount)
        
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { [theme, layout] rendererContext in
            let ctx = rendererContext.cgContext
            ctx.setFillColor(theme.background.cgColor)
            ctx.fill([bounds])
            let minorRects = (0..<layout.minorTickCount).map { index in
                let x = Double(index) * minorSpacing
                let y = h - minorHeight
                return CGRect(x: x, y: y, width: tickWidth, height: minorHeight)
            }
            ctx.setFillColor(theme.minorTick.cgColor)
            ctx.fill(minorRects)
            let majorRects = (0...layout.majorTickCount).map { index in
                let x = Double(index) * majorSpacing
                let y = h - majorHeight
                return CGRect(x: x, y: y, width: tickWidth, height: majorHeight)
            }
            ctx.setFillColor(theme.majorTick.cgColor)
            ctx.fill(majorRects)
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UIScrollViewDelegate

extension NumericGauge: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let x = scrollView.contentOffset.x + scrollView.contentInset.left
        let pct = max(0.0, min(1.0, x / 1000))
        valueSubject.send(pct * (maxValue - minValue) + minValue)
    }
}
