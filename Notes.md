The radius of a regular n-gon, given the length of its side 's', is calculated as r = s / (2 * sin(π/n)). This formula directly relates the radius (circumradius) to the side length of the polygon. 
Elaboration:
Regular n-gon: A polygon with 'n' sides where all sides are equal in length and all interior angles are equal. 
Radius (Circumradius): The distance from the center of the polygon to any of its vertices. 
Side length (s): The length of one side of the polygon. 
Formula: The radius 'r' can be expressed as r = s / (2 * sin(π/n)). This formula comes from analyzing the isosceles triangles formed by connecting the center of the polygon to two adjacent vertices and then applying trigonometry. 
Explanation: The formula utilizes the sine function to relate the side length (half of the side length) to the radius and the number of sides of the polygon. The angle π/n (180/n degrees) is half of the central angle of the regular n-gon, which is the angle formed at the center by two consecutive vertices, according to Study.com. 

///////

/* vertex position */
vx = cos(jangle)*(rout+cos(iangle)*rin);
vy = sin(jangle)*(rout+cos(iangle)*rin);
vz = sin(iangle)*rin;
/* tangent vector with respect to big circle */
tx = -sin(jangle);
ty = cos(jangle);
tz = 0;
/* tangent vector with respect to little circle */
sx = cos(jangle)*(-sin(iangle));
sy = sin(jangle)*(-sin(iangle));
sz = cos(iangle);
/* normal is cross-product of tangents */
nx = ty*sz - tz*sy;
ny = tz*sx - tx*sz;
nz = tx*sy - ty*sx;
/* normalize normal */
length = sqrt(nx*nx + ny*ny + nz*nz);
nx /= length;
ny /= length;
nz /= length;