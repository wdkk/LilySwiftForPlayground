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

#if os(macOS)
import AppKit
#else
import UIKit
#endif
import Metal
import SwiftUI

extension Lily.Stage.Playground
{
    public struct PGBaseScene<TScreen>
    {
        public var planeStorage:Plane.PlaneStorage? { didSet { requestRedesign() } }
        public var bbStorage:Billboard.BBStorage? { didSet { requestRedesign() } }
        public var modelStorage:Model.ModelStorage? { didSet { requestRedesign() } }
        public var audioStorage:PGAudioStorage? { didSet { requestRedesign() } }

        public var ready:(( TScreen )->Void)? { didSet { requestRedesign() } }
        public var design:(( TScreen )->Void)? { didSet { requestRedesign() } }
        public var update:(( TScreen )->Void)? { didSet { requestRedesign() } }
        public var resize:(( TScreen )->Void)? { didSet { requestRedesign() } }
        
        // updateフラグ関数群(PGScreenViewのupdateで利用)
        public var _updated:Bool = false
        public mutating func requestRedesign() { self._updated = true }
        public mutating func finishRedesign() { self._updated = false }
        public func checkNeedRedesign() -> Bool { return _updated }
        
        public init(
            planeStorage:Plane.PlaneStorage? = nil,
            bbStorage:Billboard.BBStorage? = nil,
            modelStorage:Model.ModelStorage? = nil,
            audioStorage:PGAudioStorage? = nil,
            ready:((TScreen) -> Void)? = nil,
            design:((TScreen) -> Void)? = nil,
            update:((TScreen) -> Void)? = nil,
            resize:((TScreen) -> Void)? = nil
        ) 
        {
            self.planeStorage = planeStorage
            self.bbStorage = bbStorage
            self.modelStorage = modelStorage
            self.audioStorage = audioStorage
            self.ready = ready
            self.design = design
            self.update = update
            self.resize = resize
        }
    }
    
    public typealias PGScene = PGBaseScene<PGScreen>
    #if os(visionOS)
    public typealias PGVisionScene = PGBaseScene<PGVisionFullyScreen>
    #endif
}

#endif
