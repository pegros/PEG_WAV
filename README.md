# PEG WAV Components

The WAV package aims at bypassing various limitations on the current Einstein Analytics / Tableau CRM integration with Salesforce core platform. It is a set of Apex tools enabling to perform (and schedule) various load/update operations within Einstein Analytics external datasets right from Salesforce core.

It addresses especially the following needs:
* load data via SOQL queries (for non sync visible standard objects or to implement delta upsert)
* sync picklist label values (via Schema describe() operations) to get proper picklist labels instead of codes in dashboards
* take Object count snapshots (via count() queries) for capacity planning
* take Org limits measurement snapshots (leveraging the [System.OrgLimit](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_System_OrgLimit.htm) class) for capacity planning and platform monitoring

It is highly configurable, the set of data to load being determined via Custom Metadata entries and the target Tableau CRM dataset being described in static resources. It indeed leverages the standard [external data API](https://developer.salesforce.com/docs/atlas.en-us.bi_dev_guide_ext_data.meta/bi_dev_guide_ext_data/bi_ext_data_overview.htm) to push Salesforce 
data into Tableau CRM datasets.


# Package Content

The package contains the following main components:
* 4 Schedulable Apex classes
    * **WAV_DataLoad_SCH** : to schedule SOQL query based data load
    * **WAV_PicklistLabelSnapshot_SCH** : to schedule the loading of picklist labels
    * **WAV_OrgLimitSnapshot_SCH** : to schedule the loading of Org Limits snapshots
    * **WAV_ObjectCountSnapshot_SCH** : to schedule the loading of Object counts
* 2 Utility Classes
    * **WAV_DataLoad_QUE** : queuable class used by theWAV_DataLoad_SCH scheduled apex class (asynchronous mass data load)
    * **WAV_DataLoad_UTL** : utility class used by the other schedulable apex classes to synchronously load data with EA.
* 2 Custom Metadata
    * **WAV_DataLoad_CFG__mdt** : configuration of the SOQL queries & mapping to target dataset for the WAV_DataLoad_SCH scheduled apex class 
    * **WAV_Snapshot_CFG__mdt** : configuration of the measures/objects/picklists to process for the other schedulable apex classes
* Static Resources
    * **WAV_LoginHistory** : JSON Dataset description to load the LoginHistory object (via WAV_DataLoad_SCH)
    * **WAV_Test** : JSON Dataset description for. tests of the WAV_DataLoad_QUE class.
    * **WAV_PicklistLabels** : JSON Dataset description used as target by the WAV_PicklistLabelSnapshot_SCH class
    * **WAV_OrgLimits** : JSON Dataset description used as target by the WAV_OrgLimitSnapshot_SCH class
    * **WAV_ObjectCounts** : JSON Dataset description used as target by the WAV_ObjectCountSnapshot_SCH class


# Installation

To retrieve the SFDX project, you may simply execute a git clone from the GitHub repository.
```
git clone git@github.com:pegros/PEG_WAV.git
```

Via SFDX you may then deploy it on you Org
```
sfdx force:source:deploy -u <yourOrgAlias> -w 10 --verbose -p force-app
```


# Configuration

Process configuration rely on 
* schedulable Apex standard properties to define when to execute each process 
* custom metadata records (prefixed as _**WAV\_**_) to define the scope and way the data flows towards Tableau CRM should be executed
* static resources (prefixed as _**WAV\_**_ for the package ones) to provide the target Tableau CRM dataset JSON description files

This configuration actually depends on the type of process, with the following 2 options:
* DataLoad (via SOQL queries)
* Snapshots & Label syncs


## DataLoad Configuration

Configuration for the **WAV_DataLoad_SCH** processes primarily relies on **WAV_DataLoad_CFG** custom metadata records 
to define the SOQL queries to use and their mappings with the applicable Tableau CRM datasets.
![Login History Example](/media/SoqlData.png)


On the **WAV_DataLoad_CFG__mdt** records, the most important fields are;
* The _Operation_ field, which indicates how the data should be pushed into Einstein Analytics (i.e. overwrite, delete, append, upsert).
    * Beware that one field needs to be marked as _isUniqueId_ in the JSON dataset definition file in some cases.
* The _Query_ field, which provides the core SOQL query to execute without _ORDER BY_ or _LIMIT_ statements
  (which are set by the process)
* The _OrderBy_ and _MaxRowsPerFile_ fields, which control how the queries are iterated
    * “order by“ and ”limit“ statements as well as additional _WHERE_ condition, to support massive data loads and avoid the standard _OFFSET_ governor limits
    * the best option being to leverage the record _Id_ as _OrderBy_ value and the _MaxRowsPerFile_ needing to be tuned to avoid the 10 MB / datapart in the external data load.
* The _Metadata_ field, which indicates which provides the name of the static resource to be used to fetch the JSON description files of the Tableau CCRM target dataset.
* The _FieldMapping_ field which should contain a JSON _mapping_ object, providing for each target Dataset field the source field extracted from the SOQL query results (lookup relation paths may be used).

As an example, the _FieldMapping_ field for the _LoginHistory_ data feed may be defined as follow:
```
{
    "ApiType": "ApiType",
    "ApiVersion":"ApiVersion",
    "Application":"Application",
    "Browser":"Browser",
    "ClientVersion":"ClientVersion",
    "Id":"Id",
    "LoginTime":"LoginTime",
    "LoginType":"LoginType",
    "LoginUrl":"LoginUrl",
    "Platform":"Platform",
    "SourceIp":"SourceIp",
    "Status":"Status",
    "UserId":"UserId"
}
```

The _**Metadata**_ field should provide the name of a static resource containing the JSON description of the
Tableau CRM dataset to ccreate/update, leveraging the standard Tableau CRM [External Data Format](https://resources.docs.salesforce.com/234/latest/en-us/sfdc/pdf/bi_dev_guide_ext_data_format.pdf)

As an example, the following static resource may be defined to store the _LoginHistory_ data in Tableau CRM:
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


## Snapshot Configuration

Configuration for the snapshots processes primarily relies on **WAV_Snapshot_CFG** custom metadata records 
to define the elements to be synced/measured. 
* for the **WAV_PicklistLabelSnapshot_SCH** process
![Picklist Labels](/media/PicklistLabel.png)
* for the **WAV_OrgLimitSnapshot_SCH** process
![Org Limit](/media/OrgLimit.png)
* for the **WAV_ObjectCountSnapshot_SCH** process
![Object Count](/media/ObjectCount.png)


In each **WAV_Snapshot_CFG** record,
* The _DataSet_ field should be set according to the target dataset
* The label of these records should contain
    * the picklist name as _ObjectApiName.FieldApiName_ for Picklist Labels (e.g. _Contract__c.Status__c_)
    * the _measure_ name for Org Limits (e.g. _DailyApiRequests_, see [_System.OrgLimits.getMap()_](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_System_OrgLimit.htm) to retrieve the possible values on the Org, which may evolve with Salesforce releases)
    * the _object_ API name for Object Counts (e.g. _Contract__c_)
* The _isActive_ may be set to _true_ if you want the record to be 

For the **WAV_Snapshot_CFG** records, the static resources describing the target Tableau datasets are provided
by the package and should not be modified. The target Datasets generated are:
* **WAV_PicklistLabels** for the Picklist labels sync
* **WAV_ObjectCounts** for the Object count snapshots
* **WAV_OrgLimits** for the Org limit snapshots

Notes:
* Picklist labels are loaded in “overwrite” mode 
* Org limits and Object counts are loaded in “append” mode
* The _MeasureDate_ field of the Org limits dataset is a real “dateTime“, which enables to generate multiple snapshots per day if necessary and leverage a ”Year-Month-Day-Hour” date grouping.


## Scheduling

4 Apex classes are available to schedule the different data flows towards Tableau CRM 
* **WAV_DataLoad_SCH** to schedule SOQL extracts
* **WAV_ObjectCountSnapshot_SCH** to schedule object counts snapshots
* **WAV_OrgLimitSnapshot_SCH** to schedule object counts snapshots
* **WAV_PicklistLabelSnapshot_SCH** to schedule picklist label syncs

For each schedulable Apex process, only custom metadata records with _isActive_ property set to true
are taken into account.

Manual launch is possible via the console in anonymous mode leveraging the
_**WAV_DataLoad_SCH.executeSynch(dataSetName)**_ static method (even if
_isActive_ is set to false)


## Monitoring

When completing a SOQL data load, a summary chatter post is automatically generated.
![Login History Example](/media/ExecutionPost.png)
The author of theses posts is the one used to run the schedulable Apex class.


# Usage Guide

## Picklist Label Usage in Tableau CRM
The **WAV_Picklists** dataset may be then used in the followin

It may be first loaded via an _edgemart_ step
![Picklist Data Flow Example](/media/PicklistDataFlow.png)

then filtered via a _filter_ step
![Picklist Filter Step Example](/media/PicklistFilterStep.png)

then added to the target dataset via an _augment_ step
![Picklist Augment Step Example](/media/PicklistAugmentStep.png)












