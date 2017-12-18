const THREE = require('three');
const EffectComposer = require('three-effectcomposer')(THREE)

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
    var renderTarget1 = new THREE.WebGLRenderTarget(Math.ceil(window.innerWidth * OneOver2Pow7), Math.ceil(window.innerHeight * OneOver2Pow7));
    var composer1 = new EffectComposer(renderer, renderTarget1);
    
    // The first render pass should not use the raydirections and t-values written in a texture because there is no previous pass
    // should create one shader and pass a define instead
	var conemarchPass1 = new EffectComposer.ShaderPass({
        uniforms: {
            u_time: {
                type: 'f',
                value: 0
            },
            u_resolution: {
                type: 'v2',
                value: new THREE.Vector2(Math.ceil(window.innerWidth * OneOver2Pow7), Math.ceil(window.innerHeight * OneOver2Pow7))
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
    
    // Render pass 2-7
    var renderTarget2 = new THREE.WebGLRenderTarget(Math.ceil(window.innerWidth * OneOver2Pow6), Math.ceil(window.innerHeight * OneOver2Pow6));
    var composer2 = new EffectComposer(renderer, renderTarget2);
    
	var conemarchPass2 = new EffectComposer.ShaderPass({
        uniforms: {
            u_time: {
                type: 'f',
                value: 0
            },
            u_resolution: {
                type: 'v2',
                value: new THREE.Vector2(Math.ceil(window.innerWidth * OneOver2Pow6), Math.ceil(window.innerHeight * OneOver2Pow6))
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
    
    // Render pass 8 (final pass)
    var renderTarget8 = new THREE.WebGLRenderTarget(window.innerWidth, window.innerHeight);
    var composer8 = new EffectComposer(renderer, renderTarget8);
    
	var conemarchPass8 = new EffectComposer.ShaderPass({
        uniforms: {
            u_time: {
                type: 'f',
                value: 0
            },
            u_resolution: {
                type: 'v2',
                value: new THREE.Vector2(window.innerWidth, window.innerHeight)
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
    conemarchPass8.renderToScreen = true; // crucial

    composer1.addPass(conemarchPass1);
    composer2.addPass(conemarchPass2);
    // ... 3-7
    composer8.addPass(conemarchPass8);

    // Each successive conemarch pass should read from the previous pass's render target
    conemarchPass2.material.uniforms.u_previous_conemarch.value = composer1.writeBuffer.texture;
    // ... 3-7
    conemarchPass8.material.uniforms.u_previous_conemarch.value = composer2.writeBuffer.texture;

    return {
        render: function(buffer, clock) {
            conemarchPass1.uniforms["u_time"].value = clock.getElapsedTime();
            conemarchPass2.uniforms["u_time"].value = clock.getElapsedTime();
            // ... 3-7
            conemarchPass8.uniforms["u_time"].value = clock.getElapsedTime();
            
            composer1.render();
            composer2.render();
            // ... 3-7
            composer8.render();
        }
    }
}