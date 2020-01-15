import Foundation
import XCTest
@testable import LambdaRuntime
@testable import LambdaEvents


class ALBTests: XCTestCase {

  static let exampleSingleValueHeadersPayload = """
    {
      "requestContext":{
        "elb":{
          "targetGroupArn": "arn:aws:elasticloadbalancing:eu-central-1:079477498937:targetgroup/EinSternDerDeinenNamenTraegt/621febf5a44b2ce5"
        }
      },
      "httpMethod": "GET",
      "path": "/",
      "queryStringParameters": {},
      "headers":{
        "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "accept-encoding": "gzip, deflate",
        "accept-language": "en-us",
        "connection": "keep-alive",
        "host": "event-testl-1wa3wrvmroilb-358275751.eu-central-1.elb.amazonaws.com",
        "upgrade-insecure-requests": "1",
        "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.2 Safari/605.1.15",
        "x-amzn-trace-id": "Root=1-5e189143-ad18a2b0a7728cd0dac45e10",
        "x-forwarded-for": "90.187.8.137",
        "x-forwarded-port": "80",
        "x-forwarded-proto": "http"
      },
      "body":"",
      "isBase64Encoded":false
    }
    """
  
  func testRequestWithSingleValueHeadersPayload() {
    let data = ALBTests.exampleSingleValueHeadersPayload.data(using: .utf8)!
    do {
      let decoder = JSONDecoder()
    
      let event = try decoder.decode(ALB.TargetGroupRequest.self, from: data)
      
      XCTAssertEqual(event.httpMethod, .GET)
      XCTAssertEqual(event.body, nil)
      XCTAssertEqual(event.isBase64Encoded, false)
      XCTAssertEqual(event.headers.count, 11)
      XCTAssertEqual(event.path, "/")
      XCTAssertEqual(event.queryStringParameters, [:])
    }
    catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
  
  // MARK: - Response -
  
  private struct TestStruct: Codable {
    let hello: String
  }
  
  private struct SingleValueHeadersResponse: Codable, Equatable {
    let statusCode: Int
    let body: String
    let isBase64Encoded: Bool
    let headers: [String: String]
  }
  
  private struct MultiValueHeadersResponse: Codable, Equatable {
    let statusCode: Int
    let body: String
    let isBase64Encoded: Bool
    let multiValueHeaders: [String: [String]]
  }
  
  func testJSONResponseWithSingleValueHeaders() throws {
    let response = try ALB.TargetGroupResponse(statusCode: .ok, payload: TestStruct(hello: "world"))
    let encoder = JSONEncoder()
    encoder.userInfo[ALB.TargetGroupResponse.MultiValueHeadersEnabledKey] = false
    let data = try encoder.encode(response)
    
    let expected = SingleValueHeadersResponse(
      statusCode: 200, body: "{\"hello\":\"world\"}",
      isBase64Encoded: false,
      headers: ["Content-Type": "application/json"])
    
    let result = try JSONDecoder().decode(SingleValueHeadersResponse.self, from: data)
    XCTAssertEqual(result, expected)
  }
  
  func testJSONResponseWithMultiValueHeaders() throws {
    let response = try ALB.TargetGroupResponse(statusCode: .ok, payload: TestStruct(hello: "world"))
    let encoder = JSONEncoder()
    encoder.userInfo[ALB.TargetGroupResponse.MultiValueHeadersEnabledKey] = true
    let data = try encoder.encode(response)
    
    let expected = MultiValueHeadersResponse(
      statusCode: 200, body: "{\"hello\":\"world\"}",
      isBase64Encoded: false,
      multiValueHeaders: ["Content-Type": ["application/json"]])
    
    let result = try JSONDecoder().decode(MultiValueHeadersResponse.self, from: data)
    XCTAssertEqual(result, expected)
  }
  
  func testEmptyResponseWithMultiValueHeaders() throws {
    let response = ALB.TargetGroupResponse(statusCode: .ok)
    let encoder = JSONEncoder()
    encoder.userInfo[ALB.TargetGroupResponse.MultiValueHeadersEnabledKey] = true
    let data = try encoder.encode(response)
    
    let expected = MultiValueHeadersResponse(
      statusCode: 200, body: "",
      isBase64Encoded: false,
      multiValueHeaders: [:])
    
    let result = try JSONDecoder().decode(MultiValueHeadersResponse.self, from: data)
    XCTAssertEqual(result, expected)
  }
  
  func testEmptyResponseWithSingleValueHeaders() throws {
    let response = ALB.TargetGroupResponse(statusCode: .ok)
    let encoder = JSONEncoder()
    encoder.userInfo[ALB.TargetGroupResponse.MultiValueHeadersEnabledKey] = false
    let data = try encoder.encode(response)
    
    let expected = SingleValueHeadersResponse(
      statusCode: 200, body: "",
      isBase64Encoded: false,
      headers: [:])
    
    let result = try JSONDecoder().decode(SingleValueHeadersResponse.self, from: data)
    XCTAssertEqual(result, expected)
  }
  
}
