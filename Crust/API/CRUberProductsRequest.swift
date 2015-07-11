import Alamofire

enum CRHTTPMethod : String {
    case GET = "GET"
}

protocol CRUberRequestProtocol {
    
    var requestUrl : String { get }
    var HTTPMethod : CRHTTPMethod { get }
    
    func send()
}

class CRUberRequest : CRUberRequestProtocol {
    func send() {
        let URL = NSURL(string: self.requestUrl)!
        let mutableURLRequest = NSMutableURLRequest(URL: URL)
        mutableURLRequest.HTTPMethod = self.HTTPMethod.rawValue
        
        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        mutableURLRequest.setValue("Token VN13RQ21ivJxCHatCirEK1461EEvwNqpfjccIN9-", forHTTPHeaderField: "Authorization")
        
        Alamofire.request(mutableURLRequest)
            .response { (request, response, data, error) in
                println(request)
                println(response)
                println(error)
        }
    }
    
    var requestUrl : String {
        get {
            assertionFailure("Must override in subclass")
            return ""
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
            return "https://api.uber.com/v1/products?latitude=37.775&longitude=-122"
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
            return "https://api.uber.com/v1/estimates/price?start_latitude=37.775&start_longitude=-122&end_latitude=38&end_longitude=-122"
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
            return "https://api.uber.com/v1/estimates/time?start_latitude=37.775&start_longitude=-122"
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
            return "https://api.uber.com/v1/promotions?start_latitude=37.775&start_longitude=-122&end_latitude=38&end_longitude=-122"
        }
    }
    
    override var HTTPMethod : CRHTTPMethod {
        get {
            return CRHTTPMethod.GET
        }
    }
}



