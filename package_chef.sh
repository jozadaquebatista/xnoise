# Script for debian packagement by Tal Hadad.
# You can do what ever you want with this file under
# your responsibility, no copyright intended.

#The format is:
#ARGS_INPUT_FORMAT="OPTION STRING 1|OPTION STRING 2(OPTIONAL)|OPTION STRING N(OPTIONAL):VARIABLE NAME WHICH HOLDS OPTION VALUE:DEFAULT OPTION VALUE(OPTIONAL):DEFAULT OPTION VALUE IF USED AS SWITCH(OPTIONAL)"

ARGS_INPUT_FORMAT="-h|-?|--help:help:-1:0,--name:name:package,--version:version:1.0,--src-tar:src_tar:-1,--src-dir:src_dir:${PWD},--output-dir:output_dir:package_result,--distro:distro:debian,-S|--build-source:build_source:no:yes,-B|--build-binary:build_binary:no:yes,--maintainer:maintainer:-1,-us|--dont-sign:dont_sign:no:yes,-uc|--dont-sign-changes:dont_sign_changes:no:yes,-sa|--include-orig:include_orig:yes:yes"

# Parsing arguments script.
# This script was taken from:
# http://www.findlinuxhelp.com/archives/script/shellscript/easy-commandline-argument-parsing-in-shell-script/
for arg_opts in $(echo "$ARGS_INPUT_FORMAT" | tr "," " ") ; do
  opt_names=$(echo "$arg_opts" | cut -d':' -f1)
  opt_var=$(echo "$arg_opts" | cut -d':' -f2)
  opt_def_val=$(echo "$arg_opts" | cut -d':' -f3)
  opt_switch_val=$(echo "$arg_opts" | cut -d':' -f4)
  eval "$opt_var=$opt_def_val"
  for opt_name in $(echo "$opt_names" | tr "|" " ") ; do
    arg_pos=1
    while [ $arg_pos -le $# ] ; do
      case "$(eval "echo \$$arg_pos")" in
        "$opt_name="*)
              eval "$opt_var=\"$(echo "$(eval "echo \$$arg_pos")" | sed 's/^'"$opt_name"'=//')\""
              ARGS_STAT[$arg_pos]=0
              ;;
        "$opt_name")
              if [ $(expr $arg_pos + 1) -le $# ] && [ $(echo "$(eval "echo \$$(expr $arg_pos + 1)")" | grep -c '^-') -eq 0 ] ; then
                ARGS_STAT[$arg_pos]=0
                arg_pos=$(expr $arg_pos + 1)
                eval "$opt_var=\"$(eval "echo \$$arg_pos")\""
              else
                eval "$opt_var=\"$opt_switch_val\""
              fi
              ARGS_STAT[$arg_pos]=0
              ;;
        "$opt_name"*)
              eval "$opt_var=\"$(echo "$(eval "echo \$$arg_pos")" | sed 's/^'"$opt_name"'//')\""
              ARGS_STAT[$arg_pos]=0
              ;;
        *)
              [ -z "${ARGS_STAT[$arg_pos]}" ] && ARGS_STAT[$arg_pos]=1
              ;;
      esac
      arg_pos=$(expr $arg_pos + 1)
    done
  done
done

# Help
if [ "$help" != "-1" ]; then
  echo \
"Usage: $(basename $0) [OPTIONS]
Builds a given package into a Debian package, source package, or both into an
  output folder.

Options:
  -h, -?, --help               Show this help message.
  --name=NAME                  The name of the package. (default: package)
  --version=VERSION            The version of the package. (default: 1.0)
  --src-tar=TARBALL            The source tarball(.tar, .tar.gz or .tar.bz2) of
                                 the package. (default: empty string)
  --src-dir=DIR                The directory of the source package, if no
                                 TARBALL was given. (default: $\{PWD\})
  --output-dir=OUT_DIR         The output folder. (default: package_result)
  --distro=DISTRO              The targeted distro for the packge. (default:
                                 debian; for Ubuntu use 'ubuntu/precise' or
                                 'ubuntu/quantal')
  -S, --build-source[=yes|no]  Weather to only build a Debian source package.
  -B, --build-binary[=yes|no]  Weather to only build Debian binary packages.
  --maintainer=MAINTAINER      The maintainer which sign on the packages.
  -us, --dont-sign[=yes|no]    Dont create a GPG signature file(.dsc) for the
                                 packages. (default: no)
  -uc,                         Dont sign the .changes file. (default: no)
  --dont-sign-changes[=yes|no]
  -sa, --include-orig[=yes|no] Include the package original source file in the
                                 .changes file. (default: no)
  
  
Xnoise EXAMPLE:
  Source package tar.gz is in the same folder as this script.
  
  ./package_chef.sh --distro=ubuntu/precise --name=xnoise --version=0.2.6 
    --src-tar=xnoise-0.2.6.tar.gz
  
  
Bugs:
  Please report bugs in this script on the xnoise bugtracker here:
  https://github.com/shuerhaaken/xnoise/issues
"
  exit 0
fi

# Define convinient varibles.
mkdir -p "$output_dir"
formatted_version=$(echo "$version" | sed 's/-/./g')
std_version=$(echo "$version" | cut -d'-' -f1)
name_version=$name-$std_version
package_dir=$output_dir/$name_version

# Extract/copy source directory.
case $src_tar in
  -1 )
    echo "no source tarball was given. copy source directory."
    cp -R -T "$src_dir" "$package_dir"
    ;;
  *tar )
    echo "tarball ends with tar."
    tar -C $output_dir -xvf "$src_tar" "$name_version"
    ;;
  *tar.gz )
    echo "tarball ends with tar.gz."
    tar -C $output_dir -xvzf "$src_tar" "$name_version"
    ;;
  *tar.bz2 )
    echo "tarball ends with tar.bz2."
    tar -C $output_dir -xvjf "$src_tar" "$name_version"
    ;;
  *)
    echo "Error: unsupported tarball!" 1>&2;;
esac

cp -R "$package_dir/packaging/$distro/debian" "$package_dir"

old_dir0=$PWD

cd $output_dir
orig_tar_name=${name}_${formatted_version}.orig.tar.bz2

# Create a source package (tarball).
tar -cvjf $orig_tar_name $name_version

cd $name_version
debuild_args=$(echo "-v$version ")

if [ "$build_source" == "yes" ] && [ "$build_binary" != "yes" ]; then
  echo "build source only"
  debuild_args=$(echo "$debuild_args-S ")
else if [ "$build_source" != "yes" ] && [ "$build_binary" == "yes" ]; then
  echo "build binary only"
  debuild_args=$(echo "$debuild_args-B ")
else
  echo "build binary and source"
fi
fi

if [ "$maintainer" != "-1" ]; then
  debuild_args=$(echo "$debuild_args-m$maintainer ")
fi

if [ "$dont_sign" == "yes" ]; then
  debuild_args=$(echo "$debuild_args-us ")
fi

if [ "$dont_sign_changes" == "yes" ]; then
  debuild_args=$(echo "$debuild_args-uc ")
fi

if [ "$include_orig" == "yes" ]; then
  debuild_args=$(echo "$debuild_args-sa ")
fi

command -v debuild > /dev/null && \
debuild $debuild_args || \
{ echo "debuild command haven’t been found. Please install the devscripts package."; \
exit 1; }

cd ..

cd $old_dir0
