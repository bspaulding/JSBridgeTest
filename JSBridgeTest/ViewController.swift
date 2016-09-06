import Alamofire
import JavaScriptCore
import UIKit

class ViewController: UIViewController, UITextFieldDelegate {
  @IBOutlet weak var textView: UITextView!
  @IBOutlet weak var textInput: UITextField!

  let fetch: @convention(block) (AnyObject?, JSValue?, JSValue?) -> () = { url, success, error in
    if let url = url {
      Alamofire.request(.GET, url as! String)
        .responseJSON { response in
          if let success = success {
            success.callWithArguments([response.result.value!])
          }
        }
    }
  }

  let log: @convention(block) (AnyObject?) -> () = { x in
    if let x = x {
      print(x)
    } else {
      print("")
    }
  }

  var context: JSContext?

  override func viewDidLoad() {
    super.viewDidLoad()

    context = JSContext()
    context!.setObject(
      unsafeBitCast(fetch, AnyObject.self),
      forKeyedSubscript: "fetch"
    )
		context!.setObject(
			unsafeBitCast(["log": log, "error": log, "info": log, "warn": log], AnyObject.self),
			forKeyedSubscript: "console"
		)
    context!.setObject(
      unsafeBitCast([], AnyObject.self),
      forKeyedSubscript: "window"
    )
    
    if let sourceURL = NSBundle.mainBundle().URLForResource("bundle", withExtension: "js") {
      let source = try! String(contentsOfURL: sourceURL)
      context?.evaluateScript(source)
    } else {
      print("getting sourceURL failed")
    }
    
    let rootView = JSRootView()
    rootView.render(context!, rendererSubscript: "window.App()")
    rootView.frame = self.view.frame
    
    self.view.addSubview(rootView)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  @IBAction func exec(sender: AnyObject) {
    let cmd = textInput.text!
    textInput.text = ""

    let value = context?.evaluateScript(cmd)

    textView.text = textView.text!
      + "\n> " + cmd
      + "\n " + value!.toString()

    textView.scrollRangeToVisible(
      NSMakeRange(textView.text.characters.count-1, 1))
  }
}
