//
// LilySwift Library Project
//
// Copyright (c) Watanabe-Denki, Inc. and Kengo Watanabe.
//   https://wdkk.co.jp/
//
// This software is released under the MIT License.
//   https://opensource.org/licenses/mit-license.php
//

import Foundation

/// zlibモジュール
open class LLZ
{
    /// zlibのアルゴリズムでデータを伸長する
    /// - Parameter data: 圧縮されたデータオブジェクト
    /// - Returns: 伸長後のデータオブジェクト(失敗時サイズ0のデータオブジェクトを返す)
    public static func inflate( _ data:Data )
    -> Data { 
        return data.withUnsafeBytes { 
            guard let ptr:OpaquePointer = OpaquePointer( $0.baseAddress ) else { return Data() }
            let inf_data:LCDataSmPtr = LCZInflate( LLNonNullUInt8Ptr( ptr ), $0.count )
            guard let inf_ptr = LCDataPointer( inf_data ) else { return Data() }
            guard let length:Int = LCDataLength( inf_data ).i else { return Data() }
            
            let nocopy_data:Data = Data( bytesNoCopy: inf_ptr,
                                         count: length,
                                         deallocator: .none ) 
            return nocopy_data
        }
    }
    
	public static func deflate( _ data:Data, type:LLZCompressionType = .default_compression )
    -> Data {
        return data.withUnsafeBytes { 
            guard let ptr:OpaquePointer = OpaquePointer( $0.baseAddress ) else { return Data() }
            let def_data:LCDataSmPtr = LCZDeflate( LLNonNullUInt8Ptr( ptr ), $0.count, type )
            guard let def_ptr = LCDataPointer( def_data ) else { return Data() }
            guard let length:Int = LCDataLength( def_data ).i else { return Data() }
            
            let nocopy_data:Data = Data( bytesNoCopy: def_ptr,
                                         count: length,
                                         deallocator: .none ) 
            return nocopy_data
        }
    }
}
