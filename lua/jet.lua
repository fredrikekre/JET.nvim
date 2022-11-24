local M = {}

local lspconfig = require("lspconfig")

local cmd = {
  'julia',
  '--startup-file=no',
  '--history-file=no',
  '-e',
  [[
    # Load JETLS.jl: attempt to load from ~/.julia/environments/nvim-jetls
    # with the regular load path as a fallback
    jet_install_path = joinpath(
        get(DEPOT_PATH, 1, joinpath(homedir(), ".julia")),
        "environments", "nvim-jetls"
    )
    pushfirst!(LOAD_PATH, jet_install_path)
    import JETLS
    popfirst!(LOAD_PATH)
    # depot_path = get(ENV, "JULIA_DEPOT_PATH", "")
    project_path = let
        dirname(something(
            ## 1. Finds an explicitly set project (JULIA_PROJECT)
            Base.load_path_expand((
                p = get(ENV, "JULIA_PROJECT", nothing);
                p === nothing ? nothing : isempty(p) ? nothing : p
            )),
            ## 2. Look for a Project.toml file in the current working directory,
            ##    or parent directories, with $HOME as an upper boundary
            Base.current_project(),
            ## 3. First entry in the load path
            get(Base.load_path(), 1, nothing),
            ## 4. Fallback to default global environment,
            ##    this is more or less unreachable
            Base.load_path_expand("@v#.#"),
        ))
    end
    pushfirst!(LOAD_PATH, project_path) # ???
    @info "Running JETLS language server" VERSION pwd() project_path
    JETLS.runserver(stdin, stdout)
  ]],
}

local jetls = {
  default_config = {
    cmd = cmd,
    filetypes = {'julia'},
    root_dir = function(fname)
      local util = require'lspconfig.util'
      return util.root_pattern 'Project.toml'(fname) or util.find_git_ancestor(fname) or
             util.path.dirname(fname)
    end,
  },
  docs = {
    description = [[
TBW
    ]],
  },
}

function M.setup(opts)
    local lspconfigs = require("lspconfig.configs")
    lspconfigs['jetls'] = jetls
    lspconfig.jetls.setup({})
end

return M
