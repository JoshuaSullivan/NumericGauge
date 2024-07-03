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
    
    /// Create a new instance of Theme.
    init(background: UIColor, majorTick: UIColor, minorTick: UIColor, indicator: UIColor) {
        self.background = background
        self.majorTick = majorTick
        self.minorTick = minorTick
        self.indicator = indicator
    }
}

// MARK: - Default

public extension NumericGaugeTheme {
    /// The default color theme for the NumericGauge.
    ///
    /// Works with both light and dark system themes.
    ///
    public static let `default`: NumericGaugeTheme = {
        guard
            let bg = UIColor(named: "BarBackground"),
            let major = UIColor(named: "MajorTick"),
            let minor = UIColor(named: "MinorTick"),
            let ind = UIColor(named: "Indicator")
        else {
            return NumericGaugeTheme(background: .darkGray, majorTick: .white, minorTick: .lightGray, indicator: .yellow)
        }
        return NumericGaugeTheme(background: bg, majorTick: major, minorTick: minor, indicator: ind)
    }()
}
