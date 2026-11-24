import SbuKit
import SwiftUI

/// The text that scrolls, plus the countdown, the pause button and the voice level bar.
struct PrompterView: View {
    let controller: PrompterController
    let settings: PrompterSettings
    let speech: SpeechFollower
    let chrome: PrompterChrome
    let isEmpty: Bool
    var reportsLayout = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .top) {
            background
            GeometryReader { proxy in
                PrompterTextColumn(controller: controller, settings: settings, width: proxy.size.width,
                                   viewportHeight: proxy.size.height, reportsLayout: reportsLayout)
                    .offset(y: -controller.engine.offset)
                    .scaleEffect(x: settings.isMirrored ? -1 : 1, y: 1)
            }
            .clipped()
            // The text fades out at the bottom edge instead of being cut.
            .mask {
                LinearGradient(stops: [.init(color: SbuTheme.ink, location: 0.75), .init(color: .clear, location: 1)],
                               startPoint: .top, endPoint: .bottom)
            }
            .padding(.horizontal, SbuTheme.space5)
            .padding(.top, chrome.topInset + SbuTheme.space2)
            .padding(.bottom, SbuTheme.space2)
            .opacity(controller.countdownLeft == nil ? 1 : 0.15)

            if isEmpty {
                Text("Scegli un copione dalla libreria.")
                    .font(SbuTheme.body)
                    .foregroundStyle(SbuTheme.inkMuted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, chrome.topInset)
            }

            if let left = controller.countdownLeft {
                Text(left, format: .number)
                    .font(.sbuFigure(size: 72))
                    .monospacedDigit()
                    .foregroundStyle(SbuTheme.ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, chrome.topInset)
                    .accessibilityLabel(Text("Si parte tra \(left) secondi"))
            }

            if !isEmpty, controller.engine.maxOffset > 0 {
                progressLine
            }
            overlayControls
            if chrome != .floating, reportsLayout {
                PanelResizeHandles(settings: settings)
            }
        }
        // Floating, the whole prompter is a handle to move it.
        .gesture(WindowDragGesture(), including: chrome == .floating ? .all : .subviews)
        .environment(\.colorScheme, .dark)
        .environment(\.sbuAccent, .prompter)
    }

    private var shape: some Shape {
        switch chrome {
        case .notch: AnyShape(UnevenRoundedRectangle(bottomLeadingRadius: SbuTheme.radiusXl, bottomTrailingRadius: SbuTheme.radiusXl))
        case .pill: AnyShape(RoundedRectangle(cornerRadius: SbuTheme.radiusXl))
        case .floating: AnyShape(RoundedRectangle(cornerRadius: SbuTheme.radiusLg))
        }
    }

    private var background: some View {
        shape.fill(SbuTheme.paper.opacity(settings.backgroundOpacity))
    }

    /// How far through the script the text is: a hairline along the bottom edge.
    private var progressLine: some View {
        let fraction = min(max(controller.engine.offset / controller.engine.maxOffset, 0), 1)
        return Rectangle()
            .fill(SbuTheme.line)
            .frame(height: 2)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(SbuTheme.inkMuted)
                    .scaleEffect(x: fraction, anchor: .leading)
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.horizontal, SbuTheme.radiusXl)
            .padding(.bottom, 1)
            .accessibilityHidden(true)
    }

    private var overlayControls: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    controller.perform(.togglePlay)
                } label: {
                    Image(systemName: controller.isPlaying ? "pause.fill" : "play.fill")
                        .fontWeight(.medium)
                        .foregroundStyle(SbuTheme.inkMuted)
                        .frame(width: SbuTheme.space6, height: SbuTheme.space6)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(controller.isPlaying ? Text("Pausa") : Text("Avvia"))
            }
            Spacer()
            if speech.isSilent, controller.isMoving {
                // Says which input is listening: when nothing is heard is listening, the usual cause is the wrong one.
                Text("Non sento niente da \(speech.inputName ?? String(localized: "il microfono")).")
                    .font(SbuTheme.caption)
                    .foregroundStyle(SbuTheme.inkMuted)
                    .lineLimit(1)
                    .transition(.opacity)
            }
            if speech.isListening {
                Capsule()
                    .fill(SbuAccent.prompter.base)
                    .frame(width: max(SbuTheme.space1, speech.level * 120), height: 3)
                    .animation(SbuMotion.animation(SbuMotion.short, reduceMotion: reduceMotion), value: speech.level)
                    .accessibilityHidden(true)
            }
        }
        .padding(.top, chrome.topInset + SbuTheme.space1)
        .padding(.horizontal, SbuTheme.space2)
        .padding(.bottom, SbuTheme.space1)
    }
}
