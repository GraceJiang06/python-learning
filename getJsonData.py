import sys,os
import httplib
import json
import types

httpClient = None
headers = {'Content-Type': 'application/json'}
host = ""
TELNET = ""
SWITCH = ""
MDU = ""
CABINET = ""
ENODEB = ""

class getErisData():
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
            if (self.hasKeyValue(self.testPlan, ['items'])):
                self.testPlan = self.testPlan['items']

            for hashElement in self.testPlan:
                if "ci_type" in hashElement:
                    if ENODEB in hashElement['ci_type'].upper():
                        self.rbsHash = hashElement
                    if CABINET in hashElement['ci_type'].upper():
                        self.cabinetHash = hashElement
                    if MDU in hashElement['ci_type'].upper():
                        if(self.hasKeyValue(hashElement,['params','Master','value']).lower() == 'true'):
                            self.mduHash = hashElement
                    if TELNET in hashElement['ci_type'].upper() and SWITCH in hashElement['ci_type'].upper():
                        self.switchHash = hashElement
                else:
                    raise AttributeError("ci_type")
        except AttributeError:
            print "can't find some attributes in testplan:\n" + self.tpname
            print ""
        finally:
            print ""

    def hasKeyValue(self, dict, paramsList):
        ref = dict
        try:
            for key in paramsList:
                if isinstance(ref,list):
                    ref = ref[0]
                ref = ref[key]
            return ref
        except AttributeError:
            print "logic for error"
            return False
        finally:
            print ""

    def _getCiAttributes(self, ciName, attribs):
        ref = ""
        try:
            if(ENODEB in ciName ):
                ref = self.rbsHash
            if (CABINET in ciName ):
                ref =self.cabinetHash
            if (TELNET in ciName):
                ref = self.switchHash
            if (MDU in ciName):
                ref = self.mduHash
            return self.hasKeyValue(ref, attribs)
        except Exception, e:
            print "error msg deal"
            return False
        finally:
            print ""

    def getSwitchPort(self):
        return self._getCiAttributes(TELNET, ['relation_list', 'params_ci_1', 'Port'])

    def getSwitchIp(self):
        return self._getCiAttributes(TELNET, ['params','IP interface','value','0','IP','value'])

    def getBroadcastAddress(self):
        return self._getCiAttributes(MDU,['params','Site LAN subnet broadcast address','value'])

    def getNetmask(self):
        return self._getCiAttributes(MDU,['params','Site LAN subnet name','value'])

    def getIp(self):
        return self._getCiAttributes(MDU,['params','Site LAN IP address','value'])

    def getDefaultRouter(self):
        return self._getCiAttributes(MDU,['params','Site LAN subnet default router','value'])

    def getTuSlot(self):
        return self._getCiAttributes(MDU,['params','Slot','value'])

    def getEtSlot(self):
        return self._getCiAttributes(MDU,['params','Slot','value'])

    def getEtPort(self):
        return self._getCiAttributes(MDU,['params','Port','value'])

if __name__ == '__main__':
    ged = getErisData("")
    print ged.getSwitchPort()
    print ged.getSwitchIp()
    print ged.getIp()




