import Foundation
import XCTest
import NIO
@testable import LambdaRuntime
@testable import LambdaEvents

class S3Tests: XCTestCase {

  static let eventPayload = """
    {
      "Records": [
        {
          "eventVersion":"2.1",
          "eventSource":"aws:s3",
          "awsRegion":"eu-central-1",
          "eventTime":"2020-01-13T09:25:40.621Z",
          "eventName":"ObjectCreated:Put",
          "userIdentity":{
            "principalId":"AWS:AAAAAAAJ2MQ4YFQZ7AULJ"
          },
          "requestParameters":{
            "sourceIPAddress":"123.123.123.123"
          },
          "responseElements":{
            "x-amz-request-id":"01AFA1430E18C358",
            "x-amz-id-2":"JsbNw6sHGFwgzguQjbYcew//bfAeZITyTYLfjuu1U4QYqCq5CPlSyYLtvWQS+gw0RxcroItGwm8="
          },
          "s3":{
            "s3SchemaVersion":"1.0",
            "configurationId":"98b55bc4-3c0c-4007-b727-c6b77a259dde",
            "bucket":{
              "name":"eventsources",
              "ownerIdentity":{
                "principalId":"AAAAAAAAAAAAAA"
              },
              "arn":"arn:aws:s3:::eventsources"
            },
            "object":{
              "key":"Hi.md",
              "size":2880,
              "eTag":"91a7f2c3ae81bcc6afef83979b463f0e",
              "sequencer":"005E1C37948E783A6E"
            }
          }
        }
      ]
    }
    """
  
  struct TestStruct: Decodable {
    let hello: String
  }
  
  func testSimpleEventFromJSON() {
    let data = S3Tests.eventPayload.data(using: .utf8)!
    do {
      let event = try JSONDecoder().decode(S3.Event.self, from: data)
      
      guard let record = event.records.first else {
        XCTFail("Expected to have one record"); return
      }
      
      XCTAssertEqual(record.eventVersion, "2.1")
      XCTAssertEqual(record.eventSource, "aws:s3")
      XCTAssertEqual(record.awsRegion, "eu-central-1")
      XCTAssertEqual(record.eventName, "ObjectCreated:Put")
      XCTAssertEqual(record.eventTime, Date(timeIntervalSince1970: 1578907540.621))
      XCTAssertEqual(record.userIdentity, S3.UserIdentity(principalId: "AWS:AAAAAAAJ2MQ4YFQZ7AULJ"))
      XCTAssertEqual(record.requestParameters, S3.RequestParameters(sourceIPAddress: "123.123.123.123"))
      XCTAssertEqual(record.responseElements.count, 2)
      XCTAssertEqual(record.s3.schemaVersion, "1.0")
      XCTAssertEqual(record.s3.configurationId, "98b55bc4-3c0c-4007-b727-c6b77a259dde")
      XCTAssertEqual(record.s3.bucket.name, "eventsources")
      XCTAssertEqual(record.s3.bucket.ownerIdentity, S3.UserIdentity(principalId: "AAAAAAAAAAAAAA"))
      XCTAssertEqual(record.s3.bucket.arn, "arn:aws:s3:::eventsources")
      XCTAssertEqual(record.s3.object.key, "Hi.md")
      XCTAssertEqual(record.s3.object.size, 2880)
      XCTAssertEqual(record.s3.object.eTag, "91a7f2c3ae81bcc6afef83979b463f0e")
      XCTAssertEqual(record.s3.object.sequencer, "005E1C37948E783A6E")
    }
    catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
}
