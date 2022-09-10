//
//  Opcodes.swift
//  
//
//  Created by Rishi Serumadar on 09/09/2022.
//

import Foundation

extension LeapEdge {
    public enum OpCode: Int, Codable {
        case dispatch = 0
        case hello = 1
        case identify = 2
        case heartbeat = 3
        case heartbeatAck = 4
    }
}

extension LeapEdge.OpCode {
    public struct DispatchControl: Codable {
        let c: String?
        
    }
    
    public struct HelloControl: Codable {
        public let heartbeatInterval: Int
        
        enum CodingKeys: String, CodingKey {
            case heartbeatInterval = "heartbeat_interval"
        }
    }
    
    public struct IdentifyControl: Codable {
        public let projectId: String
        public let token: String?
        
        enum CodingKeys: String, CodingKey {
            case projectId = "project_id"
            case token
        }
    }
    
    public struct HeartbeatControl: Codable {
        public var tag: String? = nil
    }
    
    public struct HeartbeatAckControl: Codable {
        public let tag: String?
        public let latency: Int?
    }
}
