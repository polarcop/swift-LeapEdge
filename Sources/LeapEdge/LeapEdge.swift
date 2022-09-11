//
//  LeapEdge.swift
//
//
//  Created by Rishi Serumadar on 09/09/2022.
//

import Foundation
import Starscream

// This is ok to unwrap since we know it's valid
fileprivate let DEFAULT_ENDPOINT = URL(string: "wss://leap.hop.io/ws").unsafelyUnwrapped

final public class LeapEdge: WebSocketDelegate {
    private let auth: AuthenticationParameters
    private var socket: WebSocket?
    private var heartbeat: Timer?
    private var heartbeatInterval: Int?
    private var lastServerHeartbeatAck: Int?
    private var connectionState: ConnectionState
    private var options: InitOptions
    private let emitter: Emitter
    private let throttler: Throttler
    
    public init(
        auth: AuthenticationParameters,
        opts: Partial<InitOptions>? = nil
    ) {
        self.auth = auth
        self.socket = nil
        self.heartbeat = nil
        self.heartbeatInterval = nil
        self.lastServerHeartbeatAck = nil
        self.connectionState = .idle
        self.options = InitOptions(
            socketUrl: opts?[\.socketUrl] ?? DEFAULT_ENDPOINT,
            debug: opts?[\.debug] ?? false
        )
        self.emitter = Emitter()
        self.throttler = Throttler(minimumDelay: 1.0)
    }
    
    public func connect() {
        throttler.throttle {
            guard self.socket == nil else {
                if self.options.debug {
                    print("[Leap Edge] LeapEdgeClient#connect was called during active connection. This is a noop.")
                }
                return
            }
            self.updateConnectionState(.connecting)
            self.socket = WebSocket(request: URLRequest(url: self.options.socketUrl))
            self.socket?.delegate = self
            self.socket?.connect()
        }
    }
    
    public func sendServicePayload(payload: EncapsulatingServicePayload) {
        guard let socket = self.socket, self.connectionState == .connected else {
            if (self.options.debug) {
                print("[Leap Edge] Attempted to send payload when socket connection was not established or authorized")
            }
            return
        }
        guard let json = try? JSONEncoder().encode(payload) else { return }
        if (self.options.debug) {
            print("[Leap Edge] send:", json.debugDescription)
        }
        socket.write(stringData: json, completion: nil)
    }
    
    @discardableResult
    public func on<Message>(_ listener: @escaping (Message)->Void) -> Listener<Message> {
        self.emitter.when { (message: Message) in
            return listener(message)
        }
    }
}

extension LeapEdge {
    public func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(_):
            self.updateConnectionState(.connected)
            break
        case .disconnected(let reason, let code):
            self.updateConnectionState(.errored)
            if self.options.debug {
                print("[Leap Edge] Client disconnected unexpectedly:", reason, "with code:", code)
            }
            self.resetState()
            
            let leapError = LeapError.init(rawValue: Int(code)) ?? .unknown
            switch (leapError) {
            case .badRoute:
                guard let newSocketUrl = URL(string: reason) else { return }
                self.options.socketUrl = newSocketUrl
                self.connect()
                break
            default:
                if (leapError.canReconnect){
                    self.connect()
                }
                break
            }
            break
        case .text(let string):
            guard let data = string.data(using: .utf8),
                  let json = try? JSONDecoder().decode(EncapsulatingPayload<AnyCodable?>.self, from: data) else {
                if self.options.debug {
                    print("[Leap Edge] Received badly formatted payload:", string);
                }
                return
            }
            if (self.options.debug) {  print("[Leap Edge] recv:", string) }
            self.handleOpcode(op: json.op, json: data)
            break
        case .binary(_): break
        case .ping(_): break
        case .pong(_): break
        case .viabilityChanged(_): break
        case .reconnectSuggested(_): break
        case .cancelled: break
        case .error(let error):
            if self.options.debug {
                print("[Leap Edge] Client errored:", error.debugDescription)
            }
            self.updateConnectionState(.errored)
            self.resetState()
            break
        }
    }
}

extension LeapEdge {
    private func updateConnectionState(_ connectionState: ConnectionState) {
        self.connectionState = connectionState
        self.emitter.emit(connectionState)
    }
    
    private func resetState() {
        self.heartbeat?.invalidate()
        self.heartbeat = nil
        self.socket?.forceDisconnect()
        self.socket = nil
    }
    
    private func handleOpcode(op: OpCode, json: Data) {
        switch (op) {
        case .dispatch:
            guard let control = try? JSONDecoder().decode(EncapsulatingPayload<EncapsulatingServicePayload>.self, from: json) else { return }
            if (control.d.e == "INIT") {
                self.updateConnectionState(.connected)
            }
            self.emitter.emit(ServiceEvent(channelId: control.d.c, eventType: control.d.e, data: control.d.d))
            break
        case .hello:
            self.updateConnectionState(.authenticating)
            guard let control = try? JSONDecoder().decode(EncapsulatingPayload<OpCode.HelloControl>.self, from: json) else { return }
            self.setupHeartbeat(interval: control.d.heartbeatInterval)
            self.identify()
            break
        case .identify: break
        case .heartbeat:
            guard let control = try? JSONDecoder().decode(EncapsulatingPayload<OpCode.HeartbeatControl>.self, from: json) else { return }
            self.sendPayload(data: EncapsulatingPayload<OpCode.HeartbeatControl>(op: .heartbeat, d: OpCode.HeartbeatControl(tag: control.d.tag)))
            break
        case .heartbeatAck:
            self.lastServerHeartbeatAck = Int(Date().timeIntervalSince1970 * 1000)
            break
        }
    }
}

extension LeapEdge {
    private func setupHeartbeat(interval: Int) {
        self.heartbeatInterval = interval
        self.heartbeat = Timer.scheduledTimer(withTimeInterval: Double(interval), repeats: true) {_ in
            self.sendHeartbeat()
        }
    }
    
    private func sendHeartbeat(optimisticResolution: Bool? = nil) {
        self.sendPayload(data: EncapsulatingPayload<OpCode.HeartbeatControl>(op: .heartbeat, d: OpCode.HeartbeatControl()))
        let sendTs = Int(Date().timeIntervalSince1970 * 1000)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(optimisticResolution != nil ? 750 : 5000)) {
            self.validateHeartbeatAck(sendTs: sendTs, optimisticResolution: optimisticResolution)
        }
    }
    
    private func identify() {
        self.sendPayload(
            data: EncapsulatingPayload<OpCode.IdentifyControl>(
                op: .identify,
                d: OpCode.IdentifyControl(
                    projectId: self.auth.projectId,
                    token: self.auth.token
                )
            ))
    }
    
    public func validateHeartbeatAck(sendTs: Int, optimisticResolution: Bool? = nil) {
        let diff: Int? = self.lastServerHeartbeatAck != nil ?  self.lastServerHeartbeatAck! - sendTs : nil
        if let diff = diff, (diff >= 0 && diff < 5000) { return }
        
        guard optimisticResolution != true else {
            if self.options.debug {
                print("[Leap Edge] Optimistic resolution failed. Hard reconnecting...")
            }
            self.socket?.disconnect()
            self.updateConnectionState(.errored)
            self.resetState()
            return
        }
        if self.options.debug {
            print("[Leap Edge] Leap didn't respond to heartbeat in time. Attempting optimistic heartbeat resolution")
        }
        
        self.sendHeartbeat()
    }
}

extension LeapEdge {
    private func sendPayload<T: Codable>(data: EncapsulatingPayload<T>) {
        guard socket != nil && self.connectionState != .idle else { return }
        guard let json = try? JSONEncoder().encode(data) else { return }
        if (self.options.debug) {
            print("[Leap Edge] send:", String(data: json, encoding: .utf8) ?? "")
        }
        socket?.write(stringData: json, completion: nil)
    }
}

extension LeapEdge {
    public struct AuthenticationParameters {
        let token: String?
        let projectId: String
    }
    
    public struct InitOptions {
        var socketUrl: URL
        let debug: Bool
    }
    
    public enum ConnectionState: String {
        case idle = "idle"
        case connecting = "connecting"
        case authenticating = "authenticating"
        case connected = "connected"
        case errored = "errored"
    }
}
