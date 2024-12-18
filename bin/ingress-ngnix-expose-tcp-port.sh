#!/usr/bin/env bash

set -e
set -o pipefail

# This is a rather minimal example Argbash potential
# Example taken from http://argbash.readthedocs.io/en/stable/example.html
#
# ARG_OPTIONAL_SINGLE([src-port],[p],[source port])
# ARG_OPTIONAL_SINGLE([namespace],[n],[namespace name])
# ARG_OPTIONAL_SINGLE([dst-service],[s],[destination service])
# ARG_OPTIONAL_SINGLE([dst-port],[d],[destination port])
# ARG_OPTIONAL_BOOLEAN([debug],[x],[enable debug])
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
	local first_option all_short_options='pnsdxh'
	first_option="${1:0:1}"
	test "$all_short_options" = "${all_short_options/$first_option/}" && return 1 || return 0
}

# THE DEFAULTS INITIALIZATION - OPTIONALS
_arg_src_port=
_arg_namespace=
_arg_dst_service=
_arg_dst_port=
_arg_debug="off"


# Function that prints general usage of the script.
# This is useful if users asks for it, or if there is an argument parsing error (unexpected / spurious arguments)
# and it makes sense to remind the user how the script is supposed to be called.
print_help()
{
	printf '%s\n' "The general script's help msg"
	printf 'Usage: %s [-p|--src-port <arg>] [-n|--namespace <arg>] [-s|--dst-service <arg>] [-d|--dst-port <arg>] [-x|--(no-)debug] [-h|--help]\n' "$0"
	printf '\t%s\n' "-p, --src-port: source port (no default)"
	printf '\t%s\n' "-n, --namespace: namespace name (no default)"
	printf '\t%s\n' "-s, --dst-service: destination service (no default)"
	printf '\t%s\n' "-d, --dst-port: destination port (no default)"
	printf '\t%s\n' "-x, --debug, --no-debug: enable debug (off by default)"
	printf '\t%s\n' "-h, --help: Prints help"
}


# The parsing of the command-line
parse_commandline()
{
	while test $# -gt 0
	do
		_key="$1"
		case "$_key" in
			# We support whitespace as a delimiter between option argument and its value.
			# Therefore, we expect the --src-port or -p value.
			# so we watch for --src-port and -p.
			# Since we know that we got the long or short option,
			# we just reach out for the next argument to get the value.
			-p|--src-port)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_src_port="$2"
				shift
				;;
			# We support the = as a delimiter between option argument and its value.
			# Therefore, we expect --src-port=value, so we watch for --src-port=*
			# For whatever we get, we strip '--src-port=' using the ${var##--src-port=} notation
			# to get the argument value
			--src-port=*)
				_arg_src_port="${_key##--src-port=}"
				;;
			# We support getopts-style short arguments grouping,
			# so as -p accepts value, we allow it to be appended to it, so we watch for -p*
			# and we strip the leading -p from the argument string using the ${var##-p} notation.
			-p*)
				_arg_src_port="${_key##-p}"
				;;
			# See the comment of option '--src-port' to see what's going on here - principle is the same.
			-n|--namespace)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_namespace="$2"
				shift
				;;
			# See the comment of option '--src-port=' to see what's going on here - principle is the same.
			--namespace=*)
				_arg_namespace="${_key##--namespace=}"
				;;
			# See the comment of option '-p' to see what's going on here - principle is the same.
			-n*)
				_arg_namespace="${_key##-n}"
				;;
			# See the comment of option '--src-port' to see what's going on here - principle is the same.
			-s|--dst-service)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_dst_service="$2"
				shift
				;;
			# See the comment of option '--src-port=' to see what's going on here - principle is the same.
			--dst-service=*)
				_arg_dst_service="${_key##--dst-service=}"
				;;
			# See the comment of option '-p' to see what's going on here - principle is the same.
			-s*)
				_arg_dst_service="${_key##-s}"
				;;
			# See the comment of option '--src-port' to see what's going on here - principle is the same.
			-d|--dst-port)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_dst_port="$2"
				shift
				;;
			# See the comment of option '--src-port=' to see what's going on here - principle is the same.
			--dst-port=*)
				_arg_dst_port="${_key##--dst-port=}"
				;;
			# See the comment of option '-p' to see what's going on here - principle is the same.
			-d*)
				_arg_dst_port="${_key##-d}"
				;;
			# The debug argurment doesn't accept a value,
			# we expect the --debug or -x, so we watch for them.
			-x|--no-debug|--debug)
				_arg_debug="on"
				test "${1:0:5}" = "--no-" && _arg_debug="off"
				;;
			# We support getopts-style short arguments clustering,
			# so as -x doesn't accept value, other short options may be appended to it, so we watch for -x*.
			# After stripping the leading -x from the argument, we have to make sure
			# that the first character that follows coresponds to a short option.
			-x*)
				_arg_debug="on"
				_next="${_key##-x}"
				if test -n "$_next" -a "$_next" != "$_key"
				then
					{ begins_with_short_option "$_next" && shift && set -- "-x" "-${_next}" "$@"; } || die "The short option '$_key' can't be decomposed to ${_key:0:2} and -${_key:2}, because ${_key:0:2} doesn't accept value and '-${_key:2:1}' doesn't correspond to a short option."
				fi
				;;
			# See the comment of option '--debug' to see what's going on here - principle is the same.
			-h|--help)
				print_help
				exit 0
				;;
			# See the comment of option '-x' to see what's going on here - principle is the same.
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

[ "${_arg_debug}" == "on" ] && set -x

if [ "${_arg_src_port}" == "" ]; then
    printf "error: missing src-port parameter\n\n"
        print_help
    exit 1
fi

if [ "${_arg_namespace}" == "" ]; then
    printf "error: missing namespace parameter\n\n"
        print_help
    exit 1
fi

if [ "${_arg_dst_service}" == "" ]; then
    printf "error: missing dst-service parameter\n\n"
        print_help
    exit 1
fi

if [ "${_arg_dst_port}" == "" ]; then
    printf "error: missing dst-port parameter\n\n"
        print_help
    exit 1
fi

helm upgrade --reuse-values --namespace ingress-nginx ingress-controller \
    ingress-nginx/ingress-nginx \
    --set "tcp.${_arg_src_port}=${_arg_namespace}/${_arg_dst_service}:${_arg_dst_port}"
