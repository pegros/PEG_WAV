# PEG WAV Components
Set of schedulable Apex utility classes to sync Salesforce data not supported
by the standard Tableau CRM sync feature.

Leverages the standard [external data API](https://developer.salesforce.com/docs/atlas.en-us.bi_dev_guide_ext_data.meta/bi_dev_guide_ext_data/bi_ext_data_overview.htm) to push Salesforce 
data to Tableau CRM datasets.

Enables to push 4 types of data:
* SOQL query based data (for non sync visible standard objects or to implement delta upsert)
* picklist label values (via schema describe operations)
* Object counts (via count() queries)
* Org limits measurements,leveraging the [System.OrgLimit](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_System_OrgLimit.htm) class


# Configuration
Configuration relies on a set of custom metadata records: 
* **WAV_DataLoad_CFG** to configure the various custom data loads (basd on SOQL queries) 
![Login History Example](/media/SoqlData.png)
* **WAV_Snapshot_CFG** to configure the various snapshots (picklist label, org limits, object counts)
![Picklist Labels](/media/PicklistLabel.png)
![Prg Limit](/media/OrgLimit.png)
![Object Count](/media/ObjectCount.png)

For each custom metadata record, only recors with "isActive" set to true are taken into account by the schedulable processes.

Each configuration relies on a set of static resources to describe the target datasets within Tableau CRM.
* For the **WAV_Snapshot_CFG** records, the static resources are provided by the package
* For the **WAV_DataLoad_CFG** records, they need to be added and registered in the custom metadat records, leveraging the standard Tableau CRM [External Data Format](https://resources.docs.salesforce.com/234/latest/en-us/sfdc/pdf/bi_dev_guide_ext_data_format.pdf)
![Dataset Description](/media/DatasetDesc.png)
```
{
    "fileFormat": {
        "charsetName": "UTF-8",
        "fieldsDelimitedBy": ",",
        "linesTerminatedBy": "\n"
    },
    "objects": [
        {
            "connector": "CSV",
            "fullyQualifiedName": "WAV_LoginHistory",
            "label": "WAV_LoginHistory",
            "name": "WAV_LoginHistory",
            "fields": [
                {
                    "fullyQualifiedName": "WAV_LoginHistory.ApiType",
                    "name":  "ApiType",
                    "type":  "Text",
                    "label": "ApiType",
                    "defaultValue": "Unknown"
                },
                {
                    "fullyQualifiedName": "WAV_LoginHistory.ApiVersion",
                    "name":  "ApiVersion",
                    "type":  "Text",
                    "label": "ApiVersion",
                    "defaultValue": "Unknown"
                },
                {
                    "fullyQualifiedName": "WAV_LoginHistory.Application",
                    "name":  "Application",
                    "type":  "Text",
                    "label": "Application",
                    "defaultValue": "Unknown"
                },
                {
                    "fullyQualifiedName": "WAV_LoginHistory.Browser",
                    "name":  "Browser",
                    "type":  "Text",
                    "label": "Browser",
                    "defaultValue": "Unknown"
                },
                {
                    "fullyQualifiedName": "WAV_LoginHistory.ClientVersion",
                    "name":  "ClientVersion",
                    "type":  "Text",
                    "label": "ClientVersion",
                    "defaultValue": "Unknown"
                },
                {
                    "fullyQualifiedName": "WAV_LoginHistory.Id",
                    "name":  "Id",
                    "type":  "Text",
                    "label": "Id",
                    "defaultValue": "Unknown",
                    "isUniqueId":true
                },
                {
                    "fullyQualifiedName": "WAV_LoginHistory.LoginTime",
                    "name": "LoginTime",
                    "type": "Date",
                    "label": "LoginTime",
                    "format":"yyyy-MM-dd HH:mm:ss",
                    "fiscalMonthOffset":0
                },
                {
                    "fullyQualifiedName": "WAV_LoginHistory.LoginType",
                    "name":  "LoginType",
                    "type":  "Text",
                    "label": "LoginType",
                    "defaultValue": "Unknown"
                },
                {
                    "fullyQualifiedName": "WAV_LoginHistory.LoginUrl",
                    "name":  "LoginUrl",
                    "type":  "Text",
                    "label": "LoginUrl",
                    "defaultValue": "Unknown"
                },
                {
                    "fullyQualifiedName": "WAV_LoginHistory.Platform",
                    "name":  "Platform",
                    "type":  "Text",
                    "label": "Platform",
                    "defaultValue": "Unknown"
                },
                {
                    "fullyQualifiedName": "WAV_LoginHistory.SourceIp",
                    "name":  "SourceIp",
                    "type":  "Text",
                    "label": "SourceIp",
                    "defaultValue": "Unknown"
                },
                {
                    "fullyQualifiedName": "WAV_LoginHistory.Status",
                    "name":  "Status",
                    "type":  "Text",
                    "label": "Status",
                    "defaultValue": "Unknown"
                },
                {
                    "fullyQualifiedName": "WAV_LoginHistory.UserId",
                    "name":  "UserId",
                    "type":  "Text",
                    "label": "UserId",
                    "defaultValue": "Unknown"
                }
            ]
        }
    ]
}
```

# Scheduling
4 Apex classes are available to schedule the different data flows towards Tableau CRM 
* **WAV_DataLoad_SCH** to schedule SOQL extracts
* **WAV_ObjectCountSnapshot_SCH** to schedule object counts snapshots
* **WAV_OrgLimitSnapshot_SCH** to schedule object counts snapshots
* **WAV_PicklistLabelSnapshot_SCH** to schedule picklist label syncs


