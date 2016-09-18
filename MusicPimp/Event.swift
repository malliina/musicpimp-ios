//
//  Event.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 01/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//
//  See http://blog.scottlogic.com/2015/02/05/swift-events.html

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

//class CompositeDisposable<T: Disposable> {
//    let inners: [T]
//    init(inners: [T]) {
//        self.inners = inners
//    }
//    func dispose() {
//        for inner in inners {
//            inner.dispose()
//        }
//    }
//}

private protocol Invocable: class {
    func invoke(_ data: Any)
}

