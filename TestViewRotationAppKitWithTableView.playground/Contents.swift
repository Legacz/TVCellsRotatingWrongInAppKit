//: A Cocoa based Playground to present user interface

import AppKit
import PlaygroundSupport

let arrangedObjects : [ NSColor ] = [
  .purple,
  .green, .red, .blue
]


// MARK: - Animation

fileprivate let animRotationKey = "de.zeezide.view.rotation"

public struct ZzViewAnimations {
  // Trampoline
  
  let view : NSView
  
  init(view : NSView) {
    self.view = view
  }
  
  public enum Direction {
    case forward, backward
  }
  
  var animationLayer : CALayer? {
    guard let layer = view.layer else {
      print("view got no (root) layer ...")
      return nil
    }
    return layer.sublayers?.first
  }
  
  public func startRotation(speed     : TimeInterval = 1.0,
                            direction : Direction = .backward)
  {
    guard let rootLayer = view.layer else {
      print("\(#function): view got no layer ...")
      return
    }
    
    let layer : CALayer = {
      if let layer = animationLayer { return layer }
      
      let layer = CALayer()
      layer.frame            = rootLayer.bounds
      layer.autoresizingMask = [ .layerHeightSizable, .layerWidthSizable ]
      layer.anchorPoint      = CGPoint(x: 0.5, y: 0.5)
      // layer.position      = center
      rootLayer.addSublayer(layer)
      
      layer.backgroundColor = rootLayer.backgroundColor
      layer.borderColor     = NSColor.white.cgColor // rootLayer.borderColor
      layer.borderWidth     = 1 //rootLayer.borderWidth
      layer.contents        = rootLayer.contents

      return layer
    }()
    

    let fakeRepeat : Float = 10000
    
    let a = CABasicAnimation()
    a.keyPath      = "transform.rotation.z"
    a.toValue      = .pi * 2.0 * fakeRepeat * -1.0
    a.duration     = speed     * TimeInterval(fakeRepeat)
    a.isCumulative = true
    a.repeatCount  = 1 // 10
    
    #if os(macOS)
      layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
      //layer.position    = CGPoint(x: NSMidX(view.frame), y: NSMidY(view.frame))
        // center
    #endif
    
    print("start anim \(view.identifier?.rawValue ?? "") \(layer.position) ..")

    if let pos = layer.value(forKeyPath: "transform.rotation.z") as? Float {
      // this is close but wrong. essentially we repeatly start from the
      // stopped position
      // we can simulate this using the pos forward a lot instead of using
      // repeat, but that isn't cool. rather find a way to do 'repeat'
      a.fromValue = pos
      a.toValue   = pos + .pi * 2.0 * fakeRepeat * -1.0
    }
    
    layer.add(a, forKey: animRotationKey)
  }
  
  func stopRotation() {
    print("stop anim \(view.identifier?.rawValue ?? "")")
    
    guard let rootLayer = view.layer else {
      print("\(#function): view got no layer ...")
      return
    }
    guard let layer = animationLayer else {
      print("\(#function): view got no layer ...")
      return
    }
    
    let pos = layer.presentation()?.value(forKeyPath: "transform.rotation.z")
    layer.removeAnimation(forKey: animRotationKey)
    if let pos = pos {
      layer    .setValue(pos, forKeyPath: "transform.rotation.z")
      rootLayer.setValue(pos, forKeyPath: "transform.rotation.z")
      // in here we just get radians, it doesn't add up (*repeat)
    }
    
    layer.removeFromSuperlayer()
  }
  
}
public extension NSView {
  
  public var uxAnim : ZzViewAnimations { return ZzViewAnimations(view: self) }
  
  public var center: CGPoint { // on UIKit this can be set, can we emulate this?
    return CGPoint(x: NSMidX(frame), y: NSMidY(frame))
  }
}


// MARK: - LayerView

class LayerView : NSView {
  override init(frame: CGRect) {
    super.init(frame: frame)
    wantsLayer = true
  }
  required init?(coder decoder: NSCoder) {
    fatalError("\(#function) has not been implemented")
  }
  
  var backgroundColor : NSColor? = nil {
    didSet {
      layer?.backgroundColor = backgroundColor?.cgColor
    }
  }

}


// MARK: - HostView

let hostView = LayerView(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
hostView.backgroundColor = .lightGray
PlaygroundPage.current.liveView = hostView


// MARK: - TableView

class TVDelegate : NSObject, NSTableViewDelegate {
  open func tableView(_ tv: NSTableView, heightOfRow row: Int) -> CGFloat {
    return 42
  }
  open func tableView(_ tv: NSTableView, shouldSelectRow row: Int) -> Bool {
    return false
  }
  
  open func tableView(_ tv: NSTableView,
                      viewFor tc: NSTableColumn?,
                      row: Int) -> NSView?
  {
    let cell = LayerView(frame: CGRect(x:100, y:100, width: 80, height: 40))
    cell.identifier = NSUserInterfaceItemIdentifier("Cell[\(row)]")
    
    cell.uxAnim.startRotation(speed: 5)
    
    cell.backgroundColor = arrangedObjects[row]
    //cell.onClick(ch, action: #selector(ClickHandler.onClick(_:)))
    return cell
  }
}

class DataSource : NSObject, NSTableViewDataSource {
  open func numberOfRows(in tableView: NSTableView) -> Int {
    return arrangedObjects.count
  }
  open func tableView(_ tv: NSTableView,
                      objectValueFor tc: NSTableColumn?, row: Int) -> Any?
  {
    return arrangedObjects[row]
  }
}

class MyTableView : NSTableView {
}

class MyTableVC : NSViewController {
  
  let d  = TVDelegate()
  let ds = DataSource()
  
  override func loadView() {
    let tv : NSTableView = {
      let tv = MyTableView()
      tv.headerView              = nil
      tv.floatsGroupRows         = false // Sidebar has NO
      tv.rowSizeStyle            = .default
      tv.allowsColumnResizing    = false
      tv.columnAutoresizingStyle = .firstColumnOnlyAutoresizingStyle
      
      // this is what Sidebar (IB?) does
      tv.layerContentsRedrawPolicy = .onSetNeedsDisplay
      
      let tc = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("id"))
      tc.title = "Hello"
      tc.isEditable = false

      tv.addTableColumn(tc)
      tv.sizeLastColumnToFit()

      tv.dataSource = ds
      tv.delegate   = d
      
      return tv
    }()
    
    let sv : NSScrollView = {
      let sv = NSScrollView(frame: CGRect(x: 0, y: 0, width: 200, height: 400))
      sv.usesPredominantAxisScrolling = false // YES by default
      sv.autohidesScrollers           = true // default NO
      sv.hasHorizontalScroller        = true
      sv.hasVerticalScroller          = true
      sv.documentView                 = tv
      return sv
    }()

    sv.frame = CGRect(x: 0, y: 0, width: 200, height: 400)
    view = sv
    
    self.title = "Table"
  }
}

let tableVC = MyTableVC()
let tableVC2 = MyTableVC()
tableVC2.view.frame = CGRect(x: 200, y: 0, width: 200, height: 400)


class MyEmptyVC : NSViewController {
  override func loadView() {
    let view = LayerView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
    view.backgroundColor = .red
    self.view = view
    
    self.title = "Empty"
  }
}

let emptyVC = MyEmptyVC()

let tabVC = NSTabViewController()
tabVC.addChildViewController(emptyVC)
tabVC.addChildViewController(tableVC)

tabVC.view.frame = CGRect(x: 0, y: 0, width: 200, height: 400)
hostView.addSubview(tabVC.view)

hostView.addSubview(tableVC2.view)
