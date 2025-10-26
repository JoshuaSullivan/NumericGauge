import Testing
import UIKit
import Combine
import TransientLabel
@testable import NumericGauge

@Suite("NumericGauge Tests")
@MainActor
struct NumericGaugeTests {

    @Test("Initialization with default values")
    func testInitializationWithDefaults() {
        let gauge = NumericGauge(minValue: 0, maxValue: 100, valuePreviewMode: .disabled)

        #expect(gauge.value == 0)
        #expect(gauge.minValue == 0)
        #expect(gauge.maxValue == 100)
    }

    @Test("Initialization with custom range")
    func testInitializationWithCustomRange() {
        let gauge = NumericGauge(minValue: -50, maxValue: 50, valuePreviewMode: .disabled)

        #expect(gauge.value == -50)
        #expect(gauge.minValue == -50)
        #expect(gauge.maxValue == 50)
    }

    @Test("Initialization with custom layout")
    func testInitializationWithCustomLayout() {
        let customLayout = NumericGaugeLayout(
            barWidth: 2000,
            majorTickCount: 20,
            minorTickCount: 200
        )
        let gauge = NumericGauge(
            minValue: 0,
            maxValue: 100,
            layout: customLayout,
            valuePreviewMode: .disabled
        )

        #expect(gauge.layout.barWidth == 2000)
        #expect(gauge.layout.majorTickCount == 20)
        #expect(gauge.layout.minorTickCount == 200)
    }

    @Test("Initialization with custom theme")
    func testInitializationWithCustomTheme() {
        let customTheme = NumericGaugeTheme(
            background: .red,
            majorTick: .blue,
            minorTick: .green,
            indicator: .yellow,
            labelFont: .systemFont(ofSize: 14),
            labelTextColor: .white,
            labelBackgroundColor: .black
        )
        let gauge = NumericGauge(
            minValue: 0,
            maxValue: 100,
            theme: customTheme,
            valuePreviewMode: .disabled
        )

        #expect(gauge.theme.background == .red)
        #expect(gauge.theme.majorTick == .blue)
        #expect(gauge.theme.minorTick == .green)
        #expect(gauge.theme.indicator == .yellow)
    }

    @Test("Value changes trigger value publisher")
    func testValuePublisher() async {
        let gauge = NumericGauge(minValue: 0, maxValue: 100, valuePreviewMode: .disabled)
        var receivedValue: Double?

        let cancellable = gauge.valuePublisher
            .dropFirst() // Skip initial value
            .sink { value in
                receivedValue = value
            }

        gauge.value = 42

        // Give async operations time to complete
        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(receivedValue == 42)

        cancellable.cancel()
    }

    @Test("Value stays within bounds", arguments: [
        (value: 0.0, expected: 0.0),
        (value: 50.0, expected: 50.0),
        (value: 100.0, expected: 100.0)
    ])
    func testValueWithinBounds(testCase: (value: Double, expected: Double)) {
        let gauge = NumericGauge(minValue: 0, maxValue: 100, valuePreviewMode: .disabled)
        gauge.value = testCase.value

        #expect(gauge.value == testCase.expected)
    }

    @Test("Number formatter configuration for different ranges", arguments: [
        (min: 0.0, max: 1.0, expectedMaxFraction: 3),
        (min: 0.0, max: 50.0, expectedMaxFraction: 2),
        (min: 0.0, max: 500.0, expectedMaxFraction: 1),
        (min: 0.0, max: 5000.0, expectedMaxFraction: 0)
    ])
    func testNumberFormatterConfiguration(testCase: (min: Double, max: Double, expectedMaxFraction: Int)) {
        let gauge = NumericGauge(
            minValue: testCase.min,
            maxValue: testCase.max,
            valuePreviewMode: .default
        )

        #expect(gauge.formatter.maximumFractionDigits == testCase.expectedMaxFraction)
    }

    @Test("Disabled preview mode")
    func testDisabledPreviewMode() {
        let gauge = NumericGauge(
            minValue: 0,
            maxValue: 100,
            valuePreviewMode: .disabled
        )

        #expect(gauge.formatter != nil)
    }

    @Test("Custom preview mode")
    func testCustomPreviewMode() {
        let customFormatter = NumberFormatter()
        customFormatter.numberStyle = .currency
        let customLabel = TransientLabel(
            font: .systemFont(ofSize: 20),
            textColor: .red,
            background: .solidColor(.blue)
        )

        let gauge = NumericGauge(
            minValue: 0,
            maxValue: 100,
            valuePreviewMode: .custom(formatter: customFormatter, label: customLabel)
        )

        #expect(gauge.formatter.numberStyle == .currency)
    }

    @Test("Gauge is a UIControl subclass")
    func testIsUIControl() {
        let gauge = NumericGauge(minValue: 0, maxValue: 100, valuePreviewMode: .disabled)

        #expect(gauge is UIControl)
    }

    @Test("Multiple value changes")
    func testMultipleValueChanges() async {
        let gauge = NumericGauge(minValue: 0, maxValue: 100, valuePreviewMode: .disabled)
        var allValues: [Double] = []

        let cancellable = gauge.valuePublisher
            .sink { value in
                allValues.append(value)
            }

        for i in 0...10 {
            gauge.value = Double(i * 10)
        }

        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(allValues.count >= 11)
        #expect(gauge.value == 100)

        cancellable.cancel()
    }

    @Test("Value changes are reflected in publisher")
    func testValueChangesReflectedInPublisher() async {
        let gauge = NumericGauge(minValue: 0, maxValue: 100, valuePreviewMode: .disabled)
        var lastPublishedValue: Double = 0

        let cancellable = gauge.valuePublisher
            .sink { value in
                lastPublishedValue = value
            }

        gauge.value = 42
        try? await Task.sleep(nanoseconds: 50_000_000)

        #expect(lastPublishedValue == 42)

        gauge.value = 73
        try? await Task.sleep(nanoseconds: 50_000_000)

        #expect(lastPublishedValue == 73)

        cancellable.cancel()
    }

    @Test("Fractional values are supported")
    func testFractionalValues() {
        let gauge = NumericGauge(minValue: 0, maxValue: 1, valuePreviewMode: .disabled)

        gauge.value = 0.5
        #expect(gauge.value == 0.5)

        gauge.value = 0.25
        #expect(gauge.value == 0.25)

        gauge.value = 0.75
        #expect(gauge.value == 0.75)
    }

    @Test("Negative ranges work correctly")
    func testNegativeRanges() {
        let gauge = NumericGauge(minValue: -100, maxValue: -50, valuePreviewMode: .disabled)

        #expect(gauge.value == -100)
        #expect(gauge.minValue == -100)
        #expect(gauge.maxValue == -50)

        gauge.value = -75
        #expect(gauge.value == -75)
    }
}
