//
//  OrderItem.swift
//  Bookish
//
//  Created by Soroka, Olena on 13.08.2026.
//

import Foundation

struct OrderItem: Codable, Identifiable, Equatable {
  let id: Int
  let bookId: Int?
  let book: Book?
  let amount: Int
  let unitPrice: Decimal?

  init(
    id: Int,
    bookId: Int? = nil,
    book: Book?,
    amount: Int,
    unitPrice: Decimal?
  ) {
    self.id = id
    self.bookId = bookId ?? book?.id
    self.book = book
    self.amount = amount
    self.unitPrice = unitPrice
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(Int.self, forKey: .id)
    bookId = try container.decodeIfPresent(Int.self, forKey: .bookId)
    book = try container.decodeIfPresent(Book.self, forKey: .book)
    amount = try container.decodeIfPresent(Int.self, forKey: .amount) ?? 0
    unitPrice = try container.decodeFlexibleDecimal(forKey: .unitPrice)
  }

  init(cache: OrderItemCache) {
    self.init(
      id: cache.id,
      bookId: cache.book?.id,
      book: cache.book.map(Book.init(cache:)),
      amount: cache.amount,
      unitPrice: cache.unitPrice
    )
  }

  func resolvedUnitPrice(currency: Currency?) -> Decimal? {
    if let unitPrice {
      return unitPrice
    }
    return BookPrice.preferred(from: book?.prices ?? [], currency: currency)?.price
  }

  func lineTotal(currency: Currency?) -> Decimal? {
    guard let unit = resolvedUnitPrice(currency: currency) else { return nil }
    return unit * Decimal(amount)
  }

  func formattedUnitPrice(currency: Currency?) -> String {
    guard let unit = resolvedUnitPrice(currency: currency) else {
      return "Price unavailable"
    }
    return PriceFormatter.string(price: unit, currency: currency)
  }

  func formattedLineTotal(currency: Currency?) -> String {
    guard let lineTotal = lineTotal(currency: currency) else {
      return "—"
    }
    return PriceFormatter.string(price: lineTotal, currency: currency)
  }
}
