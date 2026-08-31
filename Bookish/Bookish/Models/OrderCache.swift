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
  var fullname: String?
  var email: String?
  var address: String?
  var currency: CurrencyCache?

  init(
    id: Int,
    fullname: String?,
    email: String?,
    address: String?,
    currency: CurrencyCache? = nil
  ) {
    self.id = id
    self.fullname = fullname
    self.email = email
    self.address = address
    self.currency = currency
  }

  func update(from customer: Customer, currency: CurrencyCache?) {
    fullname = customer.fullname
    email = customer.email
    address = customer.address
    self.currency = currency
  }
}

@Model
final class OrderCache {
  @Attribute(.unique) var id: Int
  var orderDescription: String?
  var totalPrice: Decimal?
  var createdAt: Date?
  var status: String?
  var customer: CustomerCache?
  var currency: CurrencyCache?

  @Relationship(deleteRule: .cascade, inverse: \OrderItemCache.order)
  var items: [OrderItemCache]

  init(
    id: Int,
    orderDescription: String? = nil,
    totalPrice: Decimal? = nil,
    createdAt: Date? = nil,
    status: String? = nil,
    customer: CustomerCache? = nil,
    currency: CurrencyCache? = nil,
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

  func update(from order: Order, customer: CustomerCache?, currency: CurrencyCache?) {
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
  var amount: Int
  var unitPrice: Decimal?
  var book: BookCache?
  var order: OrderCache?

  init(
    id: Int,
    amount: Int,
    unitPrice: Decimal? = nil,
    book: BookCache? = nil,
    order: OrderCache? = nil
  ) {
    self.id = id
    self.amount = amount
    self.unitPrice = unitPrice
    self.book = book
    self.order = order
  }

  func update(from item: OrderItem, book: BookCache?) {
    amount = item.amount
    unitPrice = item.unitPrice
    self.book = book
  }
}
