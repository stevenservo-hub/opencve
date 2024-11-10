function Get-PreviousDay {
    $datePart = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd")
    return "${datePart}T13:00:00.000%2B01:00"
}

function Get-CurrentDay {
    $datePart = (Get-Date).ToString("yyyy-MM-dd")
    return "${datePart}T13:00:00.000%2B01:00"
}

Write-Output "Previous day: $(Get-PreviousDay)" #TODO: this is for testing

function Get-CVEInfo {
    param (
        [string]$Manufacturer,
        [string]$Model
    )
    
    $previousDay = Get-PreviousDay
    $currentDay = Get-CurrentDay
    $url = "https://services.nvd.nist.gov/rest/json/cves/2.0/?keywordSearch=$Model&pubStartDate=$previousDay&pubEndDate=$currentDay&resultsPerPage=1000"
    try {
        $response = Invoke-RestMethod -Uri $url -Method Get
        $cveIds = $response.vulnerabilities | ForEach-Object { $_.cve.id }
        return $cveIds
    }
    catch {
        Write-Error "Failed to retrieve CVE information: $_"
    }
}

function Send-CVEEmail {
    param (
        [string[]]$CVEIds,
        [string]$Model
    )

    $smtpServer = ""
    $smtpFrom = ""
    $subject = "CVE Vulnerabilities have been found for $Model"
    $body = "The following CVEs were found for $Model:`n"

    foreach ($cveId in $CVEIds) {
        $body += "$cveId - https://nvd.nist.gov/vuln/detail/$cveId`n"
    }

    $mailMessage = @{
        To       = "smarteams@placeholder.com"
        From     = $smtpFrom
        Subject  = $subject
        Body     = $body
        SmtpServer = $smtpServer
    }

    Send-MailMessage @mailMessage
}

# Example customer equipment list
$customerEquipment = @(
    @{ Manufacturer = "Microsoft"; Model = "Windows"; ClientsAffected = "ClientA" },
    @{ Manufacturer = "Cisco"; Model = "Router"; ClientsAffected = "ClientB" }
)

foreach ($equipment in $customerEquipment) {
    $cveList = Get-CVEinfo -Manufacturer $equipment.Manufacturer -Model $equipment.Model
    if ($cveList.Count -gt 0) {
        Send-CVEEmail -CVEIds $cveList -Model $equipment.Model
    }
}