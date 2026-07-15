/*
Test Classes: TruelinkRestUtilTest,TrueLinkApiHandlerTest
*/

public without sharing class TruelinkRestUtil {
    @testvisible
    String apiURL;
    @testvisible
    String paramString='';
    @testvisible
    HttpRequest req;
    HTTPResponse res;
    Track_API_Call__c trackObj;
    public TruelinkRestUtil(String apiURL){
        this.apiURL = apiURL;
        req = new HttpRequest();
    }
    public TruelinkRestUtil setParams(Map<String,String> paramMap){
        paramString = '?';
        for(String key:paramMap.keySet()){
            paramString += key + '=' +paramMap.get(key) + '&';
        }
        return this;
    }
    public TruelinkRestUtil setEndPoint(String endPoint){
        apiURL += endPoint;
        return this;
    }
    public TruelinkRestUtil setMethod(String method){
        req.setMethod(method);
        return this;
    }
    public TruelinkRestUtil setBody(String body){
        if(String.isNotEmpty(body))
            req.setBody(body);  
        return this;
    }
    public TruelinkRestUtil setHeader(String headerKey, String headerValue){
        req.setHeader(headerKey, headerValue);  
        return this;
    }
    public Track_API_Call__c getTrackObj(){
		if(trackObj == null)
            trackObj =  TrackApiUtil.track(trackObj,req,res,null);
        return trackObj;
    }
    public HTTPResponse send(){
        req.setEndpoint(apiURL+paramString);
        //req.setHeader('Authorization', 'Apikey 60e95ff8-8721-47af-bae5-1b49053e2a1b');
        //req.setHeader('Content-Type', 'application/json');
        system.debug(req);
        Http http = new Http();
        //if(!Test.isRunningTest())
        	res = http.send(req);
        this.logData(null);
        return res;
    }

    public Track_API_Call__c logData(String msg){
        trackObj = TrackApiUtil.track(trackObj,req,res,msg);
        return trackObj;
    }

    public static String formatDate(Date dd){
        return  String.format(
            '{0}-{1}-{2}',
            new String[]{
                String.valueOf(dd.year()),
                String.valueOf(dd.month()).leftPad(2, '0'),
                String.valueOf(dd.day()).leftPad(2, '0')
        });
    }
}