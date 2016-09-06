import UIKit

extension UITextField {
  public override var keyCommands: [UIKeyCommand]? {
    return [
      UIKeyCommand(
        input: UIKeyInputUpArrow,
        modifierFlags: UIKeyModifierFlags(),
        action: #selector(arrowUp)
      ),
      UIKeyCommand(
        input: UIKeyInputDownArrow,
        modifierFlags: UIKeyModifierFlags(),
        action: #selector(arrowDown)
      )
    ]
  }
  
  func arrowUp() {
    if let delegate = self.delegate {
      if delegate.respondsToSelector(#selector(arrowUp)) {
        delegate.performSelector(#selector(arrowUp))
      }
    }
  }
  
  func arrowDown() {
    if let delegate = self.delegate {
      if delegate.respondsToSelector(#selector(arrowDown)) {
        delegate.performSelector(#selector(arrowDown))
      }
    }
  }
}