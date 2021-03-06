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
import HTTP
@testable import SwiftRouter

class StaticApp: HTTPRequestHandling {
    let body: String

    init(body: String) {
        self.body = body
    }

    func handle(request: HTTPRequest, response: HTTPResponseWriter ) -> HTTPBodyProcessing {
        //Assume the router gave us the right request - at least for now
        response.writeHeader(status: .ok)
        response.writeBody(body.data(using: .utf8)!) { _ in }
        response.done()
        return .discardBody
    }
}

class SwiftRouterTests: XCTestCase {
    func testStringMatcher() {
        XCTAssertTrue("/foo/bar".matches(target: "/foo/bar"))
        XCTAssertFalse("/foo/bar".matches(target: "/foo/baz"))
        XCTAssertTrue("/foo/bar/".matches(target: "/foo/bar"))
        XCTAssertFalse("/foo/bar".matches(target: "/foo"))
    }

    func testPathMatcher() {
        let matcher1 = PathMatcher(components: [.fixed(value: "foo")])
        XCTAssertTrue(matcher1.matches(target: "/foo"))
        XCTAssertFalse(matcher1.matches(target: "/bar"))

        let matcher2 = PathMatcher(components: [.fixed(value: "foo"), .fixed(value: "bar")])
        XCTAssertTrue(matcher2.matches(target: "/foo/bar"))
        XCTAssertFalse(matcher2.matches(target: "/foo/baz"))

        let matcher3 = PathMatcher(components: [.fixed(value: "foo"), .fixed(value: "bar"), .string])
        XCTAssertTrue(matcher3.matches(target: "/foo/bar/baz"))
        XCTAssertFalse(matcher3.matches(target: "/foo/bar"))

        let matcher4 = PathMatcher(components: [.fixed(value: "foo"), .fixed(value: "bar"), .int])
        XCTAssertTrue(matcher4.matches(target: "/foo/bar/42"))
        XCTAssertFalse(matcher4.matches(target: "/foo/bar/baz"))
    }

    func testRouter() {
        let server = HTTPServer()
        let router = Router()
        router.on(.get, "/foo", StaticApp(body: "bar").handle)
        router.on(.post, "/baz", StaticApp(body: "qux").handle)
        do {
            try server.start(port: 0, handler: router.handle)
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
