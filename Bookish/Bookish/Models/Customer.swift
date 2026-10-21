//
//  Customer.swift
//  Bookish
//
//  Created by Soroka, Olena on 13.08.2026.
//

import Foundation

struct Customer: Codable, Identifiable, Equatable {
  typealias ID = Identifier<Customer>

  let id: ID
  let fullname: String
  let email: String?
  let address: String?
  let currency: Currency

  init(
    id: ID,
    fullname: String,
    email: String?,
    address: String?,
    currency: Currency
  ) {
    self.id = id
    self.fullname = fullname
    self.email = email
    self.address = address
    self.currency = currency
  }

  init(cache: CustomerCache) {
    id = ID(id: cache.id)
    fullname = cache.fullname
    email = cache.email
    address = cache.address
    currency = Currency(cache: cache.currency)
  }

  var displayName: String {
    fullname.isEmpty ? "Customer #\(id.id)" : fullname
  }
}
