/***
* @description		This class enables to load data extracted via SOQL
* 					into custom datasets in Analytics.
* 					It relies on the WAV_DataLoad_CFG__mdt custom metadata
* 					for configuration and requires Analytics JSON dataset
* 					metadata files to be loaded as static resources.
* 					This is the Queuable migration of the initial design
* 					to enhance bulkification of the process
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

public class WAV_DataLoad_QUE implements Queueable {
    
    private String                   processName;
    private String                   query;
    private String                   orderByField;
    private String                   lastFieldValue;
    private Integer                  offset;
    private Integer                  iteration;    
    private InsightsExternalData     loader;
    private Map<String,list<String>> fieldMap;
    private Boolean                  hasRelationFields;
    private String                   header;
    private Datetime                 startTS;
    
/***
* @description Constructor for process launch.
* @param       dataSet        Developer name of the WAV_DataLoad_CFG__mdt record to be processed
* @Exception   none special.
***/
    public WAV_DataLoad_QUE(WAV_DataLoad_CFG__mdt dataSet) {
               
        this.startTS = System.now();
        this.processName = dataSet.DeveloperName;
        this.iteration = 0;
        system.debug('initializing DataLoad process ' + this.processName
                    + ' for iteration ' + this.iteration);
        
        this.query = dataSet.Query__c;
        system.debug('initializing query --> ' + this.query);
        
        this.orderByField = dataSet.OrderBy__c;
        system.debug('initializing orderByField --> ' + this.orderByField);
        
        // ignoring lastFieldValue on first iteration.
        this.lastFieldValue = '';
            
        this.offset = (Integer)(dataSet.MaxRowsPerFile__c);
        system.debug('initializing query --> ' + this.offset);
            
        initLoader(dataSet);
        system.debug('initializing loader --> ' + this.loader);
       
        initFieldMap(dataSet);
        system.debug('initializing fieldMap --> '          + this.fieldMap);
        system.debug('initializing hasRelationFields --> ' + this.hasRelationFields);
        system.debug('initializing header --> '            + this.header);
    }
    
/***
* @description Constructor for process continuation.
* @Exception   none special.
***/
    public WAV_DataLoad_QUE(String               	processName,
                            String               	query,
                            String               	orderByField,
                            String	             	lastFieldValue,
                            Integer              	offset,
                            Integer              	iteration,
                            InsightsExternalData 	loader,
                            Map<String,list<String>> fieldMap,
                            Boolean              	hasRelationFields,
                            String               	header,
                            Datetime             	startTS) {
        System.debug('continuing DataLoad process ' + processName
                    + ' for iteration ' + iteration
                    + ' after value '   + lastFieldValue);
        this.processName       = processName;
        this.query             = query;
        this.orderByField      = orderByField;
        this.lastFieldValue    = lastFieldValue;
        this.offset            = offset;
        this.iteration         = iteration;
        this.loader            = loader;
        this.fieldMap          = fieldMap;  
        this.hasRelationFields = hasRelationFields;  
        // ignoring header on subsequent data parts.                  
        this.header            = '';
        this.startTS           = startTS; 
    }
    
/***
* @description Main process execution : iterates on all datasets declared in the configuration.
* @Exception   none special.
***/   
    public void execute(QueueableContext context) {
        System.debug('execute DataLoad process ' + processName
                   + ' for iteration ' + iteration);
        
        Integer partNbr = processDS();
        if (partNbr < offset) {
            system.debug('execute DataLoad process ' + processName
                       + ' completed at iteration '  + iteration);
            loader.Action = 'Process';
            update loader;
            system.debug('execute loader action triggered ' + loader);
            if (!Test.isRunningTest()) {
              ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(
                'internal', 'me',
                ConnectApi.FeedElementType.FeedItem,
                '### WAV Dataload processed for ' + processName + ' data ###\n\n'
                + 'started at ' + startTS + ' and ended at ' + System.now() + '\n'
                + 'completed after ' + (iteration + 1) + ' iteration(s) (' + (iteration * offset + partNbr) + ' records fetched).');
            }
        } else {
            system.debug('execute DataLoad process '  + processName
                       + ' requeued after iteration ' + iteration);
            WAV_DataLoad_QUE continueJob = new WAV_DataLoad_QUE(
                             processName, query, orderByField, lastFieldValue,
                             offset, (iteration + 1), loader, fieldMap, hasRelationFields, header,startTS);
            ID jobID = System.enqueueJob(continueJob); 
            system.debug('execute continuation job launched: ' + jobID);
        }
    }

/***
* @description Unitary process execution : sequences all the operation to fetch 
*              and upload data to Analytics for a given dataset at a given offset.
*              Returns the actual number of rows processed.
* @Exception   none special.
***/  
    public Integer processDS() {
       system.debug('processDS START'); 
       String offsetQuery = getOffsetQuery();
       system.debug('processDS processing SOQL ' + offsetQuery);
           
       String loaderFileStr = header;
       system.debug('processDS data file header initialized ' + loaderFileStr);
       
       Integer rowNbr = 0;
       for (SObject iterObj : database.query(offsetQuery)) {
           system.debug('processDS processing object ' + iterObj);
           loaderFileStr += formatDataLine(fieldMap,hasRelationFields,iterObj);
           rowNbr += 1;
           lastFieldValue = String.valueOf(iterObj.get(orderByField));
       }
       system.debug('processDS data file content prepared with '
                    + rowNbr + ' rows.');
       addDataPart(loaderFileStr);
                       
       system.debug('processDS END: data file stored ');
       return rowNbr;
    }
    
/***
* @description Private helper classes for Initialization.
*              Initializes the main InsightsExternalData record.
* @Exception   none special.
***/     
    private void initLoader(WAV_DataLoad_CFG__mdt dataSet) {
        
       system.debug('initLoader: START');
       StaticResource MetadataJson = [SELECT Id, Body FROM StaticResource
                                       WHERE Name = :dataSet.MetaJson__c LIMIT 1];
       system.debug('initLoader: MetadataJson fetched ' + MetadataJson);     
   
	   String metadataBodyStr = MetadataJson.Body.toString();
	   Integer dsNameStart = metadataBodyStr.indexOf('fullyQualifiedName');
	   //System.debug('initLoader: DS Name declare start is ' + dsNameStart);
	   Integer dsNameEnd = metadataBodyStr.indexOf(',',dsNameStart);
	   //System.debug('initLoader: DS Name declare end is ' + nameEnd);
	   String dsName = MetadataBodyStr.substring(dsNameStart + 19,dsNameEnd);
	   //System.debug('initLoader: DS Name declaration extracted is ' + nameStr);
	   dsName = dsName.replaceAll('[" :]','');
	   System.debug('initLoader: DS Name extracted is ' + dsName);
        
       this.loader = new InsightsExternalData();
       this.loader.Format        = 'Csv';
       //this.loader.EdgemartAlias = dataSet.DeveloperName;
       //this.loader.EdgemartAlias = dataSet.MetaJson__c;
       this.loader.EdgemartAlias = dsName;
       this.loader.MetadataJson  = MetadataJson.Body;
       //this.loader.Operation     = 'Overwrite';
       this.loader.Operation     = dataSet.Operation__c;
       this.loader.Action        = 'None';
       system.debug('initLoader: loader initialized ' + loader);
       insert this.loader;
       //system.debug('initLoader END: loader inserted --> ' + this.loader); 
       system.debug('initLoader END: loader inserted'); 
       
       return;
    }

/***
* @description Private helper classes for Initialization.
*              Initializes the map to relate SOQL fields with EA dataset fields.
* @Exception   none special.
***/       
    private void initFieldMap(WAV_DataLoad_CFG__mdt dataSet) {
        system.debug('initFieldMap START');
        
        this.hasRelationFields = false;
        this.fieldMap = new Map<String,list<String>>();
        JSONParser parser = JSON.createParser(dataSet.FieldMapping__c);

        this.header = '';
        String dsFieldName, objFieldName;
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                dsFieldName = parser.getText();
                //system.debug('initFieldMap dsFieldName found --> ' + dsFieldName);
                parser.nextToken();
                objFieldName = parser.getText();
                //system.debug('initFieldMap objFieldName found --> ' + objFieldName);
                
                //fieldMap.put(dsFieldName,objFieldName);
                list<string> fieldNameItems = objFieldName.split('\\.');
                this.fieldMap.put(dsFieldName,fieldNameItems);
                //system.debug('initFieldMap field inserted --> ' + fieldNameItems);
                if (objFieldName.contains('.')) {
                    system.debug('initFieldMap relationship found');
                    this.hasRelationFields = true;
                }
                this.header += '"' + dsFieldName + '",';
                //system.debug('initFieldMap adding ' + dsFieldName + ' / ' + objFieldName);
            } 
        }
        //system.debug('initFieldMap field map initialized  ' + this.fieldMap);
        //system.debug('initFieldMap hasRelationFields init ' + this.hasRelationFields);
        
        this.header = header.removeEnd(',');
        this.header += '\n';
        //system.debug('initFieldMap END : data file header initialized ' + header);
        
        return;
    }
    
/***
* @description Private helper classes for Execution.
*              Generates the output data line for a given SOQL record.
* @Exception   none special.
***/       
    @TestVisible
    private String formatDataLine(	map<String,list<String>> fieldMap,
                                 	Boolean	hasRelationFields,
                                 	SObject objRecord) {
       //system.debug('formatDataLine processing object ' + objRecord);
       String dataLine = '';
       Object fieldValue = null;
            
       if (hasRelationFields){
           
           for (String fieldKey : fieldMap.keySet() ) {
               //system.debug('formatDataLine processing fieldKey '  + fieldKey);
               //system.debug('formatDataLine processing fieldName ' + fieldMap.get(fieldKey));
               Iterator<String> iterator = (fieldMap.get(fieldKey)).iterator();
               SObject objectIter = objRecord;
               
               while (iterator.hasNext()) {
                   String fieldName = iterator.next();
                   //system.debug('formatDataLine processing token ' + fieldName);

                   if (objectIter != null) {
                       if (!iterator.hasNext()) {
                           fieldValue = objectIter.get(fieldName);
                       } else {
                           objectIter = objectIter.getSobject(fieldName);
                       }
                   } else {
                       fieldValue = '';
                   }
               }   
               //system.debug('formatDataLine field value fetched  ' + fieldValue);    

               if (fieldValue != null) {
                   //dataLine += '"' + String.valueOf(objRecord.get(fieldMap.get(fieldKey))).remove('"') + '",';
                   dataLine += '"' + String.valueOf(fieldValue).remove('"') + '",';
               } else {
                   dataLine += '"",';
               }
           }
       } else {
           for (String fieldKey : fieldMap.keySet() ) {
               //system.debug('formatDataLine processing fieldKey '  + fieldKey);
               //system.debug('formatDataLine processing fieldName ' + fieldMap.get(fieldKey));
               fieldValue = objRecord.get((fieldMap.get(fieldKey))[0]);
          
               if (fieldValue != null) {
                   //dataLine += '"' + String.valueOf(objRecord.get(fieldMap.get(fieldKey))).remove('"') + '",';
                   dataLine += '"' + String.valueOf(fieldValue).remove('"') + '",';
               } else {
                   dataLine += '"",';
               }
           }
       }
       dataLine = dataLine.removeEnd(',');
       dataLine += '\n';   
       system.debug('formatDataLine dataLine formatted '  + dataLine);
        
       return dataLine;
    }

/***
* @description Private helper classes for Execution
*              Adds a new InsightsExternalDataPart record with the data of multiple SOQL records
* @Exception   none special.
***/ 
    private void addDataPart(String partContentStr) {
        
        Blob partContent = Blob.valueOf(partContentStr);
        system.debug('addDataPart partContent size ' + partContent.size());
              
        InsightsExternalDataPart dataPart = new InsightsExternalDataPart();
        dataPart.PartNumber = iteration + 1;
        dataPart.InsightsExternalDataId = loader.Id;
        dataPart.DataFile = partContent;
        //system.debug('addDataPart dataPart initialized ' + dataPart);

        insert dataPart;
        //system.debug('addDataPart dataPart inserted ' + dataPart);
        
        return;
    }
    
/***
* @description Private helper classes for Execution
*              Generates the proper offset query for each iteration.
* @Exception   none special.
***/ 
    @TestVisible
    private String getOffsetQuery() {       
       String resultQuery = this.query;
       if (iteration != 0) {
           // keeping standard query for first iteration
           if (resultQuery.contains('WHERE')
               || resultQuery.contains('where')
               || resultQuery.contains('Where')) {
               // adding offset condition in existing where clause
               resultQuery = resultQuery + ' AND ';
           } else {
               // adding new where clause with offset condition
               resultQuery = resultQuery + ' WHERE ';
           }
           resultQuery = resultQuery + this.orderByField + ' > \'' + this.lastFieldValue + '\'';
       }
       resultQuery =   resultQuery + ' ORDER BY ' + this.orderByField + ' LIMIT ' + this.offset;
       
       return resultQuery;
    }
}