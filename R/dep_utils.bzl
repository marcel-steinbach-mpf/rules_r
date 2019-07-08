load(
    "@com_grail_rules_r//R/internal:common.bzl", _library_deps = "library_deps"
)

load("@com_grail_rules_r//R:providers.bzl", "RPackage")

_repo_management = attr.label(
    default = "@com_grail_rules_r//scripts:repo_management.R",
    allow_single_file = True,
    doc = "R source file containing repo_management functions.",
)

_dep_utils = attr.label(
    default = "@com_grail_rules_r//R/scripts:dep_utils.R",
    allow_single_file = True,
    doc = "R source file containing dep_utils functions.",
)

_check_pkgs_sh_tpl = attr.label(
    allow_single_file = True,
    default = "@com_grail_rules_r//R/scripts:check_pkgs.sh.tpl",
)


_script_deps = attr.label_list(
    providers = [RPackage],
    default = ["@R_digest_INTERNAL//:digest"],
)

def _impl(ctx):

    library_deps = _library_deps(ctx.attr._script_deps)

    repo_mgmt_script = ctx.file._repo_management
    dep_utils_script = ctx.file._dep_utils

    script = ctx.actions.declare_file("%s-run" % ctx.label.name)

    repos = "c(%s)" % (", ".join( [k + "='" + v + "'" for k, v in ctx.attr.remote_repos.items()]))

    ctx.actions.expand_template(
        template = ctx.file._check_pkgs_sh_tpl,
        output = script,
        substitutions = {
            "{extra_r_libs}": ":".join([d.short_path for d in library_deps["lib_dirs"]]),
            "{repo_mgmt_script}": repo_mgmt_script.short_path,
            "{dep_utils_script}": dep_utils_script.short_path,
            "{package_list}": ctx.file.base_pkg_list.short_path,
            "{repos}": repos,
            "{repo_package_list}": "repo_pkgs_%s.csv" % ctx.attr.name, # % (output_pkgs.short_path, ctx.attr.name),
            "{applied_package_list}": "final_pkgs_%s.csv"  % ctx.attr.name, # % (output_pkgs.short_path, ctx.attr.name),
            "{pkgs}": ",".join(ctx.attr.pkgs),
            "{versions}": ",".join(ctx.attr.versions),
            "{all_pkgs}": "Y" if ctx.attr.all else "",

        },
        is_executable = True,
    )

    runfiles =  ctx.runfiles(files = library_deps["lib_dirs"] + [repo_mgmt_script, dep_utils_script, ctx.file.base_pkg_list])
    return struct(
            providers = [
                DefaultInfo(
                    runfiles = runfiles,
                    executable = script)
            ]

        )

r_check_pkgs = rule(
    implementation = _impl,
    attrs = {
        "base_pkg_list": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "CSV containing packages with name, version and sha256; with a header.",
        ),
        "pkgs": attr.string_list(
            mandatory = False,
            doc = "Packages (and dependencies) to check. This can be overriden by -p option",
        ),
        "versions": attr.string_list(
            mandatory = False,
            doc = "Desired package versions. This can be overriden by -v option",
        ),
        "all": attr.bool(
            mandatory = False,
            default = False,
            doc = "Update all packages designated in base_pkg_list. This parameter has lower precendence than 'pkgs' and ignored if 'pkgs' is set. Use -a option on runtime.",
        ),
        "remote_repos": attr.string_dict(
            default = {"CRAN": "https://cloud.r-project.org"},
            doc = "Repo URLs to use.",
        ),
        "_repo_management": _repo_management,
         "_dep_utils": _dep_utils,
         "_check_pkgs_sh_tpl": _check_pkgs_sh_tpl,
         "_script_deps": _script_deps,
    },
    executable = True,
)
