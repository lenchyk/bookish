//
//  OrderStatus.swift
//  Bookish
//
//  Created by Soroka, Olena on 13.09.2026.
//

import Foundation

enum OrderStatus: String, Codable, CaseIterable, Hashable {
  case pending
  case paid
  case shipped
  case cancelled
  case completed

  init(from decoder: Decoder) throws {
    self = try FlexibleEnumDecoding.value(
      from: decoder,
      aliases: ["canceled": .cancelled]
    )
  }

  var displayName: String {
    rawValue.capitalized
  }
}
