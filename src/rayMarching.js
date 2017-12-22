const THREE = require('three');
const EffectComposer = require('three-effectcomposer')(THREE)
import {windowResPow2} from './main'

// Render target resolutions
const OneOver2Pow7 = 0.0078125;
const OneOver2Pow6 = 0.015625;
const OneOver2Pow5 = 0.03125;
const OneOver2Pow4 = 0.0625;
const OneOver2Pow3 = 0.125;
const OneOver2Pow2 = 0.25;
const OneOver2Pow1 = 0.5;

export default function RayMarcher(renderer, scene, camera) {
    
    /* Create 8 render passes of varying resolution */
    
    // Render pass 1
    var renderTarget1 = new THREE.WebGLRenderTarget(Math.ceil(windowResPow2.innerWidth * OneOver2Pow7), Math.ceil(windowResPow2.innerHeight * OneOver2Pow7));
    var composer1 = new EffectComposer(renderer, renderTarget1);
    
	var conemarchPass1 = new EffectComposer.ShaderPass({
        uniforms: {
            u_time: {
                type: 'f',
                value: 0
            },
            u_resolution: {
                type: 'v2',
                value: new THREE.Vector2(Math.ceil(windowResPow2.innerWidth * OneOver2Pow7), Math.ceil(windowResPow2.innerHeight * OneOver2Pow7))
            },
            u_aspect: {
                type: 'f',
                value: Math.ceil(windowResPow2.innerWidth * OneOver2Pow7) / Math.ceil(windowResPow2.innerHeight * OneOver2Pow7)
            },
            u_tan_fovy_over2: {
                type: 'f',
                value: Math.tan(22.5 * 0.01745329251) // that's pi/180
            },
            u_is_first_pass: {
                type: 'i',
                value: 1
            },
            u_is_final_pass: {
                type: 'i',
                value: 0
            }
        },
        vertexShader: require('./glsl/pass-vert.glsl'),
        fragmentShader: require('./glsl/conemarch-frag.glsl')
    });
    
    // Render pass 2
    var renderTarget2 = new THREE.WebGLRenderTarget(Math.ceil(windowResPow2.innerWidth * OneOver2Pow6), Math.ceil(windowResPow2.innerHeight * OneOver2Pow6));
    var composer2 = new EffectComposer(renderer, renderTarget2);
    
	var conemarchPass2 = new EffectComposer.ShaderPass({
        uniforms: {
            u_time: {
                type: 'f',
                value: 0
            },
            u_resolution: {
                type: 'v2',
                value: new THREE.Vector2(Math.ceil(windowResPow2.innerWidth * OneOver2Pow6), Math.ceil(windowResPow2.innerHeight * OneOver2Pow6))
            },
            u_aspect: {
                type: 'f',
                value: Math.ceil(windowResPow2.innerWidth * OneOver2Pow6) / Math.ceil(windowResPow2.innerHeight * OneOver2Pow6)
            },
            u_tan_fovy_over2: {
                type: 'f',
                value: Math.tan(22.5 * 0.01745329251) // that's pi/180
            },
            u_previous_conemarch: {
                type: 't',
                value: null
            },
            u_is_first_pass: {
                type: 'i',
                value: 0
            },
            u_is_final_pass: {
                type: 'i',
                value: 0
            }
        },
        vertexShader: require('./glsl/pass-vert.glsl'),
        fragmentShader: require('./glsl/conemarch-frag.glsl')
    });

    // Render pass 3
    var renderTarget3 = new THREE.WebGLRenderTarget(Math.ceil(windowResPow2.innerWidth * OneOver2Pow5), Math.ceil(windowResPow2.innerHeight * OneOver2Pow5));
    var composer3 = new EffectComposer(renderer, renderTarget3);
    
	var conemarchPass3 = new EffectComposer.ShaderPass({
        uniforms: {
            u_time: {
                type: 'f',
                value: 0
            },
            u_resolution: {
                type: 'v2',
                value: new THREE.Vector2(Math.ceil(windowResPow2.innerWidth * OneOver2Pow5), Math.ceil(windowResPow2.innerHeight * OneOver2Pow5))
            },
            u_aspect: {
                type: 'f',
                value: Math.ceil(windowResPow2.innerWidth * OneOver2Pow5) / Math.ceil(windowResPow2.innerHeight * OneOver2Pow5)
            },
            u_tan_fovy_over2: {
                type: 'f',
                value: Math.tan(22.5 * 0.01745329251) // that's pi/180
            },
            u_previous_conemarch: {
                type: 't',
                value: null
            },
            u_is_first_pass: {
                type: 'i',
                value: 0
            },
            u_is_final_pass: {
                type: 'i',
                value: 0
            }
        },
        vertexShader: require('./glsl/pass-vert.glsl'),
        fragmentShader: require('./glsl/conemarch-frag.glsl')
    });
    
    // Render pass 4
    var renderTarget4 = new THREE.WebGLRenderTarget(Math.ceil(windowResPow2.innerWidth * OneOver2Pow4), Math.ceil(windowResPow2.innerHeight * OneOver2Pow4));
    var composer4 = new EffectComposer(renderer, renderTarget4);
    
	var conemarchPass4 = new EffectComposer.ShaderPass({
        uniforms: {
            u_time: {
                type: 'f',
                value: 0
            },
            u_resolution: {
                type: 'v2',
                value: new THREE.Vector2(Math.ceil(windowResPow2.innerWidth * OneOver2Pow4), Math.ceil(windowResPow2.innerHeight * OneOver2Pow4))
            },
            u_aspect: {
                type: 'f',
                value: Math.ceil(windowResPow2.innerWidth * OneOver2Pow4) / Math.ceil(windowResPow2.innerHeight * OneOver2Pow4)
            },
            u_tan_fovy_over2: {
                type: 'f',
                value: Math.tan(22.5 * 0.01745329251) // that's pi/180
            },
            u_previous_conemarch: {
                type: 't',
                value: null
            },
            u_is_first_pass: {
                type: 'i',
                value: 0
            },
            u_is_final_pass: {
                type: 'i',
                value: 0
            }
        },
        vertexShader: require('./glsl/pass-vert.glsl'),
        fragmentShader: require('./glsl/conemarch-frag.glsl')
    });

    // Render pass 5
    var renderTarget5 = new THREE.WebGLRenderTarget(Math.round(windowResPow2.innerWidth * OneOver2Pow3), Math.round(windowResPow2.innerHeight * OneOver2Pow3));
    var composer5 = new EffectComposer(renderer, renderTarget5);
    
	var conemarchPass5 = new EffectComposer.ShaderPass({
        uniforms: {
            u_time: {
                type: 'f',
                value: 0
            },
            u_resolution: {
                type: 'v2',
                value: new THREE.Vector2(Math.round(windowResPow2.innerWidth * OneOver2Pow3), Math.round(windowResPow2.innerHeight * OneOver2Pow3))
            },
            u_aspect: {
                type: 'f',
                value: Math.round(windowResPow2.innerWidth * OneOver2Pow3) / Math.round(windowResPow2.innerHeight * OneOver2Pow3)
            },
            u_tan_fovy_over2: {
                type: 'f',
                value: Math.tan(22.5 * 0.01745329251) // that's pi/180
            },
            u_previous_conemarch: {
                type: 't',
                value: null
            },
            u_is_first_pass: {
                type: 'i',
                value: 0
            },
            u_is_final_pass: {
                type: 'i',
                value: 0
            }
        },
        vertexShader: require('./glsl/pass-vert.glsl'),
        fragmentShader: require('./glsl/conemarch-frag.glsl')
    });

    // Render pass 6
    var renderTarget6 = new THREE.WebGLRenderTarget(Math.round(windowResPow2.innerWidth * OneOver2Pow2), Math.round(windowResPow2.innerHeight * OneOver2Pow2));
    var composer6 = new EffectComposer(renderer, renderTarget6);
    
	var conemarchPass6 = new EffectComposer.ShaderPass({
        uniforms: {
            u_time: {
                type: 'f',
                value: 0
            },
            u_resolution: {
                type: 'v2',
                value: new THREE.Vector2(Math.round(windowResPow2.innerWidth * OneOver2Pow2), Math.round(windowResPow2.innerHeight * OneOver2Pow2))
            },
            u_aspect: {
                type: 'f',
                value: Math.round(windowResPow2.innerWidth * OneOver2Pow2) / Math.round(windowResPow2.innerHeight * OneOver2Pow2)
            },
            u_tan_fovy_over2: {
                type: 'f',
                value: Math.tan(22.5 * 0.01745329251) // that's pi/180
            },
            u_previous_conemarch: {
                type: 't',
                value: null
            },
            u_is_first_pass: {
                type: 'i',
                value: 0
            },
            u_is_final_pass: {
                type: 'i',
                value: 0
            }
        },
        vertexShader: require('./glsl/pass-vert.glsl'),
        fragmentShader: require('./glsl/conemarch-frag.glsl')
    });

    // Render pass 7
    var renderTarget7 = new THREE.WebGLRenderTarget(Math.round(windowResPow2.innerWidth * OneOver2Pow1), Math.round(windowResPow2.innerHeight * OneOver2Pow1));
    var composer7 = new EffectComposer(renderer, renderTarget7);
    
	var conemarchPass7 = new EffectComposer.ShaderPass({
        uniforms: {
            u_time: {
                type: 'f',
                value: 0
            },
            u_resolution: {
                type: 'v2',
                value: new THREE.Vector2(Math.round(windowResPow2.innerWidth * OneOver2Pow1), Math.round(windowResPow2.innerHeight * OneOver2Pow1))
            },
            u_aspect: {
                type: 'f',
                value: Math.round(windowResPow2.innerWidth * OneOver2Pow1) / Math.round(windowResPow2.innerHeight * OneOver2Pow1)
            },
            u_tan_fovy_over2: {
                type: 'f',
                value: Math.tan(22.5 * 0.01745329251) // that's pi/180
            },
            u_previous_conemarch: {
                type: 't',
                value: null
            },
            u_is_first_pass: {
                type: 'i',
                value: 0
            },
            u_is_final_pass: {
                type: 'i',
                value: 0
            }
        },
        vertexShader: require('./glsl/pass-vert.glsl'),
        fragmentShader: require('./glsl/conemarch-frag.glsl')
    });

    // Render pass 8 (raymarch pass)
    var renderTarget8 = new THREE.WebGLRenderTarget(windowResPow2.innerWidth, windowResPow2.innerHeight);
    var composer8 = new EffectComposer(renderer, renderTarget8);
    
	var conemarchPass8 = new EffectComposer.ShaderPass({
        uniforms: {
            u_time: {
                type: 'f',
                value: 0
            },
            u_resolution: {
                type: 'v2',
                value: new THREE.Vector2(windowResPow2.innerWidth, windowResPow2.innerHeight)
            },
            u_aspect: {
                type: 'f',
                value: windowResPow2.innerWidth / windowResPow2.innerHeight
            },
            u_tan_fovy_over2: {
                type: 'f',
                value: Math.tan(22.5 * 0.01745329251) // that's pi/180
            },
            u_previous_conemarch: {
                type: 't',
                value: null
            },
            u_is_first_pass: {
                type: 'i',
                value: 0
            },
            u_is_final_pass: {
                type: 'i',
                value: 1
            }
        },
        vertexShader: require('./glsl/pass-vert.glsl'),
        fragmentShader: require('./glsl/conemarch-frag.glsl')
    });    

    composer1.addPass(conemarchPass1);
    composer2.addPass(conemarchPass2);
    composer3.addPass(conemarchPass3);
    composer4.addPass(conemarchPass4);
    composer5.addPass(conemarchPass5);
    composer6.addPass(conemarchPass6);
    composer7.addPass(conemarchPass7);
    composer8.addPass(conemarchPass8);

    // Each successive conemarch pass should read from the previous pass's render target
    conemarchPass2.material.uniforms.u_previous_conemarch.value = composer1.writeBuffer.texture;
    conemarchPass3.material.uniforms.u_previous_conemarch.value = composer2.writeBuffer.texture;
    conemarchPass4.material.uniforms.u_previous_conemarch.value = composer3.writeBuffer.texture;
    conemarchPass5.material.uniforms.u_previous_conemarch.value = composer4.writeBuffer.texture;
    conemarchPass6.material.uniforms.u_previous_conemarch.value = composer5.writeBuffer.texture;
    conemarchPass7.material.uniforms.u_previous_conemarch.value = composer6.writeBuffer.texture;
    conemarchPass8.material.uniforms.u_previous_conemarch.value = composer7.writeBuffer.texture;

    conemarchPass8.renderToScreen = true;

    return {
        render: function(clock) {
            var time = clock.getElapsedTime();
            conemarchPass1.uniforms["u_time"].value = time;
            conemarchPass2.uniforms["u_time"].value = time;
            conemarchPass3.uniforms["u_time"].value = time;
            conemarchPass4.uniforms["u_time"].value = time;
            conemarchPass5.uniforms["u_time"].value = time;
            conemarchPass6.uniforms["u_time"].value = time;
            conemarchPass7.uniforms["u_time"].value = time;
            conemarchPass8.uniforms["u_time"].value = time;
            
            composer1.render();
            composer2.render();
            composer3.render();
            composer4.render();
            composer5.render();
            composer6.render();
            composer7.render();
            composer8.render();
        }
    }
}