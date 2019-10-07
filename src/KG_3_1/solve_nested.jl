
using LinearAlgebra

function solve_lin_system!(sol, A_mat, b_vec)
    A_fact = lu!(A_mat)
    ldiv!(A_fact, b_vec)
    sol .= b_vec
    nothing
end

function nested_g1(sys)
    coords = sys.coords
    uderiv = sys.uderiv
    xderiv = sys.xderiv
    yderiv = sys.yderiv

    uu, xx, yy = Vivi.xx(coords)
    Nu = length(uu)
    Nx = length(xx)
    Ny = length(yy)

    Du_phi    = zeros(Nu, Nx, Ny)
    Dxx_phi   = zeros(Nu, Nx, Ny)
    Dyy_phi   = zeros(Nu, Nx, Ny)

    A_mat = zeros(Nu, Nu)
    b_vec = zeros(Nu)
    ABCS  = zeros(4)
    vars  = AllVars{Float64}()

    function (bulk::BulkVars, boundary::BoundaryVars)

        Vivi.D!(Du_phi, bulk.phi, uderiv, 1)
        Vivi.D2!(Dxx_phi, bulk.phi, xderiv, 2)
        Vivi.D2!(Dyy_phi, bulk.phi, yderiv, 3)

        # set Sd
        @fastmath @inbounds for j in eachindex(yy)
            @fastmath @inbounds for i in eachindex(xx)
                @fastmath @inbounds @simd for a in eachindex(uu)
                    bulk.Sd[a,i,j] = 0.5 * boundary.a4[i,j]
                end
            end
        end


        # solve for phidg1

        # TODO: parallelize here
        @fastmath @inbounds for j in eachindex(yy)
            @fastmath @inbounds for i in eachindex(xx)

                @fastmath @inbounds @simd for a in eachindex(uu)
                    vars.u       = uu[a]
                    vars.Sd_d0   = bulk.Sd[a,i,j]
                    vars.phi_d0  = bulk.phi[a,i,j]
                    vars.phi_du  = Du_phi[a,i,j]
                    vars.phi_dxx = Dxx_phi[a,i,j]
                    vars.phi_dyy = Dyy_phi[a,i,j]

                    phig1_eq_coeff!(ABCS, vars)

                    b_vec[a]     = -ABCS[4]

                    @inbounds @simd for aa in eachindex(uu)
                        A_mat[a,aa] = ABCS[1] * uderiv.D2[a,aa] + ABCS[2] * uderiv.D[a,aa]
                    end
                    A_mat[a,a] += ABCS[3]
                end

                # boundary condition
                b_vec[1]    = bulk.phi[1,i,j]  # phi2[i,j]
                A_mat[1,:] .= 0.0
                A_mat[1,1]  = 1.0

                sol = view(bulk.phid, :, i, j)
                solve_lin_system!(sol, A_mat, b_vec)
            end
        end


        # set Ag1
        @fastmath @inbounds for j in eachindex(yy)
            @fastmath @inbounds for i in eachindex(xx)
                @fastmath @inbounds @simd for a in eachindex(uu)
                    bulk.A[a,i,j] = boundary.a4[i,j]
                end
            end
        end

        nothing
    end

end