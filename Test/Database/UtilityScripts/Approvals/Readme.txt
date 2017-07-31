This folder contains a number of scripts that can be used to:
 - check and correct approval statuses
 - generate summary data for past approvals
 - unapprove in bulk
 
General:
 - before running a script, please read the comments at the top of the script and adjust any control variables (month selections etc)
 
 The scripts are as follows:
 
 0. ApprovalUtilityScript
 ------------------------
 This script should be used in preference over all others because it takes into account the dynamic location hierarchy.
 This script can:
  - output a list of details about required approvals
  - output a list of required approvals for which there is no matching actual approval (missing approvals)
  - output a list of details about actual approvals
  - unapprove actual approvals
  - approve missing approvals
 
 1. DetermineApprovalStatus
 --------------------------
 This script serves these purposes:
  - it can be used to produce a list of missing approval data
  - it can be used to produce a list of required approvals and their status
  - it can be used to store a list of missing approval data in a temporary table which can then be used by the "AutoApproveMissingApprovals.sql" script
 
 The variables at the top of the script should be used to control the time range the script will operate on.
 A flag called @outputMissingApprovalsOnly can be used to limit the results to missing approvals only, otherwise data requiring approval that is already approved will also be output (see IsApproved column)
 A flag called @removeTemporaryTableAfterScriptRun is used to specify whether the script should leave it's results in place or not
  - Note @removeTemporaryTableAfterScriptRun must be set to 0 if you want to subsequently run the "AutoApproveMissingApprovals.sql" script
  
 Note: This script does NOT output superfluous approvals (ie data that is approved that didn't need to be... it is more focused on missing rather than unneccessary approvals)
 
 2. AutoApproveMissingApprovals
 ------------------------------

This script will run through the set of missing approvals found using the DetermineApprovalStatus script described above and Auto-Approve them.

It is neccessary to specify the username of the user that the approvals should appear to have been made by.

Note: The DetermineApprovalStatus script must have been run first with the @removeTemporaryTableAfterScriptRun flag set to 0
Note: Because this script shares a connection based temporary table with DetermineApprovalStatus both should be run under the same connection

 
 3. SummariseHistoryForApprovals
 -------------------------------
 
 This script can be used to regenerate summary date for previously made approvals.
 
 In the enhanced system summary data is generated as the user makes approvals.  However when the archiving version is deployed there will already be many approvals in place.  This script
 can be used to get the data into a state where the summary data present is consistant with approvals made to date.
 
 Please adjust the date filter as appropriate prior to running the script
 
 
 --------------------------------------------------------------------------------
 
  4. Unnaprove.sql
 -------------------------------
 
 This script can be used to unapprove, approvals already made based on the contents of the #BhpbioTemporaryApprovalStatus temporary table...
 
 To populate the #BhpbioTemporaryApprovalStatus table, first use the DetermineApprovalStatus.sql script as described in 1.
 
 Note:  This approach has a flaw in that, the DetermineApprovalStatus script only produces output for rows that require approval...  it is possilbe that blastblocks are approved, but later don't require approval due to data changes
 .. it is possible that some unapprovals could be missed in certain data scenarios...   after the unapproval, check the contents of BhpbioApprovalData.
  
 --------------------------------------------------------------------------------
 
 

 
 