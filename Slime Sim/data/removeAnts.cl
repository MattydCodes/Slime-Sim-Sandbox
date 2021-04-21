float dist(float x, float y, float x1, float y1){
    return sqrt(pow(x-x1,2)+pow(y-y1,2));
}

__kernel void removeAnts(__global float* x,__global float* y, __global float* ants, int mouseX, int mouseY, float radius) {

    int gid = get_global_id(0);
    
    if(ants[gid] == 1){
        if(dist(x[gid],y[gid],mouseX,mouseY) < radius){
            ants[gid] = 0;
        }
    }
    
}

