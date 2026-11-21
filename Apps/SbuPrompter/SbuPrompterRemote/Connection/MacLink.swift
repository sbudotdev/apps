@preconcurrency import MultipeerConnectivity
import UIKit

/// The iPhone end of the remote: looks for Sbu Prompter on the local network with
/// MultipeerConnectivity (encrypted, nothing leaves the LAN) and carries `RemoteModel`'s messages.
final class MacLink: NSObject {
    private let model: RemoteModel
    private let peer = MCPeerID(displayName: UIDevice.current.name)
    private let session: MCSession
    private let browser: MCNearbyServiceBrowser
    /// The Macs nearby by the name shown; two Macs with the same name get "Studio (2)".
    // shortcut: tokens are keyed by this label, and the label depends on which Mac is found
    // first. Two Macs with the same name can swap tokens after a relaunch, and a refused
    // `resume` then forgets the other Mac's token. Key tokens by a Mac id if that ever matters.
    private var found: [String: MCPeerID] = [:]

    init(model: RemoteModel) {
        self.model = model
        session = MCSession(peer: peer, securityIdentity: nil, encryptionPreference: .required)
        browser = MCNearbyServiceBrowser(peer: peer, serviceType: "sbu-prompter")
        super.init()
        session.delegate = self
        browser.delegate = self
        model.send = { [weak self] message in self?.send(message) }
        model.connect = { [weak self] name in self?.invite(name) }
    }

    /// Starts looking from scratch: at launch and back from the background, when iOS has
    /// dropped the session.
    func restart() {
        browser.stopBrowsingForPeers()
        session.disconnect()
        found = [:]
        names = [:]
        if let mac = model.currentMac { model.disconnected(from: mac) }
        model.found([])
        browser.startBrowsingForPeers()
    }

    private func invite(_ name: String) {
        guard let mac = found[name] else { return }
        browser.invitePeer(mac, to: session, withContext: nil, timeout: 15)
    }

    private func send(_ message: RemoteMessage) {
        guard let data = try? RemoteCodec.encode(message), !session.connectedPeers.isEmpty else { return }
        try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
    }

    private func receive(_ data: Data) {
        do {
            model.receive(try RemoteCodec.decode(data))
        } catch RemoteCodec.Failure.unsupportedVersion {
            model.outdated()
        } catch {
            // Garbage from a peer: ignore it.
        }
    }

    /// One label per peer, so the session's callbacks use the name shown in the list. A lost
    /// peer keeps its label: a late `.notConnected` still names the Mac the model knows.
    private var names: [MCPeerID: String] = [:]

    private func name(for mac: MCPeerID) -> String {
        if let name = names[mac] { return name }
        let name = Self.label(for: mac.displayName, taken: Set(found.keys))
        names[mac] = name
        return name
    }

    private func foundChanged() {
        model.found(Array(found.keys))
    }

    static func label(for name: String, taken: Set<String>) -> String {
        guard taken.contains(name) else { return name }
        return (2...).lazy.map { "\(name) (\($0))" }.first { !taken.contains($0) }!
    }
}

extension MacLink: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID,
                             withDiscoveryInfo info: [String: String]?) {
        Task { @MainActor in
            self.found[self.name(for: peerID)] = peerID
            self.foundChanged()
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor in
            // A relaunched Mac comes back as a new peer and takes its plain name again,
            // since labels only clash with the Macs found now.
            if let name = self.names[peerID], self.found[name] == peerID { self.found[name] = nil }
            self.foundChanged()
        }
    }
}

extension MacLink: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected: self.model.connected(to: self.name(for: peerID))
            case .notConnected: self.model.disconnected(from: self.name(for: peerID))
            case .connecting: break
            @unknown default: break
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in self.receive(data) }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String,
                             fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String,
                             fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String,
                             fromPeer peerID: MCPeerID, at localURL: URL?, withError error: (any Error)?) {}
}
