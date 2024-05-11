#!/bin/bash

################################################################################
# CONSTANTS
################################################################################
KERNEL_NAME=$(uname -s)
IS_CLEAR_FLAG=0
IS_PSEUDO_FLAG=0
IS_VERBOSE_FLAG=0
IF_PLAY_SONG=1
IF_USE_BROWSER=1
IS_LOOP=0

SONG_FILE_NAME="like_a_surgeon.mp3"
SONG_FILE_NAME_SHORT="like_a_surgeon-short.mp3"
INDEX_FILE_NAME="welcome.html"

MUSIC_PLAYER_SONG="$SONG_FILE_NAME"
MUSIC_PLAYER="cvlc"
# MUSIC_PLAYER_FLAGS=" --audio --fullscreen --play-and-exit --video-on-top"
MUSIC_PLAYER_FLAGS="--fullscreen --play-and-exit --video-on-top"
MUSIC_PLAYER_LOOP_CMD="--no-loop"
BROWSER_BIN="chromium-browser"
BROWSER_FLAGS="--user-data-dir='./run_time' --disable-web-security "

BROWSER_FULLSCREEN_CMD="--start-fullscreen"
# BROSWER_START_PROGRAM="ecg-line-webcomponent/welcome.html"
BROSWER_START_PROGRAM="index.html"
KILL_CHROMIUM_CMD="pkill -o chromium"
BROWSER_FULLSCREEN=1
IS_LINUX_ENVIRONMENT=1
HAVE_BROWSER_START_PROGRAM=0

VALIDATE_RVAL=0
SKIP_VALIDATION=0
RUN_TIME_DIR="run_time"

echo "program: $0"
PROGRAM_NAME=$(basename -- "$0")

#----------------------------------------------
# THE DISCOVERY POSSIBILITIES
#----------------------------------------------
ERR_UNKNOWN_BROWSWER=1
declare -a browser_possibilities
browser_possibilities+=("google-chrome")
browser_possibilities+=("google-chrome-stable")
browser_possibilities+=("chromium")
browser_possibilities+=("firefox")

#----------------------------------------------
# MESSAGE VARIABLES
#----------------------------------------------
MSG_ERROR=0
MSG_WARNING=1
MSG_INFO=2

#----------------------------------------------
# PROGRAM VARIABLES
#----------------------------------------------

################################################################################
# SPECIFIC FUNCTIONS
################################################################################

#-------------------------------------------------------------------
# check_for_root()
#
# Comments:
#    Verify that the user is running as root
#------------------------------------------------------------------
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
# discovery()
#
# Comments:
#    See what we can discover from the system.
#------------------------------------------------------------------
discovery() {
	for browser in "${browser_possibilities[@]}"; do
		is_verbose "Checking the followoing browser: $browser"
		if ! $(command -V "${browser}") &>/dev/null; then
			is_verbose "Did not find the following browser: $(browser)"
		else
			BROWSER_BIN="$browser"
			is_verbose "Found the following browser: $BROWSER_BIN"
			return
		fi
	done
}

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
# setup_raspberry
#-------------------------------------------------------------------
setup_raspberry() {
	BROWSER_BIN="chromium-browser"
}

display_vars() {
	is_verbose "-------------------------------------------------------------"
	is_verbose "DISCOVERED:"
	is_verbose "-------------------------------------------------------------"
	is_verbose "BROSWER_BIN:                 $BROWSER_BIN"
	is_verbose "-------------------------------------------------------------"
	is_verbose "DATA"
	is_verbose "-------------------------------------------------------------"
	is_verbose "MUSIC_PLAYER:                $MUSIC_PLAYER"
	is_verbose "MUSIC_PLAYER_FLAGS:          $MUSIC_PLAYER_FLAGS"
	is_verbose "MUSIC_PLAYER_LOOP_CMD:       $MUSIC_PLAYER_LOOP_CMD"
	is_verbose "MUSIC_PLAYER_SONG:           $MUSIC_PLAYER_SONG"
	is_verbose "SONG_FILE_NAME:              $SONG_FILE_NAME"
	is_verbose "SONG_FILE_NAME_SHORT:        $SONG_FILE_NAME_SHORT"
	is_verbose "BROWSER_FULLSCREEN_CMD:      $BROWSER_FULLSCREEN_CMD"
	is_verbose "BROSWER_START_PROGRAM:       $BROSWER_START_PROGRAM"
	is_verbose "HAVE_BROWSER_START_PROGRAM:  $HAVE_BROWSER_START_PROGRAM"
	is_verbose "IS_LINUX_ENVIRONMENT:        $IS_LINUX_ENVIRONMENT"
	is_verbose "-------------------------------------------------------------"
	is_verbose "Flags"
	is_verbose "-------------------------------------------------------------"
	is_verbose "IF_USE_BROWSER:              $IF_USE_BROWSER"
	is_verbose "IF_PLAY_SONG:                $IF_PLAY_SONG"
	is_verbose "SKIP_VALIDATION:             $SKIP_VALIDATION"
	is_verbose "-------------------------------------------------------------"
	is_verbose "Standard Options"
	is_verbose "-------------------------------------------------------------"
	is_verbose "IS_VERBOSE_FLAG flag:        $IS_VERBOSE_FLAG"
	is_verbose "IS_PSEUDO_FLAG flag:         $IS_PSEUDO_FLAG"
	is_verbose "-------------------------------------------------------------"
}

#-------------------------------------------------------------------
# help
#-------------------------------------------------------------------
help() {
	echo "PROGRAM"
	echo "   $PROGRAM_NAME"
	echo
	echo "SYNOPSIS"
	echo "   $PROGRAM_NAME"
	echo "                 [-b, --browser BROWSER]"
	echo "                  Note: Currently seclected browser: $(CURRENT_BROWSER)"
	echo "                 [-s, --start HTML FILE]"
	echo "                 [-w, --windows]"
	echo "         flags:"
	echo "                 [-l, -loop]"
	echo "                 [--nobrowser]"
	echo "                 [--nofullscreen]"
	echo "                 [--nosong]"
	echo "                 [-s, --short]"
	echo "                 [--skipval]"
	echo
	echo "        debug:   [-h, --help], [-p, --pseudo], [-v, --verbose]"
	echo "              If no options are given, the program starts a chromium browser"
	echo " and the song. When the song is completed, the browser is closed.  If the song is not"
	echo " started, the browser will not close."
	echo
	echo "DESCRIPTION"
	echo "     $PROGRAM_NAME runs the browser and the song."
	echo
	echo "OPTIONS"
	echo
	echo " -b, --browser BROWSER"
	echo "  Sets the browser command."
	echo
	echo " -s, --start FILE"
	echo "  Calls the starting point, by default is ${BROSWER_START_PROGRAM}."
	echo
	echo " -w, --windows"
	echo "  Keeps all calls within the browser (no external calls to start the music)."
	echo
	echo "FLAGS (turns things off/on)"
	echo
	echo " -l, --loop"
	echo " Loop the song.  The only way to exit is to <Ctrl>-C."
	echo
	echo " --nobrowser"
	echo " The browser will not be run."
	echo
	echo " --nofullscreen"
	echo " The browser will not be set to fullscreen."
	echo
	echo " --nosong"
	echo " The song will not be played, and consequently, the browser will not be shutdown."
	echo
	echo " -r, --raspberry"
	echo " Setup defaults for the raspberry pi"
	echo
	echo " --short"
	echo " Use the short song file."
	echo
	echo "--skipval"
	echo " Skip the validation."
	echo
	echo "DEBUG OPTIONS"
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

	SHORT=b:,l,r,s:,w,h,p,v
	LONG=browser:,loop,nobrowser,nofullscreen,nosong,raspberry,short,skipval,start:,windows,help,pseudo,verbose OPTS=$(getopt --options $SHORT --longoptions $LONG -- "${@}")

	eval set -- "$OPTS"

	while :; do
		case "$1" in
		-b | --browser)
			BROWSER_BIN="$2"
			shift 2
			;;
		-s | --start)
			BROSWER_START_PROGRAM="$2"
			HAVE_BROWSER_START_PROGRAM=1
			shift 2
			;;
		--nobrowser)
			IF_USE_BROWSER=0
			shift 1
			;;
		--nofullscreen)
			BROWSER_FULLSCREEN_CMD=""
			shift 1
			;;
		--nosong)
			IF_PLAY_SONG=0
			shift 1
			;;
		-r | --raspberry)
			setup_raspberry
			shift 1
			;;
		--skipval)
			SKIP_VALIDATION=1
			shift 1
			;;
		-l | --loop)
			MUSIC_PLAYER_LOOP_CMD="--loop"
			shift 1
			;;
		--short)
			MUSIC_PLAYER_SONG="$SONG_FILE_NAME_SHORT"
			shift 1
			;;
		-w | --windows)
			shift 1
			is_verbose "[parse] Setting up for a Windows environment"
			IS_LINUX_ENVIRONMENT=0
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

	display_vars
	return 1

} # parse()

################################################################################
# validate: validate all necessary programms, etc
################################################################################
validate() {
	# The music play is only necessary if we are running on Linux
	if [[ $IS_LINUX_ENVIRONMENT -eq 1 ]]; then
		# VERIFY media player
		if ! command -v $MUSIC_PLAYER &>/dev/null; then
			err_msg $MSG_ERROR "Unable to find music player $MUSIC_PLAYER" 1
		fi
	fi

	# VERIFY browser
	if ! command -v $BROWSER_BIN &>/dev/null; then
		err_msg $MSG_ERROR "Unable to find browser program $BROWSER_BIN" 2
	fi
}

################################################################################
# MAIN
################################################################################
main() {

	discovery
	parse ${@}
	# check_for_root

	# Check to see if we need to load a new start program.
	# If we're running in a Linux or Windows environment, the starts
	# program will automatically be selected; however the user
	# may override this if desired (an that will take precedance).
	if [[ $HAVE_BROWSER_START_PROGRAM -eq 1 ]]; then
		if [[ $IS_LINUX_ENVIRONMENT -eq 0 ]]; then
			is_verbose "[new_start_program] Setting new start program"
			cd $RUN_TIME_DIR
			is_verbose "$PWD"
			BROSWER_START_PROGRAM="welcome.html"
			display_vars
		fi
	fi

	# Validate or not?
	if [[ $SKIP_VALIDATION -eq 0 ]]; then
		validate
		if [[ $VALIDATE_RVAL -ne 0 ]]; then
			echo "Validation failed"
			exit
		fi
	fi

	# Start the browsser in the backbround
	if [[ $IF_USE_BROWSER -eq 1 ]]; then
		is_verbose "[if browser is used] starting the program"
		cmd="$BROWSER_BIN $BROWSER_FULLSCREEN_CMD $BROWSER_FLAGS $BROSWER_START_PROGRAM "
		do_cmd "${cmd} &"
		# $BROWSER_BIN $BROWSER_FULLSCREEN_CMD $BROSWER_START_PROGRAM &
	fi

	if [[ $IS_LINUX_ENVIRONMENT -eq 1 ]]; then
		# Start the song (short or standard)
		if [[ $IF_PLAY_SONG -eq 1 ]]; then
			($MUSIC_PLAYER $MUSIC_PLAYER_FLAGS $MUSIC_PLAYER_SONG $MUSIC_PLAYER_LOOP_CMD)
			is_verbose "Music player exited"
			is_verbose "Checking if browser was used, to determine if we should kill"
			# After the muisc is done, if we have started the browser, kill it.
			if [[ $IF_USE_BROWSER -eq 1 ]]; then
				is_verbose "Killing browser"
				do_cmd "$KILL_CHROMIUM_CMD"
			fi
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
