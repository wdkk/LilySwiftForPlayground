//
// LilySwift Library Project
//
// Copyright (c) Watanabe-Denki, Inc. and Kengo Watanabe.
//   https://wdkk.co.jp/
//
// This software is released under the MIT License.
//   https://opensource.org/licenses/mit-license.php
//

import Metal
import simd

extension Lily.Stage.Playground3D
{
    open class ModelLightingRenderer
    : Lily.Stage.LightingRenderer
    {           
        public override init( device:MTLDevice, viewCount:Int ) {
            super.init( device:device, viewCount:viewCount )

            // Mipsを活用するためにKTXフォーマットを使う
            skyCubeMap = try! Lily.Metal.Texture.create( device:device, assetName:"skyCubeMap" )!
                .makeTextureView( pixelFormat:.rgba8Unorm_srgb )
        }
    }
}
