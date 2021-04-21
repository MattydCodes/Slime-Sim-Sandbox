__kernel void fade(__global float* c) 
{
    int gid = get_global_id(0);
    
    float t = c[gid];
    
    //t = ((1/(pow(1,-t)+1))-0.5)*2.0;
    
    t*=0.9;
    
    c[gid] = t;
}