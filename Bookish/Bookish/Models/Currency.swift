//
//  Currency.swift
//  Bookish
//
//  Created by Soroka, Olena on 13.08.2026.
//

import Foundation

struct Currency: Codable, Identifiable, Equatable, Hashable {
  typealias ID = Identifier<Currency>

  let id: ID
  let name: String
  let symbol: String
  let code: String

  init(
    id: ID,
    name: String,
    symbol: String,
    code: String
  ) {
    self.id = id
    self.name = name
    self.symbol = symbol
    self.code = code
  }

  init(cache: CurrencyCache) {
    id = ID(id: cache.id)
    name = cache.name
    symbol = cache.symbol
    code = cache.code
  }
}
