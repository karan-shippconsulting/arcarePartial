public class TrackApiUtil {
    public static Track_API_Call__c track(Track_API_Call__c trackObj,HttpRequest req,HttpResponse resp,String errorMsg){

        if(req == null && resp == null && errorMsg == null)
            throw new ArgumentException('Request and Response can not be null');

        Track_API_Call__c track=new Track_API_Call__c();

        if(trackObj != null){
            track.Id = trackObj.Id;
        }

        if(req != null){
            track.Http_Method__c = req.getMethod();
        //    track.IP_address__c = req.remoteAddress;
            
            Integer requestBdyLength = req.getBody().toString().length() < 13107 ? req.getBody().toString().length() : 13107;
            
            track.Request__c = req.getBody().toString().substring(0, requestBdyLength);
            track.Request_URL__c = req.getEndpoint();
        }

        if(errorMsg != null && String.isNotEmpty(errorMsg)){
            track.Error_Message__c = errorMsg;
            track.Status__c = 'Error';
        }

        if(resp != null){
            Integer responseBdyLength = resp.getBody().toString().length() < 13107 ? resp.getBody().toString().length() : 13107;
            track.Response__c = resp.getBody().toString().substring(0,responseBdyLength);
            track.StatusCode__c =  resp.getStatusCode();
			track.Status__c = (track.StatusCode__c >= 200 && track.StatusCode__c <= 300) || track.Error_Message__c == null ? 'Success': 'Error';
        }
        
        Database.upsert(track, Track_API_Call__c.Id, false);
        return track;
    }

    class ArgumentException extends Exception{}
}