# Unity-RayMarcher
 A custom RayMarcher in Unity's new Post Processing v3 stack
 ![Fractalship](https://i.imgur.com/n6mEKTM.png)
 
 This project is made with custom shaders and is utilizing Unity's Post Processing stack.
 
 Raymarching is a technique a bit like traditional raytracing where the surface function is not easy to solve (or impossible without numeric iterative methods). In raytracing you   just look up the ray intersection, whereas in ray marching you march forward (or back and forth) until you find the intersection, have enough samples or whatever it is you're trying to solve. So when you have complicated surfaces like fractals or non-euclidean geometry, raymarching is the way to go.
 
Below are some of my experiments with using ray marching to render signed distance functions in Unity:

 - A Spacebulb
 <img src="/projectGIFS/ezgif-2-237dc5daaf3b.gif?raw=true">
 
 - A Glowbox
  <img src="/projectGIFS/ezgif-2-2e093dd2b6d4.gif?raw=true">
 
 - A Shadedbox
  <img src="/projectGIFS/ezgif-2-c74e57deeb1f.gif?raw=true">
 
 - A Fractalship
  <img src="/projectGIFS/ezgif-2-a169b1d8c624.gif?raw=true">
 
 - Blobthingies
 ** Simple geometric (with some displacement) scene showcasing some boolean operators
  <img src="/projectGIFS/ezgif-6-301bcffb1209.gif?raw=true">
 
 
 - FractalFPS ???
 ** I also managed to add some physics using the same signed distance fields that the gpu calculates in the shader but this time in the cpu.
  <img src="/projectGIFS/ezgif-3-6915a234aa2a.gif?raw=true">
  <img src="/projectGIFS/ezgif-3-ee71b35e15a7.gif?raw=true">
 
 Bonus: Here is a cool visualization of a mandelbulb fractal with some cool music: https://www.youtube.com/watch?v=_0YLEfMZloU ...wait for it... :)
 
