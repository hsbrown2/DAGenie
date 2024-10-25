# Distributed-Application.Genie
## SYNOPSIS
This script will Management Packs containing Distributed Applications based on a simple .xml input file.

## SYNTAX
```powershell
Distributed-Application.Genie [-SCOMConnection] <String> [-InputFolder] <String> [-OutputFolder] <String> [-KeyFile] <String> [<CommonParameters>]
```

## DESCRIPTION
Using this script, you are able to generate a Distributed Application based on a set of criteria defined in .xml manifest (precept requires a file in the correct format with the prefix name "DAManifest"). This file has some pre-defined types of objects:

--Application - an application class defined in a management pack using the LocalApplication class as a base

--Web Sites - IIS Web Sites

--Databases - SQL Server Databases

--URL Monitors - Very specifc to the required URL Genie Managment Pack (https://monitoringguys.com/2015/05/04/urlgenie-management-pack-for-scom-an-easy-powerful-solution-for-bulk-website-monitoring/)

--AvailabilityGroups - SQL Server Availability Groups

-- Distributed-Application.Genie.ps1 also supports any valid class defined as any Type you wish. Type will be use to populate Display Names for the objects you choose to include in your Distributed Application.

Additionally, custom icons can be added to the Application Type. If configured to use custom icons, Distributed-Application.Genie.ps1 
will then bundle the resulting .mp file into an .mpb, with the icons you desire included.

## PARAMETERS
### -SCOMConnection &lt;String&gt;

```
Required?                    true
Position?                    1
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -InputFolder &lt;String&gt;

```
Required?                    true
Position?                    2
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -OutputFolder &lt;String&gt;

```
Required?                    true
Position?                    3
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -KeyFile &lt;String&gt;

```
Required?                    true
Position?                    4
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```

## INPUTS


## OUTPUTS


## NOTES
File Name  : Distributed-Application.Genie.ps1
Author     : Scott Brown

## EXAMPLES
### EXAMPLE 1
```powershell
.\Distributed-Application.Genie.ps1 -SCOMConnection <MANAGEMENT SERVER> -InputFolder C:\TEMP2\DistributedApplications -OutputFolder C:\DA -KeyFile 'Path to my .snk file'

Generate a Distributed Application Managment Pack for all DAManifest* files in -InputFolder, and place the resulting files in -OutputFolder
```


