# LeapEdge

An unofficial Swift utility library for connecting and receiving events from [Leap Edge](https://docs.hop.io/docs/channels/internals/leap). Used for Channels.

## Usage

### Connecting

```swift
import LeapEdge

let leap = LeapEdge(auth: .init(token: "leap_token_xxx", projectId: "project_xxx"))
leap.connect()
```

> If you don't want to supply a token (e.g. to only connect to unprotected channels), then pass `nil` for `token` in the authentication parameters object

### Listening for Connection Status Updates

```swift
leap.emitter.when { (message: LeapEdge.ConnectionState) in
  // Do something
}
```

### Listening for Service Events

```swift
leap.emitter.when { (message: LeapEdge.ServiceEvent) in
  // Do something
}
```
