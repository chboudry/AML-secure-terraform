## Troubleshooting

### Kusto query

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