//
//  Currency.swift
//  Bookish
//
//  Created by Soroka, Olena on 13.08.2026.
//

import Foundation

struct Currency: Codable, Identifiable, Equatable, Hashable {
  let id: Int
  let name: String
  let symbol: String?
  let code: String?

  init(
    id: Int,
    name: String,
    symbol: String?,
    code: String?
  ) {
    self.id = id
    self.name = name
    self.symbol = symbol
    self.code = code
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(Int.self, forKey: .id)
    name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
    symbol = try container.decodeIfPresent(String.self, forKey: .symbol)
    code = try container.decodeIfPresent(String.self, forKey: .code)
  }

  init(cache: CurrencyCache) {
    self.init(
      id: cache.id,
      name: cache.name,
      symbol: cache.symbol,
      code: cache.code
    )
  }
}
