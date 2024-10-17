
// declare the variable for the camera
@group(${bindGroup_scene}) @binding(0)
var<uniform> camera: CameraUniforms;

// declare the diffuse texture
@group(${bindGroup_material}) @binding(0)
var diffuse_texture: texture_2d<f32>;

// declare the diffuse texture sampler
@group(${bindGroup_material}) @binding(1)
var diffuse_texture_sampler: sampler;

// declare the intermediate data
struct IntermediateData {
    
    // declare the fragment position
    @location(0) point: vec3f,
    
    // declare the fragment normal
    @location(1) normal: vec3f,
    
    // declare the fragment texture coordinate
    @location(2) coordinate: vec2f
};

// declare the fragment shader
@fragment fn main(data: IntermediateData) -> @location(0) vec4f {
    
    // acquire the diffuse color
    var color = textureSample(
        diffuse_texture,
        diffuse_texture_sampler,
        data.coordinate
    );
    
    // perform alpha cut with a threshold of 0.5
    if (color.a < 0.5f) {
        discard;
    }
    
    // compute and return the fragment color
    return vec4(color.rgb, 1.0f);
}
