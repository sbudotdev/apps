@preconcurrency import MultipeerConnectivity
import UIKit

/// The iPhone end of the remote: looks for Sbu Prompter on the local network with
/// MultipeerConnectivity (encrypted, nothing leaves the LAN) and carries `RemoteModel`'s messages.
final class MacLink: NSObject {
    private let model: RemoteModel
    private let peer = MCPeerID(displayName: UIDevice.current.name)
    private let session: MCSession
    private let browser: MCNearbyServiceBrowser
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

    private func foundChanged() {
        model.found(Array(found.keys))
    }
}

extension MacLink: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID,
                             withDiscoveryInfo info: [String: String]?) {
        Task { @MainActor in
            self.found[peerID.displayName] = peerID
            self.foundChanged()
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor in
            self.found[peerID.displayName] = nil
            self.foundChanged()
        }
    }
}

extension MacLink: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected: self.model.connected(to: peerID.displayName)
            case .notConnected: self.model.disconnected(from: peerID.displayName)
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
