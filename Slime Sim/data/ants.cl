


float random(int id, int frame){
    return cos(cos(cos((id*id*frame+frame)*234.54676)*458.9058)*3242.43276);
}



float brightness(float x, float y,__global float* img){  
    int index = (int)x + (int)y*500;
    if(index > -1 && index < 500*500){
        return img[index];
    }
    return 0;
}




float steerAdv(float x, float y, float r, __global float* img){
    int samples = 6;
    
    float totalAngle = 0;
    float total = 0;
    
    float HALF_PI = 1.570796;
    float PI = 3.141592;
    
    for(int i = 0; i < samples; i++){
        float rot = r - HALF_PI/2.0 + HALF_PI*(i+0.5)/samples;
        
        float px = x + cos(rot)*10;
        float py = y + sin(rot)*10;
        
        float v = brightness(px,py,img);
        
        totalAngle+=rot*v;
        total+=v;
    }
    
    totalAngle/=total;
    
    if(total == 0){
        return r;
    }
    
    return totalAngle;
}



__kernel void ants(__global float* x,__global float* y, __global float* rot, __global float* c, int n, __global float* ants, float ss, float rs) 
{
    int gid = get_global_id(0);
    
    if(ants[gid] != 0){
    
    float dx = cos(rot[gid]);
    float dy = sin(rot[gid]);
    
    x[gid]+=dx;
    y[gid]+=dy;
    
    rot[gid] = rot[gid]*(1.0-ss) + steerAdv(x[gid],y[gid],rot[gid],c)*ss;
    rot[gid]+=random(gid,n)*rs;
    
    if(x[gid] > 499.99){
        x[gid] = 499.99;
        rot[gid]-=1.570796;
    }
    if(x[gid] < 0){
        x[gid] = 0;
        rot[gid]-=1.570796;
    }
    
    if(y[gid] > 499.99){
        y[gid] = 499.99;
        rot[gid]-=1.570796;
    }
    if(y[gid] < 0){
        y[gid] = 0;
        rot[gid]-=1.570796;
    }  
    
    int index = (int)x[gid] + (int)y[gid]*500;
    
    c[index] = c[index] + 1;
    }
}

