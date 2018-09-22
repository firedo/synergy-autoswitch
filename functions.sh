#!/bin/bash

function checkIfRunningAtTheSameTime {
	LOCKFILE="/tmp/$(basename ${0}).${username}.lock"
	if [ -e ${LOCKFILE} ] && kill -0 `cat ${LOCKFILE}` 2>/dev/null; then
		echo "ERROR: This script is already running at the same time! Exiting..."
		exit 1
	fi
	# make sure the lockfile is removed when we exit and then claim it
	trap "rm -f ${LOCKFILE}; exit" INT TERM EXIT
	echo $$ > ${LOCKFILE}
}

function killallSynergy {
	# Kill existing Synergy processes (force or wait for 10s)
	# Send kill signals first
	killall --quiet synergys
	killall --quiet synergyc
	killall --quiet synergy
	# Wait 30s for them to be killed (per process type)
	timeout 30s killall --wait --quiet -0 synergys
	timeout 30s killall --wait --quiet -0 synergyc
	timeout 30s killall --wait --quiet -0 synergy
	# Send SIGKILL signals 2nd
	killall --quiet -9 synergys
	killall --quiet -9 synergyc
	killall --quiet -9 synergy
	# Wait 30s for them to be killed (per process type)
	timeout 30s killall --wait --quiet -0 synergys
	timeout 30s killall --wait --quiet -0 synergyc
	timeout 30s killall --wait --quiet -0 synergy
}

function XuserLoggedIn {
	for session in $(loginctl list-sessions 2>/dev/null | awk '{print $1}' | grep -v -e 'SESSION' -e '^$'); do
		class=$(loginctl show-session ${session} --property=Class 2>/dev/null)
		type=$(loginctl show-session ${session} --property=Type 2>/dev/null)
		active=$(loginctl show-session ${session} --property=Active 2>/dev/null)
		remote=$(loginctl show-session ${session} --property=Remote 2>/dev/null)
		#if [[ $class == "Class=user" && $type == "Type=x11" && $remote == "Remote=no" ]]; then
		if [[ $class == "Class=user" && $type == "Type=x11" && $active == "Active=yes" && $remote == "Remote=no" ]]; then
			return 0
		fi
	done
	return 1
}

function getGreeterUsername {
	for session in $(loginctl list-sessions 2>/dev/null | awk '{print $1}' | grep -v -e 'SESSION' -e '^$'); do
		class=$(loginctl show-session ${session} --property=Class 2>/dev/null)
		type=$(loginctl show-session ${session} --property=Type 2>/dev/null)
		active=$(loginctl show-session ${session} --property=Active 2>/dev/null)
		remote=$(loginctl show-session ${session} --property=Remote 2>/dev/null)
		if [[ $class == "Class=greeter" && $type == "Type=x11" && $remote == "Remote=no" ]]; then
			if [[ $1 == "id" ]]; then
				echo $(loginctl show-session ${session} --property=User 2>/dev/null | sed 's/User=//' 2>/dev/null)
			else
				echo $(loginctl show-session ${session} --property=Name 2>/dev/null | sed 's/Name=//' 2>/dev/null)
			fi
			return 0
		fi
	done

	echo "ERROR: Unable to find the 'greeter' sessions username! Exiting... (check function 'getGreeterUsername')"
	exit 1
}

# Kill other instances of this script (for stopping already running loop)
function killOtherInstances {
	# Get PIDs of other instances of this script runnin as current user ($$ => exclude this script)
	otherPIDs=$(grep -vxf <(echo $$) <(pgrep -u ${username} -f "${0}"))

	# Check if any instances are running still (there's always a 'ghost' process created by the above $otherPIDs subshell)
	if $(kill -0 ${otherPIDs} 2>/dev/null); then
		echo "Killing other instances of this script..."
		for otherPID in ${otherPIDs}; do
			if [[ $otherPID -ne $$ ]]; then
				kill ${otherPID} 2>/dev/null
			fi
		done

		for otherPID in ${otherPIDs}; do
			if [[ $otherPID -ne $$ ]]; then
				# Wait 30 secs for the processes to end
				count=0
				countMax=300
				while $(kill -0 ${otherPID} 2>/dev/null); do
					((count++))
					if [[ $count -gt $countMax ]]; then
						# Ssen
						echo "Normal kill failed, trying SIGKILL (9) (PID ${otherPID})..."
						kill -9 ${otherPID}
						# Wait 30 secs for the processes to end
						count=0
						countMax=300
						while $(kill -0 ${otherPID} 2>/dev/null); do
							((count++))
							if [[ $count -gt $countMax ]]; then
								echo "WARNING: SIGKILL (force) timed out!"
								break
							fi
							sleep 0.1
						done
						echo "Done"
						break
					fi
					sleep 0.1
				done
			fi
		done
		echo "Done."
	else
		echo "No other instances of this script running."
	fi
}
