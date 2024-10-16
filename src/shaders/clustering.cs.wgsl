
// declare the variable for the cluster grid
@group(0) @binding(0)
var<uniform> cluster_grid: vec4<u32>;

// declare the variable for the camera
@group(0) @binding(1)
var<uniform> camera: CameraUniforms;

// declare the variable for the lights
@group(0) @binding(2)
var<storage, read> lights: LightSet;

// declare the variable for the light indices
@group(0) @binding(3)
var<storage, read_write> indices: cluster_index_data;

// declare the compute shader
@compute @workgroup_size(${workgroup_size}) fn main(@builtin(global_invocation_id) index: vec3u) {
    
    // exit the compute shader if the index is out of bound
    if (index.x >= cluster_grid.x * cluster_grid.y * cluster_grid.z) {
        return;
    }
    
    // acquire the x index of the cluster
    let x = index.x % cluster_grid.x;
    
    // acquire the y index of the cluster
    let y = (index.x / cluster_grid.x) % cluster_grid.y;
    
    // acquire the z index of the cluster
    let z = index.x / (cluster_grid.x * cluster_grid.y);
    
    // compute the start index for the lights in this cluster
    let start_index = index.x * cluster_grid.w;
    
    // declare the variable for the number of lights in thie cluster
    var count = 0u;
    
    // iterate through all the lights
    for (var light_index = 0u; light_index < lights.numLights; light_index += 1) {
        
        // acquire the current light
        let light = lights.lights[light_index];
        
        // create a vector with the light's radius as each component
        let vector = vec3f(${lightRadius}, ${lightRadius}, ${lightRadius});
        
        // acquire and project the min position of the light's bounding box to the screen
        let min_position = camera.matrix * vec4(light.pos - vector, 1.0f);
        
        // acquire and project the max position of the light's bounding box to the screen
        let max_position = camera.matrix * vec4(light.pos + vector, 1.0f);
        
        // compute the min pixel-space coordinate
        let min_coordinate = min_position.xy / min_position.w;
        
        // compute the max pixel-space coordinate
        let max_coordinate = max_position.xy / max_position.w;
        
        // compute the light's min x index
        let min_x = u32(floor((min_coordinate.x * 0.5f + 0.5f) * f32(cluster_grid.x)));
        
        // compute the light's max x index
        let max_x = u32(floor((max_coordinate.x * 0.5f + 0.5f) * f32(cluster_grid.x)));
        
        // skip this light if its x is out of bound
        if (min_x > x || x > max_x) {
            continue;
        }
        
        // compute the light's min y index
        let min_y = u32(floor((min_coordinate.y * 0.5f + 0.5f) * f32(cluster_grid.y)));
        
        // compute the light's max y index
        let max_y = u32(floor((max_coordinate.y * 0.5f + 0.5f) * f32(cluster_grid.y)));
        
        // skip this light if its y is out of bound
        if (min_y > y || y > max_y) {
            continue;
        }
        
        // compute the minimal linear depth
        let min_depth = log(min_position.z / camera.camera.x) / log(camera.camera.y / camera.camera.x);
        
        // compute the maximal linear depth
        let max_depth = log(max_position.z / camera.camera.x) / log(camera.camera.y / camera.camera.x);
        
        // compute the index of the minimal linear depth
        let min_depth_index = u32(floor(min_depth * f32(cluster_grid.z)));
        
        // compute the index of the maximal linear depth
        let max_depth_index = u32(floor(max_depth * f32(cluster_grid.z)));
        
        // skip this light if its depth is out of bound
        if (min_depth_index > z || z > max_depth_index) {
            continue;
        }
        
        // write the light index
        indices.indices[start_index + count] = light_index;
        
        // increase the count
        count += 1;
        
        // exit when the index is out of range
        if (count >= cluster_grid.w) {
            break;
        }
    }
    
    // write the termination condition
    if (count < cluster_grid.w) {
        indices.indices[start_index + count] = 2 << 30;
    }
}
