import Alamofire

struct CRUberProductsRequest {
    func send() {
        let URL = NSURL(string: "https://api.uber.com/v1/products?latitude=37.775&longitude=-122")!
        let mutableURLRequest = NSMutableURLRequest(URL: URL)
        mutableURLRequest.HTTPMethod = "GET"
        
        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        mutableURLRequest.setValue("Token VN13RQ21ivJxCHatCirEK1461EEvwNqpfjccIN9-", forHTTPHeaderField: "Authorization")
        
        Alamofire.request(mutableURLRequest)
            .response { (request, response, data, error) in
                println(request)
                println(response)
                println(error)
        }

    }
}

struct CRUberPriceEstimatesRequest {
    func send() {
        let URL = NSURL(string: "https://api.uber.com/v1/estimates/price?start_latitude=37.775&start_longitude=-122&end_latitude=38&end_longitude=-122")!
        let mutableURLRequest = NSMutableURLRequest(URL: URL)
        mutableURLRequest.HTTPMethod = "GET"
        
        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        mutableURLRequest.setValue("Token VN13RQ21ivJxCHatCirEK1461EEvwNqpfjccIN9-", forHTTPHeaderField: "Authorization")
        
        Alamofire.request(mutableURLRequest)
            .response { (request, response, data, error) in
                println(request)
                println(response)
                println(error)
        }
        
    }
}


struct CRUberTimeEstimatesRequest {
    func send() {
        let URL = NSURL(string: "https://api.uber.com/v1/estimates/time?start_latitude=37.775&start_longitude=-122")!
        let mutableURLRequest = NSMutableURLRequest(URL: URL)
        mutableURLRequest.HTTPMethod = "GET"
        
        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        mutableURLRequest.setValue("Token VN13RQ21ivJxCHatCirEK1461EEvwNqpfjccIN9-", forHTTPHeaderField: "Authorization")
        
        Alamofire.request(mutableURLRequest)
            .response { (request, response, data, error) in
                println(request)
                println(response)
                println(error)
        }
        
    }
}

struct CRUberPromotionsRequest {
    func send() {
        let URL = NSURL(string: "https://api.uber.com/v1/promotions?start_latitude=37.775&start_longitude=-122&end_latitude=38&end_longitude=-122")!
        let mutableURLRequest = NSMutableURLRequest(URL: URL)
        mutableURLRequest.HTTPMethod = "GET"
        
        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        mutableURLRequest.setValue("Token VN13RQ21ivJxCHatCirEK1461EEvwNqpfjccIN9-", forHTTPHeaderField: "Authorization")
        
        Alamofire.request(mutableURLRequest)
            .response { (request, response, data, error) in
                println(request)
                println(response)
                println(error)
        }
        
    }
}



