_repo_management = attr.label(
    default = "@com_grail_rules_r//scripts:repo_management.R",
    allow_single_file = True,
    doc = "R source file containing repo_management functions.",
)

_dep_utils = attr.label(
    default = "@com_grail_rules_r//scripts:dep_utils.R",
    allow_single_file = True,
    doc = "R source file containing dep_utils functions.",
)

_check_pkgs_sh_tpl = attr.label(
    allow_single_file = True,
    default = "@com_grail_rules_r//scripts:check_pkgs.sh.tpl",
)

def _impl(ctx):

    repo_mgmt_script = ctx.file._repo_management
    dep_utils_script = ctx.file._dep_utils

    repo_dir = ctx.actions.declare_directory("stage-repo")

    # Emit the executable shell script.
    script = ctx.actions.declare_file("%s-run" % ctx.label.name)

    ctx.actions.run(
        outputs = [repo_dir, ctx.outputs.repo_pkg_list],
        executable = "mkdir",
        arguments = [
            "-p",
            repo_dir.path,
            ctx.outputs.repo_pkg_list.path,

        ],
    )

    ctx.actions.expand_template(
        template = ctx.file._check_pkgs_sh_tpl,
        output = script,
        substitutions = {
            "{repo_mgmt_script}": repo_mgmt_script.path,
            "{dep_utils_script}": dep_utils_script.path,
            "{package_list}": ctx.file.base_pkg_list.path,
            "{repo_package_list}": ctx.outputs.repo_pkg_list.path,
            "{repo_dir}": repo_dir.path,
            "{pkgs}": ",".join(ctx.attr.pkgs),
        },
        is_executable = True,
    )

    runfiles =  ctx.runfiles(files = [repo_mgmt_script, dep_utils_script, ctx.file.base_pkg_list, repo_dir])
    return [DefaultInfo(
        runfiles = runfiles,
        executable = script)
    ]


check_pkgs = rule(
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
        "_repo_management": _repo_management,
         "_dep_utils": _dep_utils,
         "_check_pkgs_sh_tpl": _check_pkgs_sh_tpl,
    },
    executable = True,
    outputs = {
        "repo_pkg_list": "external_packages_%{name}.csv",
    },
)
