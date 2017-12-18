varying vec2 f_uv;
void main() {
    f_uv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}