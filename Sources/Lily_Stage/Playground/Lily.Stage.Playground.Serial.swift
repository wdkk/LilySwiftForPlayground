//
// LilySwift Library Project
//
// Copyright (c) Watanabe-Denki, Inc. and Kengo Watanabe.
//   https://wdkk.co.jp/
//
// This software is released under the MIT License.
//   https://opensource.org/licenses/mit-license.php
//

// コメント未着手

import Foundation

extension Lily.Stage.Playground
{
    open class Serial
    {
        public static let shared:Serial = Serial()
        private init() { }
        
        private var semaphore = DispatchSemaphore( value:1 )
        
        open func serialize( _ f:@escaping ()->() ) {
            _ = semaphore.wait( timeout:.distantFuture )
            f()
            semaphore.signal()
        }
    }
}
