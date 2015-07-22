import Alamofire

enum CRHTTPMethod : String {
    case GET = "GET"
}

protocol CRUberRequest {
    
    var host : String { get }
    var requestUrl : String { get }
    var HTTPMethod : CRHTTPMethod { get }
    var queryParameters : [ String : AnyObject ] { get }
    
    func send()
}

extension CRUberRequest {
    
    var host : String {
        get {
            return "https://api.uber.com/v1/"
        }
    }
    
    func send() {
        
        var paramsArray : Array<String> = Array()
        
        for (key, value) in self.queryParameters  {
            paramsArray.append(key + "=" + "\(value)") // TODO: Not this! (FIST)
        }
        
        var fullPath = host + self.requestUrl
        
        if paramsArray.count > 0 {
            
            let params = "&".join(paramsArray)
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

struct CRUberProductsRequest : CRUberRequest {
    var requestUrl : String {
        get {
            return "products"
        }
    }
    
    var queryParameters : [ String : AnyObject ] {
        get {
            return [
                "latitude" : 37.775,
                "longitude" : -122
            ]
        }
    }
    
    var HTTPMethod : CRHTTPMethod {
        get {
            return CRHTTPMethod.GET
        }
    }
}

struct CRUberPriceEstimatesRequest : CRUberRequest {
    var requestUrl : String {
        get {
            return "estimates/price"
        }
    }
    
    var queryParameters : [ String : AnyObject ] {
        get {
            return [
                "start_latitude" : 37.775,
                "start_longitude" : -122,
                "end_latitude" : 38,
                "end_longitude" : -122
            ]
        }
    }
    
    var HTTPMethod : CRHTTPMethod {
        get {
            return CRHTTPMethod.GET
        }
    }
}


struct CRUberTimeEstimatesRequest : CRUberRequest {
    var requestUrl : String {
        get {
            return "estimates/time"
        }
    }
    
    var queryParameters : [ String : AnyObject ] {
        get {
            return [
                "start_latitude" : 37.775,
                "start_longitude" : -122
            ]
        }
    }
    
    var HTTPMethod : CRHTTPMethod {
        get {
            return CRHTTPMethod.GET
        }
    }
}

struct CRUberPromotionsRequest : CRUberRequest {
    var requestUrl : String {
        get {
            return "promotions"
        }
    }
    
    var queryParameters : [ String : AnyObject ] {
        get {
            return [
                "start_latitude" : 37.775,
                "start_longitude" : -122,
                "end_latitude" : 38,
                "end_longitude" : -122
            ]
        }
    }
    
    var HTTPMethod : CRHTTPMethod {
        get {
            return CRHTTPMethod.GET
        }
    }
}



