# LeapEdge

This package was ported from [leap-edge-js](https://github.com/hopinc/leap-edge-js) to support Swift.

An unofficial utility library for connecting and receiving events from [Leap Edge](https://docs.hop.io/docs/channels/internals/leap). Used for Channels.

## Usage
### Basic

```swift
import LeapEdge

let leap = LeapEdge(auth: .init(token: "leap_token_xxx", projectId: "project_xxx"))
leap.connect()

leap.emitter.when { (message: LeapEdge.ConnectionState) in
  // Do something with the current connection state.
}

leap.emitter.when { (message: LeapEdge.ServiceEvent) in
  // Wait for an event and respond accordingly
}

```

> If you don't want to supply a token (e.g. to only connect to unprotected channels), then pass `nil` for `token` in the authentication parameters object