using LinearAlgebra
using Symbolics

# r=1 in simulations always
struct SphericalCoord
    theta::Float64 # angle from z-axis
    phi::Float64 # angle from x-axis in x-y plane
end

Base.:+(x::SphericalCoord, y::SphericalCoord) = SphericalCoord(x.theta+y.theta, x.phi+y.phi)

struct CartesianCoord
    x::Float64
    y::Float64
    z::Float64
end

LinearAlgebra.normalize( c::CartesianCoord ) = begin
    n = normalize( [c.x, c.y, c.z ] )
    CartesianCoord( n[1], n[2], n[3])
end

LinearAlgebra.norm( c::CartesianCoord ) = norm( [c.x, c.y, c.z ] )

function cartesianToSpherical( p::CartesianCoord )
    r = sqrt( p.x^2 + p.y^2 + p.z^2 )
    theta = acos(p.z/r)
    phi = atan(p.y,p.x)
    SphericalCoord( theta, phi )
end

function sphericalToCartesian( p::SphericalCoord )
    x = cos(p.phi)*sin(p.theta)
    y = sin(p.phi)*sin(p.theta)
    z = cos(p.theta)
    CartesianCoord( x, y, z )
end

# p is the position, v is the velocity
function sphericalToCartesianVelocity( p::SphericalCoord, v::SphericalCoord )
    # p.theta is dtheta, p.phi is dphi
    vx = [cos(p.phi)*cos(p.theta), - sin(p.phi)]' * [v.theta, v.phi]
    vy = [sin(p.phi)*cos(p.theta), cos(p.phi)]' * [v.theta, v.phi]
    vz = -sin(p.theta)*v.theta
    CartesianCoord( vx, vy, vz )
end

# geodesic distance
rho( p1::SphericalCoord, p2 ::SphericalCoord) = acos( cos(p1.theta)*cos(p2.theta) + sin(p1.theta)*sin(p2.theta)*cos(p1.phi - p2.phi) )
# derivative of geodesic distance \rho wrt \phi
alpha( p1::SphericalCoord, p2 ::SphericalCoord) = sin(p1.theta) * sin(p2.theta) * sin(p1.phi-p2.phi) / sin(rho(p1,p2))
# derivative of geodesic distance \rho wrt \theta
beta( p1::SphericalCoord, p2 ::SphericalCoord) = ( cos(p2.theta) * sin(p1.theta) -  cos(p1.theta) * sin(p2.theta) * cos(p1.phi-p2.phi) ) / sin(rho(p1,p2))