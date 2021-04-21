CLProgram program;

CLContext context;
CLQueue queue;
ByteOrder byteOrder;

void setupCL(){
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
  
  void set(int i, float f){    
    pointer.set(i,f);    
  }
  
  void updateBuffer(){
    arg = context.createBuffer(Usage.InputOutput,pointer);
  }
  
  float get(int i){
    return pointer.get(i);
  }  
  
  void read(){
    arg.read(queue,pointer,false);
  }

  void read(CLEvent evt){
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
  
  
  void setArgs(Object[] args){
    kernel.setArgs(args);
  }
  
  
  CLEvent run(int size){
    return kernel.enqueueNDRange(queue, new int[] {size});
  }
  
}
