//
//  BookPrice.swift
//  Bookish
//
//  Created by Soroka, Olena on 13.08.2026.
//

import Foundation

struct BookPrice: Codable, Identifiable, Equatable, Hashable {
  let id: Int
  let bookId: Int
  let price: Decimal
  let currency: Currency
  let createdAt: Date?

  init(
    id: Int,
    bookId: Int,
    price: Decimal,
    currency: Currency,
    createdAt: Date? = nil
  ) {
    self.id = id
    self.bookId = bookId
    self.price = price
    self.currency = currency
    self.createdAt = createdAt
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(Int.self, forKey: .id)
    bookId = try container.decode(Int.self, forKey: .bookId)
    price = try container.decodeFlexibleDecimal(forKey: .price)
    currency = try container.decode(Currency.self, forKey: .currency)
    createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
  }

  init(cache: BookPriceCache) {
    id = cache.id
    bookId = cache.bookId
    price = cache.price
    currency = Currency(cache: cache.currency)
    createdAt = cache.createdAt
  }

  var formatted: String {
    PriceFormatter.string(price: price, currency: currency)
  }

  static func preferred(from prices: [BookPrice], currency: Currency) -> BookPrice? {
    prices.first { $0.currency.id == currency.id } ?? prices.first
  }
}
