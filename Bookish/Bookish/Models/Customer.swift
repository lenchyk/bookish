//
//  Customer.swift
//  Bookish
//
//  Created by Soroka, Olena on 13.08.2026.
//

import Foundation

struct Customer: Codable, Identifiable, Equatable {
  let id: Int
  let fullname: String?
  let email: String?
  let address: String?
  let currency: Currency?

  init(
    id: Int,
    fullname: String?,
    email: String?,
    address: String?,
    currency: Currency?
  ) {
    self.id = id
    self.fullname = fullname
    self.email = email
    self.address = address
    self.currency = currency
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(Int.self, forKey: .id)
    fullname = try container.decodeIfPresent(String.self, forKey: .fullname)
    email = try container.decodeIfPresent(String.self, forKey: .email)
    address = try container.decodeIfPresent(String.self, forKey: .address)
    currency = try container.decodeIfPresent(Currency.self, forKey: .currency)
  }

  init(cache: CustomerCache) {
    self.init(
      id: cache.id,
      fullname: cache.fullname,
      email: cache.email,
      address: cache.address,
      currency: cache.currency.map(Currency.init(cache:))
    )
  }

  var displayName: String {
    if let fullname, !fullname.isEmpty {
      return fullname
    }
    return "Customer #\(id)"
  }
}
