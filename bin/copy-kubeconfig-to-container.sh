#!/usr/bin/env bash

set -e
set -o pipefail

# This is a rather minimal example Argbash potential
# Example taken from http://argbash.readthedocs.io/en/stable/example.html
#
# ARG_OPTIONAL_SINGLE([namespace],[n],[namespace name])
# ARG_OPTIONAL_SINGLE([file],[f],[kubeconfig file])
# ARG_OPTIONAL_SINGLE([pod],[p],[pod name to copy kubeconfig to])
# ARG_OPTIONAL_SINGLE([container],[c],[container name to kubeconfig file to])
# ARG_OPTIONAL_BOOLEAN([debug],[d],[enable debug])
# ARG_HELP([The general script's help msg])
# ARGBASH_GO()
# needed because of Argbash --> m4_ignore([
### START OF CODE GENERATED BY Argbash v2.9.0 one line above ###
# Argbash is a bash code generator used to get arguments parsing right.
# Argbash is FREE SOFTWARE, see https://argbash.io for more info
# Generated online by https://argbash.io/generate


# # When called, the process ends.
# Args:
# 	$1: The exit message (print to stderr)
# 	$2: The exit code (default is 1)
# if env var _PRINT_HELP is set to 'yes', the usage is print to stderr (prior to $1)
# Example:
# 	test -f "$_arg_infile" || _PRINT_HELP=yes die "Can't continue, have to supply file as an argument, got '$_arg_infile'" 4
die()
{
	local _ret="${2:-1}"
	test "${_PRINT_HELP:-no}" = yes && print_help >&2
	echo "$1" >&2
	exit "${_ret}"
}


# Function that evaluates whether a value passed to it begins by a character
# that is a short option of an argument the script knows about.
# This is required in order to support getopts-like short options grouping.
begins_with_short_option()
{
	local first_option all_short_options='nfpcdh'
	first_option="${1:0:1}"
	test "$all_short_options" = "${all_short_options/$first_option/}" && return 1 || return 0
}

# THE DEFAULTS INITIALIZATION - OPTIONALS
_arg_namespace=""
_arg_file=""
_arg_pod=""
_arg_container=""
_arg_debug="off"


# Function that prints general usage of the script.
# This is useful if users asks for it, or if there is an argument parsing error (unexpected / spurious arguments)
# and it makes sense to remind the user how the script is supposed to be called.
print_help()
{
	printf '%s\n' "The general script's help msg"
	printf 'Usage: %s [-n|--namespace <arg>] [-f|--file <arg>] [-p|--pod <arg>] [-c|--container <arg>] [-d|--(no-)debug] [-h|--help]\n\n' "$0"
	printf '\t%s\t\t\t%s\n' "-n, --namespace" "namespace name (no default)"
	printf '\t%s\t\t\t%s\n' "-f, --file" "kubeconfig file (no default)"
	printf '\t%s\t\t\t%s\n' "-p, --pod" "pod name to copy kubeconfig to (no default)"
	printf '\t%s\t\t\t%s\n' "-c, --container" "container name to kubeconfig file to (no default)"
	printf '\t%s\t\t%s\n' "-d, --debug, --no-debug" "enable debug (off by default)"
	printf '\t%s\t\t\t%s\n' "-h, --help" "Prints help"
}


# The parsing of the command-line
parse_commandline()
{
	while test $# -gt 0
	do
		_key="$1"
		case "$_key" in
			# We support whitespace as a delimiter between option argument and its value.
			# Therefore, we expect the --namespace or -n value.
			# so we watch for --namespace and -n.
			# Since we know that we got the long or short option,
			# we just reach out for the next argument to get the value.
			-n|--namespace)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_namespace="$2"
				shift
				;;
			# We support the = as a delimiter between option argument and its value.
			# Therefore, we expect --namespace=value, so we watch for --namespace=*
			# For whatever we get, we strip '--namespace=' using the ${var##--namespace=} notation
			# to get the argument value
			--namespace=*)
				_arg_namespace="${_key##--namespace=}"
				;;
			# We support getopts-style short arguments grouping,
			# so as -n accepts value, we allow it to be appended to it, so we watch for -n*
			# and we strip the leading -n from the argument string using the ${var##-n} notation.
			-n*)
				_arg_namespace="${_key##-n}"
				;;
			# See the comment of option '--namespace' to see what's going on here - principle is the same.
			-f|--file)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_file="$2"
				shift
				;;
			# See the comment of option '--namespace=' to see what's going on here - principle is the same.
			--file=*)
				_arg_file="${_key##--file=}"
				;;
			# See the comment of option '-n' to see what's going on here - principle is the same.
			-f*)
				_arg_file="${_key##-f}"
				;;
			# See the comment of option '--namespace' to see what's going on here - principle is the same.
			-p|--pod)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_pod="$2"
				shift
				;;
			# See the comment of option '--namespace=' to see what's going on here - principle is the same.
			--pod=*)
				_arg_pod="${_key##--pod=}"
				;;
			# See the comment of option '-n' to see what's going on here - principle is the same.
			-p*)
				_arg_pod="${_key##-p}"
				;;
			# See the comment of option '--namespace' to see what's going on here - principle is the same.
			-c|--container)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_container="$2"
				shift
				;;
			# See the comment of option '--namespace=' to see what's going on here - principle is the same.
			--container=*)
				_arg_container="${_key##--container=}"
				;;
			# See the comment of option '-n' to see what's going on here - principle is the same.
			-c*)
				_arg_container="${_key##-c}"
				;;
			# The debug argurment doesn't accept a value,
			# we expect the --debug or -d, so we watch for them.
			-d|--no-debug|--debug)
				_arg_debug="on"
				test "${1:0:5}" = "--no-" && _arg_debug="off"
				;;
			# We support getopts-style short arguments clustering,
			# so as -d doesn't accept value, other short options may be appended to it, so we watch for -d*.
			# After stripping the leading -d from the argument, we have to make sure
			# that the first character that follows coresponds to a short option.
			-d*)
				_arg_debug="on"
				_next="${_key##-d}"
				if test -n "$_next" -a "$_next" != "$_key"
				then
					{ begins_with_short_option "$_next" && shift && set -- "-d" "-${_next}" "$@"; } || die "The short option '$_key' can't be decomposed to ${_key:0:2} and -${_key:2}, because ${_key:0:2} doesn't accept value and '-${_key:2:1}' doesn't correspond to a short option."
				fi
				;;
			# See the comment of option '--debug' to see what's going on here - principle is the same.
			-h|--help)
				print_help
				exit 0
				;;
			# See the comment of option '-d' to see what's going on here - principle is the same.
			-h*)
				print_help
				exit 0
				;;
			*)
				_PRINT_HELP=yes die "FATAL ERROR: Got an unexpected argument '$1'" 1
				;;
		esac
		shift
	done
}

# Now call all the functions defined above that are needed to get the job done
parse_commandline "$@"

# OTHER STUFF GENERATED BY Argbash

### END OF CODE GENERATED BY Argbash (sortof) ### ])

if [ "${_arg_namespace}" == "" ]; then
    printf "error: missing namespace parameter\n\n"
        print_help
    exit 1
fi

if [ "${_arg_file}" == "" ]; then
    printf "error: missing file parameter\n\n"
        print_help
    exit 1
fi

if [ "${_arg_pod}" == "" ]; then
    printf "error: missing pod parameter\n\n"
        print_help
    exit 1
fi

if [ "${_arg_container}" == "" ]; then
    printf "error: missing container parameter\n\n"
        print_help
    exit 1
fi

echo "Copying kubeconfig file ${_arg_file} to container ${_arg_container}, pod ${_arg_pod} in namespace ${_arg_namespace}"

kubectl -n "${_arg_namespace}" exec "${_arg_pod}" --container "${_arg_container}" -- mkdir -p /home/toolbox/.kube
kubectl -n "${_arg_namespace}" exec --stdin "${_arg_pod}" --container "${_arg_container}" -- bash -c "cat - > /home/toolbox/.kube/config" < "${_arg_file}"

