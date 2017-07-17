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

import SwiftServerHttp

public protocol Matcher {
    func matches(target: String) -> Bool
}

extension String: Matcher {
    public func matches(target: String) -> Bool {
        return self == target
    }
}

public typealias PathComponent = String

public typealias PathComponents = [PathComponent]

public struct PathComponentParser {
    public func parse(path: String) -> PathComponents {
        return path.components(separatedBy: "/").filter { $0 != "" }
    }
}

public struct PathMatcher: Matcher {
    public enum PathComponentMatcher {
        case fixed(value: String)
        case string
        case int

        func matches(component: PathComponent) -> Bool {
            switch self {
            case .fixed(let value):
                if component != value {
                    return false
                }
            case .string:
                break
            case .int:
                if Int(component) == .none {
                    return false
                }
            }
            return true
        }
    }

    let componentMatchers: [PathComponentMatcher]

    public init(components: [PathComponentMatcher]) {
        self.componentMatchers = components
    }

    public func matches(target: String) -> Bool {
        let targetComponents = PathComponentParser().parse(path: target)
        if targetComponents.count < componentMatchers.count {
            return false
        }
        var i = 0
        for componentMatcher in componentMatchers {
            let targetComponent = targetComponents[i]
            if !componentMatcher.matches(component: targetComponent) {
                return false
            }
            i += 1
        }
        return true
    }
}

public class Router: WebAppContaining {

    var routes = [(HTTPMethod, Matcher, WebApp)]()

    public init() {
    }

    public func on(_ method: HTTPMethod, _ matcher: Matcher, _ app: @escaping WebApp) {
        routes.append(method, matcher, app)
    }

    public func serve(req: HTTPRequest, res: HTTPResponseWriter ) -> HTTPBodyProcessing {
        if let route = routes.first(where: { $0.0 == req.method && $0.1.matches(target: req.target) }) {
            return route.2(req, res)
        } else {
            return .discardBody
        }
    }
}
