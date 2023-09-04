
import Foundation

open class Event<T> {
    
    public typealias EventHandler = (T) -> ()
    
    fileprivate var eventHandlers = [Invocable]()
    
    open func raise(_ data: T) {
        for handler in self.eventHandlers {
            handler.invoke(data)
        }
    }
    
    open func addHandler<U: AnyObject>(_ target: U,
        handler: @escaping (U) -> EventHandler) -> Disposable {
            let wrapper = EventHandlerWrapper(target: target,
                handler: handler, event: self)
            eventHandlers.append(wrapper)
            return wrapper
    }
    
    func first<U: AnyObject>(_ target: U, handler: @escaping (U) -> EventHandler) -> Disposable {
        let wrapper = OneTimeSubscription(target: target, handler: handler, event: self)
        eventHandlers.append(wrapper)
        return wrapper
    }
}

private class OneTimeSubscription<T: AnyObject, U>: EventHandlerWrapper<T, U> {
    override func invoke(_ data: Any) {
        super.invoke(data)
        dispose()
    }
}

private class EventHandlerWrapper<T: AnyObject, U> : Invocable, Disposable {
    weak var target: T?
    let handler: (T) -> (U) -> ()
    let event: Event<U>
    
    init(target: T?, handler: @escaping (T) -> (U) -> (), event: Event<U>) {
        self.target = target
        self.handler = handler
        self.event = event;
    }
    
    func invoke(_ data: Any) -> () {
        if let t = target {
            handler(t)(data as! U)
        }
    }
    
    func dispose() {
        event.eventHandlers =
            event.eventHandlers.filter { $0 !== self }
    }
}

private protocol Invocable: class {
    func invoke(_ data: Any)
}

