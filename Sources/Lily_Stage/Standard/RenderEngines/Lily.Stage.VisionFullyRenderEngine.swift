//
// LilySwift Library Project
//
// Copyright (c) Watanabe-Denki, Inc. and Kengo Watanabe.
//   https://wdkk.co.jp/
//
// This software is released under the MIT License.
//   https://opensource.org/licenses/mit-license.php
//

#if os(visionOS)

import Metal
import MetalKit
import simd
import SwiftUI
import CompositorServices
import Spatial

extension Lily.Stage
{              
    public struct VisionFullyRenderConfiguration
    : CompositorLayerConfiguration 
    {
        public init() {}
        
        public func makeConfiguration(
            capabilities: LayerRenderer.Capabilities, 
            configuration: inout LayerRenderer.Configuration
        ) 
        {
            configuration.colorFormat = BufferFormats.backBuffer
            configuration.depthFormat = BufferFormats.depth
        
            let foveationEnabled = capabilities.supportsFoveation
            configuration.isFoveationEnabled = foveationEnabled
            
            let options: LayerRenderer.Capabilities.SupportedLayoutsOptions = foveationEnabled ? [.foveationEnabled] : []
            let supportedLayouts = capabilities.supportedLayouts(options: options)
            
            configuration.layout = supportedLayouts.contains( .layered ) ? .layered : .dedicated
        }
    }
    
    open class VisionFullyRenderEngine 
    : BaseRenderEngine
    {
        let maxBuffersInFlight:Int
        lazy var inFlightSemaphore = DispatchSemaphore( value:maxBuffersInFlight )
        
        let arSession: ARKitSession
        let worldTracking:WorldTrackingProvider
        let layerRenderer:LayerRenderer
        
        let device: MTLDevice
        let commandQueue: MTLCommandQueue
        var onFrame:UInt = 0
        
        var uniforms:Lily.Metal.RingBuffer<Shared.GlobalUniformArray>
        
        var renderFlows:[BaseRenderFlow?] = []
        
        public var camera:Lily.Stage.Camera = .init(
            perspectiveWith:.init( 0, 0, 0 ),
            direction: .init( 0.0, 0.0, 1.0 ), 
            up: .init( 0, 1, 0 ), 
            viewAngle: Float.pi / 3.0, 
            aspectRatio: 320.0 / 240.0, 
            near: 10.0, 
            far: 60000.0
        )

        /*
        public var camera:Lily.Stage.Camera = .init(
            perspectiveWith: .init( 0.0, 2600, 5000.0 ),
            direction: .init( 0.0, -0.5, -1.0 ), 
            up: .init( 0, 1, 0 ), 
            viewAngle: Float.pi / 3.0, 
            aspectRatio: 320.0 / 240.0, 
            near: 10.0, 
            far: 60000.0
        )
        */
        
        public var setupHandler:(()->Void)?
        public var updateHandler:(()->Void)?
        
        public init( _ layerRenderer:LayerRenderer, renderFlows:[BaseRenderFlow?], buffersInFlight:Int ) {
            self.layerRenderer = layerRenderer
            self.worldTracking = WorldTrackingProvider()
            self.arSession = ARKitSession()
            
            self.device = layerRenderer.device
            self.commandQueue = self.device.makeCommandQueue()!
            self.maxBuffersInFlight = buffersInFlight
            
            self.uniforms = .init( device:device, ringSize:maxBuffersInFlight )
            
            self.renderFlows = renderFlows
            
            super.init()
        }
        
        public func startRenderLoop() {
            Task {
                do {
                    try await arSession.run( [worldTracking] )
                } 
                catch {
                    fatalError("Failed to initialize ARSession")
                }
                
                let renderThread = Thread {
                    self.setupHandler?()
                    self.renderLoop() 
                }
                renderThread.name = "Render Thread"
                renderThread.start()
            }
        }
        
        public func renderLoop() {
            while true {
                if layerRenderer.state == .invalidated {
                    print( "Layer is invalidated" )
                    return
                } 
                else if layerRenderer.state == .paused {
                    layerRenderer.waitUntilRunning()
                    continue
                } 
                else {
                    autoreleasepool { 
                        self.updateHandler?()
                    }
                }
            }
        }
        
        public func changeScreenSize( size:CGSize ) {
            screenSize = size.llSizeFloat
            renderFlows.forEach { $0?.changeSize( scaledSize:size ) }
            camera.aspect = (size.width / size.height).f
        }
        
        public func calcViewMatrix( 
            drawable:LayerRenderer.Drawable,
            deviceAnchor:DeviceAnchor?,
            viewIndex:Int
        )
        -> LLMatrix4x4
        {
            let deviceAnchorMatrix = deviceAnchor?.originFromAnchorTransform ?? LLMatrix4x4.identity
            let view = drawable.views[viewIndex]
            return (deviceAnchorMatrix * view.transform).inverse
        }
        
        /*
        public func calcProjectionMatrix(
            drawable:LayerRenderer.Drawable,
            deviceAnchor:DeviceAnchor?,
            near:Double,
            far:Double,
            viewIndex:Int
        )
        -> LLMatrix4x4
        {
            let view = drawable.views[viewIndex]
            
            let projection = ProjectiveTransform3D(
                leftTangent: Double(view.tangents[0]),
                rightTangent: Double(view.tangents[1]),
                topTangent: Double(view.tangents[2]),
                bottomTangent: Double(view.tangents[3]),
                nearZ:near, //Double(drawable.depthRange.y),
                farZ:far, //Double(drawable.depthRange.x),
                reverseZ:false
            )
            
            return LLMatrix4x4( projection )
        }
        */
        
        public func calcOrientationMatrix( 
            viewMatrix:LLMatrix4x4
        )
        -> LLMatrix4x4
        {
            var orientation_mat = viewMatrix
            orientation_mat.W = LLFloatv4( 0.0, 0.0, 0.0, 1.0 )
            return orientation_mat
        }
        
        public func updateGlobalUniform( 
            drawable:LayerRenderer.Drawable,
            deviceAnchor:DeviceAnchor?
        )
        {  
            onFrame += 1
            
            let viewCount = drawable.views.count
   
            uniforms.update { uni in
                for view_idx in 0 ..< viewCount {
                    // TODO: アンカーなどからマトリクスを得ているが、アンカーとdrawableからcameraをつくるべき
                    //let vM = camera.calcViewMatrix()
                    let vM = self.calcViewMatrix(
                        drawable:drawable,
                        deviceAnchor:deviceAnchor,
                        viewIndex:view_idx
                    )
                    
                    let projM = camera.calcProjectionMatrix()
                    /*
                    let projM = self.calcProjectionMatrix(
                        drawable:drawable,
                        deviceAnchor:deviceAnchor, 
                        near:camera.near.d,
                        far:camera.far.d,
                        viewIndex:view_idx
                    )
                    */
                    
                    let orientationM = self.calcOrientationMatrix( viewMatrix:vM )
                    //let orientationM = camera.calcOrientationMatrix()
                    
                    let camera_uniform = Shared.CameraUniform(
                        viewMatrix:vM, 
                        projectionMatrix:projM,
                        orientationMatrix:orientationM
                    )
                    
                    uni[view_idx] = makeGlobalUniform( 
                        onFrame:onFrame, 
                        cameraUniform:camera_uniform, 
                        screenSize:screenSize
                    )
                    
                    let cascade_sizes:[Float] = [ 400.0, 1600.0, 6400.0 ]
                    let cascade_distances = makeCascadeDistances( sizes:cascade_sizes, viewAngle:camera.viewAngle )
                    
                    // カスケードシャドウのカメラユニフォームを作成
                    for c_idx in 0 ..< Shared.Const.shadowCascadesCount {
                        let center = camera.position + camera.direction * cascade_distances[c_idx]
                        let size = cascade_sizes[c_idx]

                        var shadow_cam = Camera( 
                            parallelWith:center - uni[view_idx].sunDirection * size,
                            direction:uni[view_idx].sunDirection,
                            up: .init( 0, 1, 0 ),
                            width:size * 2.0,
                            height:size * 2.0,
                            near:0.0,
                            far:size * 2.0
                        )
                        
                        // Stepsizeはテクセルのサイズの倍数
                        let stepsize = size / 64.0
                        let stepsizes = LLFloatv3( repeating:stepsize )
                        shadow_cam.position -= fract( dot( center, shadow_cam.up ) / stepsizes ) * shadow_cam.up * stepsize
                        shadow_cam.position -= fract( dot( center, shadow_cam.right ) / stepsizes ) * shadow_cam.right * stepsize
                        
                        uni[view_idx].shadowCameraUniforms[c_idx] = shadow_cam.uniform
                    }
                }
            }
        }
                
        public func update(
            completion:(( MTLCommandBuffer? ) -> ())? = nil
        )
        {
            defer { uniforms.next() }
            
            guard let frame = layerRenderer.queryNextFrame() else { return }
            
            frame.startUpdate()
            // frameの間で処理したいことを書く
            frame.endUpdate()
            
            guard let timing = frame.predictTiming() else { return }
            LayerRenderer.Clock().wait( until:timing.optimalInputTime )
            
            guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
            commandBuffer.label = "Vision Command Buffer" 
            commandBuffer.addCompletedHandler { [weak self] _ in self?.inFlightSemaphore.signal() }
            
            guard let layerRenderDrawable = frame.queryDrawable() else { return }
            
            // 今の画面サイズで再生成する
            changeScreenSize( size:CGSize( layerRenderDrawable.colorTextures[0].width, layerRenderDrawable.colorTextures[0].height ) )
            
            _ = inFlightSemaphore.wait( timeout:DispatchTime.distantFuture )
            
            frame.startSubmission()
            
            let time = layerRendererTimeInterval( from:LayerRenderer.Clock.Instant.epoch.duration( to:layerRenderDrawable.frameTiming.presentationTime ) )
            let deviceAnchor = worldTracking.queryDeviceAnchor( atTimestamp:time )
            
            layerRenderDrawable.deviceAnchor = deviceAnchor
            
            //-- 依存があるレンダリング定数設定 --//
            let rasterizationRateMap = layerRenderDrawable.rasterizationRateMaps.first
            
            let viewports = layerRenderDrawable.views.map { $0.textureMap.viewport }
            let viewCount = layerRenderer.configuration.layout == .layered ? layerRenderDrawable.views.count : 1
            
            let destinationTexture = layerRenderDrawable.colorTextures[0]
            let depthTexture = layerRenderDrawable.depthTextures[0]
            
            //-- 依存がある処理 --//
            // Uniformの更新
            self.updateGlobalUniform(
                drawable:layerRenderDrawable, 
                deviceAnchor:deviceAnchor
            )
            
            // 共通処理
            renderFlows.forEach {
                $0?.render(
                    commandBuffer:commandBuffer,
                    rasterizationRateMap:rasterizationRateMap,
                    viewports:viewports, 
                    viewCount:viewCount,
                    destinationTexture:destinationTexture, 
                    depthTexture:depthTexture,
                    uniforms:uniforms
                )
            }
            
            layerRenderDrawable.encodePresent( commandBuffer:commandBuffer )
            
            commandBuffer.commit()
            
            frame.endSubmission()
            
            completion?( commandBuffer )
        }
    }
    
    static func layerRendererTimeInterval( from duration:LayerRenderer.Clock.Instant.Duration ) -> TimeInterval {
        let nanoseconds = TimeInterval( duration.components.attoseconds / 1_000_000_000 )
        return TimeInterval( duration.components.seconds ) + ( nanoseconds / TimeInterval(NSEC_PER_SEC) )
    }
}

#endif
