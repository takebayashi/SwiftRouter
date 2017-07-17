/*
 Copyright 2017 Shun Takebayashi.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import XCTest
import SwiftServerHttp
@testable import SwiftRouter

class StaticApp: WebAppContaining {
    let body: String

    init(body: String) {
        self.body = body
    }

    func serve(req: HTTPRequest, res: HTTPResponseWriter ) -> HTTPBodyProcessing {
        //Assume the router gave us the right request - at least for now
        res.writeResponse(HTTPResponse(
            httpVersion: req.httpVersion,
            status: .ok,
            transferEncoding: .identity(contentLength: UInt(body.lengthOfBytes(using: .utf8))),
            headers: HTTPHeaders([])
        ))
        res.writeBody(data: body.data(using: .utf8)!) { _ in }
        res.done()
        return .discardBody
    }
}

class SwiftRouterTests: XCTestCase {
    func testRouter() {
        let server = BlueSocketSimpleServer()
        let router = Router()
        router.on(.GET, "/foo", StaticApp(body: "bar").serve)
        router.on(.POST, "/baz", StaticApp(body: "qux").serve)
        do {
            try server.start(port: 0, webapp: router.serve)
            let session = URLSession(configuration: URLSessionConfiguration.default)
            let fooExpectation = self.expectation(description: "Request GET /foo")
            var fooReq = URLRequest(url: URL(string: "http://localhost:\(server.port)/foo")!)
            fooReq.httpMethod = "GET"
            let fooTask = session.dataTask(with: fooReq) { (responseBody, rawResponse, error) in
                let response = rawResponse as? HTTPURLResponse
                XCTAssertNil(error, "\(error!.localizedDescription)")
                XCTAssertNotNil(response)
                XCTAssertNotNil(responseBody)
                XCTAssertEqual(Int(HTTPResponseStatus.ok.code), response?.statusCode ?? 0)
                XCTAssertEqual("bar", String(data: responseBody ?? Data(), encoding: .utf8) ?? "Nil")
                fooExpectation.fulfill()
            }

            fooTask.resume()
            let bazExpectation = self.expectation(description: "Request POST /baz")
            var bazReq = URLRequest(url: URL(string: "http://localhost:\(server.port)/baz")!)
            bazReq.httpMethod = "POST"
            let bazTask = session.dataTask(with: bazReq) { (responseBody, rawResponse, error) in
                let response = rawResponse as? HTTPURLResponse
                XCTAssertNil(error, "\(error!.localizedDescription)")
                XCTAssertNotNil(response)
                XCTAssertNotNil(responseBody)
                XCTAssertEqual(Int(HTTPResponseStatus.ok.code), response?.statusCode ?? 0)
                XCTAssertEqual("qux", String(data: responseBody ?? Data(), encoding: .utf8) ?? "Nil")
                bazExpectation.fulfill()
            }
            bazTask.resume()
            self.waitForExpectations(timeout: 10) { (error) in
                if let error = error {
                    XCTFail("\(error)")
                }
            }
            server.stop()
        } catch {
            XCTFail("Error listening on port \(0): \(error). Use server.failed(callback:) to handle")
        }
    }


    static var allTests = [
        ("testRouter", testRouter),
    ]
}
