import Alamofire

enum CRHTTPMethod : String {
    case GET = "GET"
}

protocol CRUberRequestProtocol {
    
    var requestUrl : String { get }
    var HTTPMethod : CRHTTPMethod { get }
    var queryParameters : [ String : AnyObject ] { get }
    
    func send()
}

class CRUberRequest : CRUberRequestProtocol {
    
    let host = "https://api.uber.com/v1/"
    
    func send() {
        
        var paramsArray : Array<String> = Array()
        
        for (key, value) in self.queryParameters {
            paramsArray.append(key + "=" + value.description)
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
    
    var requestUrl : String {
        get {
            assertionFailure("Must override in subclass")
            return ""
        }
    }
    
    var queryParameters : [ String : AnyObject ] {
        get {
            assertionFailure("Must override in subclass")
            return Dictionary<String, AnyObject>()
        }
    }
    
    var HTTPMethod : CRHTTPMethod {
        get {
            assertionFailure("Must override in subclass")
            return CRHTTPMethod.GET
        }
    }
}

class CRUberProductsRequest : CRUberRequest {
    override var requestUrl : String {
        get {
            return "products"
        }
    }
    
    override var queryParameters : [ String : AnyObject ] {
        get {
            return [
                "latitude" : 37.775,
                "longitude" : -122
            ]
        }
    }
    
    override var HTTPMethod : CRHTTPMethod {
        get {
            return CRHTTPMethod.GET
        }
    }
}

class CRUberPriceEstimatesRequest : CRUberRequest {
    override var requestUrl : String {
        get {
            return "estimates/price"
        }
    }
    
    override var queryParameters : [ String : AnyObject ] {
        get {
            return [
                "start_latitude" : 37.775,
                "start_longitude" : -122,
                "end_latitude" : 38,
                "end_longitude" : -122
            ]
        }
    }
    
    override var HTTPMethod : CRHTTPMethod {
        get {
            return CRHTTPMethod.GET
        }
    }
}


class CRUberTimeEstimatesRequest : CRUberRequest {
    override var requestUrl : String {
        get {
            return "estimates/time"
        }
    }
    
    override var queryParameters : [ String : AnyObject ] {
        get {
            return [
                "start_latitude" : 37.775,
                "start_longitude" : -122
            ]
        }
    }
    
    override var HTTPMethod : CRHTTPMethod {
        get {
            return CRHTTPMethod.GET
        }
    }
}

class CRUberPromotionsRequest : CRUberRequest {
    override var requestUrl : String {
        get {
            return "promotions"
        }
    }
    
    override var queryParameters : [ String : AnyObject ] {
        get {
            return [
                "start_latitude" : 37.775,
                "start_longitude" : -122,
                "end_latitude" : 38,
                "end_longitude" : -122
            ]
        }
    }
    
    override var HTTPMethod : CRHTTPMethod {
        get {
            return CRHTTPMethod.GET
        }
    }
}



