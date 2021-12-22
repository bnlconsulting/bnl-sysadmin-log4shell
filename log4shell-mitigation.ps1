#SAS Foundation log4shell mitigation script
#Executes SAS Foundation specific steps as noted by the SAS Documentation
# SAS Documentation: https://go.documentation.sas.com/doc/en/log4j/1.0/p1gaeukqxgohkin1uho5gh7v5s7p.htm
# Created: 12/20/2021
# by: Lee Wiscovitch

# Adjust the following variables to match your environment
#Set Global varaibles for SASHome and SAS Config
#The SASConfig directory should be the directory that contains Lev# Folders 
$sas_foundation_sashome="D:\SASHome"
$sas_foundation_sasconfig="D:\SAS\BIserver"

# Location of 7za.exe
$7za=".\7za.exe"

######
#DO NOT EDIT BELOW THIS LINE
######

#Set wrapper syntax
$wrapper="wrapper.java.additional"

#Set $log4shell_formatMsgNoLookups
$log4shell_formatMsgNoLookups = "-Dlog4j2.formatMsgNoLookups=true"

#Set Date for backup files
$current_date="$(get-date -f yyyy-dd-MM_HH-mm)_log4shellfix"

# This function will find and loop log4j jar files and remove the JndiLookup.class
function fix_log4j_jars {
    param(
    [Parameter (Mandatory = $true)] [String]$path
    )

    #find all jar files and store in variable
    $jars = @(
        get-childitem -path $path -Include log4j-core-2*.jar -File -Recurse -ErrorAction SilentlyContinue
    )

    #loop through matches
    foreach ($jar in $jars)
    {
        #log activity
        write-host "Found $jar"

        #delete "org/apache/logging/log4j/core/lookup/JndiLookup.class" from jar
        $command = "$7za d '$jar' 'org/apache/logging/log4j/core/lookup/JndiLookup.class' -r"
        invoke-expression $command
    }
}

# This function will find and loop setenv.bat files and add the log4j2.formatMsgNoLookups parameter
# This step is primarily for SAS Studio deployments
function fix_tomcat_setenv {
    param(
    [Parameter (Mandatory = $true)] [String]$path
    )

    #find all setenv.bat files and store in variable
    $setenv_files = @(
        get-childitem -path "$path\Lev*\Web\WebAppServer\SASServer*\bin\*" -Include "setenv.bat" -File -Recurse -ErrorAction SilentlyContinue
    )

    #loop through matches
    foreach ($setenv_file in $setenv_files)
    {
        #look for "formatMsgNoLookups" in setenv.bat, variable will be either "True" (match found) or "False" (no match found)
        write-host "Found $setenv_file `n------"
        $setenv_check=select-string -path $setenv_file -quiet -pattern $log4shell_formatMsgNoLookups

        if($setenv_check){
            write-host "formatMsgNoLookups is already set"
        }else{
            write-host "log4j2.formatMsgNoLookups not set, adding variable to JVM_OPTS"

            #backup original file
            write-host "backing up file to $setenv_file.$current_date"
            copy-item $setenv_file -Destination "$setenv_file.$current_date"

            #find JVM_OPTS line
            $jvm_opts_original = get-content $setenv_file | select-string -pattern '^set JVM_OPTS=' | Out-String -Stream

            #append "log4j2.formatMsgNoLookups" to JVM_OPTS
            $jvm_opts_updated = $jvm_opts_original + " $log4shell_formatMsgNoLookups"

            #save updated JVM_OPTS back to file, along with some whitespace management
            $jvm_opts_trim = $jvm_opts_updated
            (Get-Content $setenv_file) -replace '^set JVM_OPTS=.*', $jvm_opts_trim | Set-Content $setenv_file
            (Get-Content $setenv_file) -replace ' set', 'set' | Set-Content $setenv_file
            (Get-Content $setenv_file) -replace '   ', ' ' | Set-Content $setenv_file
            (Get-Content $setenv_file) -replace '  ', ' ' | Set-Content $setenv_file
        }

        write-host "------"
    }
}

# This function will find and loop wrapper.conf files and add the log4j2.formatMsgNoLookups parameter
# This step is primarily for SAS Environment Manager Agent and Server
function fix_envmgr_wrapper {
    param(
    [Parameter (Mandatory = $true)] [String]$path
    )

    #find all wrapper.conf files and store in variable
    $wrapper_files = @(
        get-childitem -path "$path\Lev*\Web\SASEnvironmentManager\server-*\conf\*","$path\Lev*\Web\SASEnvironmentManager\agent-*\bundles\agent-*\conf\*","$path\Lev*\Web\WebAppServer\SASServer*\conf\*" -Include "wrapper.conf" -File -Recurse -ErrorAction SilentlyContinue
    )

    #loop through matches
    foreach ($wrapper_file in $wrapper_files)
    {       

        #look for "formatMsgNoLookups" in wrapper.conf, variable will be either "True" (match found) or "False" (no match found)
        write-host "Found $wrapper_file `n------"
        $wrapper_check=select-string -path $wrapper_file -quiet -pattern $log4shell_formatMsgNoLookups

        if($wrapper_check){
            write-host "log4j2.formatMsgNoLookups is already set"
        }else{
            write-host "log4j2.formatMsgNoLookups not set, adding variable to wrapper.conf as wrapper.java.additional.n+1"

            #backup original file
            write-host "backing up file to $wrapper_file.$current_date"
            copy-item $wrapper_file -Destination "$wrapper_file.$current_date"

            #find last "wrapper.java.additional" entry in file
            $wrapper_original = get-content $wrapper_file | select-string -pattern "^$wrapper" | select-object -last 1

            #get just the number after "wrapper.java.additional", accounting for single digit results
            $last_entry=$wrapper_original.line.Substring(24,2)
            $last_entry=$last_entry -replace "[^0-9]"
            $max=[int]$last_entry

            #new entry which is 1 more than $max
            $new=[int]$max[0] + 1
            
            #format entire new entry line
            $new_entry="$wrapper.$new=$log4shell_formatMsgNoLookups"

            #write updated file
            (Get-Content $wrapper_file) -replace $wrapper_original, "$wrapper_original`n$new_entry" | Set-Content $wrapper_file
        }

        write-host "------"
    }
}

# This function will find and loop hq-server files and add the log4j2.formatMsgNoLookups parameter
function fix_envmgr_hqserver {
    param(
    [Parameter (Mandatory = $true)] [String]$path
    )

    #find all hq-server.conf files and store in variable
    $hq_files = @(
        get-childitem -path "$path\Lev*\Web\SASEnvironmentManager\server-*\conf\*" -Include "hq-server.conf" -File -Recurse -ErrorAction SilentlyContinue
    )

    #loop through matches
    foreach ($hq_file in $hq_files)
    {
        #look for "formatMsgNoLookups" in hq-server.conf, variable will be either "True" (match found) or "False" (no match found)
        write-host "Found $hq_file `n------"
        $hq_check=select-string -path $hq_file -quiet -pattern $log4shell_formatMsgNoLookups

        if($hq_check){
            write-host "formatMsgNoLookups is already set"
        }else{
            write-host "log4j2.formatMsgNoLookups not set, adding variable to server.java.opts"

            #backup original file
            write-host "backing up file to $hq_file.$current_date"
            copy-item $hq_file -Destination "$hq_file.$current_date"

            #find server.java.opts line
            $hq_original = get-content $hq_file | select-string -pattern '^server.java.opts' | Out-String -Stream

            #append "log4j2.formatMsgNoLookups" to server.java.opts
            $hq_updated = $hq_original + " $log4shell_formatMsgNoLookups"

            #save updated server.java.opts back to file, along with some whitespace management
            $hq_trim = $hq_updated
            (Get-Content $hq_file) -replace '^server.java.opts.*', $hq_trim | Set-Content $hq_file
            (Get-Content $hq_file) -replace ' server.java.opts', 'server.java.opts' | Set-Content $hq_file
            (Get-Content $hq_file) -replace '   ', ' ' | Set-Content $hq_file
            (Get-Content $hq_file) -replace '  ', ' ' | Set-Content $hq_file
        }

        write-host "------"
    }
}

function check-permissions {
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object System.Security.Principal.WindowsPrincipal($id)
    if($p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)){
        write-host "******"
    }else{
        write-host "******"
        write-host "You must run this script as administrator...Exiting script!"
        write-host "******"
        exit
    }   
}

#check if script is running as administrator
check-permissions

write-host ""
write-host "******"
write-host "SAS log4shell Mitigation Processing"
write-host "******"
write-host "If either of these settings are wrong, cancel and update the variables at the top of this script "
write-host "SASHome Directory is set to $sas_foundation_sashome"
write-host "SASConfig Directory is set to $sas_foundation_sasconfig"

write-host ""
write-host "Please be sure to stop all SAS related Windows Services before continuing."
write-host "Also make sure the 7za.exe is in the same folder as this script, or update the location in the script at the top!"
write-host ""
Read-Host -Prompt "Do you wish to continue this process? Press any key to continue or CTRL+C to quit" 

write-host "Checking for log4j jars in $sas_foundation_sashome"
write-host "*******"

fix_log4j_jars -path $sas_foundation_sashome

write-host "*******"
write-host "Checking for log4j jars in $sas_foundation_sasconfig"
write-host "*******"

fix_log4j_jars -path $sas_foundation_sasconfig

write-host "*******"
write-host "Updating log4j2.formatMsgNoLookups in Tomcat setenv files"
write-host "*******"

fix_tomcat_setenv -path $sas_foundation_sasconfig

write-host "*******"
write-host "Updating log4j2.formatMsgNoLookups in SAS Environment Manager wrapper.conf files"
write-host "*******"
fix_envmgr_wrapper -path $sas_foundation_sasconfig

write-host "*******"
write-host "Updating log4j2.formatMsgNoLookups in SAS Environment Manager hq-server.conf files"
write-host "*******"
fix_envmgr_hqserver -path $sas_foundation_sasconfig