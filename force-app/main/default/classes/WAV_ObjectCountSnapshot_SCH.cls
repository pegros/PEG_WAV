/***
* @description		This class enables to fetch Org snapshot data (counts of object
*                   records) into the WAV_ObjectCounts dataset in Einstein Analytics.
*					It requires the WAV_ObjectCounts JSON dataset metadata file to be
*                   available as static resource and the objects to be counted to be
*                   registered as records of the WAV_OrgSnapshot_CFG__mdt metadata type.
* @author P-E GROS
* @date   April 2020
*
* Legal Notice
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

public class WAV_ObjectCountSnapshot_SCH implements Schedulable {

/***
* @description Entry for schedulable trigger.
* @param       context        Schedulable context (if any).
* @Exception   none special.
***/
    public static void execute(SchedulableContext context) {
        System.debug('WAV_ObjectCountSnapshot_SCH.execute: START');
		
        String objectHeader = '"MeasureDate","ObjectName","RecordCount"\n';
        String objectData	= '';
        //String measureDate  = '' + System.today();
        String measureDate  = '' + System.now();
        
        List<WAV_Snapshot_CFG__mdt> objectList = [	select MasterLabel from WAV_Snapshot_CFG__mdt
                                                 		where DataSet__c = 'WAV_ObjectCounts'
                                                    	and isActive__c = true ];
        System.debug('WAV_ObjectCountSnapshot_SCH.execute: object List fetched with size ' + objectList.size());
        
        if ((objectList == null) || (objectList.size() == 0)) {
            System.debug('WAV_ObjectCountSnapshot_SCH.execute: END / no object to count');
			return;
        }
		  
        for (WAV_Snapshot_CFG__mdt objectIter : objectList ) {
            //system.debug('WAV_ObjectCountSnapshot_SCH.execute: processing objectIter '  + objectIter);
            integer objCount = database.countQuery('select count() from ' + objectIter.MasterLabel);
			objectData += '"' + measureDate + '","' + objectIter.MasterLabel
                        + '","' + objCount + '"\n';
        }
        System.debug('WAV_ObjectCountSnapshot_SCH.execute: objectHeader ready ' + objectHeader);
		System.debug('WAV_ObjectCountSnapshot_SCH.execute: objectData ready '   + objectData);
         
        InsightsExternalData objectLoader = WAV_DataLoad_UTL.initLoader('WAV_ObjectCounts');
		System.debug('WAV_ObjectCountSnapshot_SCH.execute: loader ready');
        WAV_DataLoad_UTL.addDataPart(objectLoader,objectHeader + objectData,1);
        System.debug('WAV_ObjectCountSnapshot_SCH.execute: datapart added');
        objectLoader.Action = 'Process';
        if (!Test.isRunningTest()) update objectLoader;     
		
        System.debug('WAV_ObjectCountSnapshot_SCH.execute: END loading launched');
    } 
}