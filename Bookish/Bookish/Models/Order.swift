//
//  Order.swift
//  Bookish
//
//  Created by Soroka, Olena on 13.08.2026.
//

import Foundation

struct Order: Codable, Identifiable, Equatable {
  let id: Int
  let customer: Customer?
  let currency: Currency?
  let description: String?
  let totalPrice: Decimal?
  let createdAt: Date?
  let status: String?
  let items: [OrderItem]

  init(
    id: Int,
    customer: Customer?,
    currency: Currency?,
    description: String?,
    totalPrice: Decimal?,
    createdAt: Date?,
    status: String?,
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
    id = try container.decode(Int.self, forKey: .id)
    customer = try container.decodeIfPresent(Customer.self, forKey: .customer)
    currency = try container.decodeIfPresent(Currency.self, forKey: .currency)
    description = try container.decodeIfPresent(String.self, forKey: .description)
    totalPrice = try container.decodeFlexibleDecimal(forKey: .totalPrice)
    createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
    status = try container.decodeIfPresent(String.self, forKey: .status)
    items = try container.decodeIfPresent([OrderItem].self, forKey: .items) ?? []
  }

  init(cache: OrderCache) {
    self.init(
      id: cache.id,
      customer: cache.customer.map(Customer.init(cache:)),
      currency: cache.currency.map(Currency.init(cache:)),
      description: cache.orderDescription,
      totalPrice: cache.totalPrice,
      createdAt: cache.createdAt,
      status: cache.status,
      items: cache.items.map(OrderItem.init(cache:))
    )
  }

  var computedTotal: Decimal {
    items.reduce(Decimal.zero) { partial, item in
      guard let lineTotal = item.lineTotal(currency: currency) else { return partial }
      return partial + lineTotal
    }
  }

  var displayTotal: Decimal {
    totalPrice ?? computedTotal
  }

  var formattedTotal: String {
    PriceFormatter.string(price: displayTotal, currency: currency)
  }
}
