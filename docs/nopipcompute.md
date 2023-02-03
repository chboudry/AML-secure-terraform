# No public IP Training Compute 

## Logic

1. VNET default NAT features is only provided to VM
2. Compute instances & compute clusters are not VM
3. But they need access to public IP (AAD, etc)
4. Thus, you need to provide them a public IP
5. Solutions are Azure Firewall, VNET NAT, Gateway...
6. In the example above, we choose Firewall
7. We use UDR to route trafic to Firewall
8. in Azure Firewall, all approved traffic is automatically (S)Nated

## Observations
- No inbound rules makes this environment support No public IP __only__ (= a public IP compute won't work.)
- Make sure you are using an image builder cluster as ACR can't build image when it is using a private endpoint. I've put one for you in this template.
- Destination VNET has a route more specific than 0.0.0.0/0 thus per routes priority redirection to the Firewall of routes with destination VNET won't apply. 
