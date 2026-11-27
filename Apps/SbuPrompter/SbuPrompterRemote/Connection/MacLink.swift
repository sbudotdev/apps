@preconcurrency import MultipeerConnectivity
import UIKit

/// The iPhone end of the remote: looks for Sbu Prompter on the local network with
/// MultipeerConnectivity (encrypted, nothing leaves the LAN) and carries `RemoteModel`'s messages.
final class MacLink: NSObject {
    private let model: RemoteModel
    private var peer = MCPeerID(displayName: UIDevice.current.name)
    private var session: MCSession
    private var browser: MCNearbyServiceBrowser
    /// The Macs nearby by the name shown; two Macs with the same name get "Studio (2)".
    // shortcut: tokens are keyed by this label. A Mac opened again keeps its label (`ids`), but two
    // Macs with the same name can swap labels when this app restarts, and a refused `resume` then
    // forgets the other Mac's token. Key tokens by the Mac id if that ever matters.
    private var found: [String: MCPeerID] = [:]
    /// The Mac invited last. The session also reports the other iPhones driving that Mac (Multipeer
    /// links every peer of a session), so everything else is ignored and nothing is sent to them.
    private var mac: MCPeerID?
    /// The id each Mac announces: the same Mac app opened again is a new peer with the same id.
    private var ids: [MCPeerID: String] = [:]

    init(model: RemoteModel) {
        self.model = model
        session = MCSession(peer: peer, securityIdentity: nil, encryptionPreference: .required)
        browser = MCNearbyServiceBrowser(peer: peer, serviceType: "sbu-prompter")
        super.init()
        session.delegate = self
        browser.delegate = self
        model.send = { [weak self] message in self?.send(message) }
        model.connect = { [weak self] name in self?.invite(name) }
        model.leave = { [weak self] in
            self?.mac = nil
            self?.session.disconnect()
        }
    }

    /// Starts looking from scratch: at launch and back from the background, when iOS has
    /// dropped the session.
    func restart() {
        browser.stopBrowsingForPeers()
        browser.delegate = nil
        session.disconnect()
        session.delegate = nil
        // A new peer each time: the Mac may still hold the old link, and when it drops it late
        // it must not drop this one too (SBU-424).
        peer = MCPeerID(displayName: UIDevice.current.name)
        session = MCSession(peer: peer, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        browser = MCNearbyServiceBrowser(peer: peer, serviceType: "sbu-prompter")
        browser.delegate = self
        found = [:]
        names = [:]
        ids = [:]
        mac = nil
        settle?.cancel()
        model.restarted()
        // The list first, so the model does not try to join again a Mac this link no longer knows.
        model.found([])
        if let mac = model.currentMac { model.disconnected(from: mac) }
        browser.startBrowsingForPeers()
    }

    private func invite(_ name: String) {
        guard let mac = found[name] else { return }
        self.mac = mac
        // A Mac on the same network answers in well under a second; one that does not is asleep
        // or unreachable, and the model tries again or gives up.
        browser.invitePeer(mac, to: session, withContext: nil, timeout: 8)
    }

    private func send(_ message: RemoteMessage) {
        guard let mac, session.connectedPeers.contains(mac), let data = try? RemoteCodec.encode(message) else { return }
        try? session.send(data, toPeers: [mac], with: .reliable)
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

    private var settle: Task<Void, Never>?

    /// Bonjour reports the Macs one by one, milliseconds apart: wait for the burst to end, or the
    /// first Mac found would be joined as if it were the only one.
    private func foundChanged() {
        settle?.cancel()
        // The paired Mac is the one joined anyway: no need to wait for the others.
        if found.keys.contains(where: model.isPaired) {
            model.found(Array(found.keys))
            return
        }
        settle = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled, let self else { return }
            model.found(Array(found.keys))
        }
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
            guard browser === self.browser else { return }
            let id = info?["id"]
            // Same id and same name, and the old peer no longer linked: the same Mac app, quit and opened
            // again. It keeps its label, so its token still matches.
            // shortcut: the id is public discovery data, not a proof. A peer copying name and id gets the
            // token once the real Mac is gone, as a peer copying the name alone already could. A Mac
            // still linked is never left for it (QA SBU-425). Prove the Mac at pairing if that matters.
            if let id, let old = self.found.first(where: { self.ids[$0.value] == id && $0.value.displayName == peerID.displayName }),
               old.value != peerID, !self.session.connectedPeers.contains(old.value) {
                self.found[old.key] = peerID
                self.names[peerID] = old.key
                self.ids[peerID] = id
                if self.mac == old.value { self.mac = nil }
                self.model.macRelaunched(old.key)
                return
            }
            if let id { self.ids[peerID] = id }
            self.found[self.name(for: peerID)] = peerID
            self.foundChanged()
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor in
            guard browser === self.browser else { return }
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
            guard session === self.session else { return }
            guard peerID == self.mac else {
                // A Mac left behind for another one may still answer the old invitation.
                if state == .connected, self.found.values.contains(peerID) { session.cancelConnectPeer(peerID) }
                return
            }
            switch state {
            case .connected: self.model.connected(to: self.name(for: peerID))
            case .notConnected: self.model.disconnected(from: self.name(for: peerID))
            case .connecting: break
            @unknown default: break
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            guard session === self.session, peerID == self.mac else { return }
            self.receive(data)
        }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String,
                             fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String,
                             fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String,
                             fromPeer peerID: MCPeerID, at localURL: URL?, withError error: (any Error)?) {}
}
