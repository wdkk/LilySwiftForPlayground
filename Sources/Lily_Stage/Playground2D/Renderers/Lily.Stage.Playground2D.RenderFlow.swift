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

extension Lily.Stage.Playground2D
{
    open class RenderFlow
    : Lily.Stage.BaseRenderFlow
    {
        var pass:Lily.Stage.Playground2D.Pass?
        var mediumTextures:Lily.Stage.Playground2D.MediumTexture
        
        public private(set) var pool:PGPool
        public private(set) var storage:Storage
        
        var alphaRenderer:AlphaRenderer?
        var addRenderer:AddRenderer?
        var subRenderer:SubRenderer?
        
        var sRGBRenderer:SRGBRenderer?
        
        public let viewCount:Int
        
        public var clearColor:LLColor = .white
        
        public private(set) var screenSize:CGSize = .zero
        public private(set) var particleCapacity:Int
        
        public init(
            device:MTLDevice,
            viewCount:Int,
            environment:Lily.Stage.ShaderEnvironment = .metallib,
            particleCapacity:Int = 10000,
            textures:[String] = []
        ) 
        {
            self.pass = .init( device:device )
            self.viewCount = viewCount
            self.particleCapacity = particleCapacity
            
            self.mediumTextures = .init( device:device )
            
            // レンダラーの作成
            self.alphaRenderer = .init( 
                device:device,
                environment:environment,
                viewCount:viewCount
            )
            self.addRenderer = .init( 
                device:device,
                environment:environment,
                viewCount:viewCount
            )
            self.subRenderer = .init( 
                device:device,
                environment:environment,
                viewCount:viewCount
            )
            
            self.sRGBRenderer = .init( 
                device:device,
                environment:environment,
                viewCount:viewCount
            )
            
            self.storage = .init( 
                device:device, 
                capacity:particleCapacity
            )
            self.storage.addTextures( textures )
            
            self.pool = PGPool()
            self.pool.storage = self.storage
        
            super.init( device:device )
            
            PGPool.current = pool
        }
        
        public override func changeSize( scaledSize:CGSize ) {
            screenSize = scaledSize
            screenSize.width /= LLSystem.retinaScale
            screenSize.height /= LLSystem.retinaScale
            
            mediumTextures.updateBuffers( size:scaledSize, viewCount:viewCount )
        }
        
        public override func render(
            commandBuffer:MTLCommandBuffer,
            rasterizationRateMap:Lily.Metal.RasterizationRateMap?,
            viewports:[MTLViewport],
            viewCount:Int,
            destinationTexture:MTLTexture?,
            depthTexture:MTLTexture?,
            uniforms:Lily.Metal.RingBuffer<Lily.Stage.Shared.GlobalUniformArray>
        )
        {
            guard let pass = self.pass else { return }
        
            PGPool.current?.storage?.statuses?.update { acc, _ in
                for i in 0 ..< acc.count {
                    if acc[i].enabled == false || acc[i].state == .trush { continue }
                    acc[i].position += acc[i].deltaPosition
                    acc[i].scale += acc[i].deltaScale
                    acc[i].angle += acc[i].deltaAngle
                    acc[i].color += acc[i].deltaColor
                    acc[i].life += acc[i].deltaLife
                }
            }
            
            // 共通処理
            pass.updatePass( 
                mediumTextures:mediumTextures,
                rasterizationRateMap:rasterizationRateMap,
                renderTargetCount:viewCount        
            )
            
            // フォワードレンダリング : パーティクルの描画の設定
            pass.setDestination( texture:destinationTexture )
            pass.setDepth( texture:depthTexture )
            pass.setClearColor( self.clearColor )
            
            let encoder = commandBuffer.makeRenderCommandEncoder( descriptor:pass.passDesc! )
            
            encoder?
            .label( "Playground 2D Render" )
            .cullMode( .none )
            .frontFacing( .counterClockwise )
            .depthStencilState( pass.depthState! )
            .viewports( viewports )
            .vertexAmplification( count:viewCount, viewports:viewports )
            
            // Playground2Dレンダー描画
            alphaRenderer?.draw(
                with:encoder,
                globalUniforms:uniforms,
                mediumTextures:mediumTextures,
                storage:storage,
                screenSize:screenSize
            )
            
            alphaRenderer?.drawTriangle(
                with:encoder,
                globalUniforms:uniforms,
                mediumTextures:mediumTextures,
                storage:storage,
                screenSize:screenSize
            )
            
            addRenderer?.draw(
                with:encoder,
                globalUniforms:uniforms,
                mediumTextures:mediumTextures,
                storage:storage,
                screenSize:screenSize
            )
            
            addRenderer?.drawTriangle(
                with:encoder,
                globalUniforms:uniforms,
                mediumTextures:mediumTextures,
                storage:storage,
                screenSize:screenSize
            )
            
            subRenderer?.draw(
                with:encoder,
                globalUniforms:uniforms,
                mediumTextures:mediumTextures,
                storage:storage,
                screenSize:screenSize
            )
            
            subRenderer?.drawTriangle(
                with:encoder,
                globalUniforms:uniforms,
                mediumTextures:mediumTextures,
                storage:storage,
                screenSize:screenSize
            )
            
            // sRGB変換
            sRGBRenderer?.draw(
                with:encoder,
                mediumTextures:mediumTextures
            )
            
            encoder?.endEncoding()
        }
    }
}
