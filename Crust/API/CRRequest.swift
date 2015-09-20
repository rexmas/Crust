import Alamofire

enum CRHTTPMethod : String {
    case GET
}

protocol CRRequest {
    
    var host: String { get }
    var requestUrl: String { get }
    var HTTPMethod: CRHTTPMethod { get }
    var queryParameters: [ String : AnyObject ] { get }
    
    func send()
}

extension CRRequest {
    
    var host: String {
        return "https://api.uber.com/v1/"
    }
    
    func send() {
        
        var paramsArray: Array<String> = Array()
        
        for (key, value) in self.queryParameters  {
            paramsArray.append(key + "=" + "\(value)") // TODO: Not this! (FIST)
        }
        
        var fullPath = host + self.requestUrl
        
        if paramsArray.count > 0 {
            
            let params = paramsArray.joinWithSeparator("&")
            fullPath = fullPath + "?" + params
        }
        
        let URL = NSURL(string: fullPath)!
        let mutableURLRequest = NSMutableURLRequest(URL: URL)
        mutableURLRequest.HTTPMethod = self.HTTPMethod.rawValue
        
        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        mutableURLRequest.setValue("Token VN13RQ21ivJxCHatCirEK1461EEvwNqpfjccIN9-", forHTTPHeaderField: "Authorization")
        
        Alamofire.request(mutableURLRequest)
            .response { (request, response, data, error) in
                print(request)
                print(response)
                print(error)
        }
    }
}
