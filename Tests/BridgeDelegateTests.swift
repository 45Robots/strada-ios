import Foundation
import XCTest
import WebKit
@testable import Strada

class BridgeDelegateTests: XCTestCase {
    private var delegate: BridgeDelegate!
    private var destination: BridgeDestinationSpy!
    private var bridge: BridgeSpy!
    private let json = """
        {"title":"Page-title","subtitle":"Page-subtitle"}
    """
    
    override func setUp() async throws {
        destination = BridgeDestinationSpy()
        delegate = BridgeDelegate(location: "https://37signals.com",
                                  destination: destination,
                                  componentTypes: [OneBridgeComponent.self, BridgeComponentSpy.self])
        
        bridge = BridgeSpy()
        delegate.bridge = bridge
        delegate.onViewDidLoad()
    }
    
    func testBridgeDidInitialize() {
        delegate.bridgeDidInitialize()
        
        XCTAssertTrue(bridge.registerComponentsWasCalled)
        XCTAssertEqual(bridge.registerComponentsArg, ["one", "two"])
     
        // Registered components are lazy initialized.
        let componentOne: BridgeComponentSpy? = delegate.component()
        let componentTwo: BridgeComponentSpy? = delegate.component()
        XCTAssertNil(componentOne)
        XCTAssertNil(componentTwo)
    }
    
    func testBridgeDidReceiveMessage() {
        let json = """
            {"title":"Page-title","subtitle":"Page-subtitle"}
        """
        let message = Message(id: "1",
                              component: "two",
                              event: "connect",
                              metadata: .init(url: "https://37signals.com"),
                              jsonData: json)
        
        var component: BridgeComponentSpy? = delegate.component()
        
        XCTAssertNil(component)
        XCTAssertTrue(delegate.bridgeDidReceiveMessage(message))
        
        component = delegate.component()
        
        XCTAssertNotNil(component)
        // Make sure the component has delegate set, and did receive the message.
        XCTAssertTrue(component!.handleMessageWasCalled)
        XCTAssertEqual(component?.handleMessageArg, message)
        XCTAssertNotNil(component?.delegate)
    }
    
    func testBridgeIgnoresMessageForUnknownComponent() {
        let json = """
            {"title":"Page-title","subtitle":"Page-subtitle"}
        """
        let message = Message(id: "1",
                              component: "page",
                              event: "connect",
                              metadata: .init(url: "https://37signals.com/another_url"),
                              jsonData: json)
        
        XCTAssertFalse(delegate.bridgeDidReceiveMessage(message))
    }
    
    func testBridgeIgnoresMessageForInactiveDestination() {
        let message = Message(id: "1",
                              component: "one",
                              event: "connect",
                              metadata: .init(url: "https://37signals.com"),
                              jsonData: json)
        
        XCTAssertTrue(delegate.bridgeDidReceiveMessage(message))
        
        var component: OneBridgeComponent? = delegate.component()
        XCTAssertNotNil(component)
        
        delegate.onViewWillDisappear()
        XCTAssertFalse(delegate.bridgeDidReceiveMessage(message))
        
        component = delegate.component()
        XCTAssertNil(component)
    }
    
    func testBridgeForwardsViewWillAppearToComponents() {
        delegate.bridgeDidReceiveMessage(testMessage())
        
        let component: BridgeComponentSpy? = delegate.component()
        XCTAssertNotNil(component)
        
        delegate.onViewWillAppear()
        XCTAssertTrue(component!.onViewWillAppearWasCalled)
    }
    
    func testBridgeForwardsViewDidAppearToComponents() {
        delegate.bridgeDidReceiveMessage(testMessage())
        
        let component: BridgeComponentSpy? = delegate.component()
        XCTAssertNotNil(component)

        delegate.onViewDidAppear()
        XCTAssertTrue(component!.onViewDidAppearWasCalled)
    }
    
    func testBridgeForwardsViewWillDisappearToComponents() {
        delegate.bridgeDidReceiveMessage(testMessage())
        
        let component: BridgeComponentSpy? = delegate.component()
        XCTAssertNotNil(component)
        
        delegate.onViewWillDisappear()
        XCTAssertTrue(component!.onViewWillDisappearWasCalled)
    }
    
    func testBridgeForwardsViewDidDisappearToComponents() {
        delegate.bridgeDidReceiveMessage(testMessage())
        
        let component: BridgeComponentSpy? = delegate.component()
        XCTAssertNotNil(component)
        
        delegate.onViewDidDisappear()
        XCTAssertTrue(component!.onViewDidDisappearWasCalled)
    }
    
    private func testMessage() -> Message {
        return Message(id: "1",
                       component: "two",
                       event: "connect",
                       metadata: .init(url: "https://37signals.com"),
                       jsonData: json)
    }
}

private class BridgeDestinationSpy: BridgeDestination {}

private class OneBridgeComponent: BridgeComponent {
    static var name: String = "one"
    weak var delegate: Strada.BridgeDelegate?
    
    required init(destination: Strada.BridgeDestination) {}
    
    func handle(message: Strada.Message) {}
}

private class BridgeComponentSpy: BridgeComponent {
    static var name: String = "two"
    weak var delegate: Strada.BridgeDelegate?
    
    var handleMessageWasCalled = false
    var handleMessageArg: Message?
    
    var onViewDidLoadWasCalled = false
    var onViewWillAppearWasCalled = false
    var onViewDidAppearWasCalled = false
    var onViewWillDisappearWasCalled = false
    var onViewDidDisappearWasCalled = false
    
    required init(destination: Strada.BridgeDestination) {}
    
    func handle(message: Strada.Message) {
        handleMessageWasCalled = true
        handleMessageArg = message
    }
    
    func onViewDidLoad() {
        onViewDidLoadWasCalled = true
    }
    
    func onViewWillAppear() {
        onViewWillAppearWasCalled = true
    }
    
    func onViewDidAppear() {
        onViewDidAppearWasCalled = true
    }
    
    func onViewWillDisappear() {
        onViewWillDisappearWasCalled = true
    }
    
    func onViewDidDisappear() {
        onViewDidDisappearWasCalled = true
    }
}

private class BridgeSpy: Bridgable {
    var delegate: Strada.BridgeDelegate? = nil
    var webView: WKWebView? = nil
    
    var registerComponentWasCalled = false
    var registerComponentArg: String? = nil
    
    var registerComponentsWasCalled = false
    var registerComponentsArg: [String]? = nil
    
    var unregisterComponentWasCalled = false
    var unregisterComponentArg: String? = nil
    
    var sendMessageWasCalled = false
    var sendMessageArg: Message? = nil
    
    func register(component: String) {
        registerComponentWasCalled = true
        registerComponentArg = component
    }
    
    func register(components: [String]) {
        registerComponentsWasCalled = true
        registerComponentsArg = components
    }
    
    func unregister(component: String) {
        unregisterComponentWasCalled = true
        unregisterComponentArg = component
    }
    
    func send(_ message: Strada.Message) {
        sendMessageWasCalled = true
        sendMessageArg = message
    }
}
