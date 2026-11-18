# Run JuliaFormatter (check only), Aqua and JET on ArcLanding. Usage:
#   julia --project=style --startup-file=no style/check.jl [format|lint|typecheck|fmt]
using JuliaFormatter, Aqua, JET
push!(LOAD_PATH, joinpath(@__DIR__, ".."))
using ArcLanding

const ROOT = normpath(joinpath(@__DIR__, ".."))
const SOURCES = ["src", "test", "scripts", "style"]

function format_files(; overwrite::Bool)
    clean = true
    for dir in SOURCES
        clean &= format(joinpath(ROOT, dir); overwrite=overwrite, verbose=!overwrite)
    end
    return clean
end

task = isempty(ARGS) ? "lint" : ARGS[1]
if task == "fmt"
    format_files(; overwrite=true)
elseif task == "format"
    format_files(; overwrite=false) || error("JuliaFormatter: files are not formatted (run make fmt)")
elseif task == "lint"
    Aqua.test_all(ArcLanding)
elseif task == "typecheck"
    result = JET.report_package(ArcLanding; target_modules=(ArcLanding,))
    show(result)
    isempty(JET.get_reports(result)) || error("JET reported problems")
else
    error("unknown task $(task)")
end
