//
//  VPOperation.swift
//  VeracitySDK
//
//  Created by Andrew on 24/05/2019.
//

import Foundation

///Base operation parent class with all the boilerplate code in. Subclassers need only override `main` but they are required to call `executing` before and after executing & `finished` after operation finish.
open class VPOperation: Operation {
    ///If used, there must be called operation's `endOperation()` at end.
    ///Extends operation `main` func before finishing itself.
    ///Primary used to get & persist any data from operation's `main` before finishing.
    public var finishingBlock : (() -> ())?
    public var progressCallback : UploadProgressHandlerBlock?
    
    private var _executing = false {
        willSet {
            willChangeValue(forKey: "isExecuting")
        }
        didSet {
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    override open var isExecuting: Bool {
        return _executing
    }
    
    private var _finished = false {
        willSet {
            willChangeValue(forKey: "isFinished")
        }
        
        didSet {
            didChangeValue(forKey: "isFinished")
        }
    }
    
    override open var isFinished: Bool {
        return _finished
    }
    
    ///Sets executing state to given value.
    ///Suclasses must call this before and after execution inside `main` operation func.
    /// - Parameter executing: Bool value indicating current state of execution. Use `true` before and `false` after the execution.
    public func executing(_ executing: Bool) {
        _executing = executing
    }
    
    ///Sets finish state to given value.
    ///Subclasses must call this after execution is finished inside `main` operation func.
    /// - Parameter finished: Bool value inidcating finished state if `true`.
    public func finish(_ finished: Bool) {
        _finished = finished
    }
    
    ///Sets executing state to false & finish state to true.
    ///Subclasses must call this after execution is finished inside `finishigBlock` only if was used.
    public func endOperation() {
        executing(false)
        finish(true)
    }
    
    ///Will try to finish itself by given `finishingBlock` if there is any. Otherwise it will call `endOperation`
    ///See also `endOperation`.
    public func finishOperation() {
        if let finishingBlock = finishingBlock {
            finishingBlock()
        }else {
            endOperation()
        }
    }
}

