
// declare the intermediate data
struct IntermediateData {
    
    // declare the fragment texture coordinate
    @location(0) coordinate: vec2f
};

// declare the variable for the camera
@group(0) @binding(0)
var<uniform> camera: CameraUniforms;

// declare the intermediate texture
@group(0) @binding(1)
var intermediate_texture: texture_2d<f32>;

// declare the intermediate texture sampler
@group(0) @binding(2)
var intermediate_texture_sampler: sampler;

// declare the fragment shader
@fragment fn main(data: IntermediateData) -> @location(0) vec4f {
    
    // acquire the intermediate color
    var color = textureSample(
        intermediate_texture,
        intermediate_texture_sampler,
        data.coordinate
    );
    
    // return the fragment color
    return vec4f(color.rgb, 1.0f);
}
