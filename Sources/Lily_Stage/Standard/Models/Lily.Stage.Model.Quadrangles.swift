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

import Metal

extension Lily.Stage.Model
{
    // 四角形メッシュ形状メモリクラス
    public class Quadrangles<VerticeType> 
    : Shape<LLQuad<VerticeType>> 
    {
    }
}

#endif
