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

extension Lily.Stage
{    
    open class RenderTextures
    { 
        var device:MTLDevice
        var commandQueue:MTLCommandQueue?
        
        // G-Buffer
        var GBuffer0: MTLTexture? // albedo( r, g, b ) 
        var GBuffer1: MTLTexture? // normal( x, y, z )
        var GBuffer2: MTLTexture? // specPower, specIntensity, shadow, ambient occulusion
        var GBufferDepth: MTLTexture?
        // シャドウテクスチャ
        var shadowMap: MTLTexture?
        
        public init( device:MTLDevice ) {
            self.device = device
            // レンダパスディスクリプタを同じテクスチャポインタで揃えるためシャドウ・マップを事前に作成
            shadowMap = createShadowMap( size:LLSizeIntMake( 1024, 1024 ), arrayLength:Shared.Const.shadowCascadesCount )
        }
        
        @discardableResult
        public func updateBuffers( size:CGSize, viewCount:Int ) -> Bool {
            if GBuffer0 != nil && GBuffer0!.width.d == size.width && GBuffer0!.height.d == size.height { return false }
            
            // テクスチャ再生成の作業
            let tex_desc = MTLTextureDescriptor.texture2DDescriptor( 
                pixelFormat:.rgba8Unorm_srgb,
                width:size.width.i!,
                height:size.height.i!,
                mipmapped:false 
            )
            
            tex_desc.sampleCount = BufferFormats.sampleCount
            #if !targetEnvironment(simulator)
            if #available( macCatalyst 14.0, * ) {
                tex_desc.storageMode = .memoryless
            }
            else {
                tex_desc.storageMode = .private            
            }
            #else
            tex_desc.storageMode = .private
            #endif
            if viewCount > 1 {
                tex_desc.textureType = .type2DArray
                tex_desc.arrayLength = viewCount
            }
            tex_desc.usage = [ tex_desc.usage, .renderTarget ]
            
            // GBuffer0の再生成
            tex_desc.pixelFormat = BufferFormats.GBuffer0
            GBuffer0 = device.makeTexture( descriptor:tex_desc )
            GBuffer0?.label = "GBuffer0"
            
            // GBuffer1の再生成
            tex_desc.pixelFormat = BufferFormats.GBuffer1
            GBuffer1 = device.makeTexture( descriptor:tex_desc )
            GBuffer1?.label = "GBuffer1"
            
            // GBuffer2の再生成
            tex_desc.pixelFormat = BufferFormats.GBuffer2
            GBuffer2 = device.makeTexture( descriptor:tex_desc )
            GBuffer2?.label = "GBuffer2"
            
            // GDepthの再生成
            tex_desc.storageMode = .private
            tex_desc.pixelFormat = BufferFormats.GBufferDepth
            GBufferDepth = device.makeTexture( descriptor:tex_desc )
            GBufferDepth?.label = "GBufferDepth"
            
            return true
        }
        
        // シャドウマップテクスチャの作成
        func createShadowMap( size:LLSizeInt, arrayLength:Int ) -> MTLTexture? {
            let desc = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: Lily.Stage.BufferFormats.shadowDepth,
                width: size.width, 
                height: size.height,
                mipmapped: false 
            )
            desc.textureType = .type2DArray
            desc.arrayLength = arrayLength
            desc.usage       = [desc.usage, .renderTarget]
            desc.storageMode = .private
            
            let shadowTexture = device.makeTexture( descriptor:desc )
            shadowTexture?.label = "ShadowMap"
            
            return shadowTexture
        }
    }
}

public extension Lily.Stage.RenderTextures
{
    func shadowViewport() -> MTLViewport {
        return MTLViewport(
            originX: 0,
            originY: 0, 
            width:shadowMap!.width.d,
            height:shadowMap!.height.d,
            znear: 0.0,
            zfar: 1.0
        )
    }
    
    func shadowScissor() -> MTLScissorRect {
        return MTLScissorRect(
            x: 0,
            y: 0, 
            width:shadowMap!.width, 
            height:shadowMap!.height 
        )
    }
}
