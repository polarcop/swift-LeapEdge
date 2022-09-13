import XCTest
@testable import LeapEdge

final class LeapEdgeTests: XCTestCase {
    func testConnection() throws {
        let leap = LeapEdge(auth: .init(token: nil, projectId: "test"), opts: .init(debug: false))
        leap.connect()
        let expectation = expectation(description: "Will connect and receive a message")
        
        leap.on { (message: LeapEdge.ConnectionState) in
            print("Connection state:", message)
        }
        
        leap.on { (message: LeapEdge.ServiceEvent) in
            print("payload", message)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
}
