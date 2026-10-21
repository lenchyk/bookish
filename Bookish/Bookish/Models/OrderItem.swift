//
//  OrderItem.swift
//  Bookish
//
//  Created by Soroka, Olena on 13.08.2026.
//

import Foundation

struct OrderItem: Codable, Identifiable, Equatable {
  typealias ID = Identifier<OrderItem>

  let id: ID
  let bookId: Book.ID
  let book: Book
  let amount: Int
  let unitPrice: Decimal

  init(
    id: ID,
    bookId: Book.ID,
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
    id = try container.decode(ID.self, forKey: .id)
    book = try container.decode(Book.self, forKey: .book)
    bookId = try container.decodeIfPresent(Book.ID.self, forKey: .bookId) ?? book.id
    amount = try container.decode(Int.self, forKey: .amount)
    unitPrice = try container.decodeFlexibleDecimal(forKey: .unitPrice)
  }

  init(cache: OrderItemCache) {
    id = ID(id: cache.id)
    bookId = Book.ID(id: cache.bookId)
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
