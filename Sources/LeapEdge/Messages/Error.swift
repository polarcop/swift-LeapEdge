//
//  Error.swift
//  
//
//  Created by Rishi Serumadar on 09/09/2022.
//

import Foundation

extension LeapEdge {
    public enum LeapError: Int, CaseIterable {
        case unknown = 4000
        case invalidAuth = 4001
        case identifyTimeout = 4002
        case notAuthenticated = 4003
        case unknownOpcode = 4004
        case invalidPayload = 4005
        case badRoute = 4006
        case outOfSync = 4007
        
        var description: String {
            switch(self) {
            case .unknown:
                return "Unknown error"
            case .invalidAuth:
                return "Invalid auth"
            case .identifyTimeout:
                return "Identify timeout"
            case .notAuthenticated:
                return "Not authenticated"
            case .unknownOpcode:
                return "Invalid opcode"
            case .invalidPayload:
                return "Invalid payload (doesn't match expected data field)"
            case .badRoute:
                return "Bad route"
            case .outOfSync:
                return "Out of sync"
            }
        }
        
        var canReconnect: Bool {
            switch(self) {
            case .invalidAuth:
                return false
            default:
                return true
            }
        }
    }
}
