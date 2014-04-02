# delbackup-workflow.sh
#
# delbackup workflow for Disaster Recovery Linux Server
#
#    Disaster Recovery Linux Server is free software; you can redistribute it 
#    and/or modify it under the terms of the GNU General Public License as 
#    published by the Free Software Foundation; either version 2 of the 
#    License, or (at your option) any later version.

#    Disaster Recovery Linux Server is distributed in the hope that it will be
#    useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with Disaster Recovery Linux Server; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#
#

WORKFLOW_delbackup_DESCRIPTION="delete client backup and unregister from database"
WORKFLOWS=( ${WORKFLOWS[@]} delbackup )
LOCKLESS_WORKFLOWS=( ${LOCKLESS_WORKFLOWS[@]} delbackup )

#if [ "$WORKFLOW" == "delbackup" ]; then 
	# Parse options
	OPT="$(getopt -n $WORKFLOW -o "I:c:Ah" -l "id:,client:,all,help" -- "$@")"
	if (( $? != 0 )); then
			echo "Try \`$PROGRAM $WORKFLOW --help' for more information."
			exit 1
	fi
	
	eval set -- "$OPT"
	while true; do
		case "$1" in
		(-c|--client)
				# We need to take the option argument
				if [ -n "$2" ]; then 
					CLI_NAME="$2"
				else
					echo "$PROGRAM $WORKFLOW - $1 needs a valid argument"	
					exit 1
				fi
				shift 
				;;
		(-I|--id)
				# We need to take the option argument
				if [ -n "$2" ]; then 
					BKP_ID="$2"
				else
					echo "$PROGRAM $WORKFLOW - $1 needs a valid argument"	
					exit 1
				fi
				shift 
				;;
		(-A|--all)
				CLEAN_ALL="yes" 
				;;
		(-h|--help)
				delbackuphelp 
				exit 0
				;;
		(--) shift; break;;
		(-*)
				echo "$PROGRAM $WORKFLOW: unrecognized option '$option'"
				echo "Try \`$PROGRAM $WORKFLOW --help' for more information."
				exit 1
				;;
		esac
		shift
	done
#fi

        if [ -n "$BKP_ID" ] && [ -n "$CLEAN_ALL" ]; then
                echo "$PROGRAM $WORKFLOW: Only one option can be used: [ -A|--all ] or [ -I|--id ]"
                echo "Try \`$PROGRAM $WORKFLOW --help' for more information."
                exit 1
        fi
        
        if [ -n "$CLEAN_ALL" ]; then
        	if [ -z "$CLI_NAME" ];then
        		echo "$PROGRAM $WORKFLOW: Client name is required: [ -A|--all ] and [ -c|--client ]"
                echo "Try \`$PROGRAM $WORKFLOW --help' for more information."
                exit 1
            fi
        fi

WORKFLOW_delbackup () {
    #echo delbackup workflow
    SourceStage "backup/del"
}
