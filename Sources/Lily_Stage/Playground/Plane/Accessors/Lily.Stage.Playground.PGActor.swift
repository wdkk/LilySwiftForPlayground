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

extension Lily.Stage.Playground.Plane
{   
    open class PGActor : Hashable
    {
        public typealias Here = Lily.Stage.Playground.Plane
        public typealias PGScreen = Lily.Stage.Playground.PGScreen
        
        fileprivate static let Z_INDEX_MIN:Float = 0.0
        fileprivate static let Z_INDEX_MAX:Float = 99999.0
        // Hashableの実装
        public static func == ( lhs:PGActor, rhs:PGActor ) -> Bool { lhs === rhs }
        public func hash(into hasher: inout Hasher) { ObjectIdentifier( self ).hash( into: &hasher ) }
    
        public private(set) var index:Int
        public private(set) var storage:Storage?
        public private(set) var statusAccessor:UnsafeMutableBufferPointer<UnitStatus>?
        public private(set) var currentPointer:UnsafeMutablePointer<UnitStatus>?
                
        public var iterateField:PGField<PGActor, LLEmpty>?
        public var intervalField:ActorInterval?
        public var completionField:PGField<PGActor, LLEmpty>?
        
        public private(set) var parent:PGActor?
                
        public init( storage:Storage? ) {
            self.storage = storage
            
            guard let storage = storage else { 
                self.index = -1
                return 
            }
            
            self.statusAccessor = storage.statuses.accessor
            self.index = storage.request() 
            self.currentPointer = statusAccessor!.baseAddress! + self.index
            
            if checkIndexStatus {
                status?.state = .active
                status?.enabled = true
                status?.shapeType = .rectangle
            }
            else {
                status?.state = .trush
                status?.enabled = false
                status?.shapeType = .empty
            }
            
            PGPool.shared.insert( shape:self, to:storage )
        }
        
        private var checkIndexStatus:Bool {
            guard let storage = self.storage else { return false }
            return self.index < storage.capacity
        }
    
        public var status:UnitStatus? {
            get { currentPointer?.pointee }
            set { if let v = newValue { currentPointer?.pointee = v } }
        }
       
        @discardableResult
        public func iterate( _ f:@escaping ( PGActor )->Void ) -> Self {
            self.iterateField = PGField( me:self, action:f )
            return self
        }
        
        public func appearIterate() {
            self.iterateField?.appear()
        }
        
        @discardableResult
        public func interval( sec:Double, f:@escaping ( PGActor )->Void ) -> Self {
            self.intervalField = ActorInterval(
                sec:sec,
                prev:ActorTimer.shared.nowTime,
                field:PGField( me:self, action:f )
            )
            return self
        }
        
        public func appearInterval() {
            let now = ActorTimer.shared.nowTime
            
            guard let intv = self.intervalField else { return }
            if now - intv.prev >= intv.sec {
                intv.field.appear()
                self.intervalField?.prev = now
            }
        }
        
        @discardableResult
        public func stopInterval() -> Self {
            self.intervalField = nil
            return self
        }
        
        @discardableResult
        public func completion( _ f:@escaping ( PGActor )->Void ) -> Self {
            self.completionField = PGField( me:self, action:f )
            return self
        }

        @discardableResult
        public func parent( _ actor:PGActor ) -> Self {
            self.parent = actor
            self.status?.childDepth = actor.status!.childDepth + 1
            return self
        }        
        
        public var childDepth:LLUInt32 {
            get { return status?.childDepth ?? 0 }
        }
        
        //// 
        
        public func appearCompletion() {
            self.completionField?.appear()
        }
        
        public func checkRemove() {
            if self.life <= 0.0 {
                self.iterateField = nil
                self.intervalField = nil
                self.completionField = nil
                
                trush()
            }
        }
        
        public func trush() {
            storage?.trush( index:self.index )
            PGPool.shared.remove( shape:self, to:storage )
        }
    }
}

// 内部クラスなど
extension Lily.Stage.Playground.Plane.PGActor
{
    public class ActorTimer
    {
        public static let shared = ActorTimer()
        private init() {}
        
        public private(set) var startTime:Double = 0.0
        public private(set) var nowTime:Double = 0.0
        
        public func start() {
            startTime = LLClock.now.d / 1000.0
            nowTime = startTime
        }
        
        public func update() {
            nowTime = LLClock.now.d / 1000.0
        }
        
        public var elapsedTime:Double { nowTime - startTime }
    }

    public struct ActorInterval
    {
        var sec:Double = 1.0
        var prev:Double = 0.0
        var field:Here.PGField<Here.PGActor, LLEmpty>
        
        public init(
            sec:Double,
            prev:Double, 
            field:Here.PGField<Here.PGActor, LLEmpty> 
        ) 
        {
            self.sec = sec
            self.prev = prev
            self.field = field
        }
    }
}

// プロパティ
extension Lily.Stage.Playground.Plane.PGActor
{
    public var position:LLPointFloat { 
        get { return LLPointFloat( status?.position.x ?? 0, status?.position.y ?? 0 ) }
        set { status?.position = LLFloatv2( newValue.x, newValue.y ) }
    }
    
    public var cx:LLFloat {
        get { return status?.position.x ?? 0 }
        set { status?.position.x = newValue }
    }
    
    public var cy:LLFloat {
        get { return status?.position.y ?? 0 }
        set { status?.position.y = newValue }
    }
    
    public var scale:LLSizeFloat {
        get { return LLSizeFloat( status?.scale.x ?? 0, status?.scale.y ?? 0 ) }
        set { status?.scale = LLFloatv2( newValue.width, newValue.height ) }
    }
    
    public var width:Float {
        get { return status?.scale.x ?? 0 }
        set { status?.scale.x = newValue }
    }
    
    public var height:Float {
        get { return status?.scale.y ?? 0 }
        set { status?.scale.y = newValue }
    }
    
    public var angle:LLAngle {
        get { return LLAngle.radians( status?.angle.d  ?? 0 ) }
        set { status?.angle = newValue.radians.f }
    }
    
    public var enabled:Bool { 
        get { checkIndexStatus ? ( status?.enabled ?? false ) : false }
        set { if checkIndexStatus { status?.enabled = newValue } }
    }
    
    public var life:Float { 
        get { return status?.life  ?? 0 }
        set { status?.life = newValue }
    }
    
    public var color:LLColor {
        get { return status?.color.llColor ?? .clear }
        set { status?.color = newValue.floatv4 }
    }
    
    public var alpha:Float {
        get { return status?.color.w ?? 0 }
        set { status?.color.w = newValue }
    }
    
    public var matrix:LLMatrix4x4 { 
        get { return status?.matrix ?? .identity }
        set { status?.matrix = newValue }
    }
    
    public var deltaPosition:LLPointFloat { 
        get { return LLPointFloat( status?.deltaPosition.x ?? 0, status?.deltaPosition.y ?? 0 ) }
        set { status?.deltaPosition = LLFloatv2( newValue.x, newValue.y ) }
    }
    
    public var deltaScale:LLSizeFloat { 
        get { return LLSizeFloat( status?.deltaScale.x ?? 0, status?.deltaScale.y ?? 0 ) }
        set { status?.deltaScale = LLFloatv2( newValue.width, newValue.height ) }
    }
    
    public var deltaColor:LLColor { 
        get { return status?.deltaColor.llColor ?? .clear
        }
        set { status?.deltaColor = newValue.floatv4 }
    }
    
    public var deltaAlpha:Float {
        get { return status?.deltaColor.w  ?? 0 }
        set { status?.deltaColor.w = newValue }
    }
    
    public var deltaAngle:LLAngle {
        get { return LLAngle.radians( status?.deltaAngle.d ?? 0 ) }
        set { status?.deltaAngle = newValue.radians.f }
    }
    
    public var deltaLife:Float {
        get { return status?.deltaLife ?? 0 }
        set { status?.deltaLife = newValue }
    }
}

// MARK: - 基本パラメータ情報の各種メソッドチェーンアクセサ
extension Lily.Stage.Playground.Plane.PGActor
{
    @discardableResult
    public func position( _ p:LLPointFloat ) -> Self {
        status?.position = LLFloatv2( p.x, p.y )
        return self
    }
    
    @discardableResult
    public func position( _ p:LLPoint ) -> Self {
        status?.position = LLFloatv2( p.x.f, p.y.f )
        return self
    }
    
    @discardableResult
    public func position( cx:Float, cy:Float ) -> Self {
        position = LLPointFloat( cx, cy )
        return self
    }
    
    @discardableResult
    public func position( cx:LLFloatConvertable, cy:LLFloatConvertable ) -> Self {
        status?.position = LLFloatv2( cx.f, cy.f )
        return self
    }
    
    @discardableResult
    public func cx( _ p:Float ) -> Self {
        status?.position.x = p
        return self
    }
    
    @discardableResult
    public func cx( _ p:LLFloatConvertable ) -> Self {
        status?.position.x = p.f
        return self
    }

    @discardableResult
    public func cy( _ p:Float ) -> Self {
        status?.position.y = p
        return self
    }
    
    @discardableResult
    public func cy( _ p:LLFloatConvertable ) -> Self {
        status?.position.y = p.f
        return self
    }
    
    @discardableResult
    public func scale( _ sz:LLSizeFloat ) -> Self {
        status?.scale = LLFloatv2( sz.width, sz.height )
        return self
    }
        
    @discardableResult
    public func scale( width:Float, height:Float ) -> Self {
        status?.scale = LLFloatv2( width, height )
        return self
    }
    
    @discardableResult
    public func scale( width:LLFloatConvertable, height:LLFloatConvertable ) -> Self {
        status?.scale = LLFloatv2( width.f, height.f )
        return self
    }
    
    @discardableResult
    public func scale( square sz:Float ) -> Self {
        status?.scale = LLFloatv2( sz, sz )
        return self
    }
    
    @discardableResult
    public func scale( square sz:LLFloatConvertable ) -> Self {
        status?.scale = LLFloatv2( sz.f, sz.f )
        return self
    }

    
    @discardableResult
    public func width( _ v:Float ) -> Self {
        status?.scale.x = v
        return self
    }
    
    @discardableResult
    public func width( _ v:LLFloatConvertable ) -> Self {
        status?.scale.x = v.f
        return self
    }
    
    @discardableResult
    public func height( _ v:Float ) -> Self {
        status?.scale.y = v
        return self
    }
    
    @discardableResult
    public func height( _ v:LLFloatConvertable ) -> Self {
        status?.scale.y = v.f
        return self
    }
    
    @discardableResult
    public func angle( _ ang:LLAngle ) -> Self {
        status?.angle = ang.radians.f
        return self
    }
    
    @discardableResult
    public func angle( radians rad:LLFloatConvertable ) -> Self {
        status?.angle = rad.f
        return self
    }
    
    @discardableResult
    public func angle( degrees deg:LLFloatConvertable ) -> Self {
        status?.angle = LLAngle( degrees: deg.f.d ).radians.f
        return self
    }
        
    @discardableResult
    public func zIndex( _ index:LLFloatConvertable ) -> Self {
        status?.zIndex = LLWithin( min:Self.Z_INDEX_MIN, index.f, max:Self.Z_INDEX_MAX ) 
        return self
    }
                             
    @discardableResult
    public func enabled( _ torf:Bool ) -> Self {
        status?.enabled = torf
        return self
    }

    @discardableResult
    public func life( _ v:Float ) -> Self {
        status?.life = v
        return self
    }
    
    @discardableResult
    public func life( _ v:LLFloatConvertable ) -> Self {
        status?.life = v.f
        return self
    }
    
    @discardableResult
    public func color( _ c:LLColor ) -> Self {
        status?.color = c.floatv4
        return self
    }
    
    @discardableResult
    public func color( red:Float, green:Float, blue:Float, alpha:Float = 1.0 ) -> Self {
        status?.color = LLFloatv4( red, green, blue, alpha )
        return self
    }
    
    @discardableResult
    public func color( red:LLFloatConvertable, green:LLFloatConvertable,
                blue:LLFloatConvertable, alpha:LLFloatConvertable = 1.0 ) 
    -> Self
    {
        status?.color = LLFloatv4( red.f, green.f, blue.f, alpha.f )
        return self
    }
    
    @discardableResult
    public func alpha( _ c:Float ) -> Self {
        status?.color.w = c
        return self
    }
    
    @discardableResult
    public func alpha( _ v:LLFloatConvertable ) -> Self {
        status?.color.w = v.f
        return self
    }

    @discardableResult
    public func matrix( _ mat:LLMatrix4x4 ) -> Self {
        status?.matrix = mat
        return self
    }

    
    @discardableResult
    public func deltaPosition( _ p:LLPointFloat ) -> Self {
        status?.deltaPosition = LLFloatv2( p.x, p.y )
        return self
    }
    
    @discardableResult
    public func deltaPosition( dx:Float, dy:Float ) -> Self {
        status?.deltaPosition = LLFloatv2( dx, dy )
        return self
    }
    
    @discardableResult
    public func deltaPosition( dx:LLFloatConvertable, dy:LLFloatConvertable ) -> Self {
        status?.deltaPosition = LLFloatv2( dx.f, dy.f )
        return self
    }

    @discardableResult
    public func deltaScale( _ dsc:LLSizeFloat ) -> Self {
        status?.deltaScale = LLFloatv2( dsc.width, dsc.height )
        return self
    }
    
    @discardableResult
    public func deltaScale( dw:Float, dh:Float ) -> Self {
        status?.deltaScale = LLFloatv2( dw, dh )
        return self
    }
    
    @discardableResult
    public func deltaScale( dw:LLFloatConvertable, dh:LLFloatConvertable ) -> Self {
        status?.deltaScale = LLFloatv2( dw.f, dh.f )
        return self
    }
    

    @discardableResult
    public func deltaColor( _ c:LLColor ) -> Self {
        status?.deltaColor = c.floatv4
        return self
    }
        
    @discardableResult
    public func deltaColor( red:Float, green:Float, blue:Float, alpha:Float = 0.0 ) -> Self {
        status?.deltaColor = LLFloatv4( red, green, blue, alpha )
        return self
    }
    
    @discardableResult
    public func deltaColor( red:LLFloatConvertable, green:LLFloatConvertable,
                     blue:LLFloatConvertable, alpha:LLFloatConvertable = 0.0 )
    -> Self
    {
        status?.deltaColor = LLFloatv4( red.f, green.f, blue.f, alpha.f )
        return self
    }

    
    @discardableResult
    public func deltaAlpha( _ v:Float ) -> Self {
        status?.deltaColor.w = v
        return self
    }
    
    @discardableResult
    public func deltaAlpha( _ v:LLFloatConvertable ) -> Self {
        status?.deltaColor.w = v.f
        return self
    }

        
    @discardableResult
    public func deltaAngle( _ ang:LLAngle ) -> Self {
        status?.deltaAngle = ang.radians.f
        return self
    }
    
    @discardableResult
    public func deltaAngle( radians rad:LLFloatConvertable ) -> Self {
        status?.deltaAngle = rad.f
        return self
    }
    
    @discardableResult
    public func deltaAngle( degrees deg:LLFloatConvertable ) -> Self {
        status?.deltaAngle = LLAngle.degrees( deg.f.d ).radians.f
        return self
    }
    
    
    @discardableResult
    public func deltaLife( _ v:Float ) -> Self {
        status?.deltaLife = v
        return self
    }
    
    @discardableResult
    public func deltaLife( _ v:LLFloatConvertable ) -> Self {
        status?.deltaLife = v.f
        return self
    }
}
