
export N=3

export CERTS_DIR="certs"
export CONFIG_DIR="config"

if [[ "$MACH_PREFIX" == "" ]]; then
	export MACH_PREFIX="mach"
fi

export DEPLOY_LOG=".deploylog"
