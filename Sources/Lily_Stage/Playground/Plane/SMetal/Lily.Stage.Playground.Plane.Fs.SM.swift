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
    public static var Fs_SMetal:String { """
    //#import "Lily.Stage.Playground.Plane.h"
    \(Lily.Stage.Playground.Plane.h_SMetal)
    
    namespace Lily
    {
        namespace Stage 
        {
            namespace Playground
            {
                namespace Plane
                {
                    float4 drawPlane( Plane::VOut in ) {
                        return in.color;
                    }
                    
                    float4 drawCircle( Plane::VOut in ) {
                        float x = in.xy.x;
                        float y = in.xy.y;
                        float r = x * x + y * y;
                        if( r > 1.0 ) { discard_fragment(); }
                        return in.color;
                    } 
                    
                    float4 drawBlurryCircle( Plane::VOut in ) {
                        float x = in.xy.x;
                        float y = in.xy.y;
                        float r = sqrt( x * x + y * y );
                        if( r > 1.0 ) { discard_fragment(); }
                        
                        float4 c = in.color;
                        c[3] *= (1.0 + cos( r * M_PI_F )) * 0.5;
                        
                        return c;
                    } 
                    
                    float4 drawPicture( Plane::VOut in, texture2d<float> tex ) {
                        constexpr sampler sampler( mip_filter::nearest, mag_filter::nearest, min_filter::nearest );
                        
                        if( is_null_texture( tex ) ) { discard_fragment(); }
                        
                        float4 tex_c = tex.sample( sampler, in.texUV );
                        float4 c = in.color;
                        tex_c[3] *= c[3];
                        return tex_c;
                    } 
                    
                    float4 drawMask( Plane::VOut in, texture2d<float> tex ) {
                        constexpr sampler sampler( mip_filter::nearest, mag_filter::nearest, min_filter::nearest );
                        
                        if( is_null_texture( tex ) ) { discard_fragment(); }
                        
                        float4 tex_c = tex.sample( sampler, in.texUV );
                        float4 c = in.color;
                        c[3] *= tex_c[0];
                        return c;
                    } 
                }
            }
        }
    }

    fragment Plane::Result Lily_Stage_Playground_Plane_Fs(
        const Plane::VOut in [[ stage_in ]],
        texture2d<float> tex [[ texture(1) ]]
    )
    {
        auto type = Plane::ShapeType( in.shapeType );
        float4 color = float4( 0 );
        switch( type ) {
            case Plane::rectangle:
                color = Plane::drawPlane( in );
                break;
            case Plane::triangle:
                color = Plane::drawPlane( in );
                break;
            case Plane::circle:
                color = Plane::drawCircle( in );
                break;
            case Plane::blurryCircle:
                color = Plane::drawBlurryCircle( in );
                break;
            case Plane::picture:
                color = Plane::drawPicture( in, tex );
                break;
            case Plane::mask:
                color = Plane::drawMask( in, tex );
                break;
            default:
                discard_fragment();
        }
        
        Plane::Result result;
        result.planeTexture = color;
        return result;
    }

    """
    }
}
