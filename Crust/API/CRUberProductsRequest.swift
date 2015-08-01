import Alamofire

enum CRHTTPMethod : String {
    case GET = "GET"
}

protocol CRUberRequest {
    
    var host: String { get }
    var requestUrl: String { get }
    var HTTPMethod: CRHTTPMethod { get }
    var queryParameters: [ String : AnyObject ] { get }
    
    func send()
}

extension CRUberRequest {
    
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
    
    var latitude: Double
    var longitude: Double
    
    init(withLatitude latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    var requestUrl: String {
        return "products"
    }
    
    var queryParameters: [ String : AnyObject ] {
        return [
            "latitude" : latitude,
            "longitude" : longitude
        ]
    }
    
    var HTTPMethod: CRHTTPMethod {
        return CRHTTPMethod.GET
    }
}

struct CRUberPriceEstimatesRequest : CRUberRequest {
    
    var startLatitude: Double
    var startLongitude: Double
    var endLatitude: Double
    var endLongitude: Double
    
    init(withStartLatitude
        startLatitude: Double,
        startLongitude: Double,
        endLatitude: Double,
        endLongitude: Double) {
            
            self.startLatitude = startLatitude
            self.startLongitude = startLongitude
            self.endLatitude = endLatitude
            self.endLongitude = endLongitude
    }
    
    var requestUrl: String {
        return "estimates/price"
    }
    
    var queryParameters: [ String : AnyObject ] {
        return [
            "start_latitude" : startLatitude,
            "start_longitude" : startLongitude,
            "end_latitude" : endLatitude,
            "end_longitude" : endLongitude
        ]
    }
    
    var HTTPMethod: CRHTTPMethod {
        return CRHTTPMethod.GET
    }
}


struct CRUberTimeEstimatesRequest : CRUberRequest {
    
    var startLatitude: Double
    var startLongitude: Double
    
    init(withStartLatitude
        startLatitude: Double,
        startLongitude: Double) {
            
            self.startLatitude = startLatitude
            self.startLongitude = startLongitude
    }
    
    var requestUrl: String {
        return "estimates/time"
    }
    
    var queryParameters: [ String : AnyObject ] {
        return [
            "start_latitude" : startLatitude,
            "start_longitude" : startLongitude
        ]
    }
    
    var HTTPMethod: CRHTTPMethod {
        return CRHTTPMethod.GET
    }
}

struct CRUberPromotionsRequest : CRUberRequest {
    
    var startLatitude: Double
    var startLongitude: Double
    var endLatitude: Double
    var endLongitude: Double
    
    init(withStartLatitude
        startLatitude: Double,
        startLongitude: Double,
        endLatitude: Double,
        endLongitude: Double) {
            
            self.startLatitude = startLatitude
            self.startLongitude = startLongitude
            self.endLatitude = endLatitude
            self.endLongitude = endLongitude
    }
    
    var requestUrl: String {
        return "promotions"
    }
    
    var queryParameters: [ String : AnyObject ] {
        return [
            "start_latitude" : startLatitude,
            "start_longitude" : startLongitude,
            "end_latitude" : endLatitude,
            "end_longitude" : endLongitude
        ]
    }
    
    var HTTPMethod: CRHTTPMethod {
        return CRHTTPMethod.GET
    }
}



