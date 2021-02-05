terraform{
    required_providers {
      azurerm = {
          source = "hashicorp/azurerm"
          version = ">= 2.26"
      }
    }
}

provider "azurerm" {
    features {}  
}

locals{
    resource_group_name = "terraform-logAlerts"
    location = "southeastasia"
    alertName = "alert1"
    frequency = "Minute"
    interval = 5
    tenantId = ""
    servicePrincipalId = ""
    secret = ""
    logQuery = "Heartbeat | where TimeGenerated > datetime_add('minute', -5, now())"
    workspaceId = ""
    timespan = "PT5M"    
}


resource "azurerm_resource_group" "logicapp_alert"{
    name = local.resource_group_name
    location = local.location
}

resource "azurerm_logic_app_workflow" "logicapp_alert"{
    name = local.alertName
    location = azurerm_resource_group.logicapp_alert.location
    resource_group_name = azurerm_resource_group.logicapp_alert.name    
}

resource "azurerm_logic_app_trigger_recurrence" "logicapp_alert"{
    name = "trigger_recurrence"
    logic_app_id = azurerm_logic_app_workflow.logicapp_alert.id
    frequency = local.frequency
    interval = local.interval
}

resource "azurerm_logic_app_action_http" "logicapp_alert"{
    name = "Authenticate"
    logic_app_id = azurerm_logic_app_workflow.logicapp_alert.id
    method = "POST"
    uri = "https://login.microsoftonline.com/${local.tenantId}/oauth2/token"
    body = "client_id=${local.servicePrincipalId}&grant_type=client_credentials&client_secret=${local.secret}&resource=https%3A%2F%2Fapi.loganalytics.io"
    headers = {"Content-Type":"application/x-www-form-urlencoded"}
}

resource "azurerm_logic_app_action_custom" "logicapp_alert_authenticate"{
    name = "GetOAuthToken"
    logic_app_id = azurerm_logic_app_workflow.logicapp_alert.id
    body = <<BODY
         {
             "inputs": {
                    "content": "@body('Authenticate')",
                    "schema": {
                        "properties": {
                            "access_token": {
                                "type": "string"
                            },
                            "expires_in": {
                                "type": "string"
                            },
                            "expires_on": {
                                "type": "string"
                            },
                            "ext_expires_in": {
                                "type": "string"
                            },
                            "not_before": {
                                "type": "string"
                            },
                            "resource": {
                                "type": "string"
                            },
                            "token_type": {
                                "type": "string"
                            }
                        },
                        "type": "object"
                    }
                },
                "runAfter": {
                    "Authenticate": [
                        "Succeeded"
                    ]
                },
                "type": "ParseJson"
            }   
        
    BODY    

}

resource "azurerm_logic_app_action_custom" "logicapp_alert_executequery"{
    name = "ExecuteLogAnalyticsQuery"
    logic_app_id = azurerm_logic_app_workflow.logicapp_alert.id
    body = <<BODY
        {
            "inputs": {
                "method": "POST",
                "uri": "https://api.loganalytics.io/v1/workspaces/${local.workspaceId}/query",
                "headers": {
                    "Authorization": "Bearer @{body('GetOAuthToken')?['access_token']}",
                    "Content-Type": "application/json"
                },
                "body": {
                    "query": "${local.logQuery}",
                    "timespan": "${local.timespan}"
                }
            },
                "runAfter": {
                    "GetOAuthToken": [
                        "Succeeded"
                    ]
                },
                "type": "Http"
        }
    BODY
}