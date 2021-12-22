# bnl-sysadmin-log4shell
information and scripts related to log4shell detection and mitigation

* Created: 12/22/2021
* Created by: Lee Wiscovitch

The log4shell-mitigation.ps1 script will follow the instructions provided by SAS to mitigate the Log4Shell vulnerabilities on SAS Systems.

[SAS Log4Shell Mitigation Steps](https://go.documentation.sas.com/doc/en/log4j/1.0/p1gaeukqxgohkin1uho5gh7v5s7p.htm)

This process will update jar files in place and will update and backup configuration files.

Backup files will have the date and time appended to the end.

Example: `D:\SAS\BIserver\Lev1\Web\WebAppServer\SASServer1_1\bin\setenv.bat.2021-21-12_21-13_log4shellfix`

## Updates
* 12/21/2021
  * Updated steps to reflect 2.X specific versions
  * Added confirmation for run against current configured directories

## Configuration
Inside the script the two following variables need to be updated.

* `$sas_foundation_sashome`
  * This is the SASHome installation directory
  * Default Value: `D:\SASHome`
* `$sas_foundation_sasconfig`
  * This is the SASConfig directory that contains Lev# folders
  * Default Value: `D:\SAS\BIserver`

You must download and extract `7za.exe` from the `7-Zip Extra` archive from the 7-zip.org [download](https://www.7-zip.org/download.html) page. The `7za.exe` needs to be in the same directory as the `log4shell-mitigation.ps1` script, or you will need to edit the `$7za` variable in the script to point to the correct location.

## Running the Script

Safely shutdown all SAS services, if you don't then the script will not able to edit any of the jar files.

>You must execute the script "As Administrator", if not it will alert you and end without performing any mitigation tasks!

Open a terminal and change to the directory where the script was downloaded and run the script:

```shell
log4shell-mitigation.ps1
```

## Known Issues
None at the moment