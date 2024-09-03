import UIKit
import Combine
import TransientLabel

/// A control that functions similarly to a Slider, but uses a fixed reference point with a sliding gauge under it.
///
/// The NumericGauge control allows much more precise selection of values that the standard slider. It was inspired
/// by the color editing controls in the Photos app, with more of a classic analog gauge style.
///
public final class NumericGauge: UIControl {
    
    /// Controls whether or not a value preview is displayed as part of the numeric gauge.
    public enum ValuePreviewMode {
        /// No preview is displayed.
        case disabled
        
        /// A default number formatter will be used.
        ///
        /// This formatter will have a precision based on the numeric range encompassed by the gauge as well
        /// as a preview label using the standard (theme-aware) design.
        ///
        case `default`
        
        /// Provide a custom formatter and transient label to completely control visual design.
        case custom(formatter: NumberFormatter, label: TransientLabel)
    }
    
    /// The current value of the gauge.
    public var value: Double {
        didSet {
            sendActions(for: .valueChanged)
            valueSubject.send(value)
            updateBarIfNecessary()
            
            guard let previewLabel, let previewValue = formatter.string(from: NSNumber(value: value)) else { return }
            previewLabel.display(previewValue)
        }
    }
    
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
    
    /// Publishes the value of the NumericGauge.
    ///
    /// An alternative to target-action for those that prefer to use Combine.
    /// 
    public var valuePublisher: AnyPublisher<Double, Never> {
        valueSubject.eraseToAnyPublisher()
    }
    
    private let valueSubject = CurrentValueSubject<Double, Never>(0.0)
        
    private lazy var gaugeBar: UIImage = {
        createGaugeBar()
    }()
    
    private let scrollView: UIScrollView
    private let indicatorView: UIView
    private var imageView: UIImageView = UIImageView(frame: .zero)
    
    private var updatedByScrollView: Bool = false
    
    private var previewLabel: TransientLabel?
    
    /// Create a new instance of NumericGauge.
    public init(minValue: Double, maxValue: Double, layout: NumericGaugeLayout = NumericGaugeLayout(), theme: NumericGaugeTheme = .default, valuePreviewMode: ValuePreviewMode = .default) {
        self.value = minValue
        self.minValue = minValue
        self.maxValue = maxValue
        self.theme = theme
        self.layout = layout
        self.valueSubject.value = minValue
        
        switch valuePreviewMode {
        case .disabled:
            formatter = NumberFormatter()
        case .default:
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
            self.previewLabel = TransientLabel(font: theme.labelFont, textColor: theme.labelTextColor, background: .solidColor(theme.labelBackgroundColor))
        case let .custom(formatter, label):
            self.formatter = formatter
            self.previewLabel = label
        }
                
        scrollView = UIScrollView(frame: .zero)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.maximumZoomScale = 1.0
        scrollView.minimumZoomScale = 1.0
        scrollView.decelerationRate = .fast
        
        indicatorView = UIView(frame: .zero)
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        
        super.init(frame: .zero)
        
        addSubview(scrollView)
        scrollView.addSubview(imageView)
        addSubview(indicatorView)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        if let previewLabel {
            previewLabel.translatesAutoresizingMaskIntoConstraints = false
            addSubview(previewLabel)
        }
        
        setupConstraints()
        
        indicatorView.backgroundColor = theme.indicator
        backgroundColor = theme.background
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        guard imageView.image == nil else { return }
        
        imageView.image = createGaugeBar()
        imageView.sizeToFit()
        
        let w = floor(self.bounds.width * 0.5)
        
        scrollView.contentInset = UIEdgeInsets(top: 0, left: w, bottom: 0, right: w)
        let pct = (value - minValue) / (maxValue - minValue)
        let x = pct * layout.barWidth
        
        // We need the scrollview to layout before
        scrollView.layoutIfNeeded()
        
        scrollView.contentOffset = CGPoint(x: -w + x, y: 0.0)
        
        scrollView.delegate = self
    }
    
    private func setupConstraints() {
        
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
        
        if let previewLabel {
            NSLayoutConstraint.activate([
                previewLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
                previewLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
            
        }
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
    
    private func updateBarIfNecessary() {
        guard !updatedByScrollView else {
            updatedByScrollView = false
            return
        }
        let pct = (value - minValue) / (maxValue - minValue)
        let x = pct * layout.barWidth + scrollView.contentInset.left
        scrollView.contentOffset = CGPoint(x: x, y: 0)
    }
}

// MARK: - UIScrollViewDelegate

extension NumericGauge: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.updatedByScrollView = true
        let x = scrollView.contentOffset.x + scrollView.contentInset.left
        let pct = max(0.0, min(1.0, x / layout.barWidth))
        value = pct * (maxValue - minValue) + minValue
    }
}
