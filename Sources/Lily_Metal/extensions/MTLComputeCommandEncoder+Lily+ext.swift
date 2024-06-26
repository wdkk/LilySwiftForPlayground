//
// LilySwift Library Project
//
// Copyright (c) Watanabe-Denki, Inc. and Kengo Watanabe.
//   https://wdkk.co.jp/
//
// This software is released under the MIT License.
//   https://opensource.org/licenses/mit-license.php
//

#if !os(watchOS)

/// コメント未済

import Metal

extension MTLComputeCommandEncoder
{
    public func setBuffer( _ buffer:MTLBuffer, index idx:Int ) {
        self.setBuffer( buffer, offset: 0, index: idx )
    }
    
    public func setBuffer<T:MetalBufferAllocatable>( 
        _ obj:T, 
        offset:Int = 0,
        index idx:Int 
    ) 
    {
        self.setBuffer( obj.metalBuffer, offset: offset, index: idx )
    }
}

#endif
