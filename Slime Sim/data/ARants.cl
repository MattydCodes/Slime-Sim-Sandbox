float dist(float x, float y, float x1, float y1){
    return sqrt(pow(x-x1,2)+pow(y-y1,2));
}

__kernel void ARants(__global float* x,__global float* y, __global float* ants, int mouseX, int mouseY, float radius, float strength) {

    int gid = get_global_id(0);
    
    if(ants[gid] == 1){
        float xDiff = mouseX-x[gid];
        float yDiff = mouseY-y[gid];
        
        float d = dist(mouseX,mouseY,x[gid],y[gid]);
        
        xDiff/=d;
        yDiff/=d;
        
        float g = strength / (d/radius);
        
        xDiff*=g;
        yDiff*=g;
        
        x[gid]+=xDiff;
        y[gid]+=yDiff;
    }
    
}

