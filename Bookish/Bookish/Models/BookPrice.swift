//
//  BookPrice.swift
//  Bookish
//
//  Created by Soroka, Olena on 13.08.2026.
//

import Foundation

struct BookPrice: Codable, Identifiable, Equatable, Hashable {
  let id: Int
  let bookId: Int?
  let price: Decimal?
  let currency: Currency?
  let createdAt: Date?

  init(
    id: Int,
    bookId: Int? = nil,
    price: Decimal?,
    currency: Currency?,
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
    bookId = try container.decodeIfPresent(Int.self, forKey: .bookId)
    price = try container.decodeFlexibleDecimal(forKey: .price)
    currency = try container.decodeIfPresent(Currency.self, forKey: .currency)
    createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
  }

  init(cache: BookPriceCache) {
    self.init(
      id: cache.id,
      bookId: cache.book?.id,
      price: cache.price,
      currency: cache.currency.map(Currency.init(cache:)),
      createdAt: cache.createdAt
    )
  }

  var formatted: String {
    guard let price else {
      return "Price unavailable"
    }
    return PriceFormatter.string(price: price, currency: currency)
  }

  static func preferred(from prices: [BookPrice], currency: Currency?) -> BookPrice? {
    if let currencyId = currency?.id {
      return prices.first { $0.price != nil && $0.currency?.id == currencyId }
    }
    return prices.first { $0.price != nil }
  }
}
