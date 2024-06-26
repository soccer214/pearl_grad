#!/bin/bash

################################################################################
# CONSTANTS
################################################################################
KERNEL_NAME=$(uname -s)
IS_CLEAR_FLAG=0
IS_PSEUDO_FLAG=0
IS_VERBOSE_FLAG=0
IF_PLAY_SHORT_SONG=0
IF_PLAY_SONG=1
IF_USE_BROWSER=1
IS_LOOP=0

MUSIC_PLAYER="cvlc"
MUSIC_PLAYER_FLAGS=" --audio --play-and-exit"
MUSIC_PLAY_LOOP_FLAG="--no-loop"
BROWSER_PLAYER="chromium"
BROWSER_FULLSCREEN_FLAGS="--start-fullscreen"
BROWSER_PROGRAM="ecg-line-webcomponent/index.html"
KILL_CHROMIUM_CMD="pkill -o chromium"
BROWSER_FULLSCREEN=1

VALIDATE_RVAL=0
SKIP_VALIDATION=0

echo "program: $0"
PROGRAM_NAME=$(basename -- "$0")

#----------------------------------------------
# MESSAGE VARIABLES
#----------------------------------------------
MSG_ERROR=0
MSG_WARNING=1
MSG_INFO=2

#----------------------------------------------
# PROGRAM VARIABLES
#----------------------------------------------
SONG_FILE_NAME="like_a_surgeon.mp3"
SONG_FILE_NAME_SHORT="like_a_surgeon-short.mp3"

################################################################################
# SPECIFIC FUNCTIONS
################################################################################

#-------------------------------------------------------------------
# check_for_root()
#
# Comments:
#    Verify that the user is running as root
#-------------------------------------------------------------------
check_for_root() {
	if [ "$EUID" -ne 0 ]; then
		echo "Please run as root"
		exit
	fi
}

################################################################################
# STANDARD FUNCTIONS
################################################################################

#-------------------------------------------------------------------
# internal_error()
# $2: Message
#-------------------------------------------------------------------
internal_error() {
	"[INTERNAL ERROR] $1"
	exit
}

#-------------------------------------------------------------------
# err_msg()
# $1: Message Type
# $2: Message
# $3: Exit
#-------------------------------------------------------------------
err_msg() {
	if [[ $# -ne 3 ]]; then
		internal_error "msg() error.  Invalid parameter count ($#)"
	fi

	MSG_TYPE=$1
	MSG=$2
	MSG_EXIT=$3
	is_verbose "[err_msg] MSG_TYPE: $MSG_TYPE"

	case $1 in
	$MSG_ERROR)
		MSG_TYPE_STRING="ERROR"
		;;
	$MSG_WARNING)
		MSG_TYPE_STRING="WARNING"
		;;
	$MSG_INFO)
		MSG_TYPE_STRING="INFO"
		;;
	*)
		MSG_TYPE_STRING="UNKNOWN"
		;;
	esac

	echo "[$MSG_TYPE_STRING] $MSG"

	if [ '$MSG_EXIT' != '0' ]; then
		exit
	fi
}

#-------------------------------------------------------------------
# msg()
# $1: Message
#-------------------------------------------------------------------
msg() {
	echo "$1"
}

#-------------------------------------------------------------------
# is_verbose()
#-------------------------------------------------------------------
is_verbose() {
	if [[ $IS_VERBOSE_FLAG -eq 1 ]]; then
		echo "[VERBOSE] $1"
	fi
}

#-------------------------------------------------------------------
# do_cmd
#-------------------------------------------------------------------
do_cmd() {
	local cmd=$1
	RVAL=0

	if [[ $IS_PSEUDO_FLAG -eq 1 ]]; then
		echo "[PSEUDO] $cmd"
	else
		if [[ $IS_VERBOSE_FLAG -eq 1 ]]; then
			is_verbose "[cmd] $cmd"
		fi
		eval "$cmd"
		RVAL=$?
	fi
}

#-------------------------------------------------------------------
# help
#-------------------------------------------------------------------
help() {
	echo "PROGRAM"
	echo "   $PROGRAM_NAME"
	echo
	echo "SYNOPSIS"
	echo "   $PROGRAM_NAME [-h, --help], [-p, --pseudo], [-v, --verbose]"
	echo "                 [--nosong] [--nobrowser] [-s, --shortsong]"
	echo "                 [--skipval]"
	echo
	echo "              If no options are given, the program starts a chromium browser"
	echo " and the song. When the song is completed, the broser is closed.  If the song doesn't"
	echo " the browser won't close."
	echo
	echo "DESCRIPTION"
	echo "     $PROGRAM_NAME runs the browser and the song."
	echo
	echo "OPTIONS"
	echo " --nobrowser"
	echo " The browser will not be run."
	echo
	echo " --nosong"
	echo " The song will not be played, and consequently, the browser will not be shutdown."
	echo
	echo "--skipval"
	echo " Skip the validation."
	echo
	echo " -l, --loop"
	echo " Loop the song.  The only way to exit is to <Ctrl>-C."
	echo
	echo " -s, --short"
	echo " Use the short song file."
	echo
	echo "   -h, --help"
	echo "      Bring up the help text."
	echo
	echo "   -p, --pseudo"
	echo "      Test mode, don't actually do anything"
	echo
	echo "   -v, --verbose"
	echo "      Verbose (used for debugging)"
	echo
	echo "EXAMPLES"
	echo "  Normal running"
	echo "     $PROGRAM_NAME"
	echo
	echo "  Run with the short song:"
	echo "     $PROGRAM_NAME --short"
	echo
	echo "  Run with the short song, and not a full screen:"
	echo "     $PROGRAM_NAME --short --nofullscreen"
	exit
}

################################################################################
# PARSE
################################################################################
parse() {

	SHORT=b:,l,s,h,p,v
	LONG=browser:,loop,nobrowser,nofullscreen,nosong,short,skipval,help,pseudo,verbose OPTS=$(getopt --options $SHORT --longoptions $LONG -- "${@}")

	eval set -- "$OPTS"

	while :; do
		case "$1" in
		-b | --browser)
			BROWSER_PLAYER=$2
			shift 2
			;;
		--nobrowser)
			IF_USE_BROWSER=0
			shift 1
			;;
		--nofullscreen)
			BROWSER_FULLSCREEN_FLAGS=""
			shift 1
			;;
		--nosong)
			IF_PLAY_SONG=0
			shift 1
			;;
		--skipval)
			SKIP_VALIDATION=1
			shift 1
			;;
		-l | --loop)
			MUSIC_PLAY_LOOP_FLAG="--loop"
			shift 1
			;;
		-s | --short)
			IF_PLAY_SHORT_SONG=1
			shift 1
			;;
		-h | --help)
			help
			exit 2
			;;
		-p | --pseudo)
			IS_PSEUDO_FLAG=1
			shift
			;;
		-v | --verbose)
			echo "is verbose now 1"
			IS_VERBOSE_FLAG=1
			shift 1
			;;
		--)
			shift
			break
			;;
		*)
			echo "Unexpected option: $1"
			shift
			break
			;;
		esac
	done
	# Positional Parameters remaining...
	# echo "The number of positional parameter : $#"
	# if [ "$#" = 0 ]; then
	# 	echo "You forgot to put the file name at the end of the command line"
	# 	echo "All position parameters remaining: '$@"
	# 	echo "1: $1"
	# fi

	is_verbose "-------------------------------------------------------------"
	is_verbose "DATA"
	is_verbose "-------------------------------------------------------------"
	is_verbose "MUSIC_PLAYER:              $MUSIC_PLAYER"
	is_verbose "MUSIC_PLAYER_FLAGS:        $MUSIC_PLAYER_FLAGS"
	is_verbose "MUSIC_PLAYER_LOOP_FLAG:    $MUSIC_PLAYER_LOOP_FLAG"
	is_verbose "SONG_FILE_NAME:            $SONG_FILE_NAME"
	is_verbose "SONG_FILE_NAME_SHORT:      $SONG_FILE_NAME_SHORT"
	is_verbose "BROWSER_PROGRAM:           $BROWSER_PLAYER"
	is_verbose "BROWSER_FULLSCREEN_FLAGS:  $BROWSER_FULLSCREEN_FLAGS"
	is_verbose "BROWSER_PROGRAM:           $BROWSER_PROGRAM"
	is_verbose "-------------------------------------------------------------"
	is_verbose "Options"
	is_verbose "-------------------------------------------------------------"
	is_verbose "IF_USE_BROWSER:            $IF_USE_BROWSER"
	is_verbose "IF_PLAY_SONG:              $IF_PLAY_SONG"
	is_verbose "IF_PLAY_SHORT_SONG:        $IF_PLAY_SHORT_SONG"
	is_verbose "SKIP_VALIDATION:           $SKIP_VALIDATION"
	is_verbose "-------------------------------------------------------------"
	is_verbose "Standard Options"
	is_verbose "-------------------------------------------------------------"
	is_verbose "IS_VERBOSE_FLAG flag:      $IS_VERBOSE_FLAG"
	is_verbose "IS_PSEUDO_FLAG flag:       $IS_PSEUDO_FLAG"
	is_verbose "-------------------------------------------------------------"

	return 1

} # parse()

################################################################################
# validate: validate all necessary programms, etc
################################################################################
validate() {
	VALIDATE_RVAL=0
	RVAL=0

	# VERIFY media player
	RVAL=$(which $(MUSIC_PLAYER))
	if [[ RVAL -ne 0 ]]; then
		err_msg $MSG_ERROR "Unable to find command line music player $MUSIC_PLAYER" 0
		VALIDATE_RVAL=1
	fi

	# VERIFY browser
	RVAL=$(which $(BROWSER_PLAYER))
	if [[ RVAL -ne 0 ]]; then
		err_msg $MSG_ERROR "Unable to find command line browser $MUSIC_PLAYER" 0
		VALIDATE_RVAL=1
	fi

}

################################################################################
# MAIN
################################################################################
main() {

	parse ${@}
	# check_for_root

	if [[ $SKIP_VALIDATION -eq 0 ]]; then
		validate
		if [[ $VALIDATE_RVAL -ne 0 ]]; then
			echo "Validation failed"
			exit
		fi
	fi

	# Start the browsser in the backbround
	if [[ $IF_USE_BROWSER -eq 1 ]]; then
		# cmd="$BROWSER_PLAYER $BROWSER_FULLSCREEN_FLAGS $BROWSER_PROGRAM "
		# $(cmd) &
		$BROWSER_PLAYER $BROWSER_FULLSCREEN_FLAGS $BROWSER_PROGRAM &
	fi

	# Start the song (short or standard)
	if [[ $IF_PLAY_SONG -eq 1 ]]; then
		if [[ $IF_PLAY_SHORT_SONG -eq 1 ]]; then
			($MUSIC_PLAYER $MUSIC_PLAYER_FLAGS $SONG_FILE_NAME_SHORT $MUSIC_PLAY_LOOP_FLAG)
		else
			($MUSIC_PLAYER $MUSIC_PLAYER_FLAGS $SONG_FILE_NAME $MUSIC_PLAY_LOOP_FLAG)
			# cmd="$MUSIC_PLAYER $MUSIC_PLAYER_FLAGS $SONG_FILE_NAME"
			# do_cmd "$cmd"
		fi
		is_verbose "Music player exited"
		is_verbose "Checking if browser was used, to determine if we should kill"
		# After the muisc is done, if we have started the browser, kill it.
		if [[ $IF_USE_BROWSER -eq 1 ]]; then
			is_verbose "Killing browser"
			do_cmd "$KILL_CHROMIUM_CMD"
		fi
	fi

	#-------------------------------------------------------------------
	# Done!
	#-------------------------------------------------------------------
	echo "Complete!"
}

# For unit testing, we do not call main() if the file is sourced by the
# unit test framework
if [ "$0" == "$BASH_SOURCE" ]; then
	main $@
fi

#==============================================================================
