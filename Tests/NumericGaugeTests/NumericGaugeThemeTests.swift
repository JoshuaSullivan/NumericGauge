import Testing
import UIKit
@testable import NumericGauge

@Suite("NumericGaugeTheme Tests")
struct NumericGaugeThemeTests {

    @Test("Custom theme initialization")
    func testCustomThemeInitialization() {
        let background = UIColor.red
        let majorTick = UIColor.blue
        let minorTick = UIColor.green
        let indicator = UIColor.yellow
        let labelFont = UIFont.systemFont(ofSize: 12)
        let labelTextColor = UIColor.white
        let labelBackgroundColor = UIColor.black

        let theme = NumericGaugeTheme(
            background: background,
            majorTick: majorTick,
            minorTick: minorTick,
            indicator: indicator,
            labelFont: labelFont,
            labelTextColor: labelTextColor,
            labelBackgroundColor: labelBackgroundColor
        )

        #expect(theme.background == background)
        #expect(theme.majorTick == majorTick)
        #expect(theme.minorTick == minorTick)
        #expect(theme.indicator == indicator)
        #expect(theme.labelFont == labelFont)
        #expect(theme.labelTextColor == labelTextColor)
        #expect(theme.labelBackgroundColor == labelBackgroundColor)
    }

    @Test("Default theme exists")
    func testDefaultThemeExists() {
        let theme = NumericGaugeTheme.default

        #expect(theme.background != nil)
        #expect(theme.majorTick != nil)
        #expect(theme.minorTick != nil)
        #expect(theme.indicator != nil)
        #expect(theme.labelFont != nil)
        #expect(theme.labelTextColor != nil)
        #expect(theme.labelBackgroundColor != nil)
    }

    @Test("Default theme has valid colors")
    func testDefaultThemeHasValidColors() {
        let theme = NumericGaugeTheme.default

        // Verify colors are not nil and have valid alpha components
        var alpha: CGFloat = 0
        theme.background.getRed(nil, green: nil, blue: nil, alpha: &alpha)
        #expect(alpha > 0)

        theme.majorTick.getRed(nil, green: nil, blue: nil, alpha: &alpha)
        #expect(alpha > 0)

        theme.minorTick.getRed(nil, green: nil, blue: nil, alpha: &alpha)
        #expect(alpha > 0)

        theme.indicator.getRed(nil, green: nil, blue: nil, alpha: &alpha)
        #expect(alpha > 0)
    }

    @Test("Default theme uses preferred font")
    func testDefaultThemeUsesPreferredFont() {
        let theme = NumericGaugeTheme.default

        #expect(theme.labelFont.pointSize > 0)
    }
}
