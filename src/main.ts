import Stats from 'stats.js';
import { GUI } from 'dat.gui';

import { initWebGPU, Renderer } from './renderer';
import { NaiveRenderer } from './renderers/naive';
import { ForwardPlusRenderer } from './renderers/forward_plus';
import { ClusteredDeferredRenderer } from './renderers/clustered_deferred';

import { setupLoaders, Scene } from './stage/scene';
import { Lights } from './stage/lights';
import { Camera } from './stage/camera';
import { Stage } from './stage/stage';

await initWebGPU();
setupLoaders();

let scene = new Scene();

// load the custom scene
await scene.loadGltf('./scenes/scene/scene.gltf');

const camera = new Camera();
const lights = new Lights(camera);

const stats = new Stats();

const stage = new Stage(scene, lights, camera, stats);

// always use the clustered deferred renderer
var renderer = new ClusteredDeferredRenderer(stage);
