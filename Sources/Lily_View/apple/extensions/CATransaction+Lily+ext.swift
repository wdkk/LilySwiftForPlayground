//
// LilySwift Library Project
//
// Copyright (c) Watanabe-Denki, Inc. and Kengo Watanabe.
//   https://wdkk.co.jp/
//
// This software is released under the MIT License.
//   https://opensource.org/licenses/mit-license.php
//

import Foundation
#if canImport(QuartzCore)
import QuartzCore
#endif

#if canImport(QuartzCore)
public extension CATransaction
{
    static func stop( _ f: ()->() ) {
        CATransaction.begin()
        //CATransaction.setValue( kCFBooleanTrue, forKey: kCATransactionDisableActions )
        CATransaction.setDisableActions( true )
        
        f()
        
        CATransaction.commit()
    }
}
#endif
