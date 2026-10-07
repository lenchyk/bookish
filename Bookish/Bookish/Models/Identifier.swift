//
//  Identifier.swift
//  Bookish
//
//  Created by Soroka, Olena on 07.10.2026.
//

import Foundation

struct Identifier<Type>: Sendable, Hashable {
  let id: String

  init(id: String) {
    self.id = id
  }
}

extension Identifier: Codable {
  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    do {
      id = try container.decode(String.self)
    } catch DecodingError.typeMismatch {
      id = String(try container.decode(Int.self))
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(id)
  }
}
