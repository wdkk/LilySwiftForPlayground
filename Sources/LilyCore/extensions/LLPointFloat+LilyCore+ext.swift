//
// LilySwift Library Project
//
// Copyright (c) Watanabe-Denki, Inc. and Kengo Watanabe.
//   https://wdkk.co.jp/
//
// This software is released under the MIT License.
//   https://opensource.org/licenses/mit-license.php
//

import CoreGraphics

// 位置構造体拡張
public extension LLPointFloat
{
    /// 位置(0,0)の実体を返す
    static let zero:LLPointFloat = { return LLPointFloat(0, 0) }()

    /// CGFloatを用いた実体化
    /// - Parameters:
    ///   - x: x座標
    ///   - y: y座標
    init( _ x:CGFloat, _ y:CGFloat ) {
        self.init( x:x.f, y:y.f )
    }
    
    /// Floatを用いた実体化
    /// - Parameters:
    ///   - x: x座標
    ///   - y: y座標
    init( _ x:Float, _ y:Float ) {
        self.init( x:x, y:y )
    }
    
    /// Doubleを用いた実体化
    /// - Parameters:
    ///   - x: x座標
    ///   - y: y座標
    init( _ x:Double, _ y:Double ) {
        self.init( x:x.f, y:y.f )
    }
    
    /// Intを用いた実体化
    /// - Parameters:
    ///   - x: x座標
    ///   - y: y座標
    init( _ x:Int, _ y:Int ) {
        self.init( x:x.f, y:y.f )
    }
    
    /// CGPointを用いた実体化
    /// - Parameters:
    ///   - cgpt: 座標値
    init( _ cgpt:CGPoint ) {
        self.init( x:cgpt.x.f, y:cgpt.y.f )
    }
    
    /// CGPointへの変換
    var cgPoint:CGPoint { 
        return CGPoint( self ) 
    }

    /// LLPointへの変換
    var llPoint:LLPoint {
        return LLPoint( self.x, self.y )
    }
    
    /// LLPointIntへの変換
    var llPointInt:LLPointInt {
        return LLPointInt( self.x, self.y )
    }
    
    /// p点との2乗距離を返す
    /// - Parameter p: 対象座標
    /// - Returns: 自身の座標とp点の2乗距離
    func dist2( _ p:LLPointFloat ) -> CGFloat {
        return ((self.x - p.x) * (self.x - p.x) + (self.y - p.y) * (self.y - p.y)).cgf
    }
    
    /// p点との距離を返す
    /// - Parameter p: 対象座標
    /// - Returns: 自身の座標とp点の距離
    func dist( _ p:LLPointFloat ) -> CGFloat {
        return sqrt( dist2( p ) )
    }
    
    /// 0~指定した値のランダムサイズ値
    var randomize:LLPointFloat { 
        return LLPointFloat( LLRandomf( self.x ), LLRandomf( self.y ) )  
    }
}
