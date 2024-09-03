import UIKit

/// A color theme for the NumericGauge.
public struct NumericGaugeTheme {
    
    /// The background color of the gauge.
    public let background: UIColor
    
    /// The color of the 10 major tick marks.
    public let majorTick: UIColor
    
    /// The color of the 100 minor tick marks.
    public let minorTick: UIColor
    
    /// The color of the fixed indicator.
    public let indicator: UIColor
    
    /// The font the label uses, if active.
    public let labelFont: UIFont
    
    /// The text color of the label, if active.
    ///
    /// Default value is `UIColor.label`.
    ///
    public let labelTextColor: UIColor
    
    /// The background color of the label, if active.
    ///
    /// Default value is `UIColor.systemBackground.withAlphaComponent(0.4)`.
    ///
    public let labelBackgroundColor: UIColor
    
    /// Create a new instance of Theme.
    public init(background: UIColor, majorTick: UIColor, minorTick: UIColor, indicator: UIColor, labelFont: UIFont, labelTextColor: UIColor, labelBackgroundColor: UIColor) {
        self.background = background
        self.majorTick = majorTick
        self.minorTick = minorTick
        self.indicator = indicator
        self.labelFont = labelFont
        self.labelTextColor = labelTextColor
        self.labelBackgroundColor = labelBackgroundColor
    }
}

// MARK: - Default

public extension NumericGaugeTheme {
    /// The default color theme for the NumericGauge.
    ///
    /// Works with both light and dark system themes.
    ///
    static let `default`: NumericGaugeTheme = {
        guard
            let bg = UIColor(named: "BarBackground"),
            let major = UIColor(named: "MajorTick"),
            let minor = UIColor(named: "MinorTick"),
            let ind = UIColor(named: "Indicator")
        else {
            return NumericGaugeTheme(background: .darkGray, majorTick: .white, minorTick: .lightGray, indicator: .yellow, labelFont: .preferredFont(forTextStyle: .subheadline), labelTextColor: .label, labelBackgroundColor: .systemBackground.withAlphaComponent(0.4))
        }
        return NumericGaugeTheme(background: bg, majorTick: major, minorTick: minor, indicator: ind, labelFont: .preferredFont(forTextStyle: .subheadline), labelTextColor: .label, labelBackgroundColor: .systemBackground.withAlphaComponent(0.4))
    }()
}
