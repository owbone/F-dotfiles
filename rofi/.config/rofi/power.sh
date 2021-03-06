#!/usr/bin/env bash

# This script defines just a mode for rofi instead of being a self-contained
# executable that launches rofi by itself. This makes it more flexible than
# running rofi inside this script as now the user can call rofi as one pleases.
# For instance:
#
#   rofi -show powermenu -modi powermenu:./rofi-power-menu
#
# See README.md for more information.

lockscreen="Lock screen"
switchuser="Switch user"
logout="Log out"
suspend="Suspend"
hibernate="Hibernate"
reboot="Reboot"
shutdown="Shut down"

lockscreenConfirmation="Yes, lock screen"
switchuserConfirmation="Yes, switch user"
logoutConfirmation="Yes, log out"
suspendConfirmation="Yes, suspend"
hibernateConfirmation="Yes, hibernate"
rebootConfirmation="Yes, reboot"
shutdownConfirmation="Yes, shut down"
cancel="No, cancel"

# Default options
show="$shutdown\n$reboot\n$suspend\n$hibernate\n$logout\n$lockscreen\n"
dryrun=false
# By default, ask for confirmation for actions that are irreversible
confirmLockscreen=false
confirmSwitchuser=false
confirmLogout=true
confirmSuspend=false
confirmHibernate=false
confirmReboot=true
confirmShutdown=true

# Parse command-line options
parsed=$(getopt --options=h --longoptions=help,dry-run,confirm:,choices:,choose: --name "$0" -- "$@")
if [ $? -ne 0 ]; then
    echo 'Terminating...' >&2
    exit 1
fi
eval set -- "$parsed"
unset parsed
while true; do
    case "$1" in
        "-h"|"--help")
            echo "rofi-power-menu - a power menu mode for Rofi"
            echo
            echo "Usage: rofi-power-menu [--choices CHOICES] [--confirm CHOICES]"
            echo "                       [--choose CHOICE] [--dry-run]"
            echo
            echo "Use with Rofi in script mode. For instance, to ask for shutdown or reboot:"
            echo
            echo "  rofi -show menu -modi \"menu:rofi-power-menu --choices=shutdown/reboot\""
            echo
            echo "Available options:"
            echo "  --dry-run          Don't perform the selected action but print it to stderr."
            echo "  --choices CHOICES  Show only the selected choices in the given order. Use / "
            echo "                     as the separator. Available choices are lockscreen, logout,"
            echo "                     suspend, hibernate, reboot and shutdown. By default, all"
            echo "                     available choices are shown."
            echo "  --confirm CHOICES  Require confirmation for the gives choices only. Use / as"
            echo "                     the separator. Available choices are lockscreen, logout,"
            echo "                     suspend, hibernate, reboot and shutdown. By default, only"
            echo "                     irreversible actions logout, reboot and shutdown require"
            echo "                     confirmation."
            echo "  --choose CHOICE    Preselect the given choice and only ask for a confirmation"
            echo "                     (if confirmation is set to be requested). It is strongly"
            echo "                     recommended to combine this option with --confirm=CHOICE"
            echo "                     if the choice wouldn't require confirmation by default."
            echo "                     Available choices are lockscreen, logout, suspend,"
            echo "                     hibernate, reboot and shutdown."
            echo "  -h,--help          Show this help text."
            exit 0
            ;;
        "--dry-run")
            dryrun=true
            shift 1
            continue
            ;;
        "--confirm")
            confirmLockscreen=false
            confirmSwitchuser=false
            confirmLogout=false
            confirmSuspend=false
            confirmHibernate=false
            confirmReboot=false
            confirmShutdown=false
            IFS='/' read -ra choices <<< "$2"
            for choice in "${choices[@]}"; do
                case $choice in
                    "lockscreen")
                        confirLockscreen=true ;;
                    "logout")
                        confirmLogout=true ;;
                    "suspend")
                        confirmSuspend=true ;;
                    "hibernate")
                        confirmHibernate=true ;;
                    "reboot")
                        confirmReboot=true ;;
                    "shutdown")
                        confirmShutdown=true ;;
                    *)
                        echo "Invalid choice in --confirm: $choice" >&2
                        exit 1
                        ;;
                esac
            done
            shift 2
            continue
            ;;
        "--choices")
            IFS='/' read -ra choices <<< "$2"
            show=""
            for choice in "${choices[@]}"; do
                case $choice in
                    "lockscreen")
                        show="$show$lockscreen\n" ;;
                    "logout")
                        show="$show$logout\n" ;;
                    "suspend")
                        show="$show$suspend\n" ;;
                    "hibernate")
                        show="$show$hibernate\n" ;;
                    "reboot")
                        show="$show$reboot\n" ;;
                    "shutdown")
                        show="$show$shutdown\n" ;;
                    *)
                        echo "Invalid choice in --choices: $choice" >&2
                        exit 1
                        ;;
                esac
            done
            shift 2
            continue
            ;;
        "--choose")
            case $2 in
                "lockscreen")
                    selection=$lockscreen ;;
                "logout")
                    selection=$logout ;;
                "suspend")
                    selection=$suspend ;;
                "hibernate")
                    selection=$hibernate ;;
                "reboot")
                    selection=$reboot ;;
                "shutdown")
                    selection=$shutdown ;;
                *)
                    echo "Invalid choice in --choose: $2" >&2
                    exit 1
                    ;;
            esac
            shift 2
            continue
            ;;
        "--")
            shift
            break
            ;;
        *)
            echo "Internal error" >&2
            exit 1
            ;;
    esac
done

selection=${@:-$selection}
if [ -z "$selection" ]
then
    printf "$show"
else
    case $selection in
        $lockscreen)
            if [ $confirmLockscreen = true ]
            then
                echo $lockscreenConfirmation
                echo $cancel
                exit 0
            fi
            ;&
        $lockscreenConfirmation)
            if [ $dryrun = true ]
            then
                echo "Locking screen.." >&2
            else
                loginctl lock-session $XDG_SESSION_ID &> /dev/null
            fi
            ;;
        $switchuser)
            # TODO: I suppose this is window manager dependent?
            echo "User switching not implemented yet" >&2
            ;;
        $logout)
            if [ $confirmLogout = true ]
            then
                echo $logoutConfirmation
                echo $cancel
                exit 0
            fi
            ;&
        $logoutConfirmation)
            if [ $dryrun = true ]
            then
                echo "Logging out.." >&2
            else
                loginctl terminate-session $XDG_SESSION_ID &> /dev/null
            fi
            ;;
        $suspend)
            if [ $confirmSuspend = true ]
            then
                echo $suspendConfirmation
                echo $cancel
                exit 0
            fi
            ;&
        $suspendConfirmation)
            if [ $dryrun = true ]
            then
                echo "Suspending.." >&2
            else
                systemctl suspend &> /dev/null
            fi
            ;;
        $hibernate)
            if [ $confirmHibernate = true ]
            then
                echo $hibernateConfirmation
                echo $cancel
                exit 0
            fi
            ;&
        $hibernateConfirmation)
            if [ $dryrun = true ]
            then
                echo "Hibernating.." >&2
            else
                systemctl hibernate &> /dev/null
            fi
            ;;
        $reboot)
            if [ $confirmReboot = true ]
            then
                echo $rebootConfirmation
                echo $cancel
                exit 0
            fi
            ;&  # resume to the next case
        $rebootConfirmation)
            if [ $dryrun = true ]
            then
                echo "Rebooting.." >&2
            else
                systemctl reboot &> /dev/null
            fi
            ;;
        $shutdown)
            if [ $confirmShutdown = true ]
            then
                echo $shutdownConfirmation
                echo $cancel
                exit 0
            fi
            ;&
        $shutdownConfirmation)
            if [ $dryrun = true ]
            then
                echo "Shutting down.." >&2
            else
                systemctl poweroff &> /dev/null
            fi
            ;;
        $cancel)
            exit 0
            ;;
        *)
            >&2 echo "Invalid selection: $selection"
            exit 1
            ;;
    esac
fi

