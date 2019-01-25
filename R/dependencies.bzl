# Copyright 2018 The Bazel Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

load(
    "@com_grail_rules_r//internal:process.bzl",
    _process_file = "process_file",
)
load(
    "@com_grail_rules_r//internal:versions.bzl",
    _is_at_least = "is_at_least",
)
load(
    "@com_grail_rules_r//makevars:makevars.bzl",
    _r_makevars = "r_makevars",
)
load("@com_grail_rules_r//R/internal:coverage_deps.bzl", "r_coverage_dependencies")

load("@com_grail_rules_r//R:repositories.bzl", "r_repository")

def r_rules_dependencies(
        makevars_darwin = "@com_grail_rules_r_makevars_darwin",
        makevars_linux = None):
    _is_at_least("0.10", native.bazel_version)

    # TODO: Use bazel-skylib directly instead of replicating functionality when
    # nested workspaces become a reality.  Otherwise, dependencies will need to
    # be loaded in two stages, first load skylib and then load this file.

    _maybe(
        _process_file,
        name = "com_grail_rules_r_makevars_darwin",
        src = "@com_grail_rules_r//makevars:Makevars.darwin.tpl",
        processor = "@com_grail_rules_r//makevars:Makevars.darwin.sh",
        processor_args = ["-b"],
    )

    _maybe(
        _r_makevars,
        name = "com_grail_rules_r_makevars",
        makevars_darwin = makevars_darwin,
        makevars_linux = makevars_linux,
    )

    if not native.existing_rule("R_digest_INTERNAL"):
        r_repository(
            name = "R_digest_INTERNAL",
            build_file = None,
            sha256 = "88276798a37733adbdafa007cdfc7b005077d79bd66a3945b5c39b03bab56c51",
            strip_prefix = "digest",
            urls = [
                "https://ftp.gwdg.de/pub/misc/cran/src/contrib/digest_0.6.17.tar.gz",
                "https://ftp.gwdg.de/pub/misc/cran/src/contrib/Archive/digest/digest_0.6.17.tar.gz",
            ],
        )

def _maybe(repo_rule, name, **kwargs):
    if not native.existing_rule(name):
        repo_rule(name = name, **kwargs)
