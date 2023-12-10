#!/usr/bin/false

# Stockfish commands.sh

# ┌────────────────────────┐
# │ Info                   │
# └────────────────────────┘
# ┌────────────────────────┐
# │ Config ⚙               │
# └────────────────────────┘

# Reduce error printing:
declare -ig error_handling_frames=1;

# ┌────────────────────────┐
# │ Includes               │
# └────────────────────────┘

#source ~/dotfiles/scripts/setargs.sh;
source ~/dotfiles/scripts/git_utils.sh;
source ~/dotfiles/scripts/progress_bar.sh;

# ┌────────────────────────┐
# │ Constants              │
# └────────────────────────┘

declare -r engine_name="weiss";
declare -r engine_binary="./$engine_name";

declare -r master_binary="${engine_binary}_master"; # TODO: build command does weiss_$branch
declare -r patch_binary="${engine_binary}_patch";

# ┌────────────────────────┐
# │ Commands               │
# └────────────────────────┘

# Translation ticker

  # bench → bench

  # try → build
  # retry → build --clean
  # do -> build --retry-clean

  # cb -> binary_bench --all

  # ab  →  commit_bench --all
  # hob →  commit_bench --head
  # bb  →  commit_bench --branch
  # hb  →  commit_bench --head-branch
  # mb  →  commit_bench --master

  # db  →  (inlined into bench)

  # ok does pathc fish, normal does both
  # normal  →  build --commit=master; no longer changes patch engine
  # ok →  ready

  #ij →

# Default command (when no arguments are given)
command_default()
{
  set_args "--help" "$@";
  eval "$get_args";

  make script;
}

command_test()
{
  error_handling_frames=0

#  make;
#  errchok "Normal make";
#  make script;
#  errcho "Skript make";

  make clean;
  make script_clean;
#  progress_sleep 5 "Cleaned?";
  make -n script;
#  progress_sleep 10 "Starting compilation";
  errchol "Start compilation";
  make script;
  errchok "Skript make form clean";

  make clean;
  make script_clean;
  make script;
  errchok "Skript make form completely clean";

  subcommand bench;
  errchok "Integration ☺";
}

# This is used by vim
command_make()
{
  make "$@";
}

command_clean()
{
  set_args "--name" "$@";
  eval "$get_args";

  make clean;
  make script_clean;

  if [[ -v name ]]; then
    rm -vf "$engine_name_$name";
  fi
  errchok "Cleaned build directory";
}

command_ready()
{
  subcommand bench;
  cp -vf "$engine_binary" "$patch_binary";
  errchok "Created patch version";
  subcommand build --commit=master;
  errchok "Created master version";
}

# Replaces old ./bench script. Basically, does all is-bench-ok-tests
command_bench()
{
  set_args "--verbose=false --commit --binary --all --build" "$@";
  eval "$get_args";

  if [[ -v build ]]; then
    subcommand build "--verbose=$verbose";
  fi
  if [[ -v commit ]] || [[ -v all ]] ; then subcommand commit_bench --all; fi
  if [[ -v commit ]] || [[ -v all ]] ; then subcommand binary_bench --all; fi
}

command_commit_bench()
{
  set_args "--all --master --master-branch --head --patch --branch" "$@";
  eval "$get_args";

  if [[ -v path ]]; then abort "$FUNCNAME path: Not implemented"; fi

  errchoi "Commit Bench";

  declare -r sed_expr='s/[ 	]*[Bb]ench[: 	]*\([0-9]\+$\)/ \1/';
  declare -r sed_expr2='s/^\s*Bench[[:space:]:=]*\s([[:digit:]]+)\s*$/\1/';

  # Grep for:
  # OVERALL:   11124 ms      22405804 nodes    2014185 nps
  if [[ -v master_branch ]] || [[ -v all ]]; then show_branch_bench "master"; fi
  if [[ -v master ]] || [[ -v all ]]; then        show_commit_bench "master"; fi
  if [[ -v head   ]] || [[ -v all ]]; then        show_commit_bench "HEAD"; fi
  if [[ -v branch   ]] || [[ -v all ]]; then      show_branch_bench "$(git_current_branch)"; fi
  # TODO No use?
  #  if [[ -v head_branch   ]] || [[ -v all ]]; then show_branch_bench "HEAD" & fi
  # TODO Not implemented
  #if [[ -v patch ]] || [[ -v all ]]; then show_commit_bench "$engine_binary" Normal; fi

  wait $(jobs -p);
}

command_binary_bench()
{
  set_args "--all --master --live" "$@";
  eval "$get_args";

  errchoi "Binary Bench";

  if [[ -v master ]] || [[ -v all ]]; then show_binary_bench "master" "$master_binary" "master" & fi
  if [[ -v live   ]] || [[ -v all ]]; then show_binary_bench "live"   "$engine_binary" "HEAD" & fi
  #if [[ -v patch ]] || [[ -v all ]]; then show_binary_bench "$engine_binary" Normal; fi

  wait $(jobs -p);
}

command_build()
{
  set_args "--verbose=false --retry-clean=true --commit=? --no-skip --clean --help" "$@";
  eval "$get_args";

  # Clean build fragments
  if [[ -v clean ]]; then
    subcommand clean;
  fi

  # Special case: Build differench branch master
  if [[ "$commit" != "?" ]]; then
    if ! git_test_clean; then abort "$FUNCNAME: Working dir not clean"; fi
    declare -r current_branch="$(git_current_branch)";
    if [[ "$current_branch" == "HEAD" ]]; then
      abort "$FUNCNAME: Could not return to detached HEAD";
    fi
    errchon "Leaving: $(git rev-parse --abbrev-ref --short HEAD)";
    git checkout "$commit";
    subcommand clean "--name=$current_branch";
    subcommand build;
    errchok "Built $commit ($(git rev-parse --short HEAD))";
    # TODO use ${engine_binary}_$commit?
    mv -vf "$engine_binary" "${engine_name}_${commit}";
    git checkout "$current_branch";
    errchon "Back to: $(git rev-parse --abbrev-ref --short HEAD)";

    # Restore crrent build
    # TODO Not needed since we want to patch engine differently
    #    subcommand build;
    #    cp -vf "$engine_binary" "$patch_binary";
    subcommand bench;
  fi

  # Sanity check
  if ! git_test_clean; then
    errchow "Building unclean work tree";
  fi

  # Build config
  declare -r make_args=(--jobs=4 script);

  # Test if build needed before-hand
  if [[ ! -v no_skip ]] && [[ -z "$(make --dry-run --silent ${make_args[@]})" ]]; then
    errchos "[up-to-date] Building engine";
    return 0;
  fi

  # (!) Build ignoring errors
  declare -i ret="9876";
  set +e;
  if [[ "$verbose" != "false" ]]; then
    # No quotes
    make "${make_args[@]}";
    ret="$?";
  else
    # No quotes
    make "${make_args[@]}" 2>&1 >/dev/null;
    ret="$?";
  fi
  set -e; # (!)

  # Handle errors
  if ((ret != 0)); then
    errchoe "Build failed";
    if [[ "$retry_clean" == "true" ]]; then
      errchol "Retry building from clean state";
      subcommand build --clean --verbose="true" --retry-clean="false";
      ret="$?";
    fi
  else
    errchok "Build successful";
  fi

  return "$ret";
}

command_retool()
{
  set_args "--dir=scripts/" "$@";
  eval "$get_args";

  declare -a files;
  declare file;
  files=($(command ls ~/dotfiles/scripts/fishdev));
  for file in "${files[@]}"; do
    ln -vf ~/dotfiles/scripts/fishdev/"$file" "$dir/$file";
  done
  errchok "Linked scripts";
}

# ┌────────────────────────┐
# │ Helpers                │
# └────────────────────────┘

declare -r code_start=" ";
declare -r bin_start=" ";

# show…: Show the value with a message (for terminal output)
# get…: Output the numerical value only (for script use)
# grep_sed…: (helper; dont use)
show_commit_bench()
{
  declare cb="$(get_commit_bench "$1")";
  declare col="$text_red";
  if [[ -n "$cb" ]]; then col="$text_green"; fi
  printf "%s\n" "$code_start$cb  ${col}∗ $1$text_normal";
}
show_branch_bench()
{
  declare bb="$(get_branch_bench "$1")";
  declare col="$text_red";
  if [[ -n "$bb" ]]; then col="$text_blue"; fi
  printf "%s\n" "$code_start$bb ${col}⎇  $1$text_normal";
}
show_binary_bench()
{
  # TODO Should we validate against commit bench or branch bench?
  declare -r name="${1:-"<Unnamed>"}";
  declare -r test_binary="${2:?"$FUNCNAME: Missing binary"}";
  declare -r validation_commit="${3:-""}";

  declare -r bin_bench="$(get_binary_bench "$test_binary")";
  declare -r bin_time="$(get_mtime "$test_binary")";
  declare col="$text_normal";
  if [[ -n "$validation_commit" ]]; then
    declare -r commit_val="$(get_commit_bench "$validation_commit")";
    if [[ -n "$commit_val" ]] && [[ "$bin_bench" == "$commit_val" ]]; then
      col="$col${text_green}";
    else
      col="$col${text_red}";
    fi
  fi

  printf "%s\n" "$bin_start$bin_bench  ${col}⚙ $name $text_normal$text_dim($test_binary [∗ $validation_commit] • $bin_time$text_normal)";

}
get_commit_bench()
{
  git show "--format=%B" --no-patch "$1" | grep_sed_bench_commit;
}
get_branch_bench()
{
  git log "--format=%B" --no-patch -n10 "$1" | grep_sed_bench_commit;
}
get_binary_bench()
{
  "$1" bench | grep_sed_bench_output;
}
grep_sed_bench_commit()
{
  # Grep for "Bench: 123456789"
  declare -r sed_expr='s/^\s*Bench[[:space:]:=]*\s([[:digit:]]+)\s*$/\1/';
  grep --max-count=1 -ie '^\s*bench' |
    sed -E "$sed_expr" ||
    :; # Ignore errors from using sed with empty input
}

grep_sed_bench_output()
{
  # Grep for "OVERALL:   11124 ms      22405804 nodes    2014185 nps"
  declare -r sed_expr='s/.*\s([0-9]*) nodes.*/\1/';
  tail --lines=1 | sed -E "$sed_expr";
}

get_mtime()
{
  stat "--format=%y" "$1";
}

# ┌────────────────────────┐
# │ Help strings           │
# └────────────────────────┘

declare -r build_help_string="Build engine binary

Main building entry point. Replaces raw use of make in the happy path.

OPTIONS

  --verbose={true|false}:  Show output of make (default false).

  --retry-clean={true|false}: If build faily, make clean and retry with
    --verbose=true (default true).

  --commit=COMMIT: Checkout commit/branch before building. Return to current
    branch afterwards.

  --clean: Use make clean before building.";
