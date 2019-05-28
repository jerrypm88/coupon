import AppKit
import Foundation

final class AccessibilityElement {
    static let systemWideElement = AccessibilityElement.createSystemWideElement()

    var position: CGPoint? {
        get {
            let prePos: CGPoint = Mouse.currentPosition()
            self.getUrl(prePos: prePos)
            return self.getPosition()
        }
        set {
            if let position = newValue {
                self.set(position: position)
            }
        }
    }

    var size: CGSize? {
        get {
            let prePos: CGPoint = Mouse.currentPosition()
            self.getUrl(prePos: prePos)
            return self.getSize()
        }
        set {
            if let size = newValue {
                self.set(size: size)
            }
        }
    }

    private let elementRef: AXUIElement

    init(elementRef: AXUIElement) {
        self.elementRef = elementRef
    }

    func element(at point: CGPoint) -> Self? {
        var ref: AXUIElement?
        AXUIElementCopyElementAtPosition(self.elementRef, Float(point.x), Float(point.y), &ref)
        return ref.map(type(of: self).init)
    }

    func window() -> Self? {
        var element = self
        while element.role() != kAXWindowRole {
            if let nextElement = element.parent() {
                element = nextElement
            } else {
                return nil
            }
        }

        return element
    }

    func parent() -> Self? {
        return self.value(for: .parent)
    }

    func role() -> String? {
        return self.value(for: .role)
    }

    func pid() -> pid_t? {
        let pointer = UnsafeMutablePointer<pid_t>.allocate(capacity: 1)
        let error = AXUIElementGetPid(self.elementRef, pointer)
        return error == .success ? pointer.pointee : nil
    }

    func bringToFront() {
        if let isMainWindow = self.rawValue(for: .main) as? Bool, isMainWindow
        {
            return
        }

        AXUIElementSetAttributeValue(self.elementRef,
                                     NSAccessibilityAttributeName.main.rawValue as CFString,
                                     true as CFTypeRef)
    }

    //pm add function
    func getTitle() -> String? {
        var title : String?
        title = self.value(for: .title)
         
        if title != nil {
            print(title!);
        }
        return self.value(for: .title)
    }
    
    func getUrl(prePos point :CGPoint) -> String? {
        var ref: AXUIElement?
        AXUIElementCopyElementAtPosition(AXUIElementCreateSystemWide(), Float(point.x), Float(point.y), &ref)
      
        if let url /*: String?*/ =  self.value(for: .window, target: ref){
            print("window:\(url)")
        }
        
        if let url /*: String?*/ =  self.value(for: .description, target: ref){
            print("des:\(url)")
        }
        
        if let url =  self.value(for: .contents, target: ref){
             print("contents:\(url)")
        }
        
        if let url  =  self.value(for: .url, target: ref){
            print("url:\(url)")
        }
        
        if let url  =  self.value(for: .value, target: ref){
            print("value:\(url)")
        }

        return nil
    }
    
    // MARK: - Private functions

    private static func createSystemWideElement() -> Self {
        return self.init(elementRef: AXUIElementCreateSystemWide())
    }

    private func getPosition() -> CGPoint? {
        return self.value(for: .position)
    }

    private func set(position: CGPoint) {
        if let value = AXValue.from(value: position, type: .cgPoint) {
            AXUIElementSetAttributeValue(self.elementRef, kAXPositionAttribute as CFString, value)
        }
    }

    private func getSize() -> CGSize? {
        return self.value(for: .size)
    }

    private func set(size: CGSize) {
        if let value = AXValue.from(value: size, type: .cgSize) {
            AXUIElementSetAttributeValue(self.elementRef, kAXSizeAttribute as CFString, value)
        }
    }

    private func rawValue(for attribute: NSAccessibilityAttributeName, target element: AXUIElement? = nil) -> AnyObject? {
        var rawValue: AnyObject?
        let error = AXUIElementCopyAttributeValue(element ?? self.elementRef, attribute.rawValue as CFString, &rawValue)
        return error == .success ? rawValue : nil
    }

    private func value(for attribute: NSAccessibilityAttributeName,element: AXUIElement? = nil) -> Self? {
        if let rawValue = self.rawValue(for: attribute, target: element ?? self.elementRef), CFGetTypeID(rawValue) == AXUIElementGetTypeID() {
            return type(of: self).init(elementRef: rawValue as! AXUIElement)
        }

        return nil
    }

    private func value(for attribute: NSAccessibilityAttributeName,target element: AXUIElement? = nil) -> String? {
        return self.rawValue(for: attribute, target: element ?? self.elementRef) as? String
    }

    private func value<T>(for attribute: NSAccessibilityAttributeName, target element: AXUIElement? = nil) -> T? {
        if let rawValue = self.rawValue(for: attribute, target: element ?? self.elementRef), CFGetTypeID(rawValue) == AXValueGetTypeID() {
            return (rawValue as! AXValue).toValue()
        }

        return nil
    }
}
