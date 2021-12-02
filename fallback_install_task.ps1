try{
  $command = Start-Process msiexec.exe -Wait -ArgumentList '/qn /log C:\Users\ADMINI~1\AppData\Local\Temp\chef-client-msi29220.log /i C:\Users\ADMINI~1\AppData\Local\Temp\chef-client-latest.msi'
  $command
  Write-Host "Successfully installed #{ChefUtils::Dist::Infra::PRODUCT} package."
} catch {
  Write-Warning "WARNING: Failed to install Chef Infra MSI package in remote context."
  Write-Warning "WARNING: This may be due to a defect in operating system update KB2918614: http://support.microsoft.com/kb/2918614"

  $OLDLOGLOCATION="%CHEF_CLIENT_MSI_LOG_PATH%-fail.log"
  Move-Item -Path "{CHEF_CLIENT_MSI_LOG_PATH}" -Destination "{OLDLOGLOCATION}"

  Write-Warning WARNING: "Saving installation log of failure at ${OLDLOGLOCATION}"
  Write-Warning WARNING: "Retrying installation with local context..."

  try {
    New-Event -SourceIdentifier chefclientinstalldone -Sender $computername
    $actions = (New-ScheduledTaskAction -Execute $command), (New-ScheduledTaskAction -Execute Start-Sleep 2)
    $trigger = New-ScheduledTaskTrigger -Once -At '0:00 AM'
    $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -RunLevel Highest
    $task = Register-ScheduledTask -TaskName "chefclientbootstraptask" -Trigger $trigger -Principal $principal -Action $actions
    Wait-Event -SourceIdentifier chefclientinstalldone -Timeout 600
  } catch {
    Write-Host "ERROR: Failed to create Chef Infra installation scheduled task."
  } 

  Write-Host "Successfully created scheduled task to install Chef Infra."

  try {
    Start-ScheduledTask -TaskName "chefclientbootstraptask"
  } catch {
    Write-Host "ERROR: Failed to execute Chef Infra installation scheduled task"
  }

  Write-Host "Successfully started Chef Infra installation scheduled task."
  Write-Host "Waiting for installation to complete -- this may take a few minutes..."

  try{
    waitfor chefclientinstalldone /t 600
  } catch {
    Write-Host "ERROR: Timed out waiting for Chef Infra package to install"
  }

  Write-Host "Finished waiting for Chef Infra package to install."
  Unregister-ScheduledTask -TaskName 'chefclientbootstraptask' -Confirm:$false
}
