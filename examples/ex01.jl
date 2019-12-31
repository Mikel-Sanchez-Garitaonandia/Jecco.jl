
using Jecco
using Jecco.KG_3_1

par_base = ParamBase(
    which_potential = "square",
)

par_grid = ParamGrid(
    xmin        = -5.0,
    xmax        =  5.0,
    xnodes      =  128,
    ymin        = -5.0,
    ymax        =  5.0,
    ynodes      =  128,
    umin        =  0.0,
    umax        =  1.0,
    udomains    =  4,
    unodes      =  16,
)

par_id = ParamID(
    ID_type      = "sine2D",
    A0x          = 1.0,
    A0y          = 1.0,
    Lx           = par_grid.xmax - par_grid.xmin,
    Ly           = par_grid.ymax - par_grid.ymin,
)

par_evol = ParamEvol(
    dt      = 0.02, # for RK4
    # tmax    = 4.0,
    tmax    = 2.0,
)

par_io = ParamIO(
    out_every   = 4,
    folder      = "./data",
)

# define potential
Jecco.KG_3_1.setup(par_base)

Jecco.KG_3_1.ibvp(par_grid, par_id, par_evol, par_io)
