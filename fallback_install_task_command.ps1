$MSIERRORCODE='!ERRORLEVEL!'

if(ERRORLEVEL -eq 1)
{
  Write-Warning "WARNING: Failed to install #{ChefUtils::Dist::Infra::PRODUCT} MSI package in remote context with status code ${MSIERRORCODE}."
  Write-Warning "WARNING: This may be due to a defect in operating system update KB2918614: http://support.microsoft.com/kb/2918614"
  $OLDLOGLOCATION="%CHEF_CLIENT_MSI_LOG_PATH%-fail.log"
  Move-Item -Path "{CHEF_CLIENT_MSI_LOG_PATH}" -Destination "{OLDLOGLOCATION}"
  Write-Warning WARNING: "Saving installation log of failure at ${OLDLOGLOCATION}"
  Write-Warning WARNING: "Retrying installation with local context..."
  # @schtasks /create /f  /sc once /st 00:00:00 /tn chefclientbootstraptask /ru SYSTEM /rl HIGHEST /tr \"cmd /c #{command} & sleep 2 & waitfor /s %computername% /si chefclientinstalldone\"
  $command = #{command}
  New-Event -SourceIdentifier chefclientinstalldone -Sender $computername
  $actions = (New-ScheduledTaskAction -Execute "$command"), (New-ScheduledTaskAction -Execute Start-Sleep 2)
  $trigger = New-ScheduledTaskTrigger -Once -At '0:00 AM'
  $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -RunLevel Highest
  $task = Register-ScheduledTask -TaskName "chefclientbootstraptask" -Trigger $trigger -Principal $principal -Action $actions
  Wait-Event -SourceIdentifier chefclientinstalldone -Timeout 600

  if(ERRORLEVEL -eq 1)
  {
    Write-Host "ERROR: Failed to create #{ChefUtils::Dist::Infra::PRODUCT} installation scheduled task with status code ${ERRORLEVEL} > "&2""
  }
  else { 
    Write-Host "Successfully created scheduled task to install #{ChefUtils::Dist::Infra::PRODUCT}."
    Start-ScheduledTask -TaskName "chefclientbootstraptask"
  }
  if(ERRORLEVEL -eq 1)
  {
    Write-Host "ERROR: Failed to execute #{ChefUtils::Dist::Infra::PRODUCT} installation scheduled task with status code ${ERRORLEVEL}. > "&2""
  }
  else
  {
    Write-Host "Successfully started #{ChefUtils::Dist::Infra::PRODUCT} installation scheduled task."
    Write-Host "Waiting for installation to complete -- this may take a few minutes..."
    waitfor chefclientinstalldone /t 600
    if(ERRORLEVEL -eq 1)
    {
      Write-Host "ERROR: Timed out waiting for #{ChefUtils::Dist::Infra::PRODUCT} package to install"
    }    
    else {
      Write-Host "Finished waiting for #{ChefUtils::Dist::Infra::PRODUCT} package to install."
    }
    Unregister-ScheduledTask -TaskName 'chefclientbootstraptask' -Confirm:$false
  }
}
else{ 
  Write-Host "Successfully installed #{ChefUtils::Dist::Infra::PRODUCT} package."
}
