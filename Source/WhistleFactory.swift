import UIKit

public enum WhistleAction {
  case Present
  case Show(NSTimeInterval)
}

let whistleFactory = WhistleFactory()

public class WhistleFactory: UIViewController {

  public lazy var whistleWindow: UIWindow = UIWindow()

  public lazy var titleLabelHeight = CGFloat(20.0)

  public lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .Center

    return label
  }()
    
  public private(set) lazy var tapGestureRecognizer: UITapGestureRecognizer = { [unowned self] in
      let gesture = UITapGestureRecognizer()
      gesture.addTarget(self, action: #selector(WhistleFactory.handleTapGestureRecognizer))
        
      return gesture
  }()

  public private(set) var murmur: Murmur?
  public var viewController: UIViewController?
  public var hideTimer = NSTimer()

  // MARK: - Initializers

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
    super.init(nibName: nil, bundle: nil)

    setupWindow()
    view.clipsToBounds = true
    view.addSubview(titleLabel)
    
    view.addGestureRecognizer(tapGestureRecognizer)

    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(WhistleFactory.orientationDidChange), name: UIDeviceOrientationDidChangeNotification, object: nil)
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self, name: UIDeviceOrientationDidChangeNotification, object: nil)
  }

  // MARK: - Configuration

  public func whistler(murmur: Murmur, action: WhistleAction) {
    self.murmur = murmur
    titleLabel.text = murmur.title
    titleLabel.font = murmur.font
    titleLabel.textColor = murmur.titleColor
    view.backgroundColor = murmur.backgroundColor
    whistleWindow.backgroundColor = murmur.backgroundColor

    moveWindowToFront()
    setupFrames()

    switch action {
    case .Show(let duration):
      show(duration: duration)
    default:
      present()
    }
  }

  // MARK: - Setup

  public func setupWindow() {
    whistleWindow.addSubview(self.view)
    whistleWindow.clipsToBounds = true
    moveWindowToFront()
  }

  func moveWindowToFront() {
    let currentStatusBarStyle = UIApplication.sharedApplication().statusBarStyle
    whistleWindow.windowLevel = UIWindowLevelStatusBar
    UIApplication.sharedApplication().setStatusBarStyle(currentStatusBarStyle, animated: false)
  }

  public func setupFrames() {
    let labelWidth = UIScreen.mainScreen().bounds.width
    let defaultHeight = titleLabelHeight

    if let text = titleLabel.text {
      let neededDimensions =
        NSString(string: text).boundingRectWithSize(
          CGSize(width: labelWidth, height: CGFloat.infinity),
          options: NSStringDrawingOptions.UsesLineFragmentOrigin,
          attributes: [NSFontAttributeName: titleLabel.font],
          context: nil
        )
      titleLabelHeight = CGFloat(neededDimensions.size.height)
      titleLabel.numberOfLines = 0 // Allows unwrapping

      if titleLabelHeight < defaultHeight {
        titleLabelHeight = defaultHeight
      }
    } else {
      titleLabel.sizeToFit()
    }

    whistleWindow.frame = CGRect(x: 0, y: 0, width: labelWidth,
      height: titleLabelHeight)
    view.frame = whistleWindow.bounds
    titleLabel.frame = view.bounds
  }

  // MARK: - Movement methods

  public func show(duration duration: NSTimeInterval) {
    present()
    calm(after: duration)
  }

  public func present() {
    hideTimer.invalidate()

    let initialOrigin = whistleWindow.frame.origin.y
    whistleWindow.frame.origin.y = initialOrigin - titleLabelHeight
    whistleWindow.makeKeyAndVisible()
    UIView.animateWithDuration(0.2, animations: {
      self.whistleWindow.frame.origin.y = initialOrigin
    })
  }

  public func hide() {
    let finalOrigin = view.frame.origin.y - titleLabelHeight
    UIView.animateWithDuration(0.2, animations: {
      self.whistleWindow.frame.origin.y = finalOrigin
      }, completion: { _ in
        if let window = UIApplication.sharedApplication().windows.filter({ $0 != self.whistleWindow }).first {
          window.makeKeyAndVisible()
          self.whistleWindow.windowLevel = UIWindowLevelNormal - 1
          window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
        }
    })
  }

  public func calm(after after: NSTimeInterval) {
    hideTimer.invalidate()
    hideTimer = NSTimer.scheduledTimerWithTimeInterval(after, target: self, selector: #selector(WhistleFactory.timerDidFire), userInfo: nil, repeats: false)
  }

  // MARK: - Timer methods

  public func timerDidFire() {
    hide()
  }

  func orientationDidChange() {
    if whistleWindow.keyWindow {
      setupFrames()
      hide()
    }
  }
    
  // MARK: - Gesture methods
    
  @objc private func handleTapGestureRecognizer() {
      guard let murmur = murmur else { return }
      murmur.action?()
  }
}
