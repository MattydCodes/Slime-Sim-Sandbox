
import com.nativelibs4java.opencl.*;
import com.nativelibs4java.opencl.CLMem.*;
import java.nio.ByteOrder;

import static java.lang.System.*;
import static org.bridj.Pointer.*;

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

float steerStrength = 0.5;
float randomStrength = 0.4;

boolean steer = false;
boolean rnd = false;


void setup(){
  size(500,500);
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


void draw(){
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



void keyPressed(){
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

void keyReleased(){
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


void userControls(){ //Float Array containing Indexes of the ants which don't exist. Pointer integer variables will be used to point out the lowest value within the pointer to turn on.

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



void mouseWheel(MouseEvent event) {
   //e = event.getCount();
   
   if(rnd){
     randomStrength+=event.getCount()*0.05;
   }else if(steer){
     steerStrength+=event.getCount()*0.05;
   }else{
     mouseRadius+=event.getCount();
   }
   
   
}


void sumAnts(){
  ants = 0;
  for(int i = 0; i < maxAnts; i++){
    if(antBuffer.get(i) == 1){
      ants++;
    }
  }
}


void removeAnts(){
  remove.setArgs(new Object[]{posX.arg,posY.arg,antBuffer.arg,mouseX,mouseY,mouseRadius});
  antBuffer.read(remove.run(maxAnts));
  
}



void applyForce(float strength){
  ARants.setArgs(new Object[]{posX.arg,posY.arg,antBuffer.arg,mouseX,mouseY,mouseRadius,strength});
  posX.read(ARants.run(maxAnts));
  posY.read();
}
