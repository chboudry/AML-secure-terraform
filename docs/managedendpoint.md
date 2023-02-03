# Managed Endpoint

Requirements:
- Workspace v1_legacy_mode_enabled to false (this is by default in terraform)
- egress_public_network_access="disabled" when you add the deployment to the managed online endpoint
- Targetted env need to use private image only (=can't target mcr.microsoft.com)
