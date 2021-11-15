/***
* @description		Test class of the WAV_DataLoad_SCH class.
*                   Only code coverage objective for now (no real functional test).
* @author	P-E GROS
* @date		Nov 2018
* @see		WAV_DataLoad_SCH
* @see		WAV_DataLoad_QUE
* @todo		Implement test result assertions
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

@istest
class WAV_DataLoad_QUE_TST {

/***
* @description Test of the main WAV_DataLoad_SCH execute logic.
***/  
    static testmethod void testExecuteSynch() {
        
       WAV_DataLoad_SCH.execute(null);
       
       WAV_DataLoad_QUE testQueue = new WAV_DataLoad_QUE('test','soql','Id','Id0000',1,1,null,null,null,'test',System.now());
       
    }

/***
* @description Test of the main formatDataLine logic to increase code coverage
***/      
    static testmethod void testFormatDataLine() {                
       Map<String,list<String>> fieldMap = new Map<String,list<String>>
                  {'Client'   => new list<String> {'Name'},
                   'Location' => new list<String> {'Site'},
                   'Source'   => new list<String> {'AccountSource'}};
       Account testObj = new Account(Name='testA',site='testS');
        
       system.debug('testFormatDataLine: testObj'  + testObj);
       system.debug('testFormatDataLine: fieldMap' + fieldMap);
        
       WAV_DataLoad_QUE queue = new WAV_DataLoad_QUE(
                            'TESTProcess','select Name from Account', 'Id','Id0000',5,1,null,fieldMap,false,
                            'Client,Location,Source',System.now());
        
       String returnStr = queue.formatDataLine(fieldMap,false,testObj);
       System.assertEquals('"testA","testS",""\n',returnStr);
        
       User testUser = new User(LastName='testU');
       testObj.owner = testUser;
       fieldMap.put('Owner',new list<String> {'Owner','LastName'}) ;   
        system.debug('testFormatDataLine: testUser' + testUser);
       system.debug('testFormatDataLine: testObj2'  + testObj);
       system.debug('testFormatDataLine: fieldMap2' + fieldMap);
       returnStr = queue.formatDataLine(fieldMap,true,testObj);
       System.assertEquals('"testA","testS","","testU"\n',returnStr); 
    }
    
/***
* @description Test of the getOffsetQuery logic to increase code coverage
***/     
    static testmethod void testGetOffsetQuery() {     
       Map<String,list<String>> fieldMap = new Map<String,list<String>>
                  {'Client'   => new list<String> {'Name'},
                   'Location' => new list<String> {'Site'},
                   'Source'   => new list<String> {'AccountSource'}};
       //Map<String,String> fieldMap = new Map<String,String> {'Client' => 'Name', 'Location' => 'Site', 'Source' => 'AccountSource' };
       //Account testObj = new Account(Name='test',site='test');
        
       WAV_DataLoad_QUE queueWhere = new WAV_DataLoad_QUE(
                            'TESTProcess','select Name from Account Where Name like \'%TST%\'', 'Id','Id0000',5,1,null,fieldMap,false,
                            'Client,Location,Source',System.now());
       WAV_DataLoad_QUE queueNoWhere = new WAV_DataLoad_QUE(
                            'TESTProcess','select Name from Account', 'Id','Id0000',5,1,null,fieldMap,false,
                            'Client,Location,Source',System.now());
        
       String queryWhere   = queueWhere.getOffsetQuery();
       System.assertEquals('select Name from Account Where Name like \'%TST%\' AND Id > \'Id0000\' ORDER BY Id LIMIT 5',
                           queryWhere);
        
       String queryNoWhere = queueNoWhere.getOffsetQuery();
       System.assertEquals('select Name from Account WHERE Id > \'Id0000\' ORDER BY Id LIMIT 5',
                           queryNoWhere);
        
    }
        
}