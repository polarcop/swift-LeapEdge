# LeapEdge

This package was ported from [leap-edge-js](https://github.com/hopinc/leap-edge-js) to support Swift.

An unofficial utility library for connecting and receiving events from [Leap Edge](https://docs.hop.io/docs/channels/internals/leap). Used for Channels.

## Installation
**With** [Package Manager](https://swift.org/package-manager/)

```swift
.package(name: "LeapEdge", url: "https://github.com/polarcop/swift-LeapEdge.git", .upToNextMajor(from: "1.0.0"))
```

## Usage
### Basic

```swift
import LeapEdge

let leap = LeapEdge(auth: .init(token: "leap_token_xxx", projectId: "project_xxx"))
leap.connect()

leap.on { (message: LeapEdge.ConnectionState) in
  // Do something with the current connection state.
}

leap.on { (message: LeapEdge.ServiceEvent) in
  // Wait for an event and respond accordingly
}

```

> If you don't want to supply a token (e.g. to only connect to unprotected channels), then pass `nil` for `token` in the authentication parameters object
