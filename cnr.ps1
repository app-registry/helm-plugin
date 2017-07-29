if(!(Test-Path $Env:HELM_PLUGIN_DIR)){
    $Env:HELM_PLUGIN_DIR="$Env:USERPROFILE/.helm/plugins/registry"
}


function List_Plugin_Versions() {
    $Params = @{ 
        uri = "https://api.github.com/repos/app-registry/appr/tags"
    }
    if ($Env:HTTPS_PROXY) { 
        $Params.add('Proxy', $Env:HTTPS_PROXY) 
    }
    return Invoke-WebRequest @Params | ConvertFrom-Json

}

function Latest() {
    $latest = List_Plugin_Versions
    return $latest.name[0]
}

function Download_Appr() {
    $version = Latest
    if ($args.Count -eq 1) {
        $version = $args[0]
    }

    $Params = @{ 
        outFile = "$Env:HELM_PLUGIN_DIR/appr.exe"
        uri = "https://github.com/app-registry/appr/releases/download/$version/appr-win-x64.exe"

    }
    if ($Env:HTTPS_PROXY) { 
        $Params.add('Proxy', $Env:HTTPS_PROXY) 
    }
    Invoke-WebRequest @Params

}

function Download_Or_Noop() {
    if (!( Get-Item -Path $Env:HELM_PLUGIN_DIR/appr.exe)) {
        Write-Host "Registry plugin assets do not exist, download them now !"
        Download_Appr $args[0]
    }
}

function Appr_Helm($helm_args) {
    Invoke-Expression "$Env:HELM_PLUGIN_DIR/appr.exe $helm_args --media-type=helm"
}

switch ($args[0]) {
    "install" { Invoke-Expression ("$Env:HELM_PLUGIN_DIR/appr.exe helm install " + $args[1..($args.Length-1)]) }
    "upgrade" { Invoke-Expression ("$Env:HELM_PLUGIN_DIR/appr.exe helm upgrade " + $args[1..($args.Length-1)]) }
    "dep"     { Invoke-Expression ("$Env:HELM_PLUGIN_DIR/appr.exe helm dep " + $args[1..($args.Length-1)]) }
    "pull"    { Invoke-Expression ("$Env:HELM_PLUGIN_DIR/appr.exe pull --media-type helm " + $args[1..($args.Length-1)]) }
    "upgrade_plugin" { Download_Appr $args[1..($args.Length-1)] }
    "list_plugin_versions" { List_Plugin_Versions }
    { @("push", "list", "show", "delete-package", "inspect") -contains $_ } { Appr_Helm $args }
    default { Invoke-Expression "$Env:HELM_PLUGIN_DIR/appr.exe $args"}
    
}
