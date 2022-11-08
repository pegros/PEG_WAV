/***
* @description		This class enables to load data extracted via SOQL
*					into custom datasets in Analytics.
*					It relies on the WAV_DataLoad_CFG__mdt custom metadata
*					for configuration and requires Analytics JSON dataset
*					metadata files to be loaded as static resources.
* @author P-E GROS
* @date   Nov 2018
*
* Legal Notice
* 
* MIT License
* 
* Copyright (c) 2018 pegros
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

public class WAV_DataLoad_SCH implements Schedulable {

/***
* @description Entry for schedulable trigger.
* @param       context        Schedulable context (if any).
* @Exception   none special.
***/
    public static void execute(SchedulableContext context) {
        
        WAV_DataLoad_CFG__mdt[] datasetList;
        if (Test.isRunningTest()) {
            datasetList = [select DeveloperName
                           from WAV_DataLoad_CFG__mdt
                           where DeveloperName = 'WAV_Test'];
        } else {
            datasetList = [select DeveloperName
                           from WAV_DataLoad_CFG__mdt
                           where isActive__c = true];
        }
        system.debug('execute datasetList fetched / size ' + datasetList.size());
        
        
        for (WAV_DataLoad_CFG__mdt iterDS : datasetList) {
            WAV_DataLoad_SCH.executeSynch(iterDS.DeveloperName);
        }
        system.debug('execute all dataset synch requested ');
    }
        
/***
* @description Launches a queuable process to process a specific dataset import.
* @param       dataSetName        Developer name of the WAV_DataLoad_CFG__mdt record to process.
* @Exception   none special.
***/
    public static void executeSynch(String dataSetName) {
        System.debug('executeSynch for dataset ' + dataSetName);
        
        WAV_DataLoad_CFG__mdt configElt = [ SELECT  DeveloperName, MasterLabel, FieldMapping__c, Operation__c, 
                                                    MaxRowsPerFile__c, MetaJson__c, Query__c, OrderBy__c 
                                            FROM WAV_DataLoad_CFG__mdt
                                            WHERE DeveloperName = :dataSetName ][0];
        system.debug('executeSynch configElt fetched ' + configElt);
        
        WAV_DataLoad_QUE processJob = new WAV_DataLoad_QUE(configElt);
        ID jobID = System.enqueueJob(processJob);
        system.debug('executeSynch processing job launched: ' + jobID);
        
        return;
    }
}