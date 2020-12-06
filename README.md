# Unity-RayMarcher
 A custom RayMarcher in Unity's new Post Processing v3 stack
 ![Fractalship](https://i.imgur.com/n6mEKTM.png)
 
 This project is made with custom shaders and is utilizing Unity's Post Processing stack.
 
 I am experimenting with using ray marching to render signed distance functions in Unity.
 
 Raymarching is a technique a bit like traditional raytracing where the surface function is not easy to solve (or impossible without numeric iterative methods). In raytracing you   just look up the ray intersection, whereas in ray marching you march forward (or back and forth) until you find the intersection, have enough samples or whatever it is you're trying to solve. So when you have complicated surfaces like fractals or non-euclidean geometry, raymarching is the way to go!
 
Here are some of my experiments using raymarching:

 - A Spacebulb
 
 - A Glowbox
 
 - A Shadedbox
 
 - A Fractalship
 
 - Blobthingies
 
 ** Simple geometric (with some displacement) scene showcasing some boolean operators
 
 - FractalFPS ???
 
 ** I also managed to add some physics using the same signed distance fields that the gpu calculates in the shader but this time in the cpu.
 
