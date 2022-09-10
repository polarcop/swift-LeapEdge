//
//  Payload.swift
//  
//
//  Created by Rishi Serumadar on 09/09/2022.
//

import Foundation

extension LeapEdge {
    public struct EncapsulatingPayload<T: Codable>: Codable {
        let op: OpCode
        let d: T
    }
    
    public struct EncapsulatingServicePayload: Codable {
        let c: String?
        let u: Bool?
        let e: String
        let d: AnyCodable?
    }
    
    public struct ServiceEvent: Codable {
        let channelId: String?
        let eventType: String
        let data: AnyCodable?
    }
}
