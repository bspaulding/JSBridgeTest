import JavaScriptCore
import UIKit

class JSButton: UIButton {
  var properties: JSValue?
  
  func setProps(props: JSValue) {
    self.properties = props
    
    if props.hasProperty("onClick") {
      self.addTarget(self, action: #selector(self.onClick(_:)), forControlEvents: .TouchUpInside)
    } else {
      self.removeTarget(self, action: #selector(self.onClick(_:)), forControlEvents: .TouchUpInside)
    }
  }
  
  func onClick(sender: AnyObject?) {
    print("[JSButton#onClick]")
    if let props = self.properties {
      if props.hasProperty("onClick") {
        props
          .valueForProperty("onClick")
          .callWithArguments([])
      }
    }
  }
}