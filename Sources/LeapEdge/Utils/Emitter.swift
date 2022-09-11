//
//  File.swift
//  
//
//  Created by Rishi Serumadar on 10/09/2022.
//

import Foundation

extension LeapEdge {
    final class Emitter {
        fileprivate var registry = [ObjectIdentifier: ContiguousArray<UnsafeListener>]()
        
        func emit<Message>(_ message: Message) {
            if let listeners = registry[ObjectIdentifier(Message.self)] {
                for listener in listeners {
                    unsafeDowncast(listener, to: Listener<Message>.self).content(message)
                }
            }
        }

        @discardableResult
        func when<Message>(_ listener: @escaping (Message)->Void) -> Listener<Message> {
            let id = ObjectIdentifier(Message.self)
            let handler = Listener(content: listener)
            if registry.keys.contains(id) {
                registry[id]!.append(handler)
            } else {
                registry[id] = [handler]
            }
            return handler
        }
    }

    public class UnsafeListener {}

    public class Listener<Message>: UnsafeListener {
        let content: (Message)->Void

        init(content: @escaping (Message)->Void) {self.content = content}
    }
}
