//
//  Dispatch_After.swift
//  creams
//
//  Created by Rawlings on 07/12/2016.
//  Copyright © 2016 jiangren. All rights reserved.
//

import Foundation

typealias DelayTask = (_ cancel: Bool) -> Void

@discardableResult
func Delay(time: TimeInterval, task:@escaping () -> Void) -> DelayTask? {

    func dispatch_later(block:@escaping () -> Void) {
        let deadlineTime = DispatchTime.now() + time
        DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: block)
    }

    var closure: (() -> Void)? = task
    var result: DelayTask?

    let delayedClosure: DelayTask = { cancel in
        if let internalClosure = closure {
            if !cancel {
                DispatchQueue.main.async(execute: internalClosure)
            }
        }
        closure = nil
        result = nil
    }

    result = delayedClosure

    dispatch_later {
        if let delayedClosure = result {
            delayedClosure(false)
        }
    }

    return result
}

func Cancel(task: DelayTask?) {
    task?(true)
}
