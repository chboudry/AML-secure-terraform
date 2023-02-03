# Troubleshooting

## Terraform

If you messed up the internals aks installation, it might be convenient to delete it in Azure and in the terraform state to redeploy. You can remove part of the state using the following : 

`terraform state rm module.aks.module.kubernetes-config`

## Kusto query

```
AzureDiagnostics 
| order by TimeGenerated desc
| where msg_s contains "Deny"
| where msg_s !contains "DNS"
| where msg_s !contains "UDP"
| where msg_s !contains "database.clamav.net" 
| where msg_s !contains "snapcraftcontent.com"
| project TimeGenerated, msg_s
```