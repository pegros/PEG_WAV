/***
* @description		This class provides various utility methods to load data
*                   within Einstein Analytics (via the InsightsExternalData and
*                   InsightsExternalDataPart objects).
* @author P-E GROS
* @date   April 2020
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

public class WAV_DataLoad_UTL {
    
/***
* @description	Initializes the main InsightsExternalData record for a given dataset.
*               It assumes that there is a static resource available with exactly the
*               the same name and containing the Analytics JSON dataset description
* @param		dataSetName	Developer name of the target dataset
* @return		InsightsExternalData instance inserted and ready to use
* @Exception	none special.
***/     
    public static InsightsExternalData initLoader(String dataSetName) {
       system.debug('initLoader: START for ' + dataSetName);     
        
       StaticResource MetadataJson = [SELECT Id, Body FROM StaticResource
                                       WHERE Name = :dataSetName LIMIT 1];
       system.debug('initLoader: MetadataJson fetched ' + MetadataJson);     
   
       String metadataBodyStr = MetadataJson.Body.toString();
	   Integer dsNameStart = metadataBodyStr.indexOf('fullyQualifiedName');
	   Integer dsNameEnd = metadataBodyStr.indexOf(',',dsNameStart);
	   String dsName = MetadataBodyStr.substring(dsNameStart + 19,dsNameEnd);
	   dsName = dsName.replaceAll('[" :]','');
	   System.debug('initLoader: DS Name extracted is ' + dsName);

       InsightsExternalData loader = new InsightsExternalData();
       loader.Format        = 'Csv';
       //loader.EdgemartAlias = dataSetName;
       loader.EdgemartAlias = dsName;
       loader.MetadataJson  = MetadataJson.Body;
       loader.Operation     = 'Append';
       loader.Action        = 'None';
       insert loader;
       system.debug('initLoader: END with loader inserted ' + loader.Id); 
       
       return loader;
    }
    
/***
* @description	Adds a new InsightsExternalDataPart record with the data of multiple SOQL records
*               to a given InsightsExternalData record.
* @param		loader			InsightsExternalData record to which the new part should be added
* @param		partContentStr	Content to be added in the new InsightsExternalDataPart
* @Exception    none special.
***/ 
    public static void addDataPart(InsightsExternalData loader, String partContentStr, Integer iteration) {
        system.debug('addDataPart: START for ' + loader.Id);     

        Blob partContent = Blob.valueOf(partContentStr);
        system.debug('addDataPart: partContent size ' + partContent.size());
              
        InsightsExternalDataPart dataPart = new InsightsExternalDataPart();
        dataPart.PartNumber = iteration;
        dataPart.InsightsExternalDataId = loader.Id;
        dataPart.DataFile = partContent;
        insert dataPart;

        system.debug('addDataPart: END with loader inserted ' + dataPart.Id); 
        return;
    }
}