//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Context Propagation open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift Baggage Context project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
import Darwin
#else
import Glibc
#endif

// ==== ----------------------------------------------------------------------------------------------------------------
// MARK: CountDownLatch

internal class CountDownLatch {
    private var counter: Int
    private let condition: _Condition
    private let lock: _Mutex

    init(from: Int) {
        self.counter = from
        self.condition = _Condition()
        self.lock = _Mutex()
    }

    /// Returns previous value before the decrement was issued.
    func countDown() {
        self.lock.synchronized {
            self.counter -= 1

            if self.counter == 0 {
                self.condition.signalAll()
            }
        }
    }

    var count: Int {
        return self.lock.synchronized {
            self.counter
        }
    }

    func wait() {
        self.lock.synchronized {
            while true {
                if self.counter == 0 {
                    return // done
                }

                self.condition.wait(lock)
            }
        }
    }
}

extension CountDownLatch: CustomStringConvertible {
    public var description: String {
        return "CountDownLatch(remaining:\(self.count)"
    }
}

// ==== ----------------------------------------------------------------------------------------------------------------
// MARK: Condition

final class _Condition {
    @usableFromInline
    var condition: pthread_cond_t = pthread_cond_t()

    public init() {
        let error = pthread_cond_init(&self.condition, nil)

        switch error {
        case 0:
            return
        default:
            fatalError("Condition could not be created: \(error)")
        }
    }

    deinit {
        pthread_cond_destroy(&condition)
    }

    @inlinable
    public func wait(_ mutex: _Mutex) {
        let error = pthread_cond_wait(&self.condition, &mutex.mutex)

        switch error {
        case 0:
            return
        case EPERM:
            fatalError("Wait failed, mutex is not owned by this thread")
        case EINVAL:
            fatalError("Wait failed, condition is not valid")
        default:
            fatalError("Wait failed with unspecified error: \(error)")
        }
    }

//    @inlinable
//    public func wait(_ mutex: _Mutex) -> Bool {
//        let error = withUnsafePointer(to: time) { p -> Int32 in
//            #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
//            return pthread_cond_timedwait_relative_np(&condition, &mutex.mutex, p)
//            #else
//            return pthread_cond_timedwait(&condition, &mutex.mutex, p)
//            #endif
//        }
//
//        switch error {
//        case 0:
//            return true
//        case ETIMEDOUT:
//            return false
//        case EPERM:
//            fatalError("Wait failed, mutex is not owned by this thread")
//        case EINVAL:
//            fatalError("Wait failed, condition is not valid")
//        default:
//            fatalError("Wait failed with unspecified error: \(error)")
//        }
//    }

    @inlinable
    public func signal() {
        let error = pthread_cond_signal(&self.condition)

        switch error {
        case 0:
            return
        case EINVAL:
            fatalError("Signal failed, condition is not valid")
        default:
            fatalError("Signal failed with unspecified error: \(error)")
        }
    }

    @inlinable
    public func signalAll() {
        let error = pthread_cond_broadcast(&self.condition)

        switch error {
        case 0:
            return
        case EINVAL:
            fatalError("Signal failed, condition is not valid")
        default:
            fatalError("Signal failed with unspecified error: \(error)")
        }
    }
}

// ==== ----------------------------------------------------------------------------------------------------------------
// MARK: Mutex

final class _Mutex {
    @usableFromInline
    var mutex: pthread_mutex_t = pthread_mutex_t()

    public init() {
        var attr: pthread_mutexattr_t = pthread_mutexattr_t()
        pthread_mutexattr_init(&attr)
        pthread_mutexattr_settype(&attr, Int32(PTHREAD_MUTEX_RECURSIVE))

        let error = pthread_mutex_init(&self.mutex, &attr)
        pthread_mutexattr_destroy(&attr)

        switch error {
        case 0:
            return
        default:
            fatalError("Could not create mutex: \(error)")
        }
    }

    deinit {
        pthread_mutex_destroy(&mutex)
    }

    @inlinable
    public func lock() {
        let error = pthread_mutex_lock(&self.mutex)

        switch error {
        case 0:
            return
        case EDEADLK:
            fatalError("Mutex could not be acquired because it would have caused a deadlock")
        default:
            fatalError("Failed with unspecified error: \(error)")
        }
    }

    @inlinable
    public func unlock() {
        let error = pthread_mutex_unlock(&self.mutex)

        switch error {
        case 0:
            return
        case EPERM:
            fatalError("Mutex could not be unlocked because it is not held by the current thread")
        default:
            fatalError("Unlock failed with unspecified error: \(error)")
        }
    }

    @inlinable
    public func tryLock() -> Bool {
        let error = pthread_mutex_trylock(&self.mutex)

        switch error {
        case 0:
            return true
        case EBUSY:
            return false
        case EDEADLK:
            fatalError("Mutex could not be acquired because it would have caused a deadlock")
        default:
            fatalError("Failed with unspecified error: \(error)")
        }
    }

    @inlinable
    public func synchronized<A>(_ f: () -> A) -> A {
        self.lock()

        defer {
            unlock()
        }

        return f()
    }

    @inlinable
    public func synchronized<A>(_ f: () throws -> A) throws -> A {
        self.lock()

        defer {
            unlock()
        }

        return try f()
    }
}
