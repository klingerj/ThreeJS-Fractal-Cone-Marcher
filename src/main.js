require('file-loader?name=[name].[ext]!../index.html');

const THREE = require('three');
const OrbitControls = require('three-orbit-controls')(THREE)

import DAT from 'dat-gui'
import Stats from 'stats-js'
import ProxyGeometry, {ProxyMaterial} from './proxy_geometry'
import RayMarcher from './rayMarching'

var BoxGeometry = new THREE.BoxGeometry(1, 1, 1);
var SphereGeometry = new THREE.SphereGeometry(1, 32, 32);
var ConeGeometry = new THREE.ConeGeometry(1, 1);

var clock = new THREE.Clock();

window.addEventListener('load', function() {
    var stats = new Stats();
    stats.setMode(1);
    stats.domElement.style.position = 'absolute';
    stats.domElement.style.left = '0px';
    stats.domElement.style.top = '0px';
    document.body.appendChild(stats.domElement);

    var scene = new THREE.Scene();
    var camera = new THREE.PerspectiveCamera( 75, window.innerWidth/window.innerHeight, 0.1, 1000 );
    var renderer = new THREE.WebGLRenderer( { antialias: true } );
    renderer.setPixelRatio(window.devicePixelRatio);
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.setClearColor(0x999999, 1.0);
    document.body.appendChild(renderer.domElement);

    var controls = new OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;
    controls.enableZoom = true;
    controls.rotateSpeed = 0.3;
    controls.zoomSpeed = 1.0;
    controls.panSpeed = 2.0;

    window.addEventListener('resize', function() {
        camera.aspect = window.innerWidth / window.innerHeight;
        camera.updateProjectionMatrix();
        renderer.setSize(window.innerWidth, window.innerHeight);
    });

    scene.add(new THREE.AxisHelper(20));
    scene.add(new THREE.DirectionalLight(0xffffff, 1));

    var proxyGeometry = new ProxyGeometry();

    var boxMesh = new THREE.Mesh(BoxGeometry, ProxyMaterial);
    var sphereMesh = new THREE.Mesh(SphereGeometry, ProxyMaterial);
    var coneMesh = new THREE.Mesh(ConeGeometry, ProxyMaterial);
    
    boxMesh.position.set(-3, 0, 0);
    coneMesh.position.set(3, 0, 0);

    proxyGeometry.add(boxMesh);
    proxyGeometry.add(sphereMesh);
    proxyGeometry.add(coneMesh);

    scene.add(proxyGeometry.group);

    camera.position.set(5, 10, 15);
    camera.lookAt(new THREE.Vector3(0,0,0));
    controls.target.set(0,0,0);
    
    var rayMarcher = new RayMarcher(renderer, scene, camera);

    (function tick() {
        controls.update();
        stats.begin();
        proxyGeometry.update();
        rayMarcher.render(proxyGeometry.buffer, clock);
        stats.end();
        requestAnimationFrame(tick);
    })();
});