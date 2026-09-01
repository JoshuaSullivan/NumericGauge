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

    /// The step size used when VoiceOver users swipe up or down to adjust the value.
    ///
    /// When `nil`, defaults to one major tick division: `(maxValue - minValue) / majorTickCount`.
    ///
    public var accessibilityStep: Double?
    
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

    /// The navigation controller whose pop gestures this gauge switched off,
    /// held only for the length of a touch so they can be switched back on.
    private weak var suppressedNavigationController: UINavigationController?

    /// The width the scroll geometry was last configured for. See
    /// ``layoutSubviews()``.
    private var laidOutWidth: CGFloat = 0

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

        if imageView.image == nil {
            imageView.image = createGaugeBar()
            imageView.sizeToFit()
        }

        // Keyed on the width, not on "have we ever laid out". The inset is half
        // the view's width — it is what centres the indicator — so a gauge that
        // is resized after its first layout keeps an inset for the old width,
        // and every offset it derives from that is wrong. That went unnoticed
        // while the only host gave it a fixed 220pt.
        guard bounds.width > 0, bounds.width != laidOutWidth else { return }
        laidOutWidth = bounds.width

        let w = floor(bounds.width * 0.5)

        // Silence the delegate across the re-seat: assigning contentOffset
        // feeds scrollViewDidScroll, which would write the derived value back
        // onto `value` and drift it a little on every resize.
        scrollView.delegate = nil
        scrollView.contentInset = UIEdgeInsets(top: 0, left: w, bottom: 0, right: w)

        // We need the scrollview to layout before
        scrollView.layoutIfNeeded()

        let pct = (value - minValue) / (maxValue - minValue)
        scrollView.contentOffset = CGPoint(x: -w + pct * layout.barWidth, y: 0.0)

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
        let x = pct * layout.barWidth - scrollView.contentInset.left
        scrollView.contentOffset = CGPoint(x: x, y: 0)
    }

    // MARK: - Coexisting with navigation back gestures

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            // Never leave the app's back gesture switched off behind us.
            setNavigationPopGesturesEnabled(true)
        } else if touchSentinel.view == nil {
            addGestureRecognizer(touchSentinel)
        }
    }

    /// A zero-duration press used purely to know when a finger is on the gauge.
    ///
    /// It recognises alongside the scroll view's own pan and swallows nothing,
    /// so scrubbing is unaffected; its only job is to bracket the touch.
    private lazy var touchSentinel: UILongPressGestureRecognizer = {
        let recognizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleTouchSentinel)
        )
        recognizer.minimumPressDuration = 0
        recognizer.cancelsTouchesInView = false
        recognizer.delaysTouchesBegan = false
        recognizer.delaysTouchesEnded = false
        recognizer.delegate = self
        return recognizer
    }()

    @objc private func handleTouchSentinel(_ recognizer: UILongPressGestureRecognizer) {
        switch recognizer.state {
        case .began:
            setNavigationPopGesturesEnabled(false)
        case .ended, .cancelled, .failed:
            setNavigationPopGesturesEnabled(true)
        default:
            break
        }
    }

    /// Switches the enclosing navigation controller's interactive-pop gestures
    /// off for the duration of a touch on the gauge, and back on after.
    ///
    /// A gauge is scrubbed by dragging horizontally, and from iOS 26 so is
    /// going back: `interactiveContentPopGestureRecognizer` pops on a
    /// leading-to-trailing pan anywhere in the navigation controller's content.
    ///
    /// Disabling rather than a failure requirement, which was tried first and
    /// is worse than useless here: `require(toFail:)` makes the pop wait for
    /// the scroll view's pan to fail, but by then the pop has already engaged
    /// and taken the touch — so a rightward drag would neither scrub nor
    /// navigate. Turning the recognisers off for the length of the touch means
    /// the scroll view is the only thing competing for it.
    ///
    /// Scoped to the touch, so back navigation works normally everywhere else
    /// on the screen and the moment the finger lifts.
    /// Test seam for ``setNavigationPopGesturesEnabled(_:)``, which is driven by
    /// a real touch and so cannot be reached from a unit test.
    func setNavigationPopGesturesEnabledForTesting(_ isEnabled: Bool) {
        setNavigationPopGesturesEnabled(isEnabled)
    }

    private func setNavigationPopGesturesEnabled(_ isEnabled: Bool) {
        // Re-enabling targets whatever was disabled, not whatever is reachable
        // now. By the time a gauge leaves its window it is already detached, so
        // the responder chain no longer finds the navigation controller — and
        // re-enabling by lookup would silently do nothing, leaving the app
        // unable to navigate back for the rest of its life.
        let navigationController = isEnabled
            ? suppressedNavigationController
            : enclosingNavigationController
        guard let navigationController else { return }

        navigationController.interactivePopGestureRecognizer?.isEnabled = isEnabled
        if #available(iOS 26.0, visionOS 26.0, *) {
            navigationController.interactiveContentPopGestureRecognizer?.isEnabled = isEnabled
        }

        suppressedNavigationController = isEnabled ? nil : navigationController
    }

    /// The navigation controller this gauge is presented inside, if any.
    ///
    /// Found through the responder chain, which reaches a SwiftUI hosting
    /// controller exactly as it reaches a UIKit one — so a gauge inside a
    /// `NavigationStack` resolves the same `UINavigationController` that
    /// installed the pop gestures. `nil` where there is no navigation to fight
    /// with, which is the common case on a canvas.
    var enclosingNavigationController: UINavigationController? {
        var responder: UIResponder? = next
        while let current = responder {
            if let navigationController = current as? UINavigationController {
                return navigationController
            }
            if let viewController = current as? UIViewController,
               let navigationController = viewController.navigationController {
                return navigationController
            }
            responder = current.next
        }
        return nil
    }
}

// MARK: - Accessibility

extension NumericGauge {

    public override var isAccessibilityElement: Bool {
        get { true }
        set { }
    }

    public override var accessibilityTraits: UIAccessibilityTraits {
        get { .adjustable }
        set { }
    }

    public override var accessibilityValue: String? {
        get { formatter.string(from: NSNumber(value: value)) }
        set { }
    }

    public override var accessibilityHint: String? {
        get { "Swipe up or down to adjust" }
        set { }
    }

    /// The effective step size for accessibility adjustments.
    private var effectiveAccessibilityStep: Double {
        accessibilityStep ?? (maxValue - minValue) / Double(layout.majorTickCount)
    }

    public override func accessibilityIncrement() {
        value = min(value + effectiveAccessibilityStep, maxValue)
    }

    public override func accessibilityDecrement() {
        value = max(value - effectiveAccessibilityStep, minValue)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension NumericGauge: UIGestureRecognizerDelegate {

    /// The sentinel observes; it never competes.
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
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
