//
//  OrderItem.swift
//  Bookish
//
//  Created by Soroka, Olena on 13.08.2026.
//

import Foundation

struct OrderItem: Codable, Identifiable, Equatable {
  let id: Int
  let bookId: Int
  let book: Book
  let amount: Int
  let unitPrice: Decimal

  init(
    id: Int,
    bookId: Int,
    book: Book,
    amount: Int,
    unitPrice: Decimal
  ) {
    self.id = id
    self.bookId = bookId
    self.book = book
    self.amount = amount
    self.unitPrice = unitPrice
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(Int.self, forKey: .id)
    book = try container.decode(Book.self, forKey: .book)
    bookId = try container.decodeIfPresent(Int.self, forKey: .bookId) ?? book.id
    amount = try container.decode(Int.self, forKey: .amount)
    unitPrice = try container.decodeFlexibleDecimal(forKey: .unitPrice)
  }

  init(cache: OrderItemCache) {
    id = cache.id
    bookId = cache.bookId
    book = Book(cache: cache.book)
    amount = cache.amount
    unitPrice = cache.unitPrice
  }

  func lineTotal() -> Decimal {
    unitPrice * Decimal(amount)
  }

  func formattedUnitPrice(currency: Currency) -> String {
    PriceFormatter.string(price: unitPrice, currency: currency)
  }

  func formattedLineTotal(currency: Currency) -> String {
    PriceFormatter.string(price: lineTotal(), currency: currency)
  }
}
