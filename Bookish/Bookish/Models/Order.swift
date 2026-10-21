//
//  Order.swift
//  Bookish
//
//  Created by Soroka, Olena on 13.08.2026.
//

import Foundation

struct Order: Codable, Identifiable, Equatable {
  typealias ID = Identifier<Order>

  let id: ID
  let customer: Customer
  let currency: Currency
  let description: String
  let totalPrice: Decimal
  let createdAt: Date
  let status: OrderStatus
  let items: [OrderItem]

  init(
    id: ID,
    customer: Customer,
    currency: Currency,
    description: String,
    totalPrice: Decimal,
    createdAt: Date,
    status: OrderStatus,
    items: [OrderItem]
  ) {
    self.id = id
    self.customer = customer
    self.currency = currency
    self.description = description
    self.totalPrice = totalPrice
    self.createdAt = createdAt
    self.status = status
    self.items = items
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(ID.self, forKey: .id)
    customer = try container.decode(Customer.self, forKey: .customer)
    currency = try container.decode(Currency.self, forKey: .currency)
    description = try container.decode(String.self, forKey: .description)
    totalPrice = try container.decodeFlexibleDecimal(forKey: .totalPrice)
    createdAt = try container.decode(Date.self, forKey: .createdAt)
    status = try container.decode(OrderStatus.self, forKey: .status)
    items = try container.decode([OrderItem].self, forKey: .items)
  }

  init(cache: OrderCache) {
    id = ID(id: cache.id)
    customer = Customer(cache: cache.customer)
    currency = Currency(cache: cache.currency)
    description = cache.orderDescription
    totalPrice = cache.totalPrice
    createdAt = cache.createdAt
    status = cache.status
    items = cache.items.map(OrderItem.init(cache:))
  }

  var computedTotal: Decimal {
    items.reduce(Decimal.zero) { $0 + $1.lineTotal() }
  }

  var formattedTotal: String {
    PriceFormatter.string(price: totalPrice, currency: currency)
  }
}
