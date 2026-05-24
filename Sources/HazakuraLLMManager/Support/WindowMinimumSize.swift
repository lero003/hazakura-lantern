import AppKit
import SwiftUI

extension View {
    func lanternWindowMinimumSize(width: CGFloat, height: CGFloat) -> some View {
        modifier(WindowMinimumSizeModifier(minimumSize: CGSize(width: width, height: height)))
    }
}

private struct WindowMinimumSizeModifier: ViewModifier {
    let minimumSize: CGSize

    func body(content: Content) -> some View {
        content.background {
            WindowMinimumSizeBridge(minimumSize: minimumSize)
                .frame(width: 0, height: 0)
        }
    }
}

private struct WindowMinimumSizeBridge: NSViewRepresentable {
    let minimumSize: CGSize

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        applyMinimumSize(to: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        applyMinimumSize(to: nsView)
    }

    private func applyMinimumSize(to view: NSView) {
        DispatchQueue.main.async {
            guard let window = view.window else {
                return
            }

            window.minSize = minimumSize

            var frame = window.frame
            var needsResize = false

            if frame.width < minimumSize.width {
                frame.size.width = minimumSize.width
                needsResize = true
            }

            if frame.height < minimumSize.height {
                let currentTop = frame.maxY
                frame.size.height = minimumSize.height
                frame.origin.y = currentTop - minimumSize.height
                needsResize = true
            }

            if let visibleFrame = window.screen?.visibleFrame {
                if frame.maxX > visibleFrame.maxX {
                    frame.origin.x = max(visibleFrame.minX, visibleFrame.maxX - frame.width)
                    needsResize = true
                }

                if frame.minX < visibleFrame.minX {
                    frame.origin.x = visibleFrame.minX
                    needsResize = true
                }

                if frame.maxY > visibleFrame.maxY {
                    frame.origin.y = visibleFrame.maxY - frame.height
                    needsResize = true
                }

                if frame.minY < visibleFrame.minY {
                    frame.origin.y = visibleFrame.minY
                    needsResize = true
                }
            }

            if needsResize {
                window.setFrame(frame, display: true, animate: false)
            }
        }
    }
}
