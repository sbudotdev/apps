import AppKit
import SpriteKit

/// La busta della letterina sulla scena: sale fino alla quota della slitta, Babbo Natale passa e se la porta via.
/// Con Riduci movimento la slitta non passa (come sempre): la busta compare lassù e svanisce.
extension SeasonScene {
    /// Spedisce la letterina dal punto `point` della scena (dove stava la finestra). false = non è inverno o in pausa.
    @discardableResult
    func mailLetter(from point: CGPoint) -> Bool {
        guard season is Snow, !toysPaused else { return false }
        letter?.removeFromParent()
        let altitude = (ceiling ?? size.height) * Tuning.santaAltitude - 6
        let envelope = SKSpriteNode(texture: Self.envelopeTexture)
        envelope.size = Self.envelopeTexture.size()
        envelope.zPosition = 1.85
        let x = min(max(point.x, 40), size.width - 40)
        addChild(envelope)
        letter = envelope
        if reduceMotion {
            envelope.position = CGPoint(x: x, y: altitude)
            envelope.alpha = 0
            envelope.run(.sequence([.fadeIn(withDuration: Tuning.letterFadeIn), .wait(forDuration: Tuning.letterStay), .fadeOut(withDuration: Tuning.letterFadeOut), .removeFromParent()]))
            letter = nil
            return true
        }
        envelope.position = CGPoint(x: x, y: min(point.y, altitude))
        let rise = SKAction.move(to: CGPoint(x: x, y: altitude), duration: TimeInterval((altitude - envelope.position.y) / Tuning.letterRise))
        rise.timingMode = .easeOut
        envelope.run(rise)
        return true
    }

    /// A ogni passo di Natale: la busta arrivata in cielo chiama la slitta; la slitta che le passa sopra la prende.
    func stepLetter() {
        guard let letter, !letter.hasActions() else { return }
        if let santa, santa.pickup === letter {
            let reached = santa.heading > 0 ? santa.node.position.x >= letter.position.x : santa.node.position.x <= letter.position.x
            guard reached else { return }
            // Nel sacco: la busta va con la slitta e se ne va con lei.
            letter.removeFromParent()
            letter.position = CGPoint(x: 10 * santa.heading, y: 26)
            letter.xScale = santa.heading
            letter.setScale(0.7)
            santa.node.addChild(letter)
            self.letter = nil
            return
        }
        guard santa == nil else { return }
        let heading: CGFloat = letter.position.x > size.width / 2 ? 1 : -1
        guard let santa = sendSanta(manual: false, heading: heading, altitude: letter.position.y + 6, carriesGift: false),
              self.santa === santa else { return }
        santa.pickup = letter
        SoundBoard.shared.play("babbo-natale")
    }

    private static let envelopeTexture = drawnTexture(size: CGSize(width: 18, height: 12)) { rect in
        let paper = NSColor(calibratedRed: 0.99, green: 0.97, blue: 0.9, alpha: 1)
        paper.setFill()
        NSBezierPath(rect: rect.insetBy(dx: 0.5, dy: 0.5)).fill()
        let flap = NSBezierPath()
        flap.move(to: CGPoint(x: 0.5, y: 11.5))
        flap.line(to: CGPoint(x: 9, y: 5))
        flap.line(to: CGPoint(x: 17.5, y: 11.5))
        flap.lineWidth = 0.8
        NSColor(white: 0.55, alpha: 1).setStroke()
        flap.stroke()
        NSBezierPath(rect: rect.insetBy(dx: 0.5, dy: 0.5)).stroke()
        NSColor(calibratedRed: 0.78, green: 0.12, blue: 0.16, alpha: 1).setFill()
        NSBezierPath(ovalIn: CGRect(x: 7.5, y: 3.5, width: 3, height: 3)).fill()   // il sigillo
    }
}
