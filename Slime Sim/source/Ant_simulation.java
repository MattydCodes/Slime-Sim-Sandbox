import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import com.nativelibs4java.opencl.*; 
import com.nativelibs4java.opencl.CLMem.*; 
import java.nio.ByteOrder; 
import static java.lang.System.*; 
import static org.bridj.Pointer.*; 

import com.nativelibs4java.opencl.util.fft.*; 
import com.nativelibs4java.opencl.util.*; 
import com.nativelibs4java.opencl.*; 
import com.ochafik.util.string.*; 
import com.nativelibs4java.opencl.library.*; 
import org.bridj.*; 
import org.bridj.ann.*; 
import org.bridj.cpp.com.*; 
import org.bridj.cpp.com.shell.*; 
import org.bridj.cpp.*; 
import org.bridj.cpp.mfc.*; 
import org.bridj.cpp.std.*; 
import org.bridj.cs.*; 
import org.bridj.cs.dotnet.*; 
import org.bridj.cs.mono.*; 
import org.bridj.demangling.*; 
import org.bridj.dyncall.*; 
import org.bridj.func.*; 
import org.bridj.jawt.*; 
import org.bridj.objc.*; 
import org.bridj.util.*; 
import org.bridj.relocated.org.objectweb.asm.*; 
import org.bridj.relocated.org.objectweb.asm.signature.*; 
import com.nativelibs4java.util.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class Ant_simulation extends PApplet {









int ants = 0;

int maxAnts = 1000000;

FloatArray antBuffer;

FloatArray posX;
FloatArray posY;
FloatArray rotation;

FloatArray out;

Kernel Ants;

Kernel fade;

Kernel remove;

Kernel ARants;

float mouseRadius = 50;

boolean shift = false;

int totalSpawned = 0;

float steerStrength = 0.5f;
float randomStrength = 0.4f;

boolean steer = false;
boolean rnd = false;


public void setup(){
  
  setupCL();
  
  posX = new FloatArray(maxAnts);
  posY = new FloatArray(maxAnts);
  rotation = new FloatArray(maxAnts);
  antBuffer = new FloatArray(maxAnts);
  
  out = new FloatArray(width*height);
  
  posX.updateBuffer();
  posY.updateBuffer();
  rotation.updateBuffer();
  antBuffer.updateBuffer();
  
  Ants = new Kernel("ants.cl","ants");
  fade = new Kernel("fadeBlack.cl","fade");
  remove = new Kernel("removeAnts.cl","removeAnts");
  ARants = new Kernel("ARants.cl","ARants");
  
}


public void draw(){
  if(ants > 0){
    Ants.setArgs(new Object[]{posX.arg,posY.arg,rotation.arg,out.arg,frameCount,antBuffer.arg,steerStrength,randomStrength});
    Ants.run(maxAnts);  
    posX.read();
    posY.read();
    rotation.read();  
    out.read();
  }

  fade.setArgs(new Object[]{out.arg});
  out.read(fade.run(width*height));
  loadPixels();  
  float avgB = 0;
  for(int i = 0; i < pixels.length; i++){
    avgB += out.get(i);
  }
  
  avgB/=pixels.length;
  avgB*=9;
  avgB+=1;
  
  for(int i = 0; i < pixels.length; i++){
    float b = out.get(i)/avgB;    
    pixels[i] = color(3*b, 190*b, 252*b);
  }
  updatePixels();  
  
  
  userControls();
  
  noFill();
  stroke(255,150);
  strokeWeight(3);
  ellipse(mouseX,mouseY,mouseRadius*2,mouseRadius*2);
  fill(255);
  textSize(12);
  text("Steer: " + steerStrength,10,15);
  text("Rnd: " + randomStrength,10,35);
}



public void keyPressed(){
  if(keyCode == 16){
    shift = true;
  }
  if(key == '1'){
    steer = true;
  }
  if(key == '2'){
    rnd = true;
  }
}

public void keyReleased(){
  if(keyCode == 16){
    shift = false;
  }
  if(key == '1'){
    steer = false;
  }
  if(key == '2'){
    rnd = false;
  }
}


public void userControls(){ //Float Array containing Indexes of the ants which don't exist. Pointer integer variables will be used to point out the lowest value within the pointer to turn on.

  int antsAdd = 100;
  
  if(mousePressed){
    if(mouseButton == LEFT){
      if(shift){
        //Adds ants.
        int index = 0;
        for(int i = 0; i < antsAdd; i++){
            for(;index < maxAnts; index++){
              if(antBuffer.get(index) == 0){
                break;
              }
            }
            
            posX.set(index,mouseX);
            posY.set(index,mouseY);
            rotation.set(index,i/(float)antsAdd*TAU);
            antBuffer.set(index,1);
            
        }
        
        ants+=antsAdd;
        totalSpawned+=antsAdd;
        posX.updateBuffer();
        posY.updateBuffer();
        rotation.updateBuffer();
        antBuffer.updateBuffer();
                    
      }else{
        applyForce(1);
      }
      
    }else if(mouseButton == RIGHT){
      if(shift){
        //Remove ants.
        if(ants > 0){
          removeAnts();
          sumAnts();
        }
      }else{
        applyForce(-1);
      }
    }
  }
  
}



public void mouseWheel(MouseEvent event) {
   //e = event.getCount();
   
   if(rnd){
     randomStrength+=event.getCount()*0.05f;
   }else if(steer){
     steerStrength+=event.getCount()*0.05f;
   }else{
     mouseRadius+=event.getCount();
   }
   
   
}


public void sumAnts(){
  ants = 0;
  for(int i = 0; i < maxAnts; i++){
    if(antBuffer.get(i) == 1){
      ants++;
    }
  }
}


public void removeAnts(){
  remove.setArgs(new Object[]{posX.arg,posY.arg,antBuffer.arg,mouseX,mouseY,mouseRadius});
  antBuffer.read(remove.run(maxAnts));
  
}



public void applyForce(float strength){
  ARants.setArgs(new Object[]{posX.arg,posY.arg,antBuffer.arg,mouseX,mouseY,mouseRadius,strength});
  posX.read(ARants.run(maxAnts));
  posY.read();
}
CLProgram program;

CLContext context;
CLQueue queue;
ByteOrder byteOrder;

public void setupCL(){
  context = JavaCL.createBestContext();
  queue = context.createDefaultQueue();
  byteOrder = context.getByteOrder();  
}


class FloatArray{
  
  Pointer<Float> pointer;
  CLBuffer arg;
  
  FloatArray(int size){
    pointer = allocateFloats(size).order(byteOrder);
    arg = context.createBuffer(Usage.InputOutput,pointer);
  }
  
  FloatArray(float[] data){
    pointer = allocateFloats(data.length).order(byteOrder);
    for(int i = 0; i < data.length; i++){
      pointer.set(i,data[i]);
    }
    arg = context.createBuffer(Usage.InputOutput,pointer);    
  }
  
  public void set(int i, float f){    
    pointer.set(i,f);    
  }
  
  public void updateBuffer(){
    arg = context.createBuffer(Usage.InputOutput,pointer);
  }
  
  public float get(int i){
    return pointer.get(i);
  }  
  
  public void read(){
    arg.read(queue,pointer,false);
  }

  public void read(CLEvent evt){
    arg.read(queue,pointer,false,evt);
  }
  
}


class Kernel{
  
  CLKernel kernel;
  
  
  Kernel(String address, String kernelName){ 
    String src = join(loadStrings(dataPath(address)), "\n");
    program = context.createProgram(src);
    kernel = program.createKernel(kernelName);    
  }
  
  
  public void setArgs(Object[] args){
    kernel.setArgs(args);
  }
  
  
  public CLEvent run(int size){
    return kernel.enqueueNDRange(queue, new int[] {size});
  }
  
}
  public void settings() {  size(500,500); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "Ant_simulation" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
