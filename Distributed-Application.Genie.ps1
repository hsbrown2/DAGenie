<#
    .SYNOPSIS
        This script will Management Packs containing Distributed Applications based on a simple .xml input file.

    .DESCRIPTION
        Using this script, you are able to generate a Distributed Application based on a set of criteria defined in .xml manifest (precept requires a file in the correct
        format with the prefix name "DAManifest"). This file has some pre-defined types of objects:
        --Application - an application class defined in a management pack using the LocalApplication class as a base
        --Web Sites - IIS Web Sites
        --Databases - SQL Server Databases
        --URL Monitors - Very specifc to the required URL Genie Managment Pack (https://monitoringguys.com/2015/05/04/urlgenie-management-pack-for-scom-an-easy-powerful-solution-for-bulk-website-monitoring/)
        --AvailabilityGroups - SQL Server Availability Groups
        -- Distributed-Application.Genie.ps1 also supports any valid class defined as any Type you wish. Type will be use to populate Display Names for the objects you choose to include in your
           Distributed Application
        Additionally, custom icons can be added to the Application Type. If configured to use custom icons, Distributed-Application.Genie.ps1 
        will then bundle the resulting .mp file into an .mpb, with the icons you desire included.
    
    .PARAMETER -ScomServer : String. Name of the Management Server to query for the information on the SCOM infrastructure.
    .PARAMETER     -InputFolder : String. The location of one or more DAManifest* files.
    .PARAMETER    -OutputFolder : String. The location to which you want the completed Distributed Application(s) to be saved.
    .PARAMETER    -KeyFile : String. The location of the key file to seal the resulting Managment Pack.

    .NOTES
        File Name  : Distributed-Application.Genie.ps1
        Author     : Scott Brown
 
    .LINK
        

    .EXAMPLE
        .\Distributed-Application.Genie.ps1 -SCOMConnection <MANAGEMENT SERVER> -InputFolder C:\TEMP2\DistributedApplications -OutputFolder C:\DA -KeyFile 'Pathy to my .snk file'
        Generate a Distributed Application Managment Pack for all DAManifest* files in -InputFolder, and place the resulting files in -OutputFolder

    .COMPONENT 
        Distributed-Application.Genie.ps1 requires the following:
        --Distributed.Applications.Services.Collections.Library.mp installed in the Managment Group
        --(optional) URL.Genie.Image.Library.mp contains custom images for URL Genie HTTP Seed Requests
        --.\MPSeal\FastSeal.exe - used to seal the final resultant MP. This can be found on the SCOM installation media.
        --.\MPSeal\MPBUtil.exe - used to generate an .mpb file when custom images are used.

#>
[CmdletBinding()]
PARAM
(
	[Parameter(Mandatory=$true,HelpMessage='Please enter the FQDN of the SCOM Management Server to use')][Alias('SCOMConnection')][String]$ScomServer,
	[Parameter(Mandatory=$true,HelpMessage='Please enter the input folder location')][Alias('InputFolder')][String]$ManifestLocation,
	[Parameter(Mandatory=$true,HelpMessage='Please enter the output folder location (subfolder will be automatically created for you')][Alias('OutputFolder')][String]$OutParent,
	[Parameter(Mandatory=$true,HelpMessage='Please enter the keyfile location to seal this MP and MP Bundle (if applicable)')][Alias('KeyFile')][String]$snk
)


$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
Set-Location $scriptPath

Import-Module OperationsManager
New-SCOMManagementGroupConnection -ComputerName $ScomServer


$manloc = [io.path]::combine("$ManifestLocation","DAManifest*.xml")
$manifests = (Get-ChildItem -Path "$manloc").FullName
$usedefaultimages = $true

foreach($manifest in $manifests){

    #Open the XML
    $manxml = New-Object XML
    $manxml.load($manifest)
    $manns = New-Object System.Xml.XmlNamespaceManager($manxml.NameTable)
    $manns.AddNamespace("ns", $manxml.DocumentElement.NamespaceURI)    
    $das = $manxml.SelectNodes("//ns:DistributedApplication", $manns)

    foreach($da in $das){
        
        $daname = $da.ApplicationName
        $dadisplayname = $daname.Replace('.',' ')
        $daclass = $daname + '.Distributed.Application'
        $aliassuffix = 1

        #First, create the new Managament Pack
        $mpname = $daname + '.Distributed.Application.Management.Pack'
        $mpdname = $mpname.Replace('.',' ')
        $filename = $mpname + '.xml'
        $outfolder = [io.path]::combine("$OutParent","$dadisplayname")
        $outfile = [io.path]::combine("$outfolder","$filename")

        #Set the file location for the stub Management Pack
        #$xmlstub = [io.path]::combine((Get-Location).Path,"dastub.xml")

        #Copy the stub to a new managment pack in the output folder
        if(!(Test-Path -path $outfolder)) {New-Item $outfolder -Type Directory | Out-Null}
$stub=@"
<ManagementPack ContentReadable="true" OriginalSchemaVersion="1.1" SchemaVersion="2.0" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<Manifest>
		<Identity>
			<ID></ID>
			<Version>1.0.0.0</Version>
		</Identity>
		<References>
			<Reference Alias="SystemCenter">
				<ID>Microsoft.SystemCenter.Library</ID>
				<Version>7.0.8448.6</Version>
				<PublicKeyToken>31bf3856ad364e35</PublicKeyToken>
			</Reference>
			<Reference Alias="SCInternal">
				<ID>Microsoft.SystemCenter.Internal</ID>
				<Version>7.0.8443.6</Version>
				<PublicKeyToken>31bf3856ad364e35</PublicKeyToken>
			</Reference>			
			<Reference Alias="System">
				<ID>System.Library</ID>
				<Version>7.5.8501.0</Version>
				<PublicKeyToken>31bf3856ad364e35</PublicKeyToken>
			</Reference>
			<Reference Alias="Health">
				<ID>System.Health.Library</ID>
				<Version>7.0.8443.6</Version>
				<PublicKeyToken>31bf3856ad364e35</PublicKeyToken>
			</Reference>
			<Reference Alias="URLGenie">
				<ID>URLGenie</ID>
				<Version>2.0.0.61</Version>
				<PublicKeyToken>6649d9cd37e0d562</PublicKeyToken>
			</Reference>
			<Reference Alias="SQLServer">
				<ID>Microsoft.SQLServer.Core.Library</ID>
				<Version>7.4.0.0</Version>
				<PublicKeyToken>31bf3856ad364e35</PublicKeyToken>
			</Reference>
			<Reference Alias="Image">
				<ID>System.Image.Library</ID>
				<Version>7.5.8501.0</Version>
				<PublicKeyToken>31bf3856ad364e35</PublicKeyToken>
			</Reference>
			<Reference Alias="WindowsImage">
				<ID>Microsoft.Windows.Image.Library</ID>
				<Version>7.5.8501.0</Version>
				<PublicKeyToken>31bf3856ad364e35</PublicKeyToken>
			</Reference>
			<Reference Alias="DistributedApplications">
				<ID>Distributed.Applications.Services.Collections.Library</ID>
				<Version>1.0.0.5</Version>
				<PublicKeyToken>e29f2c7b0ce83b09</PublicKeyToken>
			</Reference>
		</References>
	</Manifest>
	<TypeDefinitions>
		<EntityTypes>
			<ClassTypes>
			</ClassTypes>
			<RelationshipTypes>
			</RelationshipTypes>
		</EntityTypes>
	</TypeDefinitions>
	<Monitoring>
		<Discoveries>
		</Discoveries>
		<Monitors>
		</Monitors>
	</Monitoring>
	<Presentation>
		<ImageReferences />
	</Presentation>	
	<LanguagePacks>
		<LanguagePack ID="ENU" IsDefault="false">
			<DisplayStrings>
			</DisplayStrings>
		</LanguagePack>
	</LanguagePacks>
</ManagementPack>
"@

$stub | Out-File $outfile        

        #Load the stub we just cloned over
        $xml = New-Object XML
        $xml.load($outfile)
        $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
        $ns.AddNamespace("ns", $xml.DocumentElement.NamespaceURI)

        #If this mp is already installed, bump the version.
        $version = (Get-SCOMManagementPack  | Select-Object Name,Version | Where-Object {$_.Name -eq "$mpname"}).Version
        if($null -ne $version){
            $revision = ($version.Revision + 1)
            $newversion = [string]$version.Major +  '.' + [string]$version.Minor + '.' + [string]$version.Build  + '.' + [string]$revision
            $node = $xml.ManagementPack.Manifest.Identity
            $node.Version = $newversion
        }


        #Add the managment pack name
        $node = $xml.ManagementPack.Manifest.Identity
        $node.ID = $mpname

        #Add the display string node for the managment pack
        $node = $xml.SelectSingleNode("//ns:LanguagePack[@ID='ENU']/DisplayStrings", $ns)
        $DisplayString = $xml.CreateElement('DisplayString')
        $DisplayString.SetAttribute('ElementID',"$mpname")
        $node.AppendChild($DisplayString) | Out-Null

        #Add the Name node
        $node = $xml.SelectSingleNode("//ns:LanguagePack[@ID='ENU']/DisplayStrings/DisplayString[@ElementID='$mpname']", $ns)
        $Name = $xml.CreateElement('Name')
        $Name.InnerText = "$mpdname"
        $node.AppendChild($Name) | Out-Null

        $node = $xml.SelectSingleNode("//ns:Manifest", $ns)
        $node2 = $xml.SelectSingleNode("//ns:Manifest/Identity", $ns)
        $Name = $xml.CreateElement('Name')
        $Name.InnerText = "$mpdname"
        $node.InsertAfter($Name,$node2) | Out-Null

        #Add the Description node
        $node = $xml.SelectSingleNode("//ns:LanguagePack[@ID='ENU']/DisplayStrings/DisplayString[@ElementID='$mpname']", $ns)
        $Description = $xml.CreateElement('Description')
        $Description.InnerText = "This Management Pack contains an auto-generated Distributed Application for $mpdname"
        $node.AppendChild($Description) | Out-Null

        #*****START ADD THE DISTRIBUTED APPLICATION CLASS*****
        $node = $xml.SelectSingleNode("//ns:TypeDefinitions/EntityTypes/ClassTypes", $ns)
        $ClassType = $xml.CreateElement('ClassType')
        $ClassType.SetAttribute('Abstract',"false")
        $ClassType.SetAttribute('Accessibility',"Public")
        $ClassType.SetAttribute('Base',"DistributedApplications!Distributed.Applications.Services.Collections.GenericService")
        $ClassType.SetAttribute('Extension',"false")
        $ClassType.SetAttribute('Hosted',"false")
        $ClassType.SetAttribute('ID',"$daclass")
        $ClassType.SetAttribute('Singleton',"true")
        $node.AppendChild($ClassType) | Out-Null
        #*****END ADD THE DISTRIBUTED APPLICATION CLASS*****
        
        #*****START ADD DESCRIPTION FOR THE DISTRIBUTED APPLICATION CLASS*****
        $node = $xml.SelectSingleNode("//ns:LanguagePack[@ID='ENU']/DisplayStrings", $ns)
        $DisplayString = $xml.CreateElement('DisplayString')
        $DisplayString.SetAttribute('ElementID',"$daclass")
        #Name
        $Name = $xml.CreateElement('Name')
        $Name.InnerText = $dadisplayname
        $DisplayString.AppendChild($Name) | Out-Null

        #Description
        $Description = $xml.CreateElement('Description')
        $Description.InnerText = "$dadisplayname is the top level class of the $dadisplayname that contains all collections."
        $DisplayString.AppendChild($Description) | Out-Null
        $node.AppendChild($DisplayString) | Out-Null
        #*****END ADD DESCRIPTION FOR THE DISTRIBUTED APPLICATION CLASS*****

        #*****START CREATE DISTRIBUTED APPLICATION DISCOVERY*****
        $dadiscid = $daclass + '.Discovery'
        $dadiscdn = $dadiscid.Replace('.',' ')
        $node = $xml.SelectSingleNode("//ns:Monitoring/Discoveries", $ns)
        $Discovery = $xml.CreateElement('Discovery')
        $Discovery.SetAttribute('ConfirmDelivery',"false")
        $Discovery.SetAttribute('Enabled',"true")
        $Discovery.SetAttribute('ID',"$dadiscid")
        $Discovery.SetAttribute('Priority',"Normal")
        $Discovery.SetAttribute('Remotable',"true")
        $Discovery.SetAttribute('Target',"$daclass")

        #Category
        $Category = $xml.CreateElement('Category')
        $Category.InnerText = "Discovery"
        $Discovery.AppendChild($Category) | Out-Null

        #DiscoveryTypes
        $DiscoveryTypes = $xml.CreateElement('DiscoveryTypes')
        $Discovery.AppendChild($DiscoveryTypes) | Out-Null

        #DataSource
        $DataSource = $xml.CreateElement('DataSource')
        $DataSource.SetAttribute('ID',"DS")
        $DataSource.SetAttribute('TypeID',"SystemCenter!Microsoft.SystemCenter.GroupPopulator")

        $RuleId = $xml.CreateElement('RuleId')
        $RuleId.InnerText = "`$MPElement$"
        $DataSource.AppendChild($RuleId) | Out-Null

        $GroupInstanceId = $xml.CreateElement('GroupInstanceId')
        $GroupInstanceId.InnerText = "`$Target/Id$"
        $DataSource.AppendChild($GroupInstanceId) | Out-Null

        $MembershipRules = $xml.CreateElement('MembershipRules')
        $DataSource.AppendChild($MembershipRules) | Out-Null
        
        $Discovery.AppendChild($DataSource) | Out-Null
        $node.AppendChild($Discovery) | Out-Null
        #*****END CREATE DISTRIBUTED APPLICATION DISCOVERY*****

        #*****START ADD DESCRIPTION FOR THE DISTRIBUTED APPLICATION DISCOVERY*****
        $node = $xml.SelectSingleNode("//ns:LanguagePack[@ID='ENU']/DisplayStrings", $ns)
        $DisplayString = $xml.CreateElement('DisplayString')
        $DisplayString.SetAttribute('ElementID',"$dadiscid")
        #Name
        $Name = $xml.CreateElement('Name')
        $Name.InnerText = $dadiscdn
        $DisplayString.AppendChild($Name) | Out-Null

        #Description
        $Description = $xml.CreateElement('Description')
        $Description.InnerText = "$discdn is the top level class of the $mpdname that contains all collections."
        $DisplayString.AppendChild($Description) | Out-Null
        $node.AppendChild($DisplayString) | Out-Null
        #*****END ADD DESCRIPTION FOR THE DISTRIBUTED APPLICATION DISCOVERY*****


        $colllist = $da.Collections.Collection
        foreach($collection in $colllist){
            
            $theclass = $collection.Class
            $classmp = Get-SCOMClass -Name $theclass

            #Create a unique alias name for this MP and add the reference if neccessary
            if($null -ne $classmp){
            
                #Get a list of class references from the current xml
                $references = @()
                $node = $xml.SelectSingleNode("//ns:References", $ns)
                $references = $node.Reference
                
                #get the name of the Management Pack that this class lives in
                $mptoref = $classmp.ManagementPackName

                #If there isn't already a reference for this MP, create one
                $refids = $references.ID
                if($mptoref -notin $refids){
                    $alias = ''
                    $regex = [System.Text.RegularExpressions.Regex]::new('([A-Z])')
                    $regex.Matches($mptoref) | ForEach-Object{$alias = $alias + $_.Groups[1].Value}
                    if($alias -in $references.Alias){
                        $alias = $alias + [string]$aliassuffix
                        $aliassuffix ++
                    }

                    $mpinfo = Get-SCOMManagementPack -Name $mptoref

                    #Add the reference for the application root class management pack
                    $node = $xml.SelectSingleNode("//ns:References", $ns)
                    $Reference = $xml.CreateElement('Reference')
                    $Reference.SetAttribute('Alias',"$alias")
                    $node.AppendChild($Reference) | Out-Null

                    #Add the ID node
                    $node = $xml.SelectSingleNode("//ns:References/Reference[@Alias='$alias']", $ns)
                    $mpid = $xml.CreateElement('ID')
                    $mpid.InnerText = $mpinfo.Name
                    $node.AppendChild($mpid) | Out-Null

                    #Add the Version node
                    $node = $xml.SelectSingleNode("//ns:References/Reference[@Alias='$alias']", $ns)
                    $mpversion = $xml.CreateElement('Version')
                    $mpversion.InnerText = $mpinfo.Version
                    $node.AppendChild($mpversion) | Out-Null

                    #Add the PublicKeyToken node
                    $node = $xml.SelectSingleNode("//ns:References/Reference[@Alias='$alias']", $ns)
                    $mpkey = $xml.CreateElement('PublicKeyToken')
                    $mpkey.InnerText = $mpinfo.KeyToken
                    $node.AppendChild($mpkey) | Out-Null

                #Otherwise, find and use the existing alias
                }else{
                
                    $alias = ($references | Where-Object {$_.ID -eq $mptoref}).Alias

                }
            
            }else{
            
                Write-Host "Management Pack containing $theclass not found. Cannot continue. Exiting..." -ForegroundColor Red
            
            }

            #Name and DisplayName of this collection
            $col = $daname + '.' + $collection.Class + '.Collection'
            $cold = $dadisplayname + ' ' + $collection.Type

            #*****START ADD CLASS*****
            $node = $xml.SelectSingleNode("//ns:TypeDefinitions/EntityTypes/ClassTypes", $ns)
            $ClassType = $xml.CreateElement('ClassType')
            $ClassType.SetAttribute('Abstract',"false")
            $ClassType.SetAttribute('Accessibility',"Public")
            $ClassType.SetAttribute('Base',"DistributedApplications!Distributed.Applications.Services.Collections.Collection")
            $ClassType.SetAttribute('Extension',"false")
            $ClassType.SetAttribute('Hosted',"false")
            $ClassType.SetAttribute('ID',"$col")
            $ClassType.SetAttribute('Singleton',"true")
            $node.AppendChild($ClassType) | Out-Null
            #*****END ADD CLASS*****

            #*****START ADD DESCRIPTION FOR THE CLASS*****
            $node = $xml.SelectSingleNode("//ns:LanguagePack[@ID='ENU']/DisplayStrings", $ns)
            $DisplayString = $xml.CreateElement('DisplayString')
            $DisplayString.SetAttribute('ElementID',"$col")
            #Name
            $Name = $xml.CreateElement('Name')
            $Name.InnerText = $cold
            $DisplayString.AppendChild($Name) | Out-Null

            #Description
            $Description = $xml.CreateElement('Description')
            $Description.InnerText = "$cold is a sub-level class that contains $theclass objects."
            $DisplayString.AppendChild($Description) | Out-Null

            $node.AppendChild($DisplayString) | Out-Null
            #*****END ADD DESCRIPTION FOR THE CLASS*****

            #*****START ADD CLASS RELATIONSHIP TO CLASS COLLECTION*****
            #Name and DisplayName of this collections relationship to contained class
            $coltoclassn = $col + '.Contains.' + $theclass
            $coltoclassd = $coltoclassn.Replace('.',' ')

            $node = $xml.SelectSingleNode("//ns:TypeDefinitions/EntityTypes/RelationshipTypes", $ns)
            $RelationshipType = $xml.CreateElement('RelationshipType')
            $RelationshipType.SetAttribute('Abstract',"false")
            $RelationshipType.SetAttribute('Accessibility',"Public")
            $RelationshipType.SetAttribute('Base',"System!System.Containment")
            $RelationshipType.SetAttribute('ID',"$coltoclassn")
            #Source
            $Source = $xml.CreateElement('Source')
            $Source.SetAttribute('ID',"source")
            $Source.SetAttribute('MaxCardinality',"2147483647")
            $Source.SetAttribute('MinCardinality',"0")
            $Source.SetAttribute('Type',"$col")
            $RelationshipType.AppendChild($Source) | Out-Null
            #Target
            $Target = $xml.CreateElement('Target')
            $Target.SetAttribute('ID',"target")
            $Target.SetAttribute('MaxCardinality',"2147483647")
            $Target.SetAttribute('MinCardinality',"0")
            $type = $alias + '!' + $theclass
            $Target.SetAttribute('Type',"$type")
            $RelationshipType.AppendChild($Target) | Out-Null
            $node.AppendChild($RelationshipType) | Out-Null
            #*****END ADD CLASS RELATIONSHIP TO CLASS COLLECTION*****

            #*****START ADD DESCRIPTION FOR THE CLASS RELATIONSHIP TO CLASS COLLECTION*****
            $node = $xml.SelectSingleNode("//ns:LanguagePack[@ID='ENU']/DisplayStrings", $ns)
            $DisplayString = $xml.CreateElement('DisplayString')
            $DisplayString.SetAttribute('ElementID',"$coltoclassn")
        
            #Name
            $Name = $xml.CreateElement('Name')
            $Name.InnerText = "$coltoclassd"
            $DisplayString.AppendChild($Name) | Out-Null

            #Description
            $Description = $xml.CreateElement('Description')
            $Description.InnerText = "All $theclass objects in the collection which roll up to the $cold."
            $DisplayString.AppendChild($Description) | Out-Null

            $node.AppendChild($DisplayString) | Out-Null
            #*****END ADD DESCRIPTION FOR THE CLASS RELATIONSHIP TO CLASS COLLECTION*****


            #*****START CREATE DEPENDENCY MONITORS (CLASS --> COLLECTION) FOR URL GENIE HTTP REQUEST SEEDS*****
            #Name and DisplayName of collection relationship to contained class dependency monitor
            $coltoclassdmn = $coltoclassn + '.Availability'
            $coltoclassdmd = $collection.Type

            $node = $xml.SelectSingleNode("//ns:Monitoring/Monitors", $ns)
            $DependencyMonitor = $xml.CreateElement('DependencyMonitor')
            $DependencyMonitor.SetAttribute('Accessibility',"Public")
            $DependencyMonitor.SetAttribute('Enabled',"true")
            $DependencyMonitor.SetAttribute('ID',"$coltoclassdmn")
            $DependencyMonitor.SetAttribute('MemberMonitor',"Health!System.Health.AvailabilityState")
            $DependencyMonitor.SetAttribute('ParentMonitorID',"Health!System.Health.AvailabilityState")
            $DependencyMonitor.SetAttribute('Priority',"Normal")
            $DependencyMonitor.SetAttribute('RelationshipType',"$coltoclassn")
            $DependencyMonitor.SetAttribute('Remotable',"true")
            $DependencyMonitor.SetAttribute('Target',"$col")
        
            $Category = $xml.CreateElement('Category')
            $Category.InnerText = 'AvailabilityHealth'
            $DependencyMonitor.AppendChild($Category) | Out-Null        
        
            $Algorithm = $xml.CreateElement('Algorithm')
            $Algorithm.InnerText = 'WorstOf'
            $DependencyMonitor.AppendChild($Algorithm) | Out-Null        
 
            $node.AppendChild($DependencyMonitor) | Out-Null
            #*****END CREATE DEPENDENCY MONITORS (CLASS --> COLLECTION) FOR URL GENIE HTTP REQUEST SEEDS*****

            #*****START ADD DESCRIPTION FOR THE DEPENDENCY MONITOR*****
            $node = $xml.SelectSingleNode("//ns:LanguagePack[@ID='ENU']/DisplayStrings", $ns)
            $DisplayString = $xml.CreateElement('DisplayString')
            $DisplayString.SetAttribute('ElementID',"$coltoclassdmn")
        
            #Name
            $Name = $xml.CreateElement('Name')
            $Name.InnerText = $coltoclassdmd
            $DisplayString.AppendChild($Name) | Out-Null

            #Description
            $Description = $xml.CreateElement('Description')
            $Description.InnerText = "$coltoclassdmd is the Availability Health Rollup of $theclass to $cold."
            $DisplayString.AppendChild($Description) | Out-Null

            $node.AppendChild($DisplayString) | Out-Null
            #*****END ADD DESCRIPTION FOR THE DEPENDENCY MONITOR*****

            #*****START ADD CLASS COLLECTION RELATIONSHIP TO DISTRIBUTED APPLICATION*****
            $coltodan = $daname + '.Contains.' + $col

            $node = $xml.SelectSingleNode("//ns:TypeDefinitions/EntityTypes/RelationshipTypes", $ns)
            $RelationshipType = $xml.CreateElement('RelationshipType')
            $RelationshipType.SetAttribute('Abstract',"false")
            $RelationshipType.SetAttribute('Accessibility',"Public")
            $RelationshipType.SetAttribute('Base',"System!System.Containment")
            $RelationshipType.SetAttribute('ID',"$coltodan")
            #Source
            $Source = $xml.CreateElement('Source')
            $Source.SetAttribute('ID',"source")
            $Source.SetAttribute('MaxCardinality',"2147483647")
            $Source.SetAttribute('MinCardinality',"0")
            $Source.SetAttribute('Type',"$daclass")
            $RelationshipType.AppendChild($Source) | Out-Null
            #Target
            $Target = $xml.CreateElement('Target')
            $Target.SetAttribute('ID',"target")
            $Target.SetAttribute('MaxCardinality',"2147483647")
            $Target.SetAttribute('MinCardinality',"0")
            $Target.SetAttribute('Type',"$col")
            $RelationshipType.AppendChild($Target) | Out-Null
            $node.AppendChild($RelationshipType) | Out-Null
            #*****END ADD CLASS COLLECTION RELATIONSHIP TO DISTRIBUTED APPLICATION*****

            #*****START ADD CLASS COLLECTION RELATIONSHIP TO DISTRIBUTED APPLICATION DISCOVERY*****
            $node = $xml.SelectSingleNode("//ns:Monitoring/Discoveries/Discovery[@ID='$dadiscid']/DataSource/MembershipRules", $ns)
            
            $MembershipRule = $xml.CreateElement('MembershipRule')
            $MembershipRules.AppendChild($MembershipRule) | Out-Null

            $MonitoringClass = $xml.CreateElement('MonitoringClass')
            $MonitoringClass.InnerText = "`$MPElement[Name=`"" + $col + "`"]$"
            $MembershipRule.AppendChild($MonitoringClass) | Out-Null

            #$relationship = '$MPElement[Name="' + $coltodan + '"]$'

            $RelationshipClass = $xml.CreateElement('RelationshipClass')
            $RelationshipClass.InnerText = "`$MPElement[Name=`"" + $coltodan + "`"]$"
            $MembershipRule.AppendChild($RelationshipClass) | Out-Null
            $node.AppendChild($MembershipRule) | Out-Null

            $node = $xml.SelectSingleNode("//ns:Monitoring/Discoveries/Discovery[@ID='$dadiscid']/DiscoveryTypes", $ns)
            $DiscoveryRelationship = $xml.CreateElement('DiscoveryRelationship')
            $DiscoveryRelationship.SetAttribute('TypeID',"$coltodan")
            $node.AppendChild($DiscoveryRelationship) | Out-Null
            #*****END ADD CLASS COLLECTION RELATIONSHIP TO DISTRIBUTED APPLICATION DISCOVERY*****

            #*****START ADD DESCRIPTION FOR THE CLASS COLLECTION RELATIONSHIP TO DISTRIBUTED APPLICATION*****
            $node = $xml.SelectSingleNode("//ns:LanguagePack[@ID='ENU']/DisplayStrings", $ns)
            $DisplayString = $xml.CreateElement('DisplayString')
            $DisplayString.SetAttribute('ElementID',"$coltodan")
        
            #Name
            $Name = $xml.CreateElement('Name')
            $Name.InnerText = "$cold relationship to $dadisplayname"
            $DisplayString.AppendChild($Name) | Out-Null

            #Description
            $Description = $xml.CreateElement('Description')
            $Description.InnerText = "$cold objects in the collection which roll up to $dadisplayname."
            $DisplayString.AppendChild($Description) | Out-Null

            $node.AppendChild($DisplayString) | Out-Null
            #*****END ADD DESCRIPTION FOR THE CLASS COLLECTION RELATIONSHIP TO DISTRIBUTED APPLICATION*****


            #*****START CREATE DEPENDENCY MONITORS (COLLECTION --> DA) FOR APPLICATION COMPONENT COLLECTION*****
            #Name and DisplayName of distributed appication relationship to contained collection dependency monitor
            $coltodadmn = $coltodan + '.Availability'
            $coltodadmd = $dadisplayname + ' - ' + $collection.Type
            $node = $xml.SelectSingleNode("//ns:Monitoring/Monitors", $ns)
            $DependencyMonitor = $xml.CreateElement('DependencyMonitor')
            $DependencyMonitor.SetAttribute('Accessibility',"Public")
            $DependencyMonitor.SetAttribute('Enabled',"true")
            $DependencyMonitor.SetAttribute('ID',"$coltodadmn")
            $DependencyMonitor.SetAttribute('MemberMonitor',"Health!System.Health.AvailabilityState")
            $DependencyMonitor.SetAttribute('ParentMonitorID',"Health!System.Health.AvailabilityState")
            $DependencyMonitor.SetAttribute('Priority',"Normal")
            $DependencyMonitor.SetAttribute('RelationshipType',"$coltodan")
            $DependencyMonitor.SetAttribute('Remotable',"true")
            $DependencyMonitor.SetAttribute('Target',"$daclass")
        
            $Category = $xml.CreateElement('Category')
            $Category.InnerText = 'AvailabilityHealth'
            $DependencyMonitor.AppendChild($Category) | Out-Null        
        
            $Algorithm = $xml.CreateElement('Algorithm')
            $Algorithm.InnerText = 'WorstOf'
            $DependencyMonitor.AppendChild($Algorithm) | Out-Null        
 
            $node.AppendChild($DependencyMonitor) | Out-Null
            #*****END CREATE DEPENDENCY MONITORS (COLLECTION-->DA) FOR APPLICATION COMPONENT COLLECTION*****

            #*****START ADD DESCRIPTION FOR THE DEPENDENCY MONITOR*****
            $node = $xml.SelectSingleNode("//ns:LanguagePack[@ID='ENU']/DisplayStrings", $ns)
            $DisplayString = $xml.CreateElement('DisplayString')
            $DisplayString.SetAttribute('ElementID',"$coltodadmn")
        
            #Name
            $Name = $xml.CreateElement('Name')
            $Name.InnerText = "$coltodadmd"
            $DisplayString.AppendChild($Name) | Out-Null

            #Description
            $Description = $xml.CreateElement('Description')
            $Description.InnerText = "Dependency Monitor for $coltodadmd"
            $DisplayString.AppendChild($Description) | Out-Null

            $node.AppendChild($DisplayString) | Out-Null
            #*****END ADD DESCRIPTION FOR THE DEPENDENCY MONITOR*****

            #*****START CLASS DISCOVERY*****
            $discid = $col + '.Discovery'
            $disciddn = $discid.Replace('.',' ')
            $node = $xml.SelectSingleNode("//ns:Monitoring/Discoveries", $ns)
            $Discovery = $xml.CreateElement('Discovery')
            $Discovery.SetAttribute('ConfirmDelivery',"false")
            $Discovery.SetAttribute('Enabled',"true")
            $Discovery.SetAttribute('ID',"$discid")
            $Discovery.SetAttribute('Priority',"Normal")
            $Discovery.SetAttribute('Remotable',"true")
            $Discovery.SetAttribute('Target',"$col")

            
            #Category
            $Category = $xml.CreateElement('Category')
            $Category.InnerText = "Discovery"
            $Discovery.AppendChild($Category) | Out-Null

            #DiscoveryTypes
            $DiscoveryTypes = $xml.CreateElement('DiscoveryTypes')
            $Discovery.AppendChild($DiscoveryTypes) | Out-Null

            #DataSource
            $DataSource = $xml.CreateElement('DataSource')
            $DataSource.SetAttribute('ID',"DS")
            $DataSource.SetAttribute('TypeID',"SystemCenter!Microsoft.SystemCenter.GroupPopulator")

            $RuleId = $xml.CreateElement('RuleId')
            $RuleId.InnerText = "`$MPElement$"
            $DataSource.AppendChild($RuleId) | Out-Null

            $GroupInstanceId = $xml.CreateElement('GroupInstanceId')
            $GroupInstanceId.InnerText = "`$Target/Id$"
            $DataSource.AppendChild($GroupInstanceId) | Out-Null

            $MembershipRules = $xml.CreateElement('MembershipRules')
            $DataSource.AppendChild($MembershipRules) | Out-Null

            $MembershipRule = $xml.CreateElement('MembershipRule')
            $MembershipRules.AppendChild($MembershipRule) | Out-Null
        
            $relationship = '$MPElement[Name="' + $col + '.Contains.' + $theclass + '"]$'        
        
            $MonitoringClass = $xml.CreateElement('MonitoringClass')
            $monclass = "$alias" + '!' + "$theclass"
            $MonitoringClass.InnerText = "`$MPElement[Name=`"$monclass`"]$"
            $MembershipRule.AppendChild($MonitoringClass) | Out-Null

            $RelationshipClass = $xml.CreateElement('RelationshipClass')
            $RelationshipClass.InnerText = "$relationship"
            $MembershipRule.AppendChild($RelationshipClass) | Out-Null

            $IncludeList = $xml.CreateElement('IncludeList')
            $MembershipRule.AppendChild($IncludeList) | Out-Null

            $colobjects = $collection.Instance
            $otype = $collection.Type

            $oclass = Get-SCOMClass -Name $theclass
            
            foreach($colobject in $colobjects){
                         
                $oname = $colobject.Servername
                $oproperty = $colobject.ClassProperty

                SWITCH($otype){
                    'Application'       {$objguid = ($oclass | Get-SCOMClassInstance | Where-Object {$_.'[Microsoft.Windows.Computer].PrincipalName'.Value -eq "$oname"}).Id.Guid}
                    'Web Sites'         {$objguid = ($oclass | Get-SCOMClassInstance | Where-Object {(($_.Name -eq "$oproperty") -and ($_.Path -eq "$oname"))}).Id.Guid}
                    'Databases'         {$objguid = ($oclass | Get-SCOMClassInstance | Where-Object {(($_.Name -eq "$oproperty") -and ($_.Path -match "$oname"))}).Id.Guid}
                    'URL Monitors'      {$objguid = ($oclass | Get-SCOMClassInstance | Where-Object {($_.'[URLGenie.HttpRequest.Seed].GroupID'.Value -eq $oproperty)}).Id.Guid}
                    'AvailabilityGroup' {$objguid = ($oclass | Get-SCOMClassInstance | Where-Object {(($_.Name -eq "$oproperty") -and ($_.DisplayName -match "$oname"))}).Id.Guid}
                    DEFAULT             {$objguid = ($oclass | Get-SCOMClassInstance | Where-Object {(($_.Name -eq "$oproperty") -and ($_.Path -eq "$oname"))}).Id.Guid}
                }

                $objectid = '{' + $objguid + '}'
                $MonitoringObjectId = $xml.CreateElement('MonitoringObjectId')
                $MonitoringObjectId.InnerText = "$objectid"
                $IncludeList.AppendChild($MonitoringObjectId) | Out-Null

            }

        
            $Discovery.AppendChild($DataSource) | Out-Null
            $node.AppendChild($Discovery) | Out-Null

            $node = $xml.SelectSingleNode("//ns:Monitoring/Discoveries/Discovery[@ID='$discid']/DiscoveryTypes", $ns)
            $DiscoveryRelationship = $xml.CreateElement('DiscoveryRelationship')
            $DiscoveryRelationship.SetAttribute('TypeID',"$coltoclassn")
            $node.AppendChild($DiscoveryRelationship) | Out-Null

            #*****START ADD IMAGE REFERENCES*****
            if($otype -eq 'Application'){
                $imagelist = $manxml.SelectNodes("//ns:Images", $manns)
                $images = $imagelist.Image | Where-Object {$_.Class -eq $theclass}
                $usedefaultimages = $false

                if($images.Count -ne 2){
                    Write-Host "There must be exactly 2 images defined. Either no custom images are defined, or there are greater or less than 2 defined. Using default images..." -ForegroundColor Yellow
                    $usedefaultimages = $true
                }
                
                if((($images.FileSize -notcontains 'Small') -or ($images.FileSize -notcontains 'Large')) -and ($images.Count -eq 2)){
                    Write-Host "There are 2 images defined, however one must be defined as Large (must be 80x80 pixels) and one must be Small (must be 16x16 pixels). Images of each type must be defined. Using default images..." -ForegroundColor Yellow
                    $usedefaultimages = $true
                }
                
                $imgszagg = 0
                Add-Type -AssemblyName System.Drawing
                foreach($image in $images){
                    if(Test-Path -Path $image.FilePath){
                        #check each image meets the filespec
                        $imgfile = $image.FilePath
                        $newimg = [io.path]::combine("$outfolder","$imgfile")
                        $filetocheck = New-Object System.Drawing.Bitmap $newimg
                        $imgszagg = $imgszagg + $filetocheck.Width + $filetocheck.Height
                        $bundle = [io.path]::combine((Split-Path $outfile -Parent),"Bundle")
                        if(!(Test-Path -Path $bundle -PathType Container)){
                            New-Item -ItemType Directory -Force -Path $bundle | Out-Null
                        }
                        Copy-Item $imgfile $bundle -Force
                    }else{
                        Write-Host $image.FilePath " not found. Using default images..." -ForegroundColor Yellow
                        $usedefaultimages = $true
                    }
                }

                if(($imgszagg -ne 192) -and ($imgszagg -ne 0)){
                    Write-Host "Large icons must be 80x80 pixels and Small icons must be 16x16 pixels. One or both icons do not meet the specification. Using default images..." -ForegroundColor Yellow
                    $usedefaultimages = $true
                }

                if($usedefaultimages){
                    $appiconsmall = 'WindowsImage!WindowsLocalApplication16'
                    $appiconlarge = 'WindowsImage!WindowsLocalApplication80'
                }else{

                    #Add the Categories section
                    $node = $xml.SelectSingleNode("//ns:ManagementPack", $ns)
                    $node2 = $xml.SelectSingleNode("//ns:TypeDefinitions", $ns)
                    $Categories = $xml.CreateElement('Categories')
                    $node.InsertAfter($Categories,$node2) | Out-Null

                    #Add the Resources section
                    $node = $xml.SelectSingleNode("//ns:ManagementPack", $ns)
                    $node2 = $xml.SelectSingleNode("//ns:ManagementPack/LanguagePacks", $ns)
                    $Resources = $xml.CreateElement('Resources')
                    $node.InsertAfter($Resources,$node2) | Out-Null

                    foreach($image in $images){
                        #Set variable values for each icon type
                        $catid = $daname + '.' + $image.FileSize + '.Icon.Category'
                        $rscid = $daname + '.' + $image.FileSize + '.Icon'
                        SWITCH($image.FileSize){
                            'Large' {$thevalue = 'System!System.Internal.ManagementPack.Images.DiagramIcon'
                            $appiconlarge = $rscid
                            }
                            'Small' {$thevalue = 'System!System.Internal.ManagementPack.Images.u16x16Icon'
                            $appiconsmall = $rscid
                            }
                        }                        
                        $filename = Split-Path $image.FilePath -leaf

                        #Category
                        $node = $xml.SelectSingleNode("//ns:Categories", $ns)
                        $Category = $xml.CreateElement('Category')
                        $Category.SetAttribute('ID',"$catid")
                        $Category.SetAttribute('Target',"$rscid")
                        $Category.SetAttribute('Value',"$thevalue")
                        $node.AppendChild($Category) | Out-Null

                        #Resource
                        $node = $xml.SelectSingleNode("//ns:Resources", $ns)
                        $Image = $xml.CreateElement('Image')
                        $Image.SetAttribute('ID',"$rscid")
                        $Image.SetAttribute('Accessibility',"Public")
                        $Image.SetAttribute('FileName',"$filename")
                        $Image.SetAttribute('HasNullStream',"false")
                        $comment = $rscid.Replace('.',' ')
                        $Image.SetAttribute('Comment',"$comment")
                        $node.AppendChild($Image) | Out-Null

                        #Add this icon to the Distributed Application itself. We don't do this if there is no custom icon for the application type (just use the default flux capacitor).
                        $node = $xml.SelectSingleNode("//ns:Presentation/ImageReferences", $ns)
                        $ImageReference = $xml.CreateElement('ImageReference')
                        $ImageReference.SetAttribute('ElementID',"$daclass")
                        $ImageReference.SetAttribute('ImageID',"$rscid")
                        $node.AppendChild($ImageReference) | Out-Null

                        #Force these icons to also be the default for the application class itself, so rollups make sense visually, and for beautification.
                        $node = $xml.SelectSingleNode("//ns:Presentation/ImageReferences", $ns)
                        $ImageReference = $xml.CreateElement('ImageReference')
                        $ImageReference.SetAttribute('ElementID',"$monclass")
                        $ImageReference.SetAttribute('ImageID',"$rscid")
                        $node.AppendChild($ImageReference) | Out-Null

                    }
                
                }

            }

            #If the URL Genie Image Library is deployed to this Management Group, add the refernce so we can leverage the custom images for the collection
            if(($otype -eq 'URL Monitors') -and (Get-SCOMManagementPack -Name 'URL.Genie.Image.Library')){
                
                $genieMP = Get-SCOMManagementPack -Name 'URL.Genie.Image.Library'
                            
                #Add the reference for the URL Genie Image Library
                $node = $xml.SelectSingleNode("//ns:References", $ns)
                $Reference = $xml.CreateElement('Reference')
                $Reference.SetAttribute('Alias',"GenieImage")
                $node.AppendChild($Reference) | Out-Null

                #Add the ID node
                $node = $xml.SelectSingleNode("//ns:References/Reference[@Alias='GenieImage']", $ns)
                $mpid = $xml.CreateElement('ID')
                $mpid.InnerText = $genieMP.Name
                $node.AppendChild($mpid) | Out-Null

                #Add the Version node
                $node = $xml.SelectSingleNode("//ns:References/Reference[@Alias='GenieImage']", $ns)
                $mpversion = $xml.CreateElement('Version')
                $mpversion.InnerText = $genieMP.Version
                $node.AppendChild($mpversion) | Out-Null

                #Add the PublicKeyToken node
                $node = $xml.SelectSingleNode("//ns:References/Reference[@Alias='GenieImage']", $ns)
                $mpkey = $xml.CreateElement('PublicKeyToken')
                $mpkey.InnerText = $genieMP.KeyToken
                $node.AppendChild($mpkey) | Out-Null
                
                $genieimage16 = 'GenieImage!URL.Genie.Small.Icon'
                $genieimage80 = 'GenieImage!URL.Genie.Diagram.Icon'
            }else{
                $genieimage16 = 'Image!ApplicationComponent16'
                $genieimage80 = 'Image!ApplicationComponent80'
            }

            $node = $xml.SelectSingleNode("//ns:Presentation/ImageReferences", $ns)
            $ImageReference = $xml.CreateElement('ImageReference')
            $ImageReference.SetAttribute('ElementID',"$col")

            SWITCH($otype){
                'Application'  {$ImageReference.SetAttribute('ImageID',"$appiconsmall")}
                'Web Sites'    {$ImageReference.SetAttribute('ImageID',"Image!WebSite16")}
                'Databases'    {$ImageReference.SetAttribute('ImageID',"SQLServer!Microsoft.SQLServer.Core.Icon.Database.Image16")}
                'URL Monitors' {$ImageReference.SetAttribute('ImageID',"$genieimage16")}
                'AvailabilityGroup'    {$ImageReference.SetAttribute('ImageID',"SQLServer!Microsoft.SQLServer.Core.Icon.AvailabilityGroup.Image16")}
                DEFAULT    {$ImageReference.SetAttribute('ImageID',"Image!ApplicationComponent16")}
            }
            $node.AppendChild($ImageReference) | Out-Null

            $ImageReference = $xml.CreateElement('ImageReference')
            $ImageReference.SetAttribute('ElementID',"$col")

            SWITCH($otype){
                'Application'  {$ImageReference.SetAttribute('ImageID',"$appiconlarge")}
                'Web Sites'    {$ImageReference.SetAttribute('ImageID',"Image!WebSite80")}
                'Databases'    {$ImageReference.SetAttribute('ImageID',"SQLServer!Microsoft.SQLServer.Core.Icon.Database.Image80")}
                'URL Monitors' {$ImageReference.SetAttribute('ImageID',"$genieimage80")}
                'AvailabilityGroup'    {$ImageReference.SetAttribute('ImageID',"SQLServer!Microsoft.SQLServer.Core.Icon.AvailabilityGroup.Image80")}
                DEFAULT    {$ImageReference.SetAttribute('ImageID',"Image!ApplicationComponent80")}
            }
            $node.AppendChild($ImageReference) | Out-Null
            #*****END ADD IMAGE REFERENCES*****

            #*****END CLASS DISCOVERY*****

            #*****START ADD DESCRIPTION FOR THE DISCOVERY*****
            $node = $xml.SelectSingleNode("//ns:LanguagePack[@ID='ENU']/DisplayStrings", $ns)
            $DisplayString = $xml.CreateElement('DisplayString')
            $DisplayString.SetAttribute('ElementID',"$discid")
        
            #Name
            $Name = $xml.CreateElement('Name')
            $Name.InnerText = "$disciddn"
            $DisplayString.AppendChild($Name) | Out-Null

            #Description
            $Description = $xml.CreateElement('Description')
            $Description.InnerText = "Discovery for $disciddn"
            $DisplayString.AppendChild($Description) | Out-Null

            $node.AppendChild($DisplayString) | Out-Null
            #*****END ADD DESCRIPTION FOR THE DISCOVERY*****


        }

        $xml.Save($outfile)
        $cmd = $scriptPath + "\MPSeal\FastSeal.exe"
        if(!($usedefaultimages)){
            $params = " `"$outfile`"" +  ' /KeyFile "' + $snk + '" /Company "-" /OutDir ' + "`"$bundle`""
        }else{
            $params = " `"$outfile`"" +  ' /KeyFile "' + $snk + '" /Company "-" /OutDir ' + "`"$outfolder`""
        }
        Start-Process -NoNewWindow -FilePath $cmd -ArgumentList $params -Wait
        if(!($usedefaultimages)){
            $resimgs = ''
            foreach($image in $images){
                
                $imgname = [string](Split-Path $image.FilePath -leaf)
                $resimg = [io.path]::combine("$bundle","$imgname")
                $resimgs = $resimgs + "`"$resimg`"" + ' '
            }

            $mpb = [io.path]::combine("$bundle",("$daclass" + '.mpb'))
            $Create = ' -Create ' + "`"$mpb`""
            $mptobundle = [io.path]::combine("$bundle","$mpname.mp")
            $ManagementPacks = ' -ManagementPacks ' + "`"$mptobundle`""
            $MPFolder = ' -MPFolder ' + "`"$bundle`""
            $resimgs = ' -Resources ' + $resimgs.TrimEnd(' ')
            $mpbparams = $Create + $ManagementPacks + $MPFolder + $resimgs
            $cmd = $scriptPath + "\MPSeal\MPBUtil.exe"
            Start-Process -NoNewWindow -FilePath $cmd -ArgumentList $mpbparams -Wait
        }

    }
}