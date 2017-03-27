import sys,os
import httplib
import json
import types

httpClient = None
headers = {'Content-Type': 'application/json'}
host = ""
TELNET = CONSTANT VALUE
SWITCH = CONSTANT VALUE"
MDU = CONSTANT VALUE
CABINET = CONSTANT VALUE
ENODEB = CONSTANT VALUE

class getJsonData():
    def __init__(self,tpName):
        self.baseUrl = ""
        self.tpname = tpName
        self.URL = self.baseUrl + tpName
        self.testPlan = ""
        self.rbsHash = ""
        self.cabinetHash = ""
        self.switchHash = ""
        self.ntpHash = ""
        self.mduHash = ""
        self._setCiAttributes()


    def _getResponseContent(self):
        try:
            if "https" in self.URL:
                httpClient = httplib.HTTPSConnection(host)
            else:
                httpClient = httplib.HTTPConnection(host)
            httpClient.request(method='GET',url=self.URL,headers=headers)
            response = httpClient.getresponse()
            if response.status >= 200 and response.status < 300 :
                content = response.read()
                if isinstance(content,str):
                    json_acceptable_string = content.replace("'", "\"")
                    return json.loads(json_acceptable_string)
                else:
                    return json.load(content.decode('utf-8'))
            else:
                raise RuntimeError
        except RuntimeError, e:
            print "Error occured:\nReturn code"+response.status+"Reason:"+response.reason+"\nwhen submitted get request for" + self.tpname
        finally:
            if httpClient:
                httpClient.close()

    def _setCiAttributes(self):
        try:
            self.testPlan = self._getResponseContent()
            #if (self.hasKeyValue(self.testPlan, ['items'])):
            self.testPlan = self.testPlan['items']

            for hashElement in self.testPlan:
                if "ci_type" in hashElement:
                    if ENODEB in hashElement['ci_type'].upper():
                        self.rbsHash = hashElement
                        #print self.rbsHash
                    if CABINET in hashElement['ci_type'].upper():
                        self.cabinetHash = hashElement
                        #print self.cabinetHash
                    if MDU in hashElement['ci_type'].upper():
                        if(self.hasKeyValue(hashElement,['params','Master','value']).lower() == 'true'):
                            self.mduHash = hashElement
                            #print self.mduHash
                    if TELNET in hashElement['ci_type'].upper() and SWITCH in hashElement['ci_type'].upper():
                        self.switchHash = hashElement
                        #print self.switchHash
                else:
                    raise AttributeError("ci_type")
        except AttributeError:
            #print "can't find some attributes in testplan:\n" + self.tpname
            print ""
        finally:
            print ""

    def hasKeyValue(self, dict, paramsList):
        ref = dict
        try:
            for key in paramsList:
                print "this is keyname:\n" + key
                print ref
                if isinstance(ref,list):
                    ref = ref[0]
                    print "1111\n"
                    # print ref
                    # print "\n"
                    # print type(ref)
                elif isinstance(ref,dict):
                    ref = ref[key]
                    # print "2222\n"
                    # print ref
                    # print "\n"
                    print type(ref)
                # else:
                #     print "can't find some attribute,key:\n" +key+"\nparams:"+str(paramsList)+"\ntestplan:\n" + self.tpname
                #     raise AttributeError(key)
            return ref
        except AttributeError:
            return False

    def _getCiAttributes(self, ciName, attribs):
        ref = ""
        try:
            if(ENODEB in ciName ):
                ref = self.rbsHash
            if (CABINET in ciName ):
                ref =self.cabinetHash
            if (TELNET in ciName):
                ref = self.switchHash
                #print self.switchHash
            if (MDU in ciName):
                ref = self.mduHash
            return self.hasKeyValue(ref, attribs)
        except Exception, e:
            raise e
        finally:
            print ""

    def getSwitchPort(self):
        return self._getCiAttributes(TELNET, ['relation_list', 'params_ci_1', 'Port'])

    def getSwitchIp(self):
        print "this is getSwitchIp"



if __name__ == '__main__':
    ged = getJsonsData("paramas name")
    print ged.getSwitchPort()
    #print  switchPort


