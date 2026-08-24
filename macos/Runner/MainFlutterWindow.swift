import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    let targetSize = NSSize(width: 1520, height: 950)
    let minimumSize = NSSize(width: 1080, height: 720)
    let visibleFrame = NSScreen.main?.visibleFrame ?? NSRect(
      x: 0,
      y: 0,
      width: targetSize.width,
      height: targetSize.height
    )

    // 优先使用默认尺寸；小屏幕按可用区域缩小，避免窗口超出屏幕。
    let windowSize = NSSize(
      width: visibleFrame.width < minimumSize.width
        ? visibleFrame.width
        : min(targetSize.width, visibleFrame.width),
      height: visibleFrame.height < minimumSize.height
        ? visibleFrame.height
        : min(targetSize.height, visibleFrame.height)
    )
    let windowFrame = NSRect(
      x: visibleFrame.midX - windowSize.width / 2,
      y: visibleFrame.midY - windowSize.height / 2,
      width: windowSize.width,
      height: windowSize.height
    )

    self.minSize = minimumSize
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    super.awakeFromNib()
  }
}
