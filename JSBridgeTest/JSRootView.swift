import JavaScriptCore
import UIKit

class JSRootView: UIView {
  var currentTree: [NSObject : AnyObject]!

  var cs: [NSLayoutConstraint] = []
  func enqueueConstraint(constraint: NSLayoutConstraint) {
    cs.append(constraint)
  }
  func applyConstraints() {
    self.removeConstraints(self.cs)
    self.addConstraints(cs)
  }

  func render(context: JSContext, rendererSubscript: String) {
    let changes = context.evaluateScript(rendererSubscript)
    cs = []
    create(self, tree: changes.valueForProperty("tree"))
    applyConstraints()
  }
  
  func update(context: JSContext, rendererSubscript: String) {
    let raw = context.evaluateScript(rendererSubscript)
    let changes2 = raw.toDictionary()
    patch(self, patches: changes2["patches"] as! [String: AnyObject])
  }

  private func patch(root: UIView, patches: [String: AnyObject]) -> UIView {
    var root = root
    let indices = patchIndices(patches)

    if indices.count == 0 {
      return root
    }

    var index = treeIndex(root, tree: patches["a"] as! [String: AnyObject], indices: indices)
    for nodeIndex in indices {
      root = applyPatches(
        root,
        node: index[nodeIndex],
        patches: patches[String(nodeIndex)]!
      )
    }

    return root
  }

  private enum PatchType: Int {
    case NONE = 0
    case VTEXT = 1
    case VNODE = 2
    case WIDGET = 3
    case PROPS = 4
    case ORDER = 5
    case INSERT = 6
    case REMOVE = 7
    case THUNK = 8
  }

  private func applyPatches(root: UIView, node: UIView?, patches: AnyObject) -> UIView {
    if let node = node {
//      var newNode : UIView
      if let patches = patches as? [[String: AnyObject]] {
        // handle each patch
        patches.forEach({ patch in
          applyPatch(patch, node: node)
        })
      } else if let patch = patches as? [String: AnyObject] {
        applyPatch(patch, node: node)
      }
      return root
    } else {
      return root
    }
  }

  private func applyPatch(patch: [String: AnyObject], node: UIView) {
    let type = PatchType(rawValue: patch["type"] as! Int)!
    let vNode = patch["vNode"] as! [String: AnyObject]
    let patchInfo = patch["patch"] as! [String: AnyObject]
    
    switch type {
    case .VTEXT:
      print("got a VTEXT patch")
      stringPatch(node, vNode: vNode, patch: patchInfo)
    default:
      print("got an unhandled patch type: \(patch["type"])")
    }
  }
  
  // BEGIN NODE TYPE PATCHERS
  
  private func stringPatch(node: UIView, vNode: [String: AnyObject], patch: [String: AnyObject]) {
    let newText = patch["text"] as! String
    let textView = node as! UITextView
    textView.text = newText
  }
  
  // END NODE TYPE PATCHERS

  private func treeIndex(root: UIView, tree: [String: AnyObject], indices: [Int]) -> [Int: UIView] {
    if indices.count == 0 {
      return [:] as Dictionary
    } else {
      return treeIndexRecurse(root, tree: tree, indices: indices.sort(), nodes: [:], rootIndex: 0)
    }
  }

  private func treeIndexRecurse(root: UIView,
                                tree: [String: AnyObject],
                                indices: [Int],
                                nodes: [Int: UIView],
                                rootIndex: Int) -> [Int: UIView] {
    var nodes = nodes
    var rootIndex = rootIndex

    if indexInRange(indices, left: rootIndex, right: rootIndex) {
      nodes[rootIndex] = root
    }

    if let children = tree["children"] as? [AnyObject] {
      let subviews = root.subviews
      var i = 0
      for child in children {
        rootIndex += 1
        var count = 0
        if let _count = child["count"] as? Int {
          count = _count
        }
        let nextIndex = rootIndex + count

        if indexInRange(indices, left: rootIndex, right: nextIndex) {
          // TODO: There's a bug here when a patch has multiple children,
          // subviews.count == 1, && i == 1, so subviews[1] yields an
          // index out of range exception
          let childNodes = treeIndexRecurse(
            subviews[i],
            tree: child as! [String: AnyObject],
            indices: indices,
            nodes: nodes,
            rootIndex: rootIndex
          )
          
          for (k, v) in childNodes {
            nodes[k] = v
          }
        }

        rootIndex = nextIndex
        i += 1
      }
    }

    return nodes
  }

  private func indexInRange(indices: [Int], left: Int, right: Int) -> Bool {
    if indices.count == 0 {
      return false
    }

    var minIndex = 0
    var maxIndex = indices.count - 1
    var currentIndex: Int
    var currentItem: Int

    while minIndex <= maxIndex {
      currentIndex = ((maxIndex + minIndex) / 2) >> 0
      currentItem = indices[currentIndex]

      if minIndex == maxIndex {
        return currentItem >= left && currentItem <= right
      } else if currentItem < left {
        minIndex = currentIndex + 1
      } else if currentItem > right {
        maxIndex = currentIndex - 1
      } else {
        return true
      }
    }

    return false
  }

  private func patchIndices(patches: [String: AnyObject]) -> [Int] {
    var indices: [Int] = []

    for (index, _) in patches {
      if index != "a" {
        if let i = Int(index) {
          indices.append(i)
        }
      }
    }

    return indices
  }

  private func create(root: UIView, tree: JSValue!) -> () {
    if tree.valueForProperty("type").toString() == "VirtualText" {
      let text = tree.valueForProperty("text").toString()
      if root.isKindOfClass(UITextView) {
        let textView = root as! UITextView
        textView.text = text
      } else if root.isKindOfClass(JSButton) {
        let button = root as! JSButton
        button.setTitle(text, forState: .Normal)
      }
      return
    }

    var view : UIView
    switch tree.valueForProperty("tagName").toString() {
    case "TEXT":
      view = UITextView()
      (view as! UITextView).textAlignment = .Center;
      enqueueConstraint(NSLayoutConstraint(
        item: view,
        attribute: NSLayoutAttribute.Bottom,
        relatedBy: NSLayoutRelation.Equal,
        toItem: root,
        attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0
      ))
      enqueueConstraint(NSLayoutConstraint(
        item: view,
        attribute: NSLayoutAttribute.Height,
        relatedBy: NSLayoutRelation.Equal,
        toItem: nil,
        attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1.0, constant: 30
      ))
      enqueueConstraint(NSLayoutConstraint(
        item: view,
        attribute: NSLayoutAttribute.Width,
        relatedBy: NSLayoutRelation.Equal,
        toItem: root,
        attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: 0
      ))
    case "BUTTON":
      view = JSButton(type: .System)
      view.tag = 1
      (view as! JSButton).setProps(tree.valueForProperty("properties"))
      enqueueConstraint(NSLayoutConstraint(
        item: view,
        attribute: NSLayoutAttribute.Top,
        relatedBy: NSLayoutRelation.Equal,
        toItem: root,
        attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0
      ))
      enqueueConstraint(NSLayoutConstraint(
        item: view,
        attribute: NSLayoutAttribute.Height,
        relatedBy: NSLayoutRelation.Equal,
        toItem: nil,
        attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1.0, constant: 30
      ))
      enqueueConstraint(NSLayoutConstraint(
        item: view,
        attribute: NSLayoutAttribute.Width,
        relatedBy: NSLayoutRelation.Equal,
        toItem: root,
        attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: 0
      ))
    default:
      view = UIView()
      view.clipsToBounds = true
      enqueueConstraint(NSLayoutConstraint(
        item: view,
        attribute: NSLayoutAttribute.Top,
        relatedBy: NSLayoutRelation.Equal,
        toItem: root,
        attribute: NSLayoutAttribute.Top, multiplier: 1.0, constant: 0
      ))
      enqueueConstraint(NSLayoutConstraint(
        item: view,
        attribute: NSLayoutAttribute.Bottom,
        relatedBy: NSLayoutRelation.Equal,
        toItem: root,
        attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: 0
      ))
      enqueueConstraint(NSLayoutConstraint(
        item: view,
        attribute: NSLayoutAttribute.Left,
        relatedBy: NSLayoutRelation.Equal,
        toItem: root,
        attribute: NSLayoutAttribute.Left, multiplier: 1.0, constant: 0
      ))
      enqueueConstraint(NSLayoutConstraint(
        item: view,
        attribute: NSLayoutAttribute.Right,
        relatedBy: NSLayoutRelation.Equal,
        toItem: root,
        attribute: NSLayoutAttribute.Right, multiplier: 1.0, constant: 0
      ))
//      view.backgroundColor = UIColor.redColor()
    }
    view.translatesAutoresizingMaskIntoConstraints = false

    root.addSubview(view)
    if let children = tree.valueForProperty("children") {
      let length = children.valueForProperty("length").toNumber() as Int
      for i in 0..<length {
        let child = children.objectAtIndexedSubscript(i)
        create(view, tree: child)
      }
    }
    //view.sizeToFit()
  }
}
