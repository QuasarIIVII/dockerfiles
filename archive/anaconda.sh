#!/bin/bash

function install(){
	# check system architecture : x86_64 or arm64
	case "$(uname -m)" in
		x86_64)
			ARCH="x86_64"
			;;
		aarch64)
			ARCH="arm64"
			;;
		*)
			echo "Unsupported architecture: $(uname -m)"
			exit 1
			;;
	esac

	if [ $ARCH = "x86_64" ]; then
		URL="https://repo.anaconda.com/archive/Anaconda3-2024.10-1-Linux-x86_64.sh"
	elif [ $ARCH = "arm64" ]; then
		URL="https://repo.anaconda.com/archive/Anaconda3-2024.10-1-Linux-aarch64.sh"
	fi

	FILEPATH="/tmp/$(whoami)/anaconda.sh"
	aria2c -x 16 -d $(dirname "$FILEPATH") -o $(basename "$FILEPATH") "$URL"
	chmod +x $FILEPATH
	bash $FILEPATH -b
	rm -f $FILEPATH

	echo "DONE." >> $LOGFILE
}

function init(){
	PREFIX="$HOME/anaconda3"

	case $SHELL in
		# We call the module directly to avoid issues with spaces in shebang
		*zsh) "$PREFIX/bin/python" -m conda init zsh ;;
		*) "$PREFIX/bin/python" -m conda init ;;
	esac
	if [ -f "$PREFIX/bin/mamba" ]; then
		case $SHELL in
			# We call the module directly to avoid issues with spaces in shebang
			*zsh) "$PREFIX/bin/python" -m mamba.mamba init zsh ;;
			*) "$PREFIX/bin/python" -m mamba.mamba init ;;
		esac
	fi
}


LOGFILE="/tmp/$(whoami)/anaconda.log"

case "$1" in
	install)
		mkdir -p $(dirname $LOGFILE)
		install &> $LOGFILE &
		echo "Anaconda installation started."
		echo "To check the progress, run: tail -f $LOGFILE"
		;;
	wait)
		if [ ! -f $LOGFILE ]; then
			echo "No installation log found. Please run `$0 install` first."
			exit 1
		fi

		echo "Waiting for Anaconda installation to complete..."

		while true; do
			if grep -q "DONE." $LOGFILE; then
				echo "Anaconda installation completed successfully."
				break
			fi
			sleep 1
		done

		sleep 1
		;;
	init)
		if [ ! -f $LOGFILE ]; then
			echo "No installation log found. Please run `$0 install` first."
			exit 1
		fi

		if grep -q "DONE." $LOGFILE; then
			init
			echo "Anaconda initialized successfully."
		else
			echo "Anaconda installation is not complete. Please wait for it to finish."
		fi
		;;
	*)
		echo "Usage: $0 install|wait"
		exit 1
		;;
esac
