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

load("@com_grail_rules_r//R:defs.bzl", "r_binary", "r_library", "r_library_tar", "r_test")

r_library(
    name = "library",
    pkgs = [
        "//exampleC",
        "@R_bitops//:bitops",
    ],
    visibility = [
        "//binary:__pkg__",
        "//container:__pkg__",
    ],
)

load("@com_grail_rules_r//R:dep_utils.bzl", "r_check_pkgs")

r_check_pkgs(
    name = "check_pkgs",
    base_pkg_list= "//cran:packages.csv",
    all = True,
)
