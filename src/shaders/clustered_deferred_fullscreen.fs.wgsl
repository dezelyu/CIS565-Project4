
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

// declare the intermediate texture
@group(0) @binding(3)
var depth_texture: texture_2d<f32>;

// declare the variable for the lights
@group(0) @binding(4)
var<storage, read> lights: LightSet;

// declare the variable for the cluster grid
@group(1) @binding(0)
var<uniform> cluster_grid: vec4<u32>;

// declare the variable for the light indices
@group(1) @binding(3)
var<storage, read_write> indices: cluster_index_data;

// declare the fragment shader
@fragment fn main(data: IntermediateData) -> @location(0) vec4f {
    
    // acquire the intermediate color
    var color = textureSample(
        intermediate_texture,
        intermediate_texture_sampler,
        data.coordinate
    );
    
    // extract the normal
    let normal = vec3f(
        color.r,
        color.g,
        color.b
    );
    
    // extract the color
    let a = color.a;
    let b = floor(a / (1000.0f * 1000.0f));
    let g = floor((a - b * 1000.0f * 1000.0f) / 1000.0f);
    let r = (a - g * 1000.0f - b * 1000.0f * 1000.0f);
    color = vec4f(vec3f(r, g, b) / 1000.0f, 1.0f);
    
    // extract the r component from the depth texture
    var depth_r = textureSample(
        depth_texture,
        intermediate_texture_sampler,
        data.coordinate
    ).r;
    
    // compute the pixel_coordinate
    var pixel_coordinate = vec4f(
        data.coordinate.x * 2.0f - 1.0f,
        (1.0f - data.coordinate.y) * 2.0f - 1.0f,
        depth_r,
        1.0f
    );
    
    // compute the view space position
    var view_space_position = camera.inverse_projection * pixel_coordinate;
    
    // perform perspective divide
    view_space_position /= view_space_position.w;
    
    // compute the world space position
    var world_space_position = camera.inverse_view * vec4f(view_space_position.xyz, 1.0f);
    
    // project the fragment position
    let position = camera.matrix * vec4f(world_space_position.xyz, 1.0f);
    
    // compute the pixel-space coordinate
    let coordinate = position.xy / position.w;
    
    // compute the linear depth
    let depth = log(position.z / camera.camera.x) / log(camera.camera.y / camera.camera.x);
    
    // compute the cluster's x index
    let x = u32(floor((coordinate.x * 0.5f + 0.5f) * f32(cluster_grid.x)));
    
    // compute the cluster's y index
    let y = u32(floor((coordinate.y * 0.5f + 0.5f) * f32(cluster_grid.y)));
    
    // compute the cluster's z index
    let z = u32(floor(depth * f32(cluster_grid.z)));
    
    // compute the cluster index
    let index = x + y * cluster_grid.x + z * cluster_grid.x * cluster_grid.y;
    
    // compute the start index for the lights to iterate
    let start_index = index * cluster_grid.w;
    
    // declare the variable for the total light contribution
    var total_light_contribution = vec3f(0.0f, 0.0f, 0.0f);
    
    // declare the number of lights iterated
    var count = 0u;
    
    // iterate through the lights in this cluster
    while (count < cluster_grid.w) {
        
        // acquire the current index
        let light_index = indices.indices[start_index + count];
        
        // exit when the termination condition is met
        if (light_index == 2 << 30) {
            break;
        }
        
        // acquire the current light
        let light = lights.lights[light_index];
        
        // update the total light contribution
        total_light_contribution += calculateLightContrib(
            light, world_space_position.xyz, normal
        );
        
        // increase the count
        count += 1;
    }
    
    // compute the lambert shading factor
    var lambert_factor = max(0.0f, dot(normalize(normal), normalize(vec3(1.0f, 1.0f, -1.0f))));
    
    // add another directional light
    lambert_factor += max(0.0f, dot(normalize(normal), normalize(vec3(1.0f, -1.0f, -1.0f))));
    
    // compute the luminance from the lighting factor
    let luminance = dot(vec3f(lambert_factor), vec3f(0.299f, 0.587f, 0.114f));
    
    // compute the shading intensity with four layers
    let intensity = vec3f(1.0f, 0.8f, 0.4f) * floor(luminance * 4.0f) / 12.0f;
    
    // update the total light contribution
    total_light_contribution += vec3f(lambert_factor * 0.2f + 0.2f);
    
    // update the color based on the total light contribution and the shading intensity
    color = vec4f(color.rgb * total_light_contribution * 0.8f + color.rgb * intensity, 1.0f);
    
    // define the offsets for the neighboring pixels
    let offset = 2.0f / vec2f(camera.camera.z, camera.camera.w);
    
    // sample the depth data at neighboring pixels
    var depth_left = textureSample(
        depth_texture,
        intermediate_texture_sampler,
        data.coordinate + vec2f(-offset.x, 0.0f)
    ).r;
    var depth_right = textureSample(
        depth_texture,
        intermediate_texture_sampler,
        data.coordinate + vec2f(offset.x, 0.0f)
    ).r;
    var depth_up = textureSample(
        depth_texture,
        intermediate_texture_sampler,
        data.coordinate + vec2f(0.0f, offset.y)
    ).r;
    var depth_down = textureSample(
        depth_texture,
        intermediate_texture_sampler,
        data.coordinate + vec2f(0.0f, -offset.y)
    ).r;
    
    // declare the threshold for edge detection
    let threshold = 0.0005f;
    
    // darken the edges
    if (abs(depth_r - depth_left) > threshold ||
        abs(depth_r - depth_right) > threshold ||
        abs(depth_r - depth_up) > threshold ||
        abs(depth_r - depth_down) > threshold) {
        color *= 0.5f;
    }
    
    // compute the distance to the nearest border
    let distance = min(
        min(data.coordinate.x, 1.0f - data.coordinate.x),
        min(data.coordinate.y, 1.0f - data.coordinate.y)
    );
    
    // compute the darkening factor
    let darkening_factor = 0.4f - smoothstep(0.0f, 0.1f, distance) * 0.4f;
    
    // darken the borders
    color = mix(color, vec4f(0.0f, 0.0f, 0.0f, 1.0f), darkening_factor);
    
    // return the fragment color
    return vec4f(color.rgb, 1.0f);
}
