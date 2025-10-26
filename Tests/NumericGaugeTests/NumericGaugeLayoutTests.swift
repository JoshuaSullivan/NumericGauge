import Testing
import CoreGraphics
@testable import NumericGauge

@Suite("NumericGaugeLayout Tests")
struct NumericGaugeLayoutTests {

    @Test("Default initialization")
    func testDefaultInitialization() {
        let layout = NumericGaugeLayout()

        #expect(layout.barWidth == 1000)
        #expect(layout.majorTickCount == 10)
        #expect(layout.minorTickCount == 100)
        #expect(layout.majorTickHeightRatio == (2.0/3.0))
        #expect(layout.minorTickHeightRatio == (1.0/3.0))
    }

    @Test("Custom initialization")
    func testCustomInitialization() {
        let layout = NumericGaugeLayout(
            barWidth: 2000,
            majorTickCount: 20,
            minorTickCount: 200,
            majorTickHeightRatio: 0.75,
            minorTickHeightRatio: 0.25
        )

        #expect(layout.barWidth == 2000)
        #expect(layout.majorTickCount == 20)
        #expect(layout.minorTickCount == 200)
        #expect(layout.majorTickHeightRatio == 0.75)
        #expect(layout.minorTickHeightRatio == 0.25)
    }

    @Test("Partial custom initialization uses defaults")
    func testPartialCustomInitialization() {
        let layout = NumericGaugeLayout(barWidth: 1500)

        #expect(layout.barWidth == 1500)
        #expect(layout.majorTickCount == 10)
        #expect(layout.minorTickCount == 100)
        #expect(layout.majorTickHeightRatio == (2.0/3.0))
        #expect(layout.minorTickHeightRatio == (1.0/3.0))
    }

    @Test("Height ratios are valid", arguments: [
        (major: 0.5, minor: 0.25),
        (major: 0.75, minor: 0.5),
        (major: 1.0, minor: 1.0),
        (major: 2.0/3.0, minor: 1.0/3.0)
    ])
    func testHeightRatiosAreValid(ratios: (major: CGFloat, minor: CGFloat)) {
        let layout = NumericGaugeLayout(
            majorTickHeightRatio: ratios.major,
            minorTickHeightRatio: ratios.minor
        )

        #expect(layout.majorTickHeightRatio >= 0)
        #expect(layout.minorTickHeightRatio >= 0)
    }
}
