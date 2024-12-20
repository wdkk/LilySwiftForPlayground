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
import simd
#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension Lily.Stage.Playground.Model
{
    open class ModelStorage : Hashable
    {
        public struct ModelSet
        {
            public var modelIndex:Int32
            public var meshData:Lily.Stage.Model.Mesh?
        }
        
        // Hashableの実装
        public static func == ( lhs:ModelStorage, rhs:ModelStorage ) -> Bool { lhs === rhs }
        public func hash(into hasher: inout Hasher) { ObjectIdentifier( self ).hash( into: &hasher ) }
        
        nonisolated(unsafe) public static var current:ModelStorage? = nil
        
        public var models:[String:ModelSet] = [:]
        public var statuses:Lily.Metal.Buffer<UnitStatus>
        
        public var cubeMap:MTLTexture?
        public var clearColor:LLColor = .white
        
        public private(set) var reuseIndice:[Int]

        public private(set) var modelCapacity:Int
        public private(set) var cameraCount:Int
        
        public var capacity:Int { modelCapacity * cameraCount }
        
        public static func playgroundDefault( 
            device:MTLDevice,
            modelCapacity:Int = 500,
            appendModelAssets:[String] = []
        )
        -> ModelStorage 
        {
            var modelAssets = [ "cottonwood1", "acacia1", "plane" ]
            modelAssets.append( contentsOf:appendModelAssets )
            return .init( 
                device:device,
                modelCapacity:modelCapacity,
                modelAssets:modelAssets
            )
        }

        
        public init( 
            device:MTLDevice, 
            modelCapacity:Int,
            modelAssets:[String] 
        )
        {
            self.modelCapacity = modelCapacity
            self.cameraCount = 4    // 現在は(3+1)で固定
            let capacity = self.modelCapacity * self.cameraCount
            
            self.statuses = .init( device:device, count:capacity + 1 )  // 1つ余分に確保
            self.statuses.update( range:0..<capacity+1 ) { us, _ in
                us.state = .trush
                us.enabled = false
            }
            
            self.reuseIndice = .init( (0..<capacity).reversed() )
            
            for i in 0 ..< modelAssets.count {
                let asset_name = modelAssets[i]
                guard let obj = loadObj( device:device, assetName:asset_name ) else { continue }
                models[asset_name] = ModelSet( modelIndex:i.i32!, meshData:obj.mesh )
            }
            
            // TODO: sphereのテスト追加
            let obj = Lily.Stage.Model.Sphere( device:device, segments:16, rings:16 )
            models["sphere"] = ModelSet( modelIndex:modelAssets.count.i32!, meshData:obj.mesh )
        }
        
        public func loadObj( device:MTLDevice, assetName:String ) -> Lily.Stage.Model.Obj? {
            guard let asset = NSDataAsset( name:assetName ) else { return nil }
            return Lily.Stage.Model.Obj( device:device, data:asset.data )
        }
        
        public func setCubeMap( device:MTLDevice, assetName:String? = nil ) {
            guard let assetName = assetName else {
                cubeMap = nil
                return
            }
            // Mipsを活用するためにKTXフォーマットを使う
            cubeMap = try? Lily.Metal.Texture.create( device:device, assetName:assetName )?
            .makeTextureView( pixelFormat:.rgba8Unorm )     
        }
                
        // パーティクルの確保をリクエストする
        public func request( assetName:String ) -> Int {
            guard let idx = reuseIndice.popLast() else { 
                LLLogWarning( "Playground.ModelStorage: ストレージの容量を超えたリクエストです. インデックス=capacityを返します" )
                return capacity
            }
            let model_index = models[assetName]?.modelIndex ?? -1
            statuses.update( at:idx ) { us in
                us = .init( modelIndex:model_index )
            }
            
            return idx
        }
        
        public func trush( index idx:Int ) {
            statuses.update( at:idx ) { us in
                us.state = .trush
                us.enabled = false
            }
            reuseIndice.append( idx )
        }
        
        public func clear() {
            self.statuses.update( range:0..<capacity+1 ) { us, _ in
                us.state = .trush
                us.enabled = false
            }
            
            self.reuseIndice = .init( (0..<capacity).reversed() )
        }
    }
}

#endif
