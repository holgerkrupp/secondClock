//
//  SeconClock2App.swift
//  SeconClock2
//
//  Created by Holger Krupp on 16.08.23.
//

import AppKit
import SwiftUI
import SwiftData

private enum SecondClockShared {
    static let panelWidth: CGFloat = 420
    static let defaultPanelHeight: CGFloat = 720
    static let panelScreenInset: CGFloat = 12

    static let modelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: UserTimeZone.self)
        } catch {
            fatalError("Could not initialize ModelContainer")
        }
    }()
}

@main
struct SecondClock2App: App {
    @NSApplicationDelegateAdaptor(SecondClockMenuBarDelegate.self) private var menuBarDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commands {
            CommandGroup(replacing: .appSettings) { }
        }
    }
}

struct SecondClockBackdrop: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.09, green: 0.12, blue: 0.18),
                Color(red: 0.13, green: 0.20, blue: 0.30),
                Color(red: 0.20, green: 0.27, blue: 0.36)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topLeading) {
            RadialGradient(
                colors: [
                    Color.white.opacity(0.22),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 12,
                endRadius: 260
            )
            .blendMode(.screen)
        }
        .overlay {
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.18)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

private struct SecondClockGlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let padding: CGFloat
    let tint: Color

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                if #available(macOS 26.0, *) {
                    Color.clear
                        .glassEffect(
                          //  .regular.tint(tint),
                            in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        )
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.thinMaterial)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.12), radius: 18, y: 12)
    }
}

extension View {
    func secondClockGlassCard(
        cornerRadius: CGFloat = 26,
        padding: CGFloat = 16,
        tint: Color = Color.white.opacity(0.18)
    ) -> some View {
        modifier(
            SecondClockGlassCardModifier(
                cornerRadius: cornerRadius,
                padding: padding,
                tint: tint
            )
        )
    }
}

@MainActor
private final class SecondClockMenuBarDelegate: NSObject, NSApplicationDelegate {
    private var statusController: FloatingStatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusController = FloatingStatusBarController(modelContainer: SecondClockShared.modelContainer)
    }
}

private struct FloatingMenuContentView: View {
    let modelContainer: ModelContainer

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SearchView()
                    .modelContainer(modelContainer)
                    .frame(maxWidth: .infinity, alignment: .top)

                HStack(spacing: 12) {
                    LaunchAtLoginView()
                    Spacer()
                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        Text("Quit")
                    }
                }
                .secondClockGlassCard(
                    cornerRadius: 22,
                    padding: 16,
                    tint: Color.white.opacity(0.15)
                )
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .scrollIndicators(.hidden)
        .frame(width: SecondClockShared.panelWidth)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.clear)
    }
}

@MainActor
private final class FloatingStatusBarController: NSObject {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    private let statusItem: NSStatusItem
    private let panel: FloatingMenuBarPanel
    private var titleTimer: Timer?

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.modelContext = modelContainer.mainContext
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.panel = FloatingMenuBarPanel()
        super.init()
        modelContext.normalizeUserTimeZoneOrders()
        configureStatusItem()
        configurePanel()
        startTitleUpdates()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        button.target = self
        button.action = #selector(togglePanel)
        button.sendAction(on: [.leftMouseUp])
        updateStatusTitle()
    }

    private func configurePanel() {
        let rootView = FloatingMenuContentView(modelContainer: modelContainer)
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.frame = CGRect(origin: .zero, size: panel.frame.size)
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView = hostingView
    }

    private func startTitleUpdates() {
        titleTimer = Timer.scheduledTimer(
            timeInterval: 0.5,
            target: self,
            selector: #selector(handleTitleTimer),
            userInfo: nil,
            repeats: true
        )
    }

    @objc private func handleTitleTimer() {
        updateStatusTitle()
    }

    @objc private func togglePanel() {
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            showPanel()
        }
    }

    private func showPanel() {
        guard let button = statusItem.button,
              let buttonWindow = button.window else {
            return
        }

        let buttonRectInWindow = button.convert(button.bounds, to: nil)
        let buttonRectOnScreen = buttonWindow.convertToScreen(buttonRectInWindow)
        let visibleFrame = buttonWindow.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero

        let panelSize = preferredPanelSize(for: visibleFrame)
        var originX = buttonRectOnScreen.midX - (panelSize.width / 2)
        originX = min(
            max(originX, visibleFrame.minX + SecondClockShared.panelScreenInset),
            visibleFrame.maxX - panelSize.width - SecondClockShared.panelScreenInset
        )

        let originY = max(
            visibleFrame.minY + SecondClockShared.panelScreenInset,
            buttonRectOnScreen.minY - panelSize.height - 8
        )

        panel.setFrame(
            CGRect(origin: NSPoint(x: originX, y: originY), size: panelSize),
            display: false
        )
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    private func preferredPanelSize(for visibleFrame: CGRect) -> CGSize {
        let availableHeight = visibleFrame.height - (SecondClockShared.panelScreenInset * 2)
        let panelHeight = availableHeight > 0 ? availableHeight : SecondClockShared.defaultPanelHeight
        return CGSize(width: SecondClockShared.panelWidth, height: panelHeight)
    }

    private func updateStatusTitle() {
        guard let button = statusItem.button else {
            return
        }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium),
            .foregroundColor: NSColor.labelColor
        ]

        button.attributedTitle = NSAttributedString(
            string: currentMenuBarText(),
            attributes: attributes
        )
        button.sizeToFit()
    }

    private func currentMenuBarText() -> String {
        let descriptor = FetchDescriptor<UserTimeZone>(
            predicate: #Predicate<UserTimeZone> { $0.selected == true },
            sortBy: [SortDescriptor(\.order)]
        )

        let selectedTimeZones = (try? modelContext.fetch(descriptor)) ?? []

        guard !selectedTimeZones.isEmpty else {
            return "SecondClock"
        }

        return selectedTimeZones.enumerated().map { index, timeZone in
            let separator = index == selectedTimeZones.count - 1 ? "" : " \u{2022} "
            return "\(timeZone.readName()) \(timeZone.currentTime)\(separator)"
        }
        .joined()
    }
}

@MainActor
private final class FloatingMenuBarPanel: NSPanel {
    init() {
        super.init(
            contentRect: CGRect(
                x: 0,
                y: 0,
                width: SecondClockShared.panelWidth,
                height: SecondClockShared.defaultPanelHeight
            ),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .statusBar
        collectionBehavior = [.transient, .moveToActiveSpace, .fullScreenAuxiliary]
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isOpaque = false
        hasShadow = false
        backgroundColor = .clear
        isMovable = false
        hidesOnDeactivate = true
    }

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }

    override func resignKey() {
        super.resignKey()
        orderOut(nil)
    }

    override func cancelOperation(_ sender: Any?) {
        orderOut(sender)
    }
}
