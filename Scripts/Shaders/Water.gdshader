shader_type spatial;
render_mode blend_mix, cull_back, depth_draw_opaque, specular_schlick_ggx;

// Water color
uniform vec4 out_color : source_color = vec4(0.0, 0.2, 1.0, 1.0);

// Amount of height for each triangle
uniform float amount : hint_range(0.2, 5.0) = 0.8;

// Speed of wave motion
uniform float speed : hint_range(0.1, 5.0) = 1.0;

// Beer factor (controls depth-based transparency)
uniform float beer_factor = 0.2;

uniform float metallic = 0.6;
uniform float specular = 0.5;
uniform float roughness = 0.2;
uniform vec3 emission = vec3(0.0, 0.0, 0.0);

// Built-in in Godot 4: DEPTH_TEXTURE replaced by SCREEN_TEXTURE_DEPTH
uniform sampler2D SCREEN_TEXTURE_DEPTH : hint_depth_texture;

float generateOffset(float x, float z, float val1, float val2, float time) {
    float radiansX = ((mod(x + z * x * val1, amount) / amount) + (time * speed) * mod(x * 0.8 + z, 1.5)) * 2.0 * 3.14159;
    float radiansZ = ((mod(val2 * (z * x + x * z), amount) / amount) + (time * speed) * 2.0 * mod(x, 2.0)) * 2.0 * 3.14159;
    return amount * 0.5 * (sin(radiansZ) * cos(radiansX));
}

vec3 applyDistortion(vec3 vertex, float time) {
    float xd = generateOffset(vertex.x, vertex.z, 0.2, 0.1, time);
    float yd = generateOffset(vertex.x, vertex.z, 0.1, 0.3, time);
    float zd = generateOffset(vertex.x, vertex.z, 0.15, 0.2, time);
    return vertex + vec3(xd, yd, zd);
}

void vertex() {
    VERTEX = applyDistortion(VERTEX, TIME * 0.1);
}

void fragment() {
    // Recalculate normal from geometry
    NORMAL = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));

    METALLIC = metallic;
    SPECULAR = specular;
    ROUGHNESS = roughness;
    EMISSION = emission;
    ALBEDO = out_color.rgb;

    // Default alpha (make slightly transparent)
    float alpha_val = out_color.a * 0.85;

    if (beer_factor != 0.0) {
        float depth_tex = texture(SCREEN_TEXTURE_DEPTH, SCREEN_UV).r;

        // Convert from [0,1] to view-space depth
    }

    ALPHA = alpha_val;
}
