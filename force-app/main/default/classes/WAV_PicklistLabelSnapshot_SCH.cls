/***
* @description		This class enables to fetch picklist labels into the WAV_PicklistLabels
*                   dataset in Einstein Analytics.
*					It requires the WAV_PicklistLabels JSON dataset metadata file to be
*                   available as static resource and the picklist fields (the labels of
*                   which are to be loaded) to be registered as records of the
*                   WAV_OrgSnapshot_CFG__mdt metadata type.
* @author P-E GROS
* @date   April 2020
* 
* MIT License
* 
* Copyright (c) 2020 pegros
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
***/

public class WAV_PicklistLabelSnapshot_SCH implements Schedulable {

/***
* @description Entry for schedulable trigger.
* @param       context        Schedulable context (if any).
* @Exception   none special.
***/
    public static void execute(SchedulableContext context) {
        System.debug('WAV_PicklistLabelSnapshot_SCH.execute: START');
    	
        String picklistHeader = '"FullName","ObjectName","FieldName","Code","Label","isActive","isDefault"\n';
        System.debug('WAV_PicklistLabelSnapshot_SCH.execute: picklistHeader ready ' + picklistHeader);

        List<WAV_Snapshot_CFG__mdt> picklistList = [	select MasterLabel from WAV_Snapshot_CFG__mdt
                                                 		where DataSet__c = 'WAV_PicklistLabels'
                                                      	and isActive__c = true];
        System.debug('WAV_PicklistLabelSnapshot_SCH.execute: picklist List fetched with size ' + picklistList.size());
        
        if ((picklistList == null) || (picklistList.size() == 0)) {
            System.debug('WAV_PicklistLabelSnapshot_SCH.execute: END / no picklist field to process');
			return;
        }

        Map<String, Schema.SObjectType> globalDesc = Schema.getGlobalDescribe();         
        InsightsExternalData picklistLoader = WAV_DataLoad_UTL.initLoader('WAV_PicklistLabels');
        picklistLoader.Operation = 'Overwrite';
		System.debug('WAV_PicklistLabelSnapshot_SCH.execute: loader ready');
        
        Integer iteration = 1;
        for (WAV_Snapshot_CFG__mdt picklistIter : picklistList ) {
            system.debug('WAV_PicklistLabelSnapshot_SCH.execute: processing picklistIter '  + picklistIter);
            String[] picklistParts = picklistIter.MasterLabel.split('\\.');
            String picklistRoot = '"' + picklistIter.MasterLabel + '","' + picklistParts[0] + '","' + picklistParts[1] + '",';
            system.debug('WAV_PicklistLabelSnapshot_SCH.execute: picklistRoot set '  + picklistRoot);
            
            Schema.DescribeSObjectResult	objectDesc	= globalDesc.get(picklistParts[0]).getDescribe();
            Schema.DescribeFieldResult		fieldDesc	= objectDesc.fields.getMap().get(picklistParts[1]).getDescribe();
            system.debug('WAV_PicklistLabelSnapshot_SCH.execute: fieldDesc fetched '  + fieldDesc);
            
            List<Schema.PicklistEntry>		fieldValues = fieldDesc.getPicklistValues();
            system.debug('WAV_PicklistLabelSnapshot_SCH.execute: fieldValues fetched with size '  + fieldValues.size());

            String picklistData	  = '';
            for(Schema.PicklistEntry iterValue : fieldValues) {
            	system.debug('WAV_PicklistLabelSnapshot_SCH.execute: processing picklist value '  + iterValue);
                picklistData += picklistRoot + '"' + iterValue.getValue() + '","' + iterValue.getLabel()
                                             + '","' + iterValue.isActive() + '","' + iterValue.isDefaultValue() + '"\n';
            }
			System.debug('WAV_PicklistLabelSnapshot_SCH.execute: picklistData ready ' + picklistData);
            
            if (iteration == 1) {
        		System.debug('WAV_PicklistLabelSnapshot_SCH.execute: datapart added for first iteration (with header)');
            	WAV_DataLoad_UTL.addDataPart(picklistLoader,picklistHeader + picklistData,iteration);
            }
            else {
        		System.debug('WAV_PicklistLabelSnapshot_SCH.execute: datapart added for iteration ' + iteration);
            	WAV_DataLoad_UTL.addDataPart(picklistLoader,picklistData,iteration);                
            }
            iteration += 1;
        }
        System.debug('WAV_PicklistLabelSnapshot_SCH.execute: all picklists processed');
         
        picklistLoader.Action = 'Process';
        if (!Test.isRunningTest()) update picklistLoader; 
		
        System.debug('WAV_PicklistLabelSnapshot_SCH.execute: END loading launched');
    }
}