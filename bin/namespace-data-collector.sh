#!/usr/bin/env bash

set -e

# This is a rather minimal example Argbash potential
# Example taken from http://argbash.readthedocs.io/en/stable/example.html
#
# ARG_OPTIONAL_SINGLE([namespace],[n],[namespace name],["default"])
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
	local first_option all_short_options='ndh'
	first_option="${1:0:1}"
	test "$all_short_options" = "${all_short_options/$first_option/}" && return 1 || return 0
}

# THE DEFAULTS INITIALIZATION - OPTIONALS
_arg_namespace="default"
_arg_debug="off"


# Function that prints general usage of the script.
# This is useful if users asks for it, or if there is an argument parsing error (unexpected / spurious arguments)
# and it makes sense to remind the user how the script is supposed to be called.
print_help()
{
	printf '%s\n\n' "The general script's help msg"
	printf 'Usage: %s -n|--namespace <arg> [-d|--(no-)debug] [-h|--help]\n\n' "$0"
	printf '\t%s\t\t\t%s\n' "-n, --namespace" "namespace name (default: 'default')"
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
			# The debug argument doesn't accept a value,
			# we expect the --debug or -d, so we watch for them.
			-d|--no-debug|--debug)
				_arg_debug="on"
				test "${1:0:5}" = "--no-" && _arg_debug="off"
				;;
			# We support getopts-style short arguments clustering,
			# so as -d doesn't accept value, other short options may be appended to it, so we watch for -d*.
			# After stripping the leading -d from the argument, we have to make sure
			# that the first character that follows corresponds to a short option.
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

[ "${_arg_debug}" == "on" ] && set -x

if [ "${_arg_namespace}" == "" ]; then
    printf "error: missing namespace parameter\n\n"
        print_help
    exit 1
fi

DATA_DIR="data-collector/${_arg_namespace}"

rm -rf "${DATA_DIR}"
mkdir -p "${DATA_DIR}"

echo ""
echo "# Collecting data from namespace ${_arg_namespace} #"
echo ""

echo "Collecting events"
kubectl -n "${_arg_namespace}" get events --sort-by='{.lastTimestamp}' > "${DATA_DIR}/events.log" 2>&1

echo "Collecting namespace details"
kubectl get namespace "${_arg_namespace}" -o yaml > "${DATA_DIR}/namespace.yaml"

RESOURCES=(
	activemqartemises
	catalogsources
	clusterrolebindings
	clusterroles
	clusterserviceversions
	configmaps
	customresourcedefinitions
	deployments
	endpoints
	ingresses
	installplans
	networkpolicies
	operatorgroups
	persistentvolumeclaims
	persistentvolumes
	poddisruptionbudgets
	pods
	replicasets
	rolebindings
	roles
	routes
	secrets
	serviceaccounts
	services
	statefulsets
	subscriptions
)

for resource_type in "${RESOURCES[@]}"; do
	# get the list of resource for the given resource type
    resource_list=$(kubectl get "${resource_type}" -n "${_arg_namespace}" -o name 2>&1 || true)

    if [ "${resource_list}" ] && [[ ! "${resource_list}" == *"the server doesn't have a resource type"* ]]; then
        echo "Collecting data for resource type ${resource_type}"

		# create resource type dir
		resource_type_dir="${DATA_DIR}/${resource_type}"
        mkdir -p "${resource_type_dir}"

		# for the given resource type get the list of resources
		kubectl -n "${_arg_namespace}" get "${resource_type}" > "${resource_type_dir}/_${resource_type}.log"

		for i in $resource_list; do
			# dump the resource yaml for the given resource
            name=${i#*/}
            kubectl get "${resource_type}" "${name}" -o yaml -n "${_arg_namespace}" > "${resource_type_dir}/${name}.yaml"

			# for pod resources, get some contents from it
			if [ "${resource_type}" == "pods" ]; then
				# get pod logs
				pod_containers=$(kubectl -n "${_arg_namespace}" get pod "${name}" -o yaml | yq '.spec.initContainers[].name, .spec.containers[].name' || true)
				echo "${pod_containers}" | while read -r c; do
					kubectl -n "${_arg_namespace}" logs "${name}" -c "${c}" > "${resource_type_dir}/${name}-${c}".log
				done

				# if pod is an artemis pod, collect the artemis instance data
				is_artemis_pod=$(kubectl -n "${_arg_namespace}" exec "${name}" -- env 2>/dev/null | grep AMQ_NAME || true)
				if [ "${is_artemis_pod}" ]; then
					pod_dir="${resource_type_dir}/${name}"
				    mkdir -p "${pod_dir}"
					kubectl -n "${_arg_namespace}" exec "${name}" -- tar cf - amq-broker 2>/dev/null | tar xf - -C "${pod_dir}"
				fi
			fi

			# for secrets, decode them
			if [ "${resource_type}" == "secrets" ]; then
				secret_dir="${resource_type_dir}/${name}"
			    mkdir -p "${secret_dir}"

				kubectl -n "${_arg_namespace}" get secrets "${name}" -o yaml | yq -r '.data' | while read -r j; do 
					secret_data_name=$(echo "$j" | awk -F": " '{ print $1 }')
					secret_data_value=$(echo "$j" | awk -F": " '{ print $2 }')
					if [ -z "${secret_data_value}" ] || [ "${secret_data_value}" == "\"\"" ]; then
						echo "${secret_data_value}" > "${secret_dir}/${secret_data_name}"; \
					else
						echo "${secret_data_value}" | base64 -d > "${secret_dir}/${secret_data_name}"
					fi
				done
			fi

        done
    else 
        echo "No data for resource type ${resource_type}"
    fi
done
