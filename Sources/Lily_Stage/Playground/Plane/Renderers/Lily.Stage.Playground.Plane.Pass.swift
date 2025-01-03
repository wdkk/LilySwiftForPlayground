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

import MetalKit
import simd

extension Lily.Stage.Playground.Plane
{
    open class Pass
    { 
        var device:MTLDevice
        
        public var passDesc:MTLRenderPassDescriptor?
        public var depthState:MTLDepthStencilState?
        
        public init( device:MTLDevice ) {
            self.device = device
            // レンダーパスの準備
            passDesc = .make {
                // Planeはそれ以前のdepthを無視して行うので一度1.0クリアする
                $0.depthAttachment.action( load:.clear, store:.store ).clearDepth( 1.0 )
                // 途中結果はテクスチャに落とすことにしたので、ロードしてストアする
                $0.colorAttachments[0].action( load:.load, store:.store )
                // colorAttachments[1]が毎フレームのバックバッファの受け取り口
                $0.colorAttachments[1].action( load:.load, store:.store )
            }
            
            // Depth stateの作成
            depthState = device.makeDepthStencilState( descriptor:.make {
                $0
                .depthCompare( .lessEqual )
                .depthWriteEnabled( true )
            } )
        }
        
        // 公開ファンクション
        public func updatePass(
            mediumResource:Lily.Stage.Playground.MediumResource,
            rasterizationRateMap:Lily.Metal.RasterizationRateMap?,
            renderTargetViewIndex:Int
        )
        {
            passDesc?.colorAttachments[0].texture = mediumResource.resultTexture
            #if !targetEnvironment(macCatalyst)
            passDesc?.rasterizationRateMap = rasterizationRateMap
            #endif
            #if os(visionOS)
            passDesc?.renderTargetArrayLength = renderTargetViewIndex
            #endif
        }
        
        public func setDestination( texture:MTLTexture? ) {
            passDesc?.colorAttachments[1].texture = texture
        }
        
        public func setDepth( texture:MTLTexture? ) {
            passDesc?.depthAttachment.texture = texture
        }
    }
}

#endif
