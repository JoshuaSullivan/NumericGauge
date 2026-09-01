import Testing
import UIKit
@testable import NumericGauge

/// A gauge is scrubbed by dragging horizontally, and from iOS 26 so is going
/// back — `interactiveContentPopGestureRecognizer` pops on a leading-to-trailing
/// pan anywhere in the navigation controller's content. The gauge has to claim
/// that gesture for itself, and it can only do that if it can find the
/// navigation controller it lives inside.
@Suite("Navigation Gesture Coexistence")
@MainActor
struct NavigationGestureCoexistenceTests {

    private func makeGauge() -> NumericGauge {
        NumericGauge(minValue: 0, maxValue: 1, valuePreviewMode: .disabled)
    }

    @Test("A gauge with no navigation around it finds none")
    func standaloneGaugeFindsNoNavigationController() {
        let gauge = makeGauge()
        #expect(gauge.enclosingNavigationController == nil)

        let container = UIView()
        container.addSubview(gauge)
        #expect(gauge.enclosingNavigationController == nil)
    }

    @Test("A gauge inside a pushed view controller finds the navigation controller")
    func gaugeInsideNavigationFindsIt() {
        let gauge = makeGauge()
        let content = UIViewController()
        content.view.addSubview(gauge)
        let navigationController = UINavigationController(rootViewController: content)

        #expect(gauge.enclosingNavigationController === navigationController)
    }

    @Test("A gauge nested several views deep still finds it")
    func nestedGaugeFindsIt() {
        let gauge = makeGauge()
        let inner = UIView()
        let outer = UIView()
        inner.addSubview(gauge)
        outer.addSubview(inner)
        let content = UIViewController()
        content.view.addSubview(outer)
        let navigationController = UINavigationController(rootViewController: content)

        #expect(gauge.enclosingNavigationController === navigationController)
    }

    @Test("A touch on a gauge inside navigation switches the pop gestures off, and lifting switches them back on")
    func touchingTheGaugeBracketsThePopGestures() {
        let gauge = makeGauge()
        let content = UIViewController()
        content.view.addSubview(gauge)
        let navigationController = UINavigationController(rootViewController: content)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        window.layoutIfNeeded()

        let popGesture = navigationController.interactivePopGestureRecognizer
        #expect(popGesture?.isEnabled == true)

        gauge.setNavigationPopGesturesEnabledForTesting(false)
        #expect(popGesture?.isEnabled == false)

        gauge.setNavigationPopGesturesEnabledForTesting(true)
        #expect(popGesture?.isEnabled == true)
    }

    @Test("Leaving the window restores the pop gestures")
    func leavingTheWindowRestoresThePopGestures() {
        let gauge = makeGauge()
        let content = UIViewController()
        content.view.addSubview(gauge)
        let navigationController = UINavigationController(rootViewController: content)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        window.layoutIfNeeded()

        // A touch that never ends — the row scrolls away mid-scrub — must not
        // leave the app unable to navigate back.
        gauge.setNavigationPopGesturesEnabledForTesting(false)
        #expect(navigationController.interactivePopGestureRecognizer?.isEnabled == false)

        gauge.removeFromSuperview()

        #expect(navigationController.interactivePopGestureRecognizer?.isEnabled == true)
    }
}
