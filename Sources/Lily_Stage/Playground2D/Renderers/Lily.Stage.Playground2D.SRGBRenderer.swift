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

extension Lily.Stage.Playground2D
{
    open class SRGBRenderer
    {
        public var device: MTLDevice
        
        var pipeline: MTLRenderPipelineState!
        
        public init( device:MTLDevice, environment:Lily.Stage.ShaderEnvironment, viewCount:Int ) {
            self.device = device
           
            let desc = MTLRenderPipelineDescriptor()
            desc.label = "Playground 2D convert sRGB"
            
            if environment == .metallib {
                let library = try! Lily.Stage.metalLibrary( of:device )
                desc.vertexShader( .init( device:device, mtllib:library, shaderName:"Lily_Stage_Playground2D_SRGB_Vs" ) )
                desc.fragmentShader( .init( device:device, mtllib:library, shaderName:"Lily_Stage_Playground2D_SRGB_Fs" ) )
            }
            else if environment == .string {
                let stringShader = Lily.Stage.Playground2D.ShaderString.shared( device:device )
                desc.vertexShader( stringShader.sRGBVertexShader )
                desc.fragmentShader( stringShader.sRGBFragmentShader )            
            }

            desc.rasterSampleCount = Lily.Stage.BufferFormats.sampleCount
            
            desc.colorAttachments[0].pixelFormat = Lily.Stage.BufferFormats.linearSRGBBuffer
            desc.colorAttachments[1].pixelFormat = Lily.Stage.BufferFormats.backBuffer
            desc.depthAttachmentPixelFormat = Lily.Stage.BufferFormats.depth
            if #available( macCatalyst 13.4, * ) {
                desc.maxVertexAmplificationCount = viewCount
            }
            
            pipeline = try! device.makeRenderPipelineState(descriptor: desc, options: [], reflection: nil)
        }
        
        public func draw( 
            with renderEncoder:MTLRenderCommandEncoder?,
            mediumTextures:Lily.Stage.Playground2D.MediumTexture
        ) 
        {
            renderEncoder?.setRenderPipelineState( pipeline )
        
            renderEncoder?.setFragmentMemoryLessTexture( mediumTextures.particleTexture, index:0 )
            renderEncoder?.drawPrimitives( type:.triangle, vertexStart:0, vertexCount:3 )
        }
    }
}
