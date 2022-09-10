import XCTest
@testable import LeapEdge

final class LeapEdgeTests: XCTestCase {
    func testConnection() throws {
        var options: Partial<LeapEdge.InitOptions> = .init()
//        options[\.debug] = true
        let leap = LeapEdge(auth: .init(token: nil, projectId: "test"), opts: options)
        leap.connect()
        let expectation = expectation(description: "Will connect and receive a message")
        
        leap.emitter.when { (message: LeapEdge.ConnectionState) in
            print("Connection state:", message)
        }
        
        leap.emitter.when { (message: LeapEdge.ServiceEvent) in
            print("payload", message)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
}
