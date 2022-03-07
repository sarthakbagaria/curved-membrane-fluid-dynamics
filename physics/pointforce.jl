#=
NOTE: This module is still incomplete, do not use in simualtions.

References:

Mark L. Henle1 and Alex J. Levine. Hydrodynamics in curved membranes: The effect of geometry on particulate mobility.
=#

include("../geometry/sphere.jl")
include("./fluid.jl")
include("../utils/data.jl")

using Symbolics
using DataFrames
using CSV
using Interpolations

#=
(θ_0,ϕ_0) is the location of the force
(θ,ϕ) is the location of the observation point
f is the force magnitude
α is the orientation angle of force from ∂ϕ_0
β is the angle from ∂ϕ along which we measure the component of velocity
=#
@variables θ_0 ϕ_0 θ ϕ f α β dl

∂θ = Differential(θ)
∂ϕ = Differential(ϕ)
∂θ_0 = Differential(θ_0)
∂ϕ_0 = Differential(ϕ_0)

grad_θϕ( f ) = [ ∂θ(f) csc(θ)*∂ϕ(f) ]'
grad_θ_0ϕ_0( f ) = [ ∂θ_0(f) csc(θ_0)*∂ϕ_0(f) ]'

γ = acos( cos(θ)*cos(θ_0) + sin(θ)*sin(θ_0)*cos(ϕ - ϕ_0) )
∂γ = Differential(γ)

twist = [ 0   1; -1  0 ]
tgrad_θϕ( f ) = twist * grad_θϕ(f)
tgrad_θ_0ϕ_0( f ) = twist * grad_θ_0ϕ_0(f)

#=
α is the angle that the force at (θ_0,ϕ_0) makes with ∂/∂ϕ_0 vector at the point
γ is the geodesic length between (θ,ϕ) and (θ_0,ϕ_0)
β is the angle with ∂/∂ϕ vector along which we measure the component of velocity

v_t = \gradient_{θ,ϕ} ( force_t ⋅ \gradient_{θ_0,ϕ_0} P(γ) )
    = d/dγ( P(γ) ) \gradient_{θ,ϕ} ( force_t ⋅ \gradient_{θ_0,ϕ_0} γ )
v is the velocity vector at point (θ,ϕ) due to force at point (θ',ϕ')
force_t is force rotated by π/2
i.e. force_t' = force' ⋅ [ ( cos(π/2), sin(π/2) ), ( - sin(π/2), cos(π/2) ) ]
              = force' ⋅ [ ( 0, 1 ), ( - 1, 0 ) ]
v_t is v rotated by π/2
i.e. v = [ ( 0, 1 )', ( - 1, 0 )' ] ⋅ v_t

v_t = d/dγ( P(γ) ) \gradient_{θ,ϕ} ( force_t ⋅ (∂/∂θ_0(γ), cosec(θ_0) ∂/∂ϕ_0(γ) )
    = d/dγ( P(γ) ) \gradient_{θ,ϕ} ( force' ⋅ [ ( 0, 1 ), ( - 1, 0 ) ] ⋅ (∂/∂θ_0(γ), cosec(θ_0) ∂/∂ϕ_0(γ) )
    = d/dγ( P(γ) ) \gradient_{θ,ϕ} ( force' ⋅ ( cosec(θ_0) ∂/∂ϕ_0(γ), -∂/∂θ_0(γ) ) )
    = d/dγ( P(γ) ) \gradient_{θ,ϕ} ( force_θ_0 cosec(θ_0) ∂/∂ϕ_0(γ) - force_ϕ_0 ∂/∂θ_0(γ) )
    = d/dγ( P(γ) ) ( force_θ_0 cosec(θ_0) ∂/∂θ( ∂/∂ϕ_0(γ) ) - force_ϕ_0  ∂/∂θ( ∂/∂θ_0(γ) ),
                       force_θ_0 cosec(θ) cosec(θ_0) ∂/∂ϕ( ∂/∂ϕ_0(γ) ) - force_ϕ_0 cosec(θ) ∂/∂ϕ( ∂/∂θ_0(γ) )
                     )

v = d/dγ( P(γ) ) ( force_θ_0 cosec(θ) cosec(θ_0) ∂/∂ϕ( ∂/∂ϕ_0(γ) ) - force_ϕ_0 cosec(θ) ∂/∂ϕ( ∂/∂θ_0(γ),
                   - force_θ_0 cosec(θ_0) ∂/∂θ( ∂/∂ϕ_0(γ) ) + force_ϕ_0 ∂/∂θ( ∂/∂θ_0(γ) ) )
                 )
  = d/dγ( P(γ) ) ( f sin(α) cosec(θ) cosec(θ_0) ∂/∂ϕ( ∂/∂ϕ_0(γ) ) - f cos(α)  cosec(θ) ∂/∂ϕ( ∂/∂θ_0(γ),
                   - f sin(α) cosec(θ_0) ∂/∂θ( ∂/∂ϕ_0(γ) ) + f cos(α) ∂/∂θ( ∂/∂θ_0(γ) ) )
                 )

 v_th = ∂γ( P ) * (   f * sin(α) * csc(θ) * csc(θ_0) * ∂ϕ( ∂ϕ_0(γ) )  -  f * cos(α) * csc(θ) * ∂ϕ( ∂θ_0(γ) ) )
 v_ph = ∂γ( P ) * ( - f * sin(α)          * csc(θ_0) * ∂θ( ∂ϕ_0(γ) )  +  f * cos(α) *          ∂θ( ∂θ_0(γ) ) )
=#

# P as a function of γ is stored in file 
pData = DataFrame(CSV.File("./data/pointforce_import_lc.tsv"))
# we compute the first few derivatives and store them in global variables to avoid
# recomputing the derivatives each time are encountered in final expression
pDataInterpolated = LinearInterpolation( pData.x, pData.y; extrapolation_bc = Line())
pDataInterpolated1 = dataDerivative( ( pDataInterpolated, pData.x ) )[1]
pDataInterpolated2 = dataDerivative( ( pDataInterpolated1, pData.x ) )[1]
pDataInterpolated3 = dataDerivative( ( pDataInterpolated2, pData.x ) )[1]
pDataInterpolated4 = dataDerivative( ( pDataInterpolated3, pData.x ) )[1]
pDataInterpolated5 = dataDerivative( ( pDataInterpolated4, pData.x ) )[1]

function Pf(n::Int64, x::Float64)
  if n==0
    pDataInterpolated(x)
  elseif n==1
    pDataInterpolated1(x)
  elseif n==2
    pDataInterpolated2(x)
  elseif n==3
    pDataInterpolated3(x)
  elseif n==4
    pDataInterpolated4(x)
  elseif n==5
    pDataInterpolated5(x)
  else
    throw( sprint(n) + "-derivative of P not precomputed" )
  end
end

# register the pre-computed derivates in the symbolics framework
Symbolics.derivative( ::typeof(Pf), args::NTuple{2,Any}, ::Val{2} ) = SymbolicUtils.Term( Pf, [ args[1]+1, args[2] ] )
Symbolics.@register Pf( data::Int64, x )

P = Pf( 0, γ )

v =  tgrad_θϕ( ( [ f*sin(α) f*cos(α) ] * tgrad_θ_0ϕ_0( P ) )[ 1 ] )
# v = ∂γ( dP ) * tgrad_θϕ( ( [ f*sin(α) f*cos(α) ] * tgrad_θ_0ϕ_0( γ ) )[ 1 ] ) +
#     ∂γ(∂γ( P )) * tgrad_θϕ( γ ) * ( [ f*sin(α) f*cos(α) ] * tgrad_θ_0ϕ_0( γ ) )[ 1 ]

# gradient matrix of v at (θ,ϕ)
#vg = [ ∂θ(v_θ) csc(θ)∂ϕ(v_θ); ∂θ(v_ϕ) csc(θ)∂ϕ(v_ϕ)]
vg = [ ∂θ(v[1]) csc(θ)*∂ϕ(v[1]); ∂θ(v[2]) csc(θ)*∂ϕ(v[2]) ]

v_simplified = simplify.( expand_derivatives.( v ) )
vg_simplified = simplify.( expand_derivatives.( vg ) )

pointForceV = build_function( v_simplified, [θ_0, ϕ_0, θ, ϕ, f, α ], expression=Val{false} )
pointForceVG = build_function( vg_simplified, [θ_0, ϕ_0, θ, ϕ, f, α ], expression=Val{false} )


#========================================
# Interface functions
========================================#

struct PointForce <: Object
    location :: SphericalCoord  # (θ_0,ϕ_0) location of
    orientation :: Float64  # angle that the force makes with ∂/∂ϕ_0
    magnitude :: Float64  # magnitude of the force
end

# velocity field generated by point force
function velocityField( destination::SphericalCoord, source::PointForce, fluid::FluidParams )::SphericalCoord
    θs = source.location.theta
    ϕs = source.location.phi
    θd = destination.theta
    ϕd = destination.phi
    if θs == θd && ϕs == ϕd
        return( SphericalCoord( 0, 0 ) )
    else
        velocity = pointForceV[1]([ θs, ϕs, θd, ϕd, source.magnitude, source.orientation ])
        return( SphericalCoord( velocity[ 1 ], velocity[ 2 ] ) )
    end
end

# gradient of velocity field generated by dipole force
# NOTE: not yet implemented
function velocityCurlField( destination::SphericalCoord, source::PointForce, fluid::FluidParams )::Float64
    return( 0 )
end

# gradient of velocity field generated by point force
function velocityGradientField( destination::SphericalCoord, source::PointForce, fluid::FluidParams )::Array{Float64,2}
    θs = source.location.theta
    ϕs = source.location.phi
    θd = destination.theta
    ϕd = destination.phi
    if θs == θd && ϕs == ϕd
        return( [0 0; 0 0] )
    else
        velocityGrad = pointForceVG[1]([ θs, ϕs, θd, ϕd, source.magnitude, source.orientation ])
        return( velocityGrad )
    end
end

# how point force moves in the presence of external velocity field
# NOTE: not yet implemented
function stepForward( object::PointForce, v::SphericalCoord, vc::Float64, dt::Float64 )::PointForce
    # right now we don't change the location of pointforce based on external field
    return( object )
end


#plot the point forces on 3d chart
function plot3d!( threeDPlot::Union{Scene,LScene}, pointForce::Observable{PointForce} )::Nothing
    pointForcePosState = @lift( $pointForce.location )
    pointForceVectorMap( f, α ) = SphericalCoord( f*sin(α), f*cos(α) )
    pointForceForceState = @lift( pointForceVectorMap(  $pointForce.magnitude,  $pointForce.orientation ) )
    pfps = @lift( sphericalToCartesian( $pointForcePosState ) )
    pfpx = @lift( [$pfps.x] )
    pfpy = @lift( [$pfps.y] )
    pfpz = @lift( [$pfps.z] )
    pffs = @lift( sphericalToCartesianVelocity( $pointForcePosState, $pointForceForceState ) )
    pffx = @lift( [$pffs.x] )
    pffy = @lift( [$pffs.y] )
    pffz = @lift( [$pffs.z] )
    arrows!(threeDPlot, pfpx, pfpy, pfpz, pffx, pffy, pffz, arrowsize = 0.05, lengthscale = 0.05 )
    nothing
end


# show point forces on theta phi chart
function plot2d!( twoDPlot::Union{Scene,LScene}, pointForce::Observable{PointForce} )::Nothing
    pointForcePosState = @lift( $pointForce.location )
    pointForceVectorMap( f, α ) = SphericalCoord( f*sin(α), f*cos(α) )
    pointForceForceState = @lift( pointForceVectorMap( $pointForce.magnitude,  $pointForce.orientation ) )
    pfptx = @lift( [$pointForcePosState.phi] )
    pfpty = @lift( [$pointForcePosState.theta] )
    pfftx = @lift( [$pointForceForceState.phi * csc($pointForcePosState.theta)] )
    pffty = @lift( [$pointForceForceState.theta] )
    arrows!( twoDPlot, pfptx, pfpty, pfftx, pffty, arrowsize = 0.05, lengthscale = 0.05 )
    nothing
end


#========================================
# Tests
========================================#

#=
Rotational symmetry check

If we have a point force at ( θ0, ϕ0 ) making an angle α with ϕ axis,
then the look at component of velocity induced at point ( θ, ϕ )  making an angle β with ϕ axis

This should be same as component of velocity induced at point ( θ0, ϕ0 ) making an angle β - rot with ϕ axis
by a point force at ( θ, ϕ ) making an angle α + rot

where rot is π + the rotation a vector suffers when parallel transported from ( θ0, ϕ0 ) to ( θ, ϕ )

the operations involved in this symmetry are exchange force and velocity locations,
parallely transporting the force and velocity vectors along the geodesic connecting them,
and then rotating the frame 180 degrees about the diameter of sphere passing through midpoint of geodesic
=#

v_th = v[ 1 ]
v_ph = v[ 2 ]
v_beta = expand_derivatives( v_ph * cos(β) + v_th * sin(β) )

tangent_angle = expand_derivatives( atan( ∂θ(γ), csc(θ)∂ϕ(γ) ) )
tangent_0_angle = expand_derivatives( atan( ∂θ_0(γ), csc(θ_0)∂ϕ_0(γ) ) )
rot = tangent_angle - tangent_0_angle

args = Dict(
      θ => π/2.5
    , ϕ => 0.4
    , θ_0 => 2π/3
    , ϕ_0 => -π/4
    , f => 1
    , α => 0.2
    , β => 0.4
)

exchange = Dict( θ_0 => θ, ϕ_0 => ϕ, θ => θ_0, ϕ => ϕ_0, α => α + rot, β => β - rot )
v_ex = substitute( v_beta, exchange )
sym_check = simplify( v_ex - v_beta )  # this should be zero, atleast in domain of interest
sym_check_eval = substitute( sym_check, args ) # this should be zero for all args as sym_check should be zero
@assert abs(sym_check_eval) < 1e-10

tangent_ex_angle = substitute( tangent_angle, exchange )
tangent_check = simplify( tangent_ex_angle - tangent_0_angle )
tangent_check_eval = substitute( tangent_check, args ) # this should be zero
@assert abs(tangent_check_eval) < 1e-10
