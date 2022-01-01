void main() {
    float speed = u_time * u_speed * 0.05; // pass in speed
    float strength = u_strength / 100.0; // pass in strength
    
    vec2 coord = v_tex_coord;
    
    coord.x += sin((coord.x + speed) * u_frequency) * strength; // pass in frequency
    coord.y += cos((coord.y + speed) * u_frequency) * strength;
    
    gl_FragColor = texture2D(u_texture, coord) * v_color_mix.a; // Retain alpha channel
}
