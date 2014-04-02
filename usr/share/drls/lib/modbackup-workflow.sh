# modbackup-workflow.sh
#
# modbackup workflow for Disaster Recovery Linux Server
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

WORKFLOW_modbackup_DESCRIPTION="change backup properties"
WORKFLOWS=( ${WORKFLOWS[@]} modbackup )
LOCKLESS_WORKFLOWS=( ${LOCKLESS_WORKFLOWS[@]} modbackup )

#if [ "$WORKFLOW" == "modbackup" ]; then 
    echo "" > /dev/null
#fi

WORKFLOW_modbackup () {
#    echo modbackup workflow
    SourceStage "backup/mod"
}

#1	Search backup in database
#2	change backup properties (or delete and add)
#3	...
