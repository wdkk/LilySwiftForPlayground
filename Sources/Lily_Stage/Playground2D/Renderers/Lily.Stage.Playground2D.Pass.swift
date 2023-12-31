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
import MetalKit
import simd

extension Lily.Stage.Playground2D
{
    open class Pass
    { 
        var device:MTLDevice
        var commandQueue:MTLCommandQueue?
        
        public var passDesc:MTLRenderPassDescriptor?
        public var depthState:MTLDepthStencilState?
        
        public init( device:MTLDevice ) {
            self.device = device
            // レンダーパスの準備
            passDesc = .make {
                $0.depthAttachment
                .action( load:.clear, store:.store )
                .clearDepth( 0.0 )
                
                #if !targetEnvironment(simulator)
                $0.colorAttachments[0].action( load:.clear, store:.dontCare ).clearColor( .darkGrey )
                #else
                // シミュレータはテクスチャを保存する
                $0.colorAttachments[0].action( load:.clear, store:.store ).clearColor( .darkGrey )
                #endif
                // colorAttachments[1]が毎フレームのバックバッファの受け取り口
                $0.colorAttachments[1].action( load:.clear, store:.store ).clearColor( .darkGrey )
            }
            
            // Depth stateの作成
            depthState = device.makeDepthStencilState( descriptor:.make {
                $0
                .depthCompare( .greaterEqual )
                .depthWriteEnabled( true )
            } )
        }
        
        // 公開ファンクション
        public func updatePass(
            mediumTextures:MediumTexture,
            rasterizationRateMap:Lily.Metal.RasterizationRateMap?,
            renderTargetCount:Int
        )
        {
            passDesc?.colorAttachments[0].texture = mediumTextures.particleTexture
            #if !targetEnvironment(macCatalyst)
            passDesc?.rasterizationRateMap = rasterizationRateMap
            #endif
            #if os(visionOS)
            passDesc?.renderTargetArrayLength = renderTargetCount
            #endif
        }
        
        public func setDestination( texture:MTLTexture? ) {
            passDesc?.colorAttachments[1].texture = texture
        }
        
        public func setDepth( texture:MTLTexture? ) {
            passDesc?.depthAttachment.texture = texture
        }
        
        public func setClearColor( _ color:LLColor? ) {
            guard let color = color else {
                passDesc?.colorAttachments[0].clearColor( .clear )
                #if !targetEnvironment(simulator)
                passDesc?.colorAttachments[0].action( load:.load, store:.dontCare )
                #else
                passDesc?.colorAttachments[0].action( load:.load, store:.store )
                #endif
                return
            }
            passDesc?.colorAttachments[0].clearColor( color )
            #if !targetEnvironment(simulator)
            passDesc?.colorAttachments[0].action( load:.clear, store:.dontCare )
            #else
            passDesc?.colorAttachments[0].action( load:.clear, store:.store )
            #endif
        }
        
        public func setClearColor( _ color:MTLClearColor ) {
            passDesc?.colorAttachments[0].clearColor( color )
            #if !targetEnvironment(simulator)
            passDesc?.colorAttachments[0].action( load:.clear, store:.dontCare )
            #else
            passDesc?.colorAttachments[0].action( load:.clear, store:.store )
            #endif
        }
    }
}
