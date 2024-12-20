//
// LilySwift Library Project
//
// Copyright (c) Watanabe-Denki, Inc. and Kengo Watanabe.
//   https://wdkk.co.jp/
//
// This software is released under the MIT License.
//   https://opensource.org/licenses/mit-license.php
//

/// コメント未済
import Foundation

open class LLTask
{
    open class Async
    {
        @Sendable
        public static func main( _ f: @Sendable @escaping () -> () ) {
            DispatchQueue.main.async( execute: f )
        }
             
        @Sendable
        public static func main( waitSec: Double, _ f: @Sendable @escaping () -> () ) {
            let delay_time:DispatchTime = DispatchTime.now() + (waitSec * NSEC_PER_SEC.d) / NSEC_PER_SEC.d
            DispatchQueue.main.asyncAfter( deadline: delay_time, execute: f )
        }
        
        @Sendable
        public static func sub( quality:DispatchQoS = .default, _ f: @Sendable @escaping () -> () ) {
            DispatchQueue.global( qos: quality.qosClass ).async( execute: f )
        }

        @Sendable
        public static func sub( waitSec: Double, quality:DispatchQoS = .default, _ f: @Sendable @escaping () -> () ) {
            let delay_time:DispatchTime = DispatchTime.now() + (waitSec * NSEC_PER_SEC.d) / NSEC_PER_SEC.d
            DispatchQueue.global( qos: quality.qosClass ).asyncAfter( deadline: delay_time, execute: f )
        }
    }
    
    open class Sync
    {
        @Sendable
        public static func main( _ f: @Sendable @escaping () -> () ) {
            DispatchQueue.main.sync( execute: f )
        }

        @Sendable
        public static func main( waitSec:Double, _ f: @Sendable @escaping () -> () ) {
            DispatchQueue.main.sync {
                LLSystem.wait( waitSec * 1000.0 )
                f()
            }
        }

        @Sendable
        public static func sub( quality:DispatchQoS = .default, _ f: @escaping () -> () ) {
            DispatchQueue.global( qos: quality.qosClass ).sync( execute: f )
        }

        @Sendable
        public static func sub( waitSec:Double, quality:DispatchQoS = .default, _ f: @escaping () -> () ) {
            DispatchQueue.global( qos: quality.qosClass ).sync {
                LLSystem.wait( waitSec * 1000.0 )
                f()
            }
        }    
    }
}
