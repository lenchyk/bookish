//
//  OrderCache.swift
//  Bookish
//
//  Created by Soroka, Olena on 13.08.2026.
//

import Foundation
import SwiftData

@Model
final class CustomerCache {
  @Attribute(.unique) var id: Int
  var fullname: String
  var email: String?
  var address: String?
  var currency: CurrencyCache

  init(
    id: Int,
    fullname: String,
    email: String?,
    address: String?,
    currency: CurrencyCache
  ) {
    self.id = id
    self.fullname = fullname
    self.email = email
    self.address = address
    self.currency = currency
  }

  func update(from customer: Customer, currency: CurrencyCache) {
    fullname = customer.fullname
    email = customer.email
    address = customer.address
    self.currency = currency
  }
}

@Model
final class OrderCache {
  @Attribute(.unique) var id: Int
  var orderDescription: String
  var totalPrice: Decimal
  var createdAt: Date
  var status: OrderStatus
  var customer: CustomerCache
  var currency: CurrencyCache

  @Relationship(deleteRule: .cascade, inverse: \OrderItemCache.order)
  var items: [OrderItemCache]

  init(
    id: Int,
    orderDescription: String,
    totalPrice: Decimal,
    createdAt: Date,
    status: OrderStatus,
    customer: CustomerCache,
    currency: CurrencyCache,
    items: [OrderItemCache] = []
  ) {
    self.id = id
    self.orderDescription = orderDescription
    self.totalPrice = totalPrice
    self.createdAt = createdAt
    self.status = status
    self.customer = customer
    self.currency = currency
    self.items = items
  }

  func update(
    from order: Order,
    customer: CustomerCache,
    currency: CurrencyCache
  ) {
    orderDescription = order.description
    totalPrice = order.totalPrice
    createdAt = order.createdAt
    status = order.status
    self.customer = customer
    self.currency = currency
  }
}

@Model
final class OrderItemCache {
  @Attribute(.unique) var id: Int
  var bookId: Int
  var amount: Int
  var unitPrice: Decimal
  var book: BookCache
  var order: OrderCache?

  init(
    id: Int,
    bookId: Int,
    amount: Int,
    unitPrice: Decimal,
    book: BookCache,
    order: OrderCache? = nil
  ) {
    self.id = id
    self.bookId = bookId
    self.amount = amount
    self.unitPrice = unitPrice
    self.book = book
    self.order = order
  }

  func update(from item: OrderItem, book: BookCache) {
    bookId = item.bookId
    amount = item.amount
    unitPrice = item.unitPrice
    self.book = book
  }
}
