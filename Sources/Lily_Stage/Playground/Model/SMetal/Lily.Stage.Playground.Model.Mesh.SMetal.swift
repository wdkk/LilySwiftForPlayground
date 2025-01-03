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
    open class SMetal
    {
        public let comDeltaShader:Lily.Metal.Shader
        public let vertexShader:Lily.Metal.Shader
        public let fragmentShader:Lily.Metal.Shader
        public let shadowVertexShader:Lily.Metal.Shader

        nonisolated(unsafe) private static var instance:SMetal?
        public static func shared( device:MTLDevice ) -> SMetal {
            if instance == nil { instance = .init( device:device ) }
            return instance!
        }
        
        private init( device:MTLDevice ) {
            //LLLog( "文字列からシェーダを生成しています." )
            
            self.comDeltaShader = .init(
                device:device, 
                code:Lily.Stage.Playground.Model.Mesh.ComDelta_SMetal,
                shaderName:"Lily_Stage_Playground_Model_Mesh_Com_Delta" 
            )
            
            self.vertexShader = .init(
                device:device, 
                code: Lily.Stage.Playground.Model.Mesh.Vs_SMetal,
                shaderName:"Lily_Stage_Playground_Model_Mesh_Vs" 
            )
            
            self.fragmentShader = .init(
                device:device,
                code: Lily.Stage.Playground.Model.Mesh.Fs_SMetal,
                shaderName:"Lily_Stage_Playground_Model_Mesh_Fs" 
            )
            
            self.shadowVertexShader = .init(
                device:device, 
                code: Lily.Stage.Playground.Model.Mesh.ShadowVs_SMetal,
                shaderName:"Lily_Stage_Playground_Model_Mesh_Shadow_Vs" 
            )
            
        }
    }
}

#endif
