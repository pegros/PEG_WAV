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
SOQL based data feed rely on the WAV_DataLoad_CFG custom metadata to configure
* **WAV_DataLoad_CFG** to configure the various custom data loads (basd on SOQL queries) 
![Login History Example](/media/SoqlData.png)
* **WAV_Snapshot_CFG** to configure the various snapshots (org limits, object counts, picklist labels)
![Picklist Labels](/media/PicklistLabel.png)
![Prg Limit](/media/OrgLimit.png)
![Object Count](/media/ObjectCount.png)

# Scheduling
4 Apex classes are available to schedule the different data flows towards Tableau CRM 
* **WAV_DataLoad_SCH** to schedule SOQL extracts
* **WAV_ObjectCountSnapshot_SCH** to schedule object counts snapshots
* **WAV_OrgLimitSnapshot_SCH** to schedule object counts snapshots
* **WAV_PicklistLabelSnapshot_SCH** to schedule picklist label syncs

#Examples

**  Load User Login History

