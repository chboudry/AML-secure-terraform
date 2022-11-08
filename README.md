# aml-secure-terraform

![architecture-schema](docs/architectureschema.png)

## Notes

### No public IP Training Compute 

#### Logic

1. VNET default NAT features is only provided to VM
2. Compute instances & compute clusters are not VM
3. But they need access to public IP (AAD, etc)
4. Thus, you need to provide them a public IP
5. Solutions are Azure Firewall, VNET NAT, Gateway...
6. In the example above, we choose Firewall
7. We use UDR to route trafic to Firewall
8. in Azure Firewall, all approved traffic is automatically (S)Nated

#### Observations
- No inbound rules makes this environment support No public IP __only__ (= a public IP compute won't work.)
- Make sure you are using an image builder cluster as ACR can't build image when it is using a private endpoint.
- Make sure your image builder cluster was created with a no public IP only otherwise it will fail/timeout when it will resize for the first time
- Destination VNET has a route more specific than 0.0.0.0/0 thus per routes priority redirection to the Firewall of routes with destination VNET won't apply. In the current example, I do not have NSG on the training subnet, if you add one you will need to add in your NSG any port source to destination VNET port 29876, 29877, 44224. 

### Inferencing Environment

#### Managed Endpoint

Requirements:
- Workspace v1_legacy_mode_enabled to false (this is by default in terraform)
- egress_public_network_access="disabled" when you add the deployment to the managed online endpoint
- Targetted env need to use private image only (=can't target mcr.microsoft.com)


#### AKS with CNI
Work in progress

## Usage

- az login
- terraform init
- terraform apply


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