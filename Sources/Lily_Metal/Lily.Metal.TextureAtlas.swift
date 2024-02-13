//
// LilySwift Library Project
//
// Copyright (c) Watanabe-Denki, Inc. and Kengo Watanabe.
//   https://wdkk.co.jp/
//
// This software is released under the MIT License.
//   https://opensource.org/licenses/mit-license.php
//

// 参考: https://blackpawn.com/texts/lightmaps/default.html
// 参考: https://tyfkda.github.io/blog/2013/10/05/texture-pakcer.html

import MetalKit
#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension Lily.Metal 
{    
    open class TextureTree
    {        
        public class ImagePosUnit
        {
            var image:MTLTexture?
            var label:String = ""
            var x:Int
            var y:Int
            var width:Int 
            var height:Int
            
            public init( x:Int, y:Int, width:Int, height:Int ) {
                self.x = x
                self.y = y
                self.width = width
                self.height = height
            }
        }
        
        public class Node
        {
            var unit:ImagePosUnit?
            var node_a:Node?
            var node_b:Node?
            
            public init( unit:ImagePosUnit? ) {
                self.unit = unit
            }
            
            public func insert( unit:ImagePosUnit ) -> Bool {
                if let self_unit = self.unit {
                    if unit.width > self_unit.width || unit.height > self_unit.height { return false }
                    
                    // ここで領域を埋め込む位置を上書きする(unitは参照なので、元データのx,y座標が書き変わる)
                    unit.x = self_unit.x
                    unit.y = self_unit.y
                    
                    let w = unit.width
                    let h = unit.height
                    let dw = self_unit.width - w
                    let dh = self_unit.height - h
                    
                    if dw > dh {
                        self.node_a = Node( unit: ImagePosUnit(x: self_unit.x,
                                                               y: self_unit.y + h,
                                                               width: w,
                                                               height: dh ) )
                        
                        self.node_b = Node( unit: ImagePosUnit(x: self_unit.x + w,
                                                               y: self_unit.y,
                                                               width: dw, 
                                                               height: self_unit.height ) )
                    }
                    else {
                        self.node_a = Node( unit: ImagePosUnit(x: self_unit.x + w,
                                                               y: self_unit.y,
                                                               width: dw,
                                                               height: h ) )
                        
                        self.node_b = Node( unit: ImagePosUnit(x: self_unit.x,
                                                               y: self_unit.y + h,
                                                               width: self_unit.width,
                                                               height: dh ) )   
                    }
                    self.unit = nil
                    return true
                }
                else {
                    if node_a!.insert( unit:unit ) { return true }
                    return node_b!.insert( unit:unit )
                }
            }        
        }
        
        @discardableResult
        public func pack( imageUnits:[ImagePosUnit] ) -> LLSizeInt {
            var size = calcInitialRect( imageUnits: imageUnits )
            while true {
                let root = Node( unit: ImagePosUnit( x: 0, y: 0, width: size.width, height: size.height ) )
                if insertImageToRoot( imageUnits:imageUnits, root:root ) {
                    return size
                }
                if size.width > size.height { size.height *= 2 } else { size.width *= 2 }
            }
        }
        
        private func insertImageToRoot( imageUnits:[ImagePosUnit], root:Node ) -> Bool {
            for unit in imageUnits {
                if !root.insert( unit:unit ) { return false }
            }
            return true
        }
        
        private func calcInitialRect( imageUnits:[ImagePosUnit] ) -> LLSizeInt {
            let total_pixel = calcTotalPixel( imageUnits: imageUnits )
            var w = pow2(x: sqrt( total_pixel.d ).i! ) / 2
            var h = w
            while w * h < total_pixel {
                if w > h { h *= 2 } else { w *= 2 }
            }
            return LLSizeIntMake( w, h )
        }
        
        private func calcTotalPixel( imageUnits:[ImagePosUnit] ) -> Int {
            var count:Int = 0
            for rc in imageUnits { count += (rc.image!.width * rc.image!.height) }
            return count
        }
        
        private func pow2( x:Int ) -> Int {
            var xpow2:Int = 1
            while xpow2 <= x { xpow2 *= 2 }
            return xpow2
        }
    }
    
    open class TextureAtlas
    {
        var device:MTLDevice?
        private var labels:[String:Any?] = [:]
        private var positions:[String:LLRegion] = [:]
        public var metalTexture:MTLTexture?
        public private(set) var width:Int32 = 0
        public private(set) var height:Int32 = 0
        
        public init( device:MTLDevice? ) {
            self.device = device
        }
        
        @discardableResult
        public func reserve( _ label:String, _ path:String ) -> Self {
            labels[label] = path
            return self
        }
        
        @discardableResult
        public func reserve( _ label:String, _ img:LLImage ) -> Self {
            labels[label] = img
            return self
        }
        
        #if os(macOS)
        @discardableResult
        public func reserve( _ label:String, _ img:NSImage ) -> Self {
            labels[label] = img
            return self
        }
        #else
        @discardableResult
        public func reserve( _ label:String, _ img:UIImage ) -> Self {
            labels[label] = img
            return self
        }
        #endif
        
        @discardableResult
        public func commit() -> Self { 
            typealias ImagePosUnit = Lily.Metal.TextureTree.ImagePosUnit

            var image_rects:[ImagePosUnit] = []
                        
            let loader = MTKTextureLoader( device:device! )
            
            for (label, v) in self.labels {
                // nullの場合処理しない
                guard let nnv = v else { continue }
                
                // nnvの中身の種類によって登録方法を変えていく
                if nnv is String {
                    let path = nnv as! String
                    let bundle:Bundle? = nil
                    
                    do {
                        guard let cgimg = CGImage.load( assetName:path ) else { continue }
                        let tex = try loader.newTexture( cgImage:cgimg )
                        //let tex = try loader.newTexture( name:path, scaleFactor:1.0, bundle:bundle )
                        let rc = ImagePosUnit( x:0, y:0, width:tex.width, height:tex.height )
                        rc.image = tex
                        rc.label = label
                        
                        image_rects.append( rc )
                        continue
                    }
                    catch {
                        LLLog( "label:\(label), \(error.localizedDescription)" )
                        continue
                    }
                }
                if nnv is LLImage {
                    let img = nnv as! LLImage
                    if !img.available { continue }
                    
                    do {
                        let tex = try Lily.Metal.Texture.create( device:device!, llImage:img )
                        
                        let rc = ImagePosUnit( x:0, y:0, width:tex!.width, height:tex!.height )
                        rc.image = tex!
                        rc.label = label
                        
                        image_rects.append( rc )
                        continue
                    }
                    catch {
                        LLLog( "label:\(label), \(error.localizedDescription)" )
                        continue
                    }
                }
                #if os(macOS)
                if nnv is NSImage {
                    let uiimg = nnv as! NSImage
                    guard let cgimg = uiimg.cgImage else { continue }
  
                    do {
                        let tex = try loader.newTexture( cgImage:cgimg, options:[:] )
                    
                        let rc = ImagePosUnit( x:0, y:0, width:tex.width, height:tex.height )
                        rc.image = tex
                        rc.label = label
                        
                        image_rects.append( rc )
                        continue
                    }
                    catch {
                        LLLog( "label:\(label), \(error.localizedDescription)" )
                        continue
                    }
                }
                #else
                if nnv is UIImage {
                    let uiimg = nnv as! UIImage
                    guard let cgimg = uiimg.cgImage else { continue }
  
                    do {
                        let tex = try loader.newTexture( cgImage:cgimg, options:[:] )
                    
                        let rc = ImagePosUnit( x:0, y:0, width:tex.width, height:tex.height )
                        rc.image = tex
                        rc.label = label
                        
                        image_rects.append( rc )
                        continue
                    }
                    catch {
                        LLLog( "label:\(label), \(error.localizedDescription)" )
                        continue
                    }
                }
                #endif
            }
            
            // ソート
            do {
                try image_rects.sort { (rc1, rc2) throws -> Bool in
                    return LLMax( rc1.width, rc1.height ) > LLMax( rc2.width, rc2.height ) 
                }
            }
            catch {
                LLLog( "ソートに失敗しました, ソートなしで処理を継続します." )
                return self
            }
            
            let tree = TextureTree()
            let all_size = tree.pack( imageUnits:image_rects )
            
            if all_size.width == 0 || all_size.height == 0 {
                LLLog( "テクスチャがないため空のテクスチャアトラスを出力します" )
                self.metalTexture = try! Lily.Metal.Texture.create( device:device!, llImage:LLImage( wid:64, hgt:64 ) )
                self.width = 64
                self.height = 64
                return self
            }
            
            if all_size.width > 16384 || all_size.height > 16384 {
                LLLog( "テクスチャのサイズが許容量を超えました." )
            }
            
            // 全体画像
            positions.removeAll()
            
            self.metalTexture = Lily.Metal.Texture.create( device:device!, width:all_size.width, height:all_size.height )
            self.width = all_size.width.i32!
            self.height = all_size.height.i32!
            
            guard let commandQueue = device?.makeCommandQueue() else { 
                LLLog( "コマンドキューの作成に失敗しました." )
                return self
            }
           
            for imgrc in image_rects {
                guard let tex = imgrc.image else { continue }
                
                let label = imgrc.label
                let px = imgrc.x
                let py = imgrc.y
                let wid = tex.width
                let hgt = tex.height
                
                let src_reg = MTLRegionMake2D( 0, 0, wid, hgt )
                let dst_reg = MTLRegionMake2D( px, py, wid, hgt )
                
                let command_buffer = commandQueue.makeCommandBuffer()
                let blit_encoder = command_buffer?.makeBlitCommandEncoder()
                
                blit_encoder?.copy(
                    from: tex,
                    sourceSlice: 0,
                    sourceLevel: 0,
                    sourceOrigin: src_reg.origin,
                    sourceSize: src_reg.size,
                    to: self.metalTexture!,
                    destinationSlice: 0,
                    destinationLevel: 0,
                    destinationOrigin: dst_reg.origin
                )
                
                blit_encoder?.endEncoding()
                
                command_buffer?.commit()
                command_buffer?.waitUntilCompleted()
                
                let left  = px.d / all_size.width.d
                let top   = py.d / all_size.height.d
                let right = (px + wid).d  / all_size.width.d
                let bottom = (py + hgt).d / all_size.height.d            
                
                positions[label] = LLRegionMake( left, top, right, bottom )                
            }
            
            return self
        }
        
        public func parts( _ key:String ) -> TextureAtlasParts {
            let reg = self.positions[key] ?? .zero
            return TextureAtlasParts( 
                metalTexture: self.metalTexture,
                atlasUV:.init( reg.left.f, reg.top.f, reg.right.f, reg.bottom.f )
            )
        }
    }
    
    public struct TextureAtlasParts {
        var metalTexture:MTLTexture?
        var atlasUV:LLFloatv4
    }
}
