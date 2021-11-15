/***
* @description		Test class of the WAV_DataLoad_UTL, WAV_OrgLimitSnapshot_SCH,
*                   WAV_ObjectCountSnapshot_SCH and WAV_LoadPicklistLabels_SCH classes.
*                   Only code coverage objective for now (no real functional test).
* @author	P-E GROS
* @date		April 2020
* @see		WAV_DataLoad_UTL
* @see		WAV_OrgLimitSnapshot_SCH
* @see		WAV_ObjectCountSnapshot_SCH
* @see		WAV_LoadPicklistLabels_SCH
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
public class WAV_DataLoad_UTL_TST {
    
/***
* @description Test of the main WAV_OrgLimitSnapshot_SCH execute logic.
***/  
    static testmethod void testOrgLimitSnapshot() {
        WAV_OrgLimitSnapshot_SCH.execute(null);
    }
/***
* @description Test of the main WAV_ObjectCountSnapshot_SCH execute logic.
***/  
    static testmethod void testObjectCountSnapshot() {
        WAV_ObjectCountSnapshot_SCH.execute(null);
    }
/***
* @description Test of the main WAV_PicklistLabelSnapshot_SCH execute logic.
***/  
    static testmethod void testPicklistLabelSnapshot_SCH() {
        WAV_PicklistLabelSnapshot_SCH.execute(null);
    }
}