# azure-logic-app-terraform
An implementation of Logic App that queries Log Analytics API

This terraform script demonstrates the creation of an Azure Logic App that uses a User Assigned Managed Identity to query a Log Analytics workspace.  Currently, the only way to assign a Managed Identity to a Logic App is through the use of ARM templates.  This script makes no assumptions that the LA workspace and the Logic App sit in the same subscription.

This script implements the following logic:

- Create a User Assigned Managed Identity
- Assign the "Monitoring Reader" role to the Managed Identity, scoped to the workspace we want to query
- Create a Logic App with Managed Identity using an ARM template.  Note the output to ensure we can get back the Logic App's ResourceId
- Create a Logic App action with Terraform to query the Log Analytics workspace using the Managed Identity
