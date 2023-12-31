//
// LilySwift Library Project
//
// Copyright (c) Watanabe-Denki Inc. and Kengo Watanabe.
//   https://wdkk.co.jp/
//
// This software is released under the MIT License.
//   https://opensource.org/licenses/mit-license.php
//

import Metal

extension Lily.Stage.Playground2D
{
    public class PGBlurryCircle : PGActor
    {        
        @discardableResult
        public override init( pool:PGPool = PGPool.current! ) {
            super.init( pool:pool )
            status.shapeType = .blurryCircle
            status.compositeType = .alpha
        }
    }
    
    public class PGAddBlurryCircle : PGActor
    {        
        @discardableResult
        public override init( pool:PGPool = PGPool.current! ) {
            super.init( pool:pool )
            status.shapeType = .blurryCircle
            status.compositeType = .add
        }
    }
    
    public class PGSubBlurryCircle : PGActor
    {        
        @discardableResult
        public override init( pool:PGPool = PGPool.current! ) {
            super.init( pool:pool )
            status.shapeType = .blurryCircle
            status.compositeType = .sub
        }
    }
}
