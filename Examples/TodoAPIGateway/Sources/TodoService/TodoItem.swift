import Foundation
import DynamoDB

public struct TodoItem {

  public let id: String
  public let order: Int?

  /// Text to display
  public let title: String

  /// Whether completed or not
  public let completed: Bool

  public init(id: String, order: Int?, title: String, completed: Bool) {
    self.id        = id
    self.order     = order
    self.title     = title
    self.completed = completed
  }
}

extension CodingUserInfoKey {
  public static let baseUrl = CodingUserInfoKey(rawValue: "de.fabianfett.TodoBackend.BaseURL")!
}

extension TodoItem : Codable {
  
  enum CodingKeys: String, CodingKey {
    case id
    case order
    case title
    case completed
    case url
  }
  
  public init(from decoder: Decoder) throws {
    let container  = try decoder.container(keyedBy: CodingKeys.self)
    self.id        = try container.decode(String.self, forKey: .id)
    self.title     = try container.decode(String.self, forKey: .title)
    self.completed = try container.decode(Bool.self, forKey: .completed)
    self.order     = try container.decodeIfPresent(Int.self, forKey: .order)
  }
  
  public func encode(to encoder: Encoder) throws {
    
    var container = encoder.container(keyedBy: CodingKeys.self)
    
    try container.encode(id,        forKey: .id)
    try container.encode(order,     forKey: .order)
    try container.encode(title,     forKey: .title)
    try container.encode(completed, forKey: .completed)
    
    if let url = encoder.userInfo[.baseUrl] as? URL {
      let todoUrl = url.appendingPathComponent("/todos/\(id)")
      try container.encode(todoUrl, forKey: .url)
    }
  }
  
}
extension TodoItem : Equatable { }

public func == (lhs: TodoItem, rhs: TodoItem) -> Bool {
  return lhs.id        == rhs.id
      && lhs.order     == rhs.order
      && lhs.title     == rhs.title
      && lhs.completed == rhs.completed
}

extension TodoItem {
  
  func toDynamoItem() -> [String: DynamoDB.AttributeValue] {
    var result: [String: DynamoDB.AttributeValue] = [
      "TodoId"   : .init(s: self.id),
      "Title"    : .init(s: self.title),
      "Completed": .init(bool: self.completed),
    ]
    
    if let order = order {
      result["Order"] = DynamoDB.AttributeValue(n: String(order))
    }
    
    return result
  }
  
  init?(attributes: [String: DynamoDB.AttributeValue]) {
    guard let id = attributes["TodoId"]?.s,
          let title = attributes["Title"]?.s,
          let completed = attributes["Completed"]?.bool
      else
    {
      return nil
    }
    
    var order: Int? = nil
    if let orderString = attributes["Order"]?.n, let number = Int(orderString) {
      order = number
    }
    
    self.init(id: id, order: order, title: title, completed: completed)
  }
  
}

public struct PatchTodo: Codable {
  public let order    : Int?
  public let title    : String?
  public let completed: Bool?
}
