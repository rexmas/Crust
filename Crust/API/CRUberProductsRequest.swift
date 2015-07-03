import Alamofire

struct CRUberProductsRequest {
    func lookupLocationData() {
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

