/***
* @description		This class enables to fetch Org snapshot data (Org limits)
*                   into the WAV_OrgLimits dataset in Einstein Analytics.
*					It requires the WAV_OrgLimits JSON dataset metadata file to be
*                   available as static resource and the actual evaluated limit names
*                   to be registered as records of the WAV_OrgSnapshot_CFG__mdt metadata type.
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

public class WAV_OrgLimitSnapshot_SCH implements Schedulable {

/***
* @description Entry for schedulable trigger.
* @param       context        Schedulable context (if any).
* @Exception   none special.
***/
    public static void execute(SchedulableContext context) {
        System.debug('WAV_OrgLimitSnapshot_SCH.execute: START');

        String limitsHeader = '"MeasureDate","Name","Value","Limit"\n';
        String limitsData	= '';
        //String measureDate  = '' + System.today();
        String measureDate  = '' + System.now();

        List<WAV_Snapshot_CFG__mdt> limitList = [	SELECT MasterLabel FROM WAV_Snapshot_CFG__mdt
                                                 		WHERE DataSet__c = 'WAV_OrgLimits'
                                                   		AND isActive__c = true];
		System.debug('WAV_OrgLimitSnapshot_SCH.execute: limit List fetched with size ' + limitList.size());
        
        if ((limitList == null) || (limitList.size() == 0)) {
            System.debug('WAV_OrgLimitSnapshot_SCH.execute: END / no limit to evaluate');
			return;
        }

        Map<String,System.OrgLimit> limitMap = OrgLimits.getMap();
		System.debug('WAV_OrgLimitSnapshot_SCH.execute: Map fetched with size ' + limitMap.size());

        for (WAV_Snapshot_CFG__mdt limitIter :  limitList) {
            //system.debug('WAV_OrgLimitSnapshot_SCH.execute: processing limitKey '  + limitKey);
            System.OrgLimit iterLimit = limitMap.get(limitIter.MasterLabel);
            if (iterLimit != null) {
                //system.debug('WAV_OrgLimitSnapshot_SCH.execute: iterLimit fetched '  + iterLimit);
                limitsData	+= '"'  + measureDate + '","' + limitIter.MasterLabel 
                            + '","' + iterLimit.getValue() + '","' + iterLimit.getLimit() + '"\n';
            }
            else {
                System.debug(LoggingLevel.WARN,'WAV_OrgLimitSnapshot_SCH.execute: limit not found ' + limitIter.MasterLabel);
            }
        } 
        System.debug('WAV_OrgLimitSnapshot_SCH.execute: limitsHeader ready ' + limitsHeader);
		System.debug('WAV_OrgLimitSnapshot_SCH.execute: limitsData ready ' + limitsData);

        InsightsExternalData limitLoader = WAV_DataLoad_UTL.initLoader('WAV_OrgLimits');
		System.debug('WAV_OrgLimitSnapshot_SCH.execute: loader ready');
        WAV_DataLoad_UTL.addDataPart(limitLoader,limitsHeader + limitsData,1);
        System.debug('WAV_OrgLimitSnapshot_SCH.execute: datapart added');
        limitLoader.Action = 'Process';
        if (!Test.isRunningTest()) update limitLoader;
  
        System.debug('WAV_OrgLimitSnapshot_SCH.execute: END loading launched');
    }
}