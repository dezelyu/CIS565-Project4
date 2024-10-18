import { Mat4, mat4, Vec3, vec3 } from "wgpu-matrix";
import { toRadians } from "../math_util";
import { device, canvas, fovYDegrees, aspectRatio } from "../renderer";

class CameraUniforms {
    
    // declare a new buffer variable
    readonly buffer = new ArrayBuffer(
        16 * 4
        + 4 * 4
        + 16 * 4
        + 16 * 4
    );
    
    private readonly floatView = new Float32Array(this.buffer);

    set viewProjMat(mat: Float32Array) {
        
        // update the view-projection matrix
        this.floatView.set(mat, 0);
    }

    // declare a setter for the camera vector
    set camera(value: Float32Array) {
        
        // update the camera vector
        this.floatView.set(value, 16);
    }
    
    // declare a setter for the inverse projection matrix
    set inverse_projection(matrix: Float32Array) {
        
        // update the camera vector
        this.floatView.set(matrix, 20);
    }
    
    // declare a setter for the inverse view matrix
    set inverse_view(matrix: Float32Array) {
        
        // update the camera vector
        this.floatView.set(matrix, 36);
    }
}

export class Camera {
    uniforms: CameraUniforms = new CameraUniforms();
    uniformsBuffer: GPUBuffer;

    projMat: Mat4 = mat4.create();
    cameraPos: Vec3 = vec3.create(-7, 2, 0);
    cameraFront: Vec3 = vec3.create(0, 0, -1);
    cameraUp: Vec3 = vec3.create(0, 1, 0);
    cameraRight: Vec3 = vec3.create(1, 0, 0);
    yaw: number = 0;
    pitch: number = 0;
    moveSpeed: number = 0.004;
    sensitivity: number = 0.15;

    static readonly nearPlane = 0.1;
    static readonly farPlane = 1000;

    keys: { [key: string]: boolean } = {};

    constructor () {
        
        // allocate the camera's uniform buffer
        this.uniformsBuffer = device.createBuffer({
            label: "camera",
            size: this.uniforms.buffer.byteLength,
            usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
        });
        
        this.projMat = mat4.perspective(toRadians(fovYDegrees), aspectRatio, Camera.nearPlane, Camera.farPlane);

        this.rotateCamera(0, 0); // set initial camera vectors
    }

    private onKeyEvent(event: KeyboardEvent, down: boolean) {
        this.keys[event.key.toLowerCase()] = down;
        if (this.keys['alt']) { // prevent issues from alt shortcuts
            event.preventDefault();
        }
    }

    private rotateCamera(dx: number, dy: number) {
        this.yaw += dx;
        this.pitch -= dy;

        if (this.pitch > 89) {
            this.pitch = 89;
        }
        if (this.pitch < -89) {
            this.pitch = -89;
        }

        const front = mat4.create();
        front[0] = Math.cos(toRadians(this.yaw)) * Math.cos(toRadians(this.pitch));
        front[1] = Math.sin(toRadians(this.pitch));
        front[2] = Math.sin(toRadians(this.yaw)) * Math.cos(toRadians(this.pitch));

        this.cameraFront = vec3.normalize(front);
        this.cameraRight = vec3.normalize(vec3.cross(this.cameraFront, [0, 1, 0]));
        this.cameraUp = vec3.normalize(vec3.cross(this.cameraRight, this.cameraFront));
    }

    private onMouseMove(event: MouseEvent) {
        if (document.pointerLockElement === canvas) {
            this.rotateCamera(event.movementX * this.sensitivity, event.movementY * this.sensitivity);
        }
    }

    private processInput(deltaTime: number) {
        let moveDir = vec3.create(0, 0, 0);
        if (this.keys['w']) {
            moveDir = vec3.add(moveDir, this.cameraFront);
        }
        if (this.keys['s']) {
            moveDir = vec3.sub(moveDir, this.cameraFront);
        }
        if (this.keys['a']) {
            moveDir = vec3.sub(moveDir, this.cameraRight);
        }
        if (this.keys['d']) {
            moveDir = vec3.add(moveDir, this.cameraRight);
        }
        if (this.keys['q']) {
            moveDir = vec3.sub(moveDir, this.cameraUp);
        }
        if (this.keys['e']) {
            moveDir = vec3.add(moveDir, this.cameraUp);
        }

        let moveSpeed = this.moveSpeed * deltaTime;
        const moveSpeedMultiplier = 3;
        if (this.keys['shift']) {
            moveSpeed *= moveSpeedMultiplier;
        }
        if (this.keys['alt']) {
            moveSpeed /= moveSpeedMultiplier;
        }

        if (vec3.length(moveDir) > 0) {
            const moveAmount = vec3.scale(vec3.normalize(moveDir), moveSpeed);
            this.cameraPos = vec3.add(this.cameraPos, moveAmount);
        }
    }

    onFrame(deltaTime: number) {
        this.processInput(deltaTime);

        const lookPos = vec3.add(this.cameraPos, vec3.scale(this.cameraFront, 1));
        const viewMat = mat4.lookAt(this.cameraPos, lookPos, [0, 1, 0]);
        const viewProjMat = mat4.mul(this.projMat, viewMat);
        
        // update the view-projection matrix
        this.uniforms.viewProjMat = viewProjMat;
        
        // acquire the main canvas
        let canvas = document.getElementById("mainCanvas") as HTMLCanvasElement;
        
        // acquire the canvas's width and height
        let width = canvas.clientWidth * window.devicePixelRatio;
        let height = canvas.clientHeight * window.devicePixelRatio;
        
        // update the camera vector
        this.uniforms.camera = [
            Camera.nearPlane,
            Camera.farPlane,
            width,
            height,
        ];
        
        // update the inverse projection and view matrices
        this.uniforms.inverse_projection = mat4.invert(this.projMat);
        this.uniforms.inverse_view = mat4.invert(viewMat);
        
        // upload the uniform buffer
        device.queue.writeBuffer(
            this.uniformsBuffer, 0,
            this.uniforms.buffer
        );
    }
}
