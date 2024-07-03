import CoreGraphics

/// Controls the layout characteristics of the numeric gauge.
public struct NumericGaugeLayout {
    
    /// The bar width of the gauge.
    ///
    /// The height will always match the view's bounds. It is a good idea to make sure that the width
    /// is a common multiple of the major and minor tick counts so that they are able to arrange with even spacing.
    ///
    /// The default value is `1000`.
    ///
    public let barWidth: CGFloat
    
    /// The number of major ticks to place along the width of the bar.
    ///
    /// The default value is `10`.
    ///
    public let majorTickCount: Int
    
    /// The number of minor ticks to place along the width of the bar.
    ///
    /// The default value is `100`.
    ///
    public let minorTickCount: Int
    
    /// The ratio of the view hieght to the major tick height.
    ///
    /// The default value is `2/3`.
    ///
    public let majorTickHeightRatio: CGFloat
    
    /// The ratio of the view height to the minor tick height.
    ///
    /// The default value is `1/3`.
    ///
    public let minorTickHeightRatio: CGFloat
    
    /// Create a new instance of NumericGaugeLayout.
    public init(barWidth: CGFloat = 1000, majorTickCount: Int = 10, minorTickCount: Int = 100, majorTickHeightRatio: CGFloat = (2.0/3.0), minorTickHeightRatio: CGFloat = (1.0/3.0)) {
        self.barWidth = barWidth
        self.majorTickCount = majorTickCount
        self.minorTickCount = minorTickCount
        self.majorTickHeightRatio = majorTickHeightRatio
        self.minorTickHeightRatio = minorTickHeightRatio
    }
}
