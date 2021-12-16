#ifdef GL_ES
precision mediump float;
#endif

uniform float camX;
uniform float camY;
uniform float camZ;

uniform float x0;
uniform float y0;
uniform float z0;

uniform float vx;
uniform float vy;
uniform float vz;

uniform float ux;
uniform float uy;
uniform float uz;

uniform float rows;
uniform float cols;

uniform float iFracScale;
uniform vec3 iFracShift;
uniform float iFracAng1;
uniform float iFracAng2;

vec3 Offset=vec3(1,1,1);
const int Iterations=1;
float Scale=1.5;

void mengerFold(inout vec3 z){
  float a=min(z.x-z.y,0.);
  z.x-=a;
  z.y+=a;
  a=min(z.x-z.z,0.);
  z.x-=a;
  z.z+=a;
  a=min(z.y-z.z,0.);
  z.y-=a;
  z.z+=a;
}

void sierpinskiFold(inout vec3 z){
  z.xy-=min(z.x+z.y,0.);
  z.xz-=min(z.x+z.z,0.);
  z.yz-=min(z.y+z.z,0.);
}

void rotX(inout vec3 z,float s,float c){
  z.yz=vec2(c*z.y+s*z.z,c*z.z-s*z.y);
}

void rotZ(inout vec3 z,float s,float c){
  z.xy=vec2(c*z.x+s*z.y,c*z.y-s*z.x);
}

void rotX(inout vec3 z,float a){
  rotX(z,sin(a),cos(a));
}

void rotZ(inout vec3 z,float a){
  rotZ(z,sin(a),cos(a));
}

float de_box(vec3 p,vec3 s){
  vec3 a=abs(p.xyz)-s;
  return(min(max(max(a.x,a.y),a.z),0.)+length(max(a,0.)));
}

float DE1(vec3 z)
{
  z.xy=mod((z.xy),1.)-vec2(.5);// instance on xy-plane
  return length(z)-.3;// sphere DE
}

float DE3(vec3 z)
{
  float r;
  int n=0;
  for(int a=0;a<Iterations;a++){
    rotZ(z,iFracAng1);
    // sierpinskiFold(z);
    mengerFold(z);
    rotX(z,iFracAng2);
    z.z-=1.;
    z.z=-abs(z.z);
    z.z+=1.;
    z.x-=2.;
    z.y-=2.;
    
    // z.y-=z.y*2.;
    z*=iFracScale;
    // z+=iFracShift;
    // if(z.x+z.y<0.)z.xy=-z.yx;// fold 1
    // if(z.x+z.z<0.)z.xz=-z.zx;// fold 2
    // if(z.y+z.z<0.)z.zy=-z.yz;// fold 3
    // z=z*Scale-Offset*(Scale-1.);
    // n=a;
    // rotX(p, iFracAng2);
    // z=z+vec3(-1.,-1.,1.);
  }
  return de_box(z,vec3(.5));
  // return(length(z))*pow(Scale,-float(n));
}

vec2 cmpxcjg(vec2 c){
  return vec2(c.x,-c.y);
}

vec2 cmpxmul(vec2 a,vec2 b){
  return vec2(a.x*b.x-a.y*b.y,a.y*b.x+a.x*b.y);
}

vec2 cmpxpow(vec2 c){
  for(int i=0;i<1;++i){
    c=cmpxmul(c,c);
  }
  return c;
}

vec2 cmpxdiv(vec2 a,vec2 b){
  return cmpxmul(a,cmpxcjg(b));
}

float cmpxmag(vec2 c){
  return sqrt(c.x*c.x+c.y*c.y);
}

bool getMandelbrotDist(vec2 cord){
  vec2 z=vec2(0.,0.);
  vec2 c=cord;
  
  for(int i=0;i<300;i++){
    z=cmpxpow(z)+c;// Performs Zn+1 = (Zn)^2 + c
    if(cmpxmag(z)>2.)
    return true;
  }
  return false;
}

vec2 distance3D(vec3 cam,vec3 vect,vec2 screen_pos){
  float dist0=0.;
  float dist1=0.;
  float dist2=0.;
  vec3 vector=vec3(0.);
  for(int i=0;i<200;i++){
    dist0=dist1;
    dist1=dist2;
    if(dist2!=0.){
      vector=vect;
    }
    vec3 d=cam+vector*dist1;
    dist2=
    dist1+DE3(d);
    // max(
      //   max(
        //     abs(d.x)-.3,
        //     abs(d.y)-.3
      //   ),
      //   max(
        //     abs(d.z)-.3,
        //     -length(d)+.375
      //   )
    // );
    if((dist2-dist1<.001))return vec2(1-i/90,(dist2-dist1)/(dist1-dist0));
    else if(dist2-dist1>100000000.)return vec2(.243,1.);
  }
  return vec2(.243,1.);
}

void main(){
  float lx=x0+vx*(gl_FragCoord.x-rows/2.);
  float ly=y0+vy*(gl_FragCoord.x-rows/2.);
  float lz=z0+vz*(gl_FragCoord.x-rows/2.);
  float cx=ux*(gl_FragCoord.y-cols/2.);
  float cy=uy*(gl_FragCoord.y-cols/2.);
  float cz=uz*(gl_FragCoord.y-cols/2.);
  float n=
  1./
  sqrt(
    pow(lx+cx,2.)+pow(ly+cy,2.)+pow(lz+cz,2.)
  );
  float x=(lx+cx)*n;
  float y=(ly+cy)*n;
  float z=(lz+cz)*n;
  vec3 cam=vec3(camX,camY,camZ);
  vec3 vect=vec3(x,y,z);
  vec2 dist3D=distance3D(cam,vect,gl_FragCoord.xy);
  
  // if(getMandelbrotDist(gl_FragCoord.xy/400.-vec2(1.5,1))>0)
  gl_FragColor=vec4(.243,.243,dist3D[0],dist3D[1]);
}