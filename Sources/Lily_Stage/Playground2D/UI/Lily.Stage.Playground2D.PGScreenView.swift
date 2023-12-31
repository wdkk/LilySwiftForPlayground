//
// LilySwift Library Project
//
// Copyright (c) Watanabe-Denki Inc. and Kengo Watanabe.
//   https://wdkk.co.jp/
//
// This software is released under the MIT License.
//   https://opensource.org/licenses/mit-license.php
//

#if os(iOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
import Metal
import SwiftUI

extension Lily.Stage.Playground2D
{
    #if os(iOS) || os(visionOS)
    public struct PGScreenView : UIViewControllerRepresentable
    {
        var device:MTLDevice
        var environment:Lily.Stage.ShaderEnvironment
        var particleCapacity:Int
        var textures:[String]
        public var design:(( PGScreen )->Void)?
        public var update:(( PGScreen )->Void)?
        
        public init( 
            device:MTLDevice,
            environment:Lily.Stage.ShaderEnvironment = .string,
            particleCapacity:Int = 10000,
            textures:[String] = ["lily", "mask-sparkle", "mask-snow", "mask-smoke", "mask-star"],
            design:(( PGScreen )->Void)? = nil,
            update:(( PGScreen )->Void)? = nil 
        )
        {
            self.device = device
            
            self.environment = environment
            self.particleCapacity = particleCapacity
            self.textures = textures
            
            self.design = design
            self.update = update
        }
        
        public func makeUIViewController( context:Context ) -> PGScreen {
            let screen = PGScreen(
                device:device,
                environment:self.environment,
                particleCapacity:self.particleCapacity,
                textures:self.textures 
            )
            
            screen.buildupHandler = self.design
            screen.loopHandler = self.update
            
            return screen
        }
        
        public func updateUIViewController( _ uiViewController:PGScreen, context:Context ) {
            uiViewController.rebuild()
        }
    }
    #elseif os(macOS)
    public struct PGScreenView : NSViewControllerRepresentable
    {
        var device:MTLDevice
        
        var environment:Lily.Stage.ShaderEnvironment
        var particleCapacity:Int
        var textures:[String]
        public var design:(( PGScreen )->Void)?
        public var update:(( PGScreen )->Void)?
        
        public init( 
            device:MTLDevice,
            environment:Lily.Stage.ShaderEnvironment = .string,
            particleCapacity:Int = 10000,
            textures:[String] = ["lily", "mask-sparkle", "mask-snow", "mask-smoke", "mask-star"],
            design:(( PGScreen )->Void)? = nil,
            update:(( PGScreen )->Void)? = nil 
        )
        {
            self.device = device
            
            self.environment = environment
            self.particleCapacity = particleCapacity
            self.textures = textures
            
            self.design = design
            self.update = update
        }
        
        public func makeNSViewController( context:Context ) -> PGScreen {
            let screen = PGScreen(
                device:device,
                environment:self.environment,
                particleCapacity:self.particleCapacity,
                textures:self.textures 
            )
            
            screen.buildupHandler = self.design
            screen.loopHandler = self.update
            
            return screen
        }
        
        public func updateNSViewController( _ nsViewController:PGScreen, context:Context ) {
            nsViewController.rebuild()
        }
    }
    #endif
}
