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

extension Lily.Stage.Playground.Model.Mesh
{
    public static var ShadowVs_SMetal:String { """
    //#import "Lily.Stage.Playground.Model.Mesh.h"
    \(Lily.Stage.Playground.Model.Mesh.h_SMetal)
    
    vertex Model::Mesh::VOut Lily_Stage_Playground_Model_Mesh_Shadow_Vs
    (
        const device Obj::Vertex* in [[ buffer(0) ]],
        const device Model::Mesh::UnitStatus* statuses [[ buffer(1) ]],
        const device uint& cascadeIndex [[ buffer(2) ]],
        constant int& modelIndex [[ buffer(3) ]],
        constant float4x4& shadowCameraVPMatrix[[ buffer(6) ]],
        ushort amp_id [[ amplification_id ]],
        uint vid [[ vertex_id ]],
        uint iid [[ instance_id ]]
    )
    {
        int idx = iid;
        
        auto us = statuses[idx];
        
        // 一致しないインスタンスは破棄
        if( us.modelIndex != modelIndex ) { 
            Model::Mesh::VOut trush_vout;
            trush_vout.position = float4( 0, 0, Model::TOO_FAR, 0 );
            return trush_vout;
        }
        
        float4 position = float4( in[vid].position, 1.0 );
        
        // アフィン変換の作成
        float3 pos = us.position;
        float3 ro = us.rotation;
        float3 sc = us.scale;
        
        float4x4 TRS = affineTransform( pos, sc, ro );
        float4 world_pos = TRS * position;
        
        // 表示/非表示の判定( state, enabled, alphaのどれかが非表示を満たしているかを計算. 負の値 = 非表示 )
        float visibility_z = us.state * us.enabled * us.color[3] > 0.00001 ? 0.0 : Model::TOO_FAR;

        Model::Mesh::VOut out;
        out.position = shadowCameraVPMatrix * world_pos;
        out.position.z += visibility_z;
        return out;
    }

    """
    }
}

#endif
